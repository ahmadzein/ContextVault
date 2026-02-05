import { VaultManager } from '../vault/manager.js';
import { ToolResponse } from '../vault/types.js';

export function handleError(vault: VaultManager, params: Record<string, unknown>): ToolResponse {
  const errorMessage = params.error_message as string;
  const rootCause = params.root_cause as string;
  const solution = params.solution as string;
  const prevention = (params.prevention as string) ?? '';

  if (!errorMessage || !rootCause || !solution) {
    return { content: [{ type: 'text', text: 'Error: error_message, root_cause, and solution are required.' }], isError: true };
  }

  const indexMgr = vault.projectIndex;
  if (!indexMgr.exists()) {
    vault.initProject();
  }

  const id = indexMgr.getNextId();
  const slug = errorMessage.slice(0, 40).toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '');
  const filename = `${id}_error_${slug}.md`;
  const topic = `Error: ${errorMessage.slice(0, 60)}`;

  const docContent = vault.generateDocContent({
    id,
    title: topic,
    type: 'error',
    sections: { error_message: errorMessage, root_cause: rootCause, solution, prevention },
  });

  vault.writeDocument(id, filename, docContent, 'project');

  const summary = `${rootCause.slice(0, 40)} → ${solution.slice(0, 30)}`;
  indexMgr.addEntry({ id, topic, status: 'Active', summary });
  indexMgr.addRelatedTerms(`error, bug, ${slug.replace(/_/g, ', ')}`, id);

  return {
    content: [{
      type: 'text',
      text: `Documented error to **${filename}**\n\nID: ${id} | Root cause: ${rootCause.slice(0, 60)}`,
    }],
  };
}
