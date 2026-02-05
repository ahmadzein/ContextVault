import { VaultManager } from '../vault/manager.js';
import { ToolResponse } from '../vault/types.js';

export function handleDecision(vault: VaultManager, params: Record<string, unknown>): ToolResponse {
  const decision = params.decision as string;
  const options = (params.options as string) ?? '';
  const reasoning = params.reasoning as string;
  const tradeoffs = (params.tradeoffs as string) ?? '';

  if (!decision || !reasoning) {
    return { content: [{ type: 'text', text: 'Error: decision and reasoning are required.' }], isError: true };
  }

  const indexMgr = vault.projectIndex;
  if (!indexMgr.exists()) {
    vault.initProject();
  }

  const id = indexMgr.getNextId();
  const slug = decision.slice(0, 40).toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '');
  const filename = `${id}_decision_${slug}.md`;
  const topic = `Decision: ${decision.slice(0, 60)}`;

  const docContent = vault.generateDocContent({
    id,
    title: topic,
    type: 'decision',
    sections: { decision, options, reasoning, tradeoffs },
  });

  vault.writeDocument(id, filename, docContent, 'project');

  const summary = `Chose: ${decision.slice(0, 50)}`;
  indexMgr.addEntry({ id, topic, status: 'Active', summary });
  indexMgr.addRelatedTerms(`decision, ${slug.replace(/_/g, ', ')}`, id);

  return {
    content: [{
      type: 'text',
      text: `Documented decision to **${filename}**\n\nID: ${id} | Decision: ${decision.slice(0, 80)}`,
    }],
  };
}
