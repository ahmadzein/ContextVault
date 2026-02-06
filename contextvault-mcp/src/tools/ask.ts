import * as fs from 'node:fs';
import * as path from 'node:path';
import { VaultManager } from '../vault/manager.js';
import { ToolResponse, VaultTier, IndexEntry } from '../vault/types.js';

export function handleAsk(vault: VaultManager, params: Record<string, unknown>): ToolResponse {
  const question = params.question as string;

  if (!question) {
    return { content: [{ type: 'text', text: 'Error: Question is required.' }], isError: true };
  }

  // Extract keywords from question
  const stopWords = new Set(['what', 'how', 'why', 'when', 'where', 'who', 'which', 'is', 'are', 'was', 'were', 'the', 'a', 'an', 'to', 'for', 'of', 'in', 'on', 'at', 'by', 'with', 'about', 'do', 'does', 'did', 'can', 'could', 'would', 'should', 'will', 'have', 'has', 'had', 'be', 'been', 'being', 'this', 'that', 'these', 'those', 'it', 'its', 'we', 'our', 'you', 'your', 'they', 'their', 'i', 'my', 'me']);

  const keywords = question
    .toLowerCase()
    .replace(/[?.,!'"]/g, '')
    .split(/\s+/)
    .filter(w => w.length > 2 && !stopWords.has(w));

  if (keywords.length === 0) {
    return { content: [{ type: 'text', text: 'Error: Could not extract meaningful keywords from question. Please be more specific.' }], isError: true };
  }

  // Search both vaults
  const projectResults = vault.projectIndex.exists() ? vault.projectIndex.search(keywords.join(' ')) : [];
  const globalResults = vault.globalIndex.exists() ? vault.globalIndex.search(keywords.join(' ')) : [];

  // Combine and rank results
  interface RankedResult extends IndexEntry {
    vault: VaultTier;
    score: number;
  }

  const allResults: RankedResult[] = [
    ...projectResults.map((e, i) => ({ ...e, vault: 'project' as VaultTier, score: projectResults.length - i })),
    ...globalResults.map((e, i) => ({ ...e, vault: 'global' as VaultTier, score: globalResults.length - i })),
  ];

  // Take top 3 most relevant
  const topResults = allResults
    .sort((a, b) => b.score - a.score)
    .slice(0, 3);

  if (topResults.length === 0) {
    return {
      content: [{
        type: 'text',
        text: `❓ No relevant documents found for: "${question}"\n\n**Keywords searched:** ${keywords.join(', ')}\n\n**Suggestions:**\n- Try different keywords\n- Check if the topic has been documented\n- Use \`ctx_search\` for broader search`,
      }],
    };
  }

  // Read the content of top documents
  const docContents: { id: string; topic: string; content: string; vault: VaultTier }[] = [];

  for (const result of topResults) {
    const vaultPath = result.vault === 'global' ? vault.globalPath : vault.projectPath;
    const docFile = findDocFile(vaultPath, result.id);

    if (docFile) {
      const content = fs.readFileSync(path.join(vaultPath, docFile), 'utf-8');
      docContents.push({
        id: result.id,
        topic: result.topic,
        content: extractRelevantSections(content, keywords),
        vault: result.vault,
      });
    }
  }

  // Generate answer
  let response = `# 💡 Answer: ${question}\n\n`;
  response += `**Based on ${docContents.length} relevant document(s):**\n\n`;

  for (const doc of docContents) {
    response += `---\n\n`;
    response += `## 📄 ${doc.id}: ${doc.topic} (${doc.vault})\n\n`;
    response += doc.content;
    response += `\n\n`;
  }

  response += `---\n\n`;
  response += `**To read full documents:**\n`;
  for (const doc of docContents) {
    response += `- \`ctx_read id="${doc.id}"\`\n`;
  }

  return {
    content: [{ type: 'text', text: response }],
  };
}

function findDocFile(vaultPath: string, id: string): string | null {
  try {
    const files = fs.readdirSync(vaultPath);
    for (const file of files) {
      if (file.startsWith(id) && file.endsWith('.md') && !file.includes('index')) {
        return file;
      }
    }
  } catch {
    return null;
  }
  return null;
}

function extractRelevantSections(content: string, keywords: string[]): string {
  const lines = content.split('\n');
  const relevantLines: string[] = [];
  let inRelevantSection = false;
  let sectionDepth = 0;

  // Always include the summary section
  let inSummary = false;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const lineLower = line.toLowerCase();

    // Track summary section
    if (line.startsWith('## Summary') || line.startsWith('> **')) {
      inSummary = true;
    }
    if (inSummary && line.startsWith('## ') && !line.includes('Summary')) {
      inSummary = false;
    }
    if (inSummary) {
      relevantLines.push(line);
      continue;
    }

    // Check if line contains any keyword
    const hasKeyword = keywords.some(k => lineLower.includes(k));

    if (line.startsWith('#')) {
      // Section header
      if (hasKeyword) {
        inRelevantSection = true;
        sectionDepth = line.match(/^#+/)?.[0].length ?? 1;
        relevantLines.push(line);
      } else {
        const currentDepth = line.match(/^#+/)?.[0].length ?? 1;
        if (currentDepth <= sectionDepth) {
          inRelevantSection = false;
        }
        if (inRelevantSection) {
          relevantLines.push(line);
        }
      }
    } else if (inRelevantSection || hasKeyword) {
      relevantLines.push(line);
      if (hasKeyword && !inRelevantSection) {
        // Include some context around keyword matches
        if (i > 0 && !relevantLines.includes(lines[i - 1])) {
          relevantLines.unshift(lines[i - 1]);
        }
        if (i < lines.length - 1) {
          relevantLines.push(lines[i + 1]);
          i++; // Skip next line since we added it
        }
      }
    }
  }

  // Limit output length
  const result = relevantLines.slice(0, 30).join('\n');
  if (relevantLines.length > 30) {
    return result + '\n\n*[Content truncated - use ctx_read for full document]*';
  }
  return result || '*No directly relevant sections found. Use ctx_read for full document.*';
}
