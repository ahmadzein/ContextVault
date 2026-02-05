import { VaultManager } from '../vault/manager.js';
import { ToolResponse } from '../vault/types.js';

export function handleSnippet(vault: VaultManager, params: Record<string, unknown>): ToolResponse {
  const name = params.name as string;
  const code = params.code as string;
  const language = (params.language as string) ?? '';
  const useCase = (params.use_case as string) ?? '';

  if (!name || !code) {
    return { content: [{ type: 'text', text: 'Error: name and code are required.' }], isError: true };
  }

  // Snippets go to global vault by default (reusable)
  const indexMgr = vault.globalIndex;
  if (!indexMgr.exists()) vault.initGlobal();

  const id = indexMgr.getNextId();
  const slug = name.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '');
  const filename = `${id}_snippet_${slug}.md`;
  const topic = `Snippet: ${name}`;

  const docContent = vault.generateDocContent({
    id,
    title: topic,
    type: 'snippet',
    sections: { code, language, use_case: useCase },
  });

  vault.writeDocument(id, filename, docContent, 'global');

  const summary = `${language ? language + ' ' : ''}snippet: ${name.slice(0, 40)}`;
  indexMgr.addEntry({ id, topic, status: 'Active', summary });

  return {
    content: [{ type: 'text', text: `Snippet saved to **${filename}** (global vault)\n\nID: ${id} | Name: ${name}` }],
  };
}
