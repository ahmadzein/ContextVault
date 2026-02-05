import { VaultManager } from '../vault/manager.js';
import { ToolResponse } from '../vault/types.js';

export function handleSearch(vault: VaultManager, params: Record<string, unknown>): ToolResponse {
  const query = params.query as string;

  if (!query) {
    return { content: [{ type: 'text', text: 'Error: query is required.' }], isError: true };
  }

  const results = vault.search(query);

  if (results.length === 0) {
    return {
      content: [{
        type: 'text',
        text: `No results found for "${query}". Try different keywords or check vault status with ctx_status.`,
      }],
    };
  }

  let text = `# Search Results for "${query}"\n\n`;
  text += `Found ${results.length} result(s):\n\n`;
  text += `| ID | Topic | Vault | Summary |\n`;
  text += `|----|-------|-------|----------|\n`;

  for (const r of results) {
    text += `| ${r.id} | ${r.topic} | ${r.vault} | ${r.summary} |\n`;
  }

  text += `\nUse **ctx_read** with the ID to read the full document.`;

  return { content: [{ type: 'text', text }] };
}
