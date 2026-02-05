import { VaultManager } from '../vault/manager.js';
import { ToolResponse } from '../vault/types.js';

export function handleIntel(vault: VaultManager, params: Record<string, unknown>): ToolResponse {
  const area = params.area as string;
  const findings = params.findings as string;

  if (!area || !findings) {
    return { content: [{ type: 'text', text: 'Error: area and findings are required.' }], isError: true };
  }

  const indexMgr = vault.projectIndex;
  if (!indexMgr.exists()) vault.initProject();

  // Check for existing intel on same area
  const existing = indexMgr.search(area);
  if (existing.length > 0) {
    return {
      content: [{
        type: 'text',
        text: `Found existing document **${existing[0].id}** on "${existing[0].topic}". Use **ctx_update** to add findings instead of creating a duplicate.`,
      }],
    };
  }

  const id = indexMgr.getNextId();
  const slug = area.slice(0, 40).toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '');
  const filename = `${id}_intel_${slug}.md`;
  const topic = `Intel: ${area}`;

  const docContent = vault.generateDocContent({
    id,
    title: topic,
    type: 'intel',
    sections: { area, findings },
  });

  vault.writeDocument(id, filename, docContent, 'project');

  const summary = `Explored: ${area.slice(0, 50)}`;
  indexMgr.addEntry({ id, topic, status: 'Active', summary });

  return {
    content: [{ type: 'text', text: `Intel documented to **${filename}**\n\nID: ${id} | Area: ${area}` }],
  };
}
