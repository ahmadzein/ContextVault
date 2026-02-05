import { VaultManager } from '../vault/manager.js';
import { ToolResponse } from '../vault/types.js';

export function handleShare(vault: VaultManager, params: Record<string, unknown>): ToolResponse {
  const ids = params.ids as string[];
  const format = (params.format as string) ?? 'md';

  if (!ids || ids.length === 0) {
    return { content: [{ type: 'text', text: 'Error: ids array is required (e.g. ["P001", "P003"]).' }], isError: true };
  }

  const results: { id: string; content: string; found: boolean }[] = [];

  for (const id of ids) {
    const content = vault.readDocument(id);
    results.push({ id, content: content ?? '', found: !!content });
  }

  const notFound = results.filter(r => !r.found);
  if (notFound.length > 0) {
    return {
      content: [{
        type: 'text',
        text: `Documents not found: ${notFound.map(r => r.id).join(', ')}. Use ctx_search to find valid IDs.`,
      }],
      isError: true,
    };
  }

  if (format === 'json') {
    const jsonOutput = results.map(r => ({
      id: r.id,
      content: r.content,
    }));
    return {
      content: [{ type: 'text', text: JSON.stringify(jsonOutput, null, 2) }],
    };
  }

  // Markdown format
  let text = `# Exported Documents\n\n`;
  text += `Exported ${results.length} document(s)\n\n`;

  for (const r of results) {
    text += `---\n\n`;
    text += r.content;
    text += '\n\n';
  }

  return { content: [{ type: 'text', text }] };
}
