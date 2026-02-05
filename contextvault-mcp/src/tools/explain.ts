import { VaultManager } from '../vault/manager.js';
import { ToolResponse } from '../vault/types.js';

export function handleExplain(vault: VaultManager, params: Record<string, unknown>): ToolResponse {
  const concept = params.concept as string;
  const save = params.save === true;

  if (!concept) {
    return { content: [{ type: 'text', text: 'Error: concept is required.' }], isError: true };
  }

  // Check if we have existing documentation about this concept
  const results = vault.search(concept);
  let existingKnowledge = '';

  if (results.length > 0) {
    existingKnowledge = `\n\n## Existing Vault Knowledge\n\nFound ${results.length} related doc(s):\n`;
    for (const r of results) {
      existingKnowledge += `- **${r.id}** (${r.vault}): ${r.topic} — ${r.summary}\n`;
    }
    existingKnowledge += `\nUse **ctx_read** to see full details.`;
  }

  let text = `# Explain: ${concept}\n\n`;
  text += `This tool helps you document your understanding of "${concept}".\n\n`;
  text += `To save an explanation, provide your explanation content and set save=true. `;
  text += `The explanation will be saved as a new vault document.`;
  text += existingKnowledge;

  if (save) {
    // Save as a document
    const indexMgr = vault.globalIndex.exists() ? vault.globalIndex : vault.projectIndex;
    if (!indexMgr.exists()) vault.initGlobal();

    const id = indexMgr.getNextId();
    const slug = concept.slice(0, 40).toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '');
    const filename = `${id}_explain_${slug}.md`;

    const docContent = vault.generateDocContent({
      id,
      title: `Explain: ${concept}`,
      type: 'explain',
      sections: { concept, explanation: `Explanation of ${concept} — to be filled in by the AI assistant.` },
    });

    const tier = id.startsWith('G') ? 'global' as const : 'project' as const;
    vault.writeDocument(id, filename, docContent, tier);
    indexMgr.addEntry({ id, topic: `Explain: ${concept}`, status: 'Active', summary: `Explanation of ${concept}` });

    text = `Saved explanation template to **${filename}**\n\nID: ${id} | Use **ctx_update** to fill in the explanation.${existingKnowledge}`;
  }

  return { content: [{ type: 'text', text }] };
}
