import { VaultManager } from '../vault/manager.js';
import { ToolResponse } from '../vault/types.js';

export function handleInit(vault: VaultManager, params: Record<string, unknown>): ToolResponse {
  const force = params.force === true;

  const result = vault.initProject(force);
  const stats = vault.getStats();

  const setupInstructions = `
## Setup Complete

${result}

**Vault Paths:**
- Global: ${stats.globalPath}
- Project: ${stats.projectPath}

**Mode:** ${stats.mode} | **Enforcement:** ${stats.enforcement}

### Client Configuration

Add this to your MCP client config to connect ContextVault:

\`\`\`json
{
  "mcpServers": {
    "contextvault": {
      "command": "npx",
      "args": ["contextvault-mcp"]
    }
  }
}
\`\`\`

The vault indexes are available as MCP resources and will auto-load in supported clients.
`;

  return { content: [{ type: 'text', text: setupInstructions.trim() }] };
}
