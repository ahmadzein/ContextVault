import { VaultManager } from '../vault/manager.js';
import { ToolResponse, VaultTier } from '../vault/types.js';

export function handleDoc(vault: VaultManager, params: Record<string, unknown>): ToolResponse {
  const topic = params.topic as string;
  const content = params.content as string;
  const tier: VaultTier = (params.vault as VaultTier) ?? 'project';

  if (!topic || !content) {
    return { content: [{ type: 'text', text: 'Error: topic and content are required.' }], isError: true };
  }

  const indexMgr = tier === 'global' ? vault.globalIndex : vault.projectIndex;

  if (!indexMgr.exists()) {
    if (tier === 'project') {
      vault.initProject();
    } else {
      vault.initGlobal();
    }
  }

  // Check for existing doc on same topic
  const existing = indexMgr.search(topic);
  if (existing.length > 0) {
    return {
      content: [{
        type: 'text',
        text: `Found existing document **${existing[0].id}** on "${existing[0].topic}". Use **ctx_update** to update it instead of creating a duplicate.\n\nExisting summary: ${existing[0].summary}`,
      }],
    };
  }

  const settings = vault.settings.load();
  const maxDocs = tier === 'global' ? settings.limits.max_global_docs : settings.limits.max_project_docs;
  const currentCount = indexMgr.getEntryCount();

  if (currentCount >= maxDocs) {
    return { content: [{ type: 'text', text: `Error: ${tier} vault is full (${currentCount}/${maxDocs} docs). Archive old docs first.` }], isError: true };
  }

  const id = indexMgr.getNextId();
  const slug = topic.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '');
  const filename = `${id}_${slug}.md`;

  const docContent = vault.generateDocContent({
    id,
    title: topic,
    type: 'doc',
    sections: { content, key_points: `- ${content.split('.')[0]}` },
  });

  vault.writeDocument(id, filename, docContent, tier);

  const summary = content.split('.')[0].trim().slice(0, 80);
  indexMgr.addEntry({ id, topic, status: 'Active', summary });
  indexMgr.addRelatedTerms(topic.toLowerCase().replace(/[^a-z0-9]+/g, ', '), id);

  return {
    content: [{
      type: 'text',
      text: `Documented to **${filename}** (${tier} vault)\n\nID: ${id} | Topic: ${topic}`,
    }],
  };
}
