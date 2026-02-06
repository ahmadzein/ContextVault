import * as fs from 'node:fs';
import { VaultManager } from '../vault/manager.js';
import { ToolResponse } from '../vault/types.js';

export function handleLink(vault: VaultManager, params: Record<string, unknown>): ToolResponse {
  const fromId = params.from_id as string;
  const toId = params.to_id as string;

  if (!fromId || !toId) {
    return { content: [{ type: 'text', text: 'Error: from_id and to_id are required.' }], isError: true };
  }

  const fromPath = vault.findDocPath(fromId);
  const toPath = vault.findDocPath(toId);

  if (!fromPath) {
    return { content: [{ type: 'text', text: `Document ${fromId} not found.` }], isError: true };
  }
  if (!toPath) {
    return { content: [{ type: 'text', text: `Document ${toId} not found.` }], isError: true };
  }

  const today = new Date().toISOString().split('T')[0];

  // Add link to source doc
  const fromContent = fs.readFileSync(fromPath, 'utf-8');
  const linkLine = `- Related: **${toId}**`;

  // Check if link already exists
  if (fromContent.includes(`Related: **${toId}**`)) {
    return { content: [{ type: 'text', text: `Link already exists between **${fromId}** and **${toId}**.` }], isError: false };
  }

  let updatedFrom: string;
  const linksIdx = fromContent.indexOf('## Related Documents');
  if (linksIdx > -1) {
    const nextSection = fromContent.indexOf('\n---', linksIdx + 20);
    if (nextSection > -1) {
      updatedFrom = fromContent.slice(0, nextSection) + `\n${linkLine}` + fromContent.slice(nextSection);
    } else {
      updatedFrom = fromContent + `\n${linkLine}\n`;
    }
  } else {
    const historyIdx = fromContent.indexOf('## History');
    if (historyIdx > -1) {
      updatedFrom = fromContent.slice(0, historyIdx) + `## Related Documents\n\n${linkLine}\n\n---\n\n` + fromContent.slice(historyIdx);
    } else {
      updatedFrom = fromContent + `\n## Related Documents\n\n${linkLine}\n\n---\n`;
    }
  }

  updatedFrom = updatedFrom.replace(/\*\*Last Updated:\*\*\s*\S+/, `**Last Updated:** ${today}`);
  fs.writeFileSync(fromPath, updatedFrom, 'utf-8');

  // Add reverse link to target doc
  const toContent = fs.readFileSync(toPath, 'utf-8');
  const reverseLinkLine = `- Related: **${fromId}**`;

  let updatedTo: string;
  const toLinksIdx = toContent.indexOf('## Related Documents');
  if (toLinksIdx > -1) {
    const nextSection = toContent.indexOf('\n---', toLinksIdx + 20);
    if (nextSection > -1) {
      updatedTo = toContent.slice(0, nextSection) + `\n${reverseLinkLine}` + toContent.slice(nextSection);
    } else {
      updatedTo = toContent + `\n${reverseLinkLine}\n`;
    }
  } else {
    const historyIdx = toContent.indexOf('## History');
    if (historyIdx > -1) {
      updatedTo = toContent.slice(0, historyIdx) + `## Related Documents\n\n${reverseLinkLine}\n\n---\n\n` + toContent.slice(historyIdx);
    } else {
      updatedTo = toContent + `\n## Related Documents\n\n${reverseLinkLine}\n\n---\n`;
    }
  }

  updatedTo = updatedTo.replace(/\*\*Last Updated:\*\*\s*\S+/, `**Last Updated:** ${today}`);
  fs.writeFileSync(toPath, updatedTo, 'utf-8');

  return {
    content: [{ type: 'text', text: `Linked **${fromId}** ↔ **${toId}** (bidirectional)` }],
  };
}
