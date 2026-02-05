import * as fs from 'node:fs';
import * as path from 'node:path';
import * as os from 'node:os';
import { VaultManager } from '../vault/manager.js';
import { ToolResponse } from '../vault/types.js';

export function handleImport(vault: VaultManager, params: Record<string, unknown>): ToolResponse {
  const sourcePath = params.source_path as string;

  if (!sourcePath) {
    return { content: [{ type: 'text', text: 'Error: source_path is required. Use "legacy" to import from .claude/vault/' }], isError: true };
  }

  if (sourcePath === 'legacy') {
    return importLegacy(vault);
  }

  // Import from custom path
  if (!fs.existsSync(sourcePath)) {
    return { content: [{ type: 'text', text: `Source path not found: ${sourcePath}` }], isError: true };
  }

  const stat = fs.statSync(sourcePath);

  if (stat.isDirectory()) {
    return importFromDirectory(vault, sourcePath);
  }

  if (sourcePath.endsWith('.md')) {
    return importSingleFile(vault, sourcePath);
  }

  return {
    content: [{ type: 'text', text: `Unsupported source: ${sourcePath}. Provide a directory path, .md file, or use "legacy".` }],
    isError: true,
  };
}

function importLegacy(vault: VaultManager): ToolResponse {
  let text = `# Legacy Import\n\n`;
  let totalImported = 0;
  let totalSkipped = 0;

  // Import from ~/.claude/vault/ (global)
  // Important: import BEFORE init so legacy index.md is preserved
  const legacyGlobal = vault.findLegacyVault('global');
  if (legacyGlobal) {
    // Ensure target directory exists without creating index.md
    const globalPath = vault.globalPath;
    if (!fs.existsSync(globalPath)) {
      fs.mkdirSync(globalPath, { recursive: true });
    }
    const result = vault.importFromLegacy(legacyGlobal, 'global');
    // Ensure settings exist (initGlobal would overwrite index, so just create settings)
    const settingsPath = path.join(globalPath, 'settings.json');
    if (!fs.existsSync(settingsPath)) {
      fs.writeFileSync(settingsPath, JSON.stringify({ mode: 'local', enforcement: 'balanced', limits: { max_global_docs: 50, max_project_docs: 50, max_doc_lines: 100, max_summary_words: 15 } }, null, 2) + '\n');
    }
    if (!fs.existsSync(path.join(globalPath, 'archive'))) {
      fs.mkdirSync(path.join(globalPath, 'archive'), { recursive: true });
    }
    text += `**Global** (${legacyGlobal}):\n`;
    text += `- Imported: ${result.imported} files\n`;
    text += `- Skipped: ${result.skipped} (already exist)\n\n`;
    totalImported += result.imported;
    totalSkipped += result.skipped;
  } else {
    text += `**Global**: No legacy vault found at ~/.claude/vault/\n\n`;
  }

  // Import from ./.claude/vault/ (project)
  const legacyProject = vault.findLegacyVault('project');
  if (legacyProject) {
    // Ensure target directory exists without creating index.md
    const projectPath = vault.projectPath;
    if (!fs.existsSync(projectPath)) {
      fs.mkdirSync(projectPath, { recursive: true });
    }
    if (!fs.existsSync(path.join(projectPath, 'archive'))) {
      fs.mkdirSync(path.join(projectPath, 'archive'), { recursive: true });
    }
    const result = vault.importFromLegacy(legacyProject, 'project');
    text += `**Project** (${legacyProject}):\n`;
    text += `- Imported: ${result.imported} files\n`;
    text += `- Skipped: ${result.skipped} (already exist)\n\n`;
    totalImported += result.imported;
    totalSkipped += result.skipped;
  } else {
    text += `**Project**: No legacy vault found at ./.claude/vault/\n\n`;
  }

  text += `---\n**Total:** ${totalImported} imported, ${totalSkipped} skipped`;

  if (totalImported > 0) {
    text += `\n\n> **Note:** Imported files include index.md and settings.json. You may want to run **ctx_health** to verify vault integrity.`;
  }

  return { content: [{ type: 'text', text }] };
}

function importFromDirectory(vault: VaultManager, dirPath: string): ToolResponse {
  if (!fs.existsSync(vault.projectPath)) {
    fs.mkdirSync(vault.projectPath, { recursive: true });
  }

  const files = fs.readdirSync(dirPath).filter(f => f.endsWith('.md'));
  let imported = 0;
  let skipped = 0;

  for (const file of files) {
    const source = path.join(dirPath, file);
    const dest = path.join(vault.projectPath, file);

    if (fs.existsSync(dest)) {
      skipped++;
      continue;
    }

    fs.copyFileSync(source, dest);
    imported++;
  }

  return {
    content: [{
      type: 'text',
      text: `Imported ${imported} files from ${dirPath}\nSkipped: ${skipped} (already exist)\n\nRun **ctx_health** to verify vault integrity.`,
    }],
  };
}

function importSingleFile(vault: VaultManager, filePath: string): ToolResponse {
  if (!vault.projectExists()) vault.initProject();

  const filename = path.basename(filePath);
  const dest = path.join(vault.projectPath, filename);

  if (fs.existsSync(dest)) {
    return {
      content: [{ type: 'text', text: `File ${filename} already exists in project vault. Use ctx_update to modify it.` }],
    };
  }

  fs.copyFileSync(filePath, dest);

  return {
    content: [{ type: 'text', text: `Imported **${filename}** to project vault.\n\nRun **ctx_health** to verify.` }],
  };
}
