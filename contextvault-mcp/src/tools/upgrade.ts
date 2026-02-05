import * as fs from 'node:fs';
import * as path from 'node:path';
import { VaultManager } from '../vault/manager.js';
import { ToolResponse } from '../vault/types.js';

export function handleUpgrade(vault: VaultManager): ToolResponse {
  const fixes: string[] = [];

  // Ensure global vault exists
  if (!vault.globalExists()) {
    vault.initGlobal();
    fixes.push('Initialized global vault');
  }

  // Ensure archive directories exist
  const globalArchive = path.join(vault.globalPath, 'archive');
  if (!fs.existsSync(globalArchive)) {
    fs.mkdirSync(globalArchive, { recursive: true });
    fixes.push('Created global archive directory');
  }

  if (vault.projectExists()) {
    const projectArchive = path.join(vault.projectPath, 'archive');
    if (!fs.existsSync(projectArchive)) {
      fs.mkdirSync(projectArchive, { recursive: true });
      fixes.push('Created project archive directory');
    }
  }

  // Ensure settings have all required fields
  const settings = vault.settings.load();
  let settingsUpdated = false;

  if (!settings.enforcement) {
    settings.enforcement = 'balanced';
    settingsUpdated = true;
  }
  if (!settings.limits) {
    settings.limits = {
      max_global_docs: 50,
      max_project_docs: 50,
      max_doc_lines: 100,
      max_summary_words: 15,
    };
    settingsUpdated = true;
  }

  if (settingsUpdated) {
    vault.settings.save(settings);
    fixes.push('Updated settings with missing fields');
  }

  const text = fixes.length > 0
    ? `# Vault Upgraded\n\n${fixes.map(f => `- ${f}`).join('\n')}`
    : `# Vault Up to Date\n\nNo upgrades needed. Everything looks good.`;

  return { content: [{ type: 'text', text }] };
}
