import { VaultManager } from '../vault/manager.js';
import { ToolResponse, VaultTier } from '../vault/types.js';

type DocType = 'learning' | 'intel' | 'snippet';

export function handleDoc(vault: VaultManager, params: Record<string, unknown>): ToolResponse {
  const topic = params.topic as string;
  const content = params.content as string;
  const docType: DocType = (params.type as DocType) ?? 'learning';

  // Default vault based on type: snippets go global (reusable), others project
  const defaultVault: VaultTier = docType === 'snippet' ? 'global' : 'project';
  const tier: VaultTier = (params.vault as VaultTier) ?? defaultVault;

  // Optional fields for specific types
  const language = params.language as string | undefined;  // for snippets
  const area = params.area as string | undefined;          // for intel (alias for topic)

  // Use area as topic for intel type if topic not provided
  const effectiveTopic = topic || (docType === 'intel' ? area : undefined);

  if (!effectiveTopic || !content) {
    const required = docType === 'intel' ? 'area/topic and findings/content' : 'topic and content';
    return { content: [{ type: 'text', text: `Error: ${required} are required.` }], isError: true };
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
  const existing = indexMgr.search(effectiveTopic);
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
  const typePrefix = docType !== 'learning' ? `${docType}_` : '';
  const slug = effectiveTopic.slice(0, 40).toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '');
  const filename = `${id}_${typePrefix}${slug}.md`;

  // Build display title based on type
  const displayTitle = docType === 'intel' ? `Intel: ${effectiveTopic}` :
                       docType === 'snippet' ? `Snippet: ${effectiveTopic}` :
                       effectiveTopic;

  // Build sections based on type
  let sections: Record<string, string>;
  if (docType === 'snippet') {
    sections = {
      code: content,
      language: language ?? '',
      use_case: params.use_case as string ?? '',
    };
  } else if (docType === 'intel') {
    sections = {
      area: effectiveTopic,
      findings: content,
    };
  } else {
    sections = {
      content,
      key_points: `- ${content.split('.')[0]}`,
    };
  }

  const docContent = vault.generateDocContent({
    id,
    title: displayTitle,
    type: docType === 'learning' ? 'doc' : docType,
    sections,
  });

  vault.writeDocument(id, filename, docContent, tier);

  // Build summary based on type
  let summary: string;
  if (docType === 'snippet') {
    summary = `${language ? language + ' ' : ''}snippet: ${effectiveTopic.slice(0, 40)}`;
  } else if (docType === 'intel') {
    summary = `Explored: ${effectiveTopic.slice(0, 50)}`;
  } else {
    summary = content.split('.')[0].trim().slice(0, 80);
  }

  indexMgr.addEntry({ id, topic: displayTitle, status: 'Active', summary });
  indexMgr.addRelatedTerms(effectiveTopic.toLowerCase().replace(/[^a-z0-9]+/g, ', '), id);

  const typeLabel = docType !== 'learning' ? ` [${docType}]` : '';
  return {
    content: [{
      type: 'text',
      text: `Documented${typeLabel} to **${filename}** (${tier} vault)\n\nID: ${id} | Topic: ${displayTitle}`,
    }],
  };
}
