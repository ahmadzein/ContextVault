import * as fs from 'node:fs';
import * as path from 'node:path';
import { VaultManager } from '../vault/manager.js';
import { ToolResponse } from '../vault/types.js';

export function handleHealth(vault: VaultManager): ToolResponse {
  const issues: string[] = [];
  const fixes: string[] = [];
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

  return { content: [{ type: 'text', text }] };
}
