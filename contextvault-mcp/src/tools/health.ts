import * as fs from 'node:fs';
import * as path from 'node:path';
import { VaultManager } from '../vault/manager.js';
import { ToolResponse } from '../vault/types.js';

// Patterns to detect file references in docs
const FILE_REF_PATTERNS = [
  // path/to/file.ext:123 (with line number)
  /`([a-zA-Z0-9_\-./]+\.[a-zA-Z0-9]+):(\d+)`/g,
  // path/to/file.ext (in backticks, no line number)
  /`([a-zA-Z0-9_\-./]+\.[a-zA-Z0-9]+)`/g,
  // **File:** path/to/file.ext
  /\*\*File:\*\*\s*`?([a-zA-Z0-9_\-./]+\.[a-zA-Z0-9]+)`?/g,
  // src/... or lib/... patterns (common code paths)
  /(?:^|\s)((?:src|lib|app|components|utils|hooks|services|api)\/[a-zA-Z0-9_\-./]+\.[a-zA-Z0-9]+)(?::(\d+))?/gm,
];

interface FileReference {
  docFile: string;
  refPath: string;
  lineNumber?: number;
}

function extractFileReferences(content: string, docFile: string): FileReference[] {
  const refs: FileReference[] = [];
  const seen = new Set<string>();

  for (const pattern of FILE_REF_PATTERNS) {
    // Reset pattern for each use
    pattern.lastIndex = 0;
    let match;
    while ((match = pattern.exec(content)) !== null) {
      const refPath = match[1];
      const lineNumber = match[2] ? parseInt(match[2], 10) : undefined;

      // Skip common false positives
      if (refPath.includes('example') || refPath.includes('placeholder')) continue;
      if (refPath.startsWith('http') || refPath.startsWith('www.')) continue;
      if (refPath.startsWith('window.') || refPath.startsWith('document.') || refPath.startsWith('console.')) continue;
      if (refPath.includes('your-') || refPath.includes('your_')) continue;
      if (refPath.match(/^\w+\.\w+$/) && !refPath.includes('/')) continue; // Skip simple dotted names like "content.type"
      if (refPath.length < 5) continue;

      const key = `${refPath}:${lineNumber || ''}`;
      if (!seen.has(key)) {
        seen.add(key);
        refs.push({ docFile, refPath, lineNumber });
      }
    }
  }
  return refs;
}

function checkFileReference(ref: FileReference, projectRoot: string): string | null {
  // Try multiple resolution paths
  const pathsToTry = [
    path.join(projectRoot, ref.refPath),
    path.join(projectRoot, '..', ref.refPath),
    ref.refPath, // Absolute path
  ];

  for (const fullPath of pathsToTry) {
    if (fs.existsSync(fullPath)) {
      // File exists - check line number if specified
      if (ref.lineNumber) {
        try {
          const content = fs.readFileSync(fullPath, 'utf-8');
          const lineCount = content.split('\n').length;
          if (ref.lineNumber > lineCount) {
            return `${ref.docFile}: Reference to ${ref.refPath}:${ref.lineNumber} - file only has ${lineCount} lines`;
          }
        } catch {
          // Can't read file, skip line check
        }
      }
      return null; // File found, no issue
    }
  }

  // File not found
  return `${ref.docFile}: Referenced file not found: ${ref.refPath}${ref.lineNumber ? ':' + ref.lineNumber : ''}`;
}

interface CategoryScore {
  name: string;
  max: number;
  score: number;
  issues: string[];
}

