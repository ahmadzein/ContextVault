import * as fs from 'node:fs';
import { VaultManager } from '../vault/manager.js';
import { ToolResponse } from '../vault/types.js';

export function handleUpdate(vault: VaultManager, params: Record<string, unknown>): ToolResponse {
  const id = params.id as string;
  const section = (params.section as string) ?? '';
  const content = params.content as string;

  if (!id || !content) {
    return { content: [{ type: 'text', text: 'Error: id and content are required.' }], isError: true };
  }

  const filePath = vault.findDocPath(id);
  if (!filePath) {
    return { content: [{ type: 'text', text: `Document ${id} not found.` }], isError: true };
  }

  const existing = fs.readFileSync(filePath, 'utf-8');
  const today = new Date().toISOString().split('T')[0];
  let updated: string = existing;

  if (section) {
    // Find the section and append to it
    const sectionHeader = `## ${section}`;
    const sectionIdx = existing.indexOf(sectionHeader);

    if (sectionIdx === -1) {
      // Section not found, add it before History
      const historyIdx = existing.indexOf('## History');
      if (historyIdx > -1) {
        updated = existing.slice(0, historyIdx) + `## ${section}\n\n${content}\n\n---\n\n` + existing.slice(historyIdx);
      } else {
        updated = existing + `\n## ${section}\n\n${content}\n\n---\n`;
      }
    } else {
      // Find the next section or --- divider
      const afterSection = existing.slice(sectionIdx + sectionHeader.length);
      const nextSection = afterSection.search(/\n## |\n---/);

      if (nextSection > -1) {
        const insertPoint = sectionIdx + sectionHeader.length + nextSection;
        updated = existing.slice(0, insertPoint) + `\n${content}\n` + existing.slice(insertPoint);
      } else {
        updated = existing + `\n${content}\n`;
      }
    }
  } else {
    // No section specified — append to "Current Understanding" or "Summary"
    const targets = ['## Current Understanding', '## Summary', '## Key Points'];
    let found = false;

    for (const target of targets) {
      const idx = existing.indexOf(target);
      if (idx > -1) {
        const afterTarget = existing.slice(idx + target.length);
        const nextSection = afterTarget.search(/\n## |\n---/);
        if (nextSection > -1) {
          const insertPoint = idx + target.length + nextSection;
          updated = existing.slice(0, insertPoint) + `\n\n${content}` + existing.slice(insertPoint);
        } else {
          updated = existing + `\n\n${content}`;
        }
        found = true;
        break;
      }
    }

    if (!found) {
      updated = existing + `\n\n${content}\n`;
    }
  }

  // Update Last Updated date
  updated = updated.replace(
    /\*\*Last Updated:\*\*\s*\S+/,
    `**Last Updated:** ${today}`
  );

  // Add to History
  const historyIdx = updated.indexOf('## History');
  if (historyIdx > -1) {
    const tableStart = updated.indexOf('|------|', historyIdx);
    if (tableStart > -1) {
      const lineEnd = updated.indexOf('\n', tableStart);
      const historyEntry = `\n| ${today} | Updated${section ? ` ${section}` : ''} |`;
      updated = updated.slice(0, lineEnd) + historyEntry + updated.slice(lineEnd);
    }
  }

  fs.writeFileSync(filePath, updated, 'utf-8');

  // Update index
  const indexMgr = id.startsWith('G') ? vault.globalIndex : vault.projectIndex;
  indexMgr.updateEntry(id, { status: 'Active' });

  // Reset enforcement counters (documentation was created/updated)
  vault.resetEnforcement();

  return {
    content: [{ type: 'text', text: `Updated **${id}**${section ? ` (section: ${section})` : ''}\n\nContent appended successfully.` }],
  };
}
