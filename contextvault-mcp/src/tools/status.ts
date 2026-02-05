import { VaultManager } from '../vault/manager.js';
import { ToolResponse } from '../vault/types.js';

export function handleStatus(vault: VaultManager): ToolResponse {
  const stats = vault.getStats();

  const text = `# ContextVault Status

| | Status |
|---|---|
| **Global Vault** | ${stats.globalExists ? `${stats.globalDocs}/${stats.globalMaxDocs} docs` : 'Not initialized'} |
| **Project Vault** | ${stats.projectExists ? `${stats.projectDocs}/${stats.projectMaxDocs} docs` : 'Not initialized'} |
| **Mode** | ${stats.mode} |
| **Enforcement** | ${stats.enforcement} |
| **Global Path** | ${stats.globalPath} |
| **Project Path** | ${stats.projectPath} |

${!stats.projectExists ? '\n> **Tip:** Run ctx_init to initialize the project vault.' : ''}`;

  return { content: [{ type: 'text', text: text.trim() }] };
}
