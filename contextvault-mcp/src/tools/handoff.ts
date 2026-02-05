import { VaultManager } from '../vault/manager.js';
import { ToolResponse } from '../vault/types.js';

export function handleHandoff(vault: VaultManager, params: Record<string, unknown>): ToolResponse {
  const completed = params.completed as string;
  const inProgress = (params.in_progress as string) ?? 'None';
  const nextSteps = params.next_steps as string;

  if (!completed || !nextSteps) {
    return { content: [{ type: 'text', text: 'Error: completed and next_steps are required.' }], isError: true };
  }

  const indexMgr = vault.projectIndex;
  if (!indexMgr.exists()) {
    vault.initProject();
  }

  const today = new Date().toISOString().split('T')[0];
  const id = indexMgr.getNextId();
  const filename = `${id}_handoff_${today}.md`;
  const topic = `Handoff ${today}`;

  const docContent = vault.generateDocContent({
    id,
    title: topic,
    type: 'handoff',
    sections: { completed, in_progress: inProgress, next_steps: nextSteps },
  });

  vault.writeDocument(id, filename, docContent, 'project');

  const summary = `Session handoff: ${nextSteps.slice(0, 40)}`;
  indexMgr.addEntry({ id, topic, status: 'Active', summary });

  return {
    content: [{
      type: 'text',
      text: `Session handoff saved to **${filename}**\n\nID: ${id}\n\n**Next session should:**\n${nextSteps}`,
    }],
  };
}
