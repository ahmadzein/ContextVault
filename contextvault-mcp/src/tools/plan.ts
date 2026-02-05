import { VaultManager } from '../vault/manager.js';
import { ToolResponse } from '../vault/types.js';

export function handlePlan(vault: VaultManager, params: Record<string, unknown>): ToolResponse {
  const goal = params.goal as string;
  const steps = params.steps as string;
  const status = (params.status as string) ?? 'In Progress';

  if (!goal || !steps) {
    return { content: [{ type: 'text', text: 'Error: goal and steps are required.' }], isError: true };
  }

  const indexMgr = vault.projectIndex;
  if (!indexMgr.exists()) vault.initProject();

  const id = indexMgr.getNextId();
  const slug = goal.slice(0, 40).toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '');
  const filename = `${id}_plan_${slug}.md`;
  const topic = `Plan: ${goal.slice(0, 60)}`;

  const docContent = vault.generateDocContent({
    id,
    title: topic,
    type: 'plan',
    sections: { goal, steps, status },
  });

  vault.writeDocument(id, filename, docContent, 'project');

  const summary = `Plan: ${goal.slice(0, 50)}`;
  indexMgr.addEntry({ id, topic, status: 'Active', summary });

  return {
    content: [{ type: 'text', text: `Plan documented to **${filename}**\n\nID: ${id} | Goal: ${goal.slice(0, 80)}` }],
  };
}