export function handleHealth(vault: VaultManager): ToolResponse {
  const fixes: string[] = [];
  const driftIssues: string[] = [];

  // Per-category scoring
  const categories: Record<string, CategoryScore> = {
    index: { name: 'Index Consistency', max: 25, score: 25, issues: [] },
    files: { name: 'File Integrity', max: 25, score: 25, issues: [] },
    size: { name: 'Size Compliance', max: 25, score: 25, issues: [] },
    drift: { name: 'Code Drift', max: 25, score: 25, issues: [] },
  };

  // Respect mode setting — skip global vault in local mode
  const mode = vault.settings.load().mode;
  const checkGlobal = mode !== 'local';

  // Check global vault (only if mode allows)
  if (checkGlobal && vault.globalExists()) {
    const globalEntries = vault.globalIndex.parseActiveEntries();
    const globalFiles = vault.listDocFiles('global');

    // Orphaned files (file exists but not in index)
    for (const file of globalFiles) {
      const id = file.split('_')[0];
      if (!globalEntries.find(e => e.id === id)) {
        categories.index.issues.push(`Orphaned file: ${file} (not in global index)`);
        categories.index.score -= 5;
      }
    }

    // Missing files (in index but file missing)
    for (const entry of globalEntries) {
      if (!globalFiles.find(f => f.startsWith(entry.id + '_'))) {
        categories.files.issues.push(`Missing file for global index entry: ${entry.id} - ${entry.topic}`);
        categories.files.score -= 10;
      }
    }

    // Doc sizes + code drift
    for (const file of globalFiles) {
      const content = fs.readFileSync(path.join(vault.globalPath, file), 'utf-8');
      const lines = content.split('\n').length;
      if (lines > 100) {
        categories.size.issues.push(`${file}: ${lines} lines (exceeds 100-line limit)`);
        categories.size.score -= 3;
      }

      const refs = extractFileReferences(content, file);
      for (const ref of refs) {
        const issue = checkFileReference(ref, process.cwd());
        if (issue) {
          driftIssues.push(issue);
          categories.drift.score -= 2;
        }
      }
    }
  } else if (checkGlobal) {
    categories.files.issues.push('Global vault not initialized');
    categories.files.score -= 10;
  }

  // Check project vault
  if (vault.projectExists()) {
    const projectEntries = vault.projectIndex.parseActiveEntries();
    const projectFiles = vault.listDocFiles('project');

    for (const file of projectFiles) {
      const id = file.split('_')[0];
      if (!projectEntries.find(e => e.id === id)) {
        categories.index.issues.push(`Orphaned file: ${file} (not in project index)`);
        categories.index.score -= 5;
      }
    }

    for (const entry of projectEntries) {
      if (!projectFiles.find(f => f.startsWith(entry.id + '_'))) {
        categories.files.issues.push(`Missing file for project index entry: ${entry.id} - ${entry.topic}`);
        categories.files.score -= 10;
      }
    }

    for (const file of projectFiles) {
      const content = fs.readFileSync(path.join(vault.projectPath, file), 'utf-8');
      const lines = content.split('\n').length;
      if (lines > 100) {
        categories.size.issues.push(`${file}: ${lines} lines (exceeds 100-line limit)`);
        categories.size.score -= 3;
      }

      const refs = extractFileReferences(content, file);
      for (const ref of refs) {
        const issue = checkFileReference(ref, process.cwd());
        if (issue) {
          driftIssues.push(issue);
          categories.drift.score -= 2;
        }
      }
    }
  } else {
    categories.files.issues.push('Project vault not initialized');
    categories.files.score -= 5;
  }

  // Check settings
  try {
    vault.settings.load();
  } catch {
    categories.index.issues.push('Settings file corrupted or missing');
    categories.index.score -= 5;
  }

  // Clamp category scores to 0
  for (const cat of Object.values(categories)) {
    cat.score = Math.max(0, cat.score);
  }

  const totalScore = Object.values(categories).reduce((sum, c) => sum + c.score, 0);
  const allIssues = Object.values(categories).flatMap(c => c.issues);

  let text = `# Vault Health Check\n\n`;
  text += `**Score:** ${totalScore}/100 ${totalScore >= 90 ? 'Healthy' : totalScore >= 70 ? 'Fair' : 'Needs Attention'}\n\n`;

  // Category breakdown
  text += `## Score Breakdown\n\n`;
  text += `| Category | Score | Status |\n`;
  text += `|----------|-------|--------|\n`;
  for (const cat of Object.values(categories)) {
    const status = cat.score === cat.max ? 'Pass' : cat.score >= cat.max * 0.7 ? 'Fair' : 'Fail';
    text += `| ${cat.name} | ${cat.score}/${cat.max} | ${status} |\n`;
  }
  text += `\n`;

  if (allIssues.length === 0) {
    text += `No issues found. Vault is in great shape.\n`;
  } else {
    text += `## Issues Found (${allIssues.length})\n\n`;
    for (const cat of Object.values(categories)) {
      if (cat.issues.length > 0) {
        text += `### ${cat.name}\n`;
        for (const issue of cat.issues) {
          text += `- ${issue}\n`;
        }
        text += `\n`;
      }
    }
  }

  if (fixes.length > 0) {
    text += `## Auto-Fixed\n\n`;
    for (const fix of fixes) {
      text += `- ${fix}\n`;
    }
  }

  if (driftIssues.length > 0) {
    text += `## Code Drift Detected (${driftIssues.length})\n\n`;
    text += `*These docs reference files or line numbers that no longer exist:*\n\n`;
    for (const drift of driftIssues) {
      text += `- ${drift}\n`;
    }
    text += `\n**Tip:** Update or archive these docs to keep documentation accurate.\n`;
  }

  return { content: [{ type: 'text', text }] };
}
