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
      if (refPath.startsWith('http')) continue;
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

export function handleHealth(vault: VaultManager): ToolResponse {
  const issues: string[] = [];
  const fixes: string[] = [];
  const driftIssues: string[] = [];
  let score = 100;

  // Check global vault
  if (vault.globalExists()) {
    const globalEntries = vault.globalIndex.parseEntries();
    const globalFiles = vault.listDocFiles('global');

    // Check for orphaned files (file exists but not in index)
    for (const file of globalFiles) {
      const id = file.split('_')[0];
      if (!globalEntries.find(e => e.id === id)) {
        issues.push(`Orphaned file: ${file} (not in global index)`);
        score -= 5;
      }
    }

    // Check for missing files (in index but file missing)
    for (const entry of globalEntries) {
      if (!globalFiles.find(f => f.startsWith(entry.id + '_'))) {
        issues.push(`Missing file for global index entry: ${entry.id} - ${entry.topic}`);
        score -= 10;
      }
    }

    // Check doc sizes
    for (const file of globalFiles) {
      const content = fs.readFileSync(path.join(vault.globalPath, file), 'utf-8');
      const lines = content.split('\n').length;
      if (lines > 100) {
        issues.push(`${file}: ${lines} lines (exceeds 100-line limit)`);
        score -= 3;
      }

      // Check for code drift (broken file references)
      const refs = extractFileReferences(content, file);
      for (const ref of refs) {
        const issue = checkFileReference(ref, process.cwd());
        if (issue) {
          driftIssues.push(issue);
          score -= 2;
        }
      }
    }
  } else {
    issues.push('Global vault not initialized');
    score -= 10;
  }

  // Check project vault
  if (vault.projectExists()) {
    const projectEntries = vault.projectIndex.parseEntries();
    const projectFiles = vault.listDocFiles('project');

    for (const file of projectFiles) {
      const id = file.split('_')[0];
      if (!projectEntries.find(e => e.id === id)) {
        issues.push(`Orphaned file: ${file} (not in project index)`);
        score -= 5;
      }
    }

    for (const entry of projectEntries) {
      if (!projectFiles.find(f => f.startsWith(entry.id + '_'))) {
        issues.push(`Missing file for project index entry: ${entry.id} - ${entry.topic}`);
        score -= 10;
      }
    }

    for (const file of projectFiles) {
      const content = fs.readFileSync(path.join(vault.projectPath, file), 'utf-8');
      const lines = content.split('\n').length;
      if (lines > 100) {
        issues.push(`${file}: ${lines} lines (exceeds 100-line limit)`);
        score -= 3;
      }

      // Check for code drift (broken file references)
      const refs = extractFileReferences(content, file);
      for (const ref of refs) {
        const issue = checkFileReference(ref, process.cwd());
        if (issue) {
          driftIssues.push(issue);
          score -= 2;
        }
      }
    }
  } else {
    issues.push('Project vault not initialized');
    score -= 5;
  }

  // Check settings
  try {
    vault.settings.load();
  } catch {
    issues.push('Settings file corrupted or missing');
    score -= 5;
  }

  score = Math.max(0, score);

  let text = `# Vault Health Check\n\n`;
  text += `**Score:** ${score}/100 ${score >= 90 ? 'Healthy' : score >= 70 ? 'Fair' : 'Needs Attention'}\n\n`;

  if (issues.length === 0) {
    text += `No issues found. Vault is in great shape.\n`;
  } else {
    text += `## Issues Found (${issues.length})\n\n`;
    for (const issue of issues) {
      text += `- ${issue}\n`;
    }
  }

  if (fixes.length > 0) {
    text += `\n## Auto-Fixed\n\n`;
    for (const fix of fixes) {
      text += `- ${fix}\n`;
    }
  }

  if (driftIssues.length > 0) {
    text += `\n## Code Drift Detected (${driftIssues.length})\n\n`;
    text += `*These docs reference files or line numbers that no longer exist:*\n\n`;
    for (const drift of driftIssues) {
      text += `- ⚠️ ${drift}\n`;
    }
    text += `\n**Tip:** Update or archive these docs to keep documentation accurate.\n`;
  }

  return { content: [{ type: 'text', text }] };
}
