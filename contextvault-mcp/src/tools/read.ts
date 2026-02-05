import { VaultManager } from '../vault/manager.js';
import { ToolResponse } from '../vault/types.js';

export function handleRead(vault: VaultManager, params: Record<string, unknown>): ToolResponse {
  const id = params.id as string;

  if (!id) {
    return { content: [{ type: 'text', text: 'Error: id is required (e.g. "P001" or "G003").' }], isError: true };
  }

  const content = vault.readDocument(id);

  if (!content) {
    return {
      content: [{
        type: 'text',
        text: `Document ${id} not found. Use ctx_search to find documents or ctx_status to check vault.`,
      }],
    };
  }

  return { content: [{ type: 'text', text: content }] };
}
