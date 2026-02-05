import * as fs from 'node:fs';
import { VaultManager } from '../vault/manager.js';
import { ToolResponse } from '../vault/types.js';

export function handleNote(vault: VaultManager, params: Record<string, unknown>): ToolResponse {
  const id = params.id as string;
  const note = params.note as string;

  if (!id || !note) {
    return { content: [{ type: 'text', text: 'Error: id and note are required.' }], isError: true };
  }

  const filePath = vault.findDocPath(id);
  if (!filePath) {
    return { content: [{ type: 'text', text: `Document ${id} not found.` }], isError: true };
  }

  const existing = fs.readFileSync(filePath, 'utf-8');
  const today = new Date().toISOString().split('T')[0];

  // Add note before History section
  const historyIdx = existing.indexOf('## History');
  let updated: string;

  if (historyIdx > -1) {
    const noteSection = `## Notes\n\n- **${today}:** ${note}\n\n---\n\n`;
    // Check if Notes section already exists
    const notesIdx = existing.indexOf('## Notes');
    if (notesIdx > -1 && notesIdx < historyIdx) {
      // Append to existing Notes
      const nextSection = existing.indexOf('\n---', notesIdx + 8);
      if (nextSection > -1) {
        updated = existing.slice(0, nextSection) + `\n- **${today}:** ${note}` + existing.slice(nextSection);
      } else {
        updated = existing.slice(0, historyIdx) + `- **${today}:** ${note}\n\n` + existing.slice(historyIdx);
      }
    } else {
      updated = existing.slice(0, historyIdx) + noteSection + existing.slice(historyIdx);
    }
  } else {
    updated = existing + `\n## Notes\n\n- **${today}:** ${note}\n\n---\n`;
  }

  // Update date
  updated = updated.replace(/\*\*Last Updated:\*\*\s*\S+/, `**Last Updated:** ${today}`);

  fs.writeFileSync(filePath, updated, 'utf-8');

  return {
    content: [{ type: 'text', text: `Note added to **${id}**: ${note.slice(0, 60)}` }],
  };
}
