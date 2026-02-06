import { VaultManager } from '../vault/manager.js';
import { ToolResponse, VaultTier } from '../vault/types.js';

export function handleArchive(vault: VaultManager, params: Record<string, unknown>): ToolResponse {
  const id = params.id as string;
  const reason = params.reason as string;

  if (!id) {
    return { content: [{ type: 'text', text: 'Error: Document ID is required (e.g., "P001", "G003").' }], isError: true };
  }

  if (!reason) {
    return { content: [{ type: 'text', text: 'Error: Reason for archiving is required.' }], isError: true };
  }

  // Determine which vault based on prefix
  const tier: VaultTier = id.startsWith('G') ? 'global' : 'project';
  const indexMgr = tier === 'global' ? vault.globalIndex : vault.projectIndex;

  if (!indexMgr.exists()) {
    return { content: [{ type: 'text', text: `Error: ${tier} vault not initialized.` }], isError: true };
  }

  // Check if document exists
  const entries = indexMgr.parseEntries();
  const entry = entries.find(e => e.id === id);

  if (!entry) {
    return { content: [{ type: 'text', text: `Error: Document ${id} not found in ${tier} vault index.` }], isError: true };
  }

  // Archive the entry
  const result = indexMgr.archiveEntry(id, reason);

  if (!result.success) {
    return { content: [{ type: 'text', text: `Error: ${result.message}` }], isError: true };
  }

  return {
    content: [{
      type: 'text',
      text: `📦 **Archived successfully**

**Document:** ${id} - ${entry.topic}
**Reason:** ${reason}
**Location:** ${tier} vault → archive/

The document has been:
1. Moved to \`archive/\` folder with archive header
2. Removed from Active Documents table
3. Added to Archived table in index

To restore, manually move the file back and update the index.`,
    }],
  };
}
