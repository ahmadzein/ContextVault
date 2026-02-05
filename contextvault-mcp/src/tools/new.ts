import { VaultManager } from '../vault/manager.js';
import { ToolResponse, VaultTier } from '../vault/types.js';

export function handleNew(vault: VaultManager, params: Record<string, unknown>): ToolResponse {
  const title = params.title as string;
  const content = params.content as string;
  const tier: VaultTier = (params.vault as VaultTier) ?? 'project';

  if (!title || !content) {
    return { content: [{ type: 'text', text: 'Error: title and content are required.' }], isError: true };
  }

  const indexMgr = tier === 'global' ? vault.globalIndex : vault.projectIndex;
  if (!indexMgr.exists()) {
    tier === 'global' ? vault.initGlobal() : vault.initProject();
  }

  const id = indexMgr.getNextId();
  const slug = title.slice(0, 40).toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '');
  const filename = `${id}_${slug}.md`;

  const docContent = vault.generateDocContent({
    id,
    title,
    type: 'doc',
    sections: { content },
  });

  vault.writeDocument(id, filename, docContent, tier);

  const summary = content.split('.')[0].trim().slice(0, 80);
  indexMgr.addEntry({ id, topic: title, status: 'Active', summary });

  return {
    content: [{ type: 'text', text: `Created **${filename}** (${tier} vault)\n\nID: ${id} | Title: ${title}` }],
  };
}
