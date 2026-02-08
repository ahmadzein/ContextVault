import * as fs from 'node:fs';
import * as path from 'node:path';
import { VaultManager } from '../vault/manager.js';
import { ToolResponse, VaultTier } from '../vault/types.js';

interface ReviewItem {
  id: string;
  topic: string;
  issue: string;
  suggestion: string;
  priority: 'high' | 'medium' | 'low';
}

export function handleReview(vault: VaultManager, params: Record<string, unknown>): ToolResponse {
  const staleDays = (params.stale_days as number) ?? 30;
  const tier: VaultTier = (params.vault as VaultTier) ?? 'project';

  const indexMgr = tier === 'global' ? vault.globalIndex : vault.projectIndex;

  if (!indexMgr.exists()) {
    return { content: [{ type: 'text', text: `Error: ${tier} vault not initialized.` }], isError: true };
  }

  const entries = indexMgr.parseActiveEntries();
  const vaultPath = tier === 'global' ? vault.globalPath : vault.projectPath;
  const today = new Date();

  const reviewItems: ReviewItem[] = [];
  const contentKeywords: Map<string, string[]> = new Map();

  // Check each document
  for (const entry of entries) {
    const docFile = findDocFile(vaultPath, entry.id);
    if (!docFile) continue;

    const docPath = path.join(vaultPath, docFile);
    const stat = fs.statSync(docPath);
    const content = fs.readFileSync(docPath, 'utf-8');

    // Check 1: Stale documents (not modified in X days)
    const daysSinceUpdate = Math.floor((today.getTime() - stat.mtime.getTime()) / (1000 * 60 * 60 * 24));
    if (daysSinceUpdate > staleDays) {
      reviewItems.push({
        id: entry.id,
        topic: entry.topic,
        issue: `Not updated in ${daysSinceUpdate} days`,
        suggestion: 'Review for relevance. Update, merge, or archive.',
        priority: daysSinceUpdate > 90 ? 'high' : 'medium',
      });
    }

    // Check 2: Very short documents (might need expansion or merging)
    const lineCount = content.split('\n').length;
    if (lineCount < 15) {
      reviewItems.push({
        id: entry.id,
        topic: entry.topic,
        issue: `Very short (${lineCount} lines)`,
        suggestion: 'Consider merging with related doc or expanding.',
        priority: 'low',
      });
    }

    // Check 3: Collect content keywords for merge suggestions
    const keywords = extractContentKeywords(entry.topic, content);
    contentKeywords.set(entry.id, keywords);
  }

  // Check 4: Find documents with significant content overlap
  const entryIds = entries.map(e => e.id);
  const suggestedPairs = new Set<string>();

  for (let i = 0; i < entryIds.length; i++) {
    for (let j = i + 1; j < entryIds.length; j++) {
      const idA = entryIds[i];
      const idB = entryIds[j];
      const kwA = contentKeywords.get(idA);
      const kwB = contentKeywords.get(idB);
      if (!kwA || !kwB) continue;

      const shared = kwA.filter(w => kwB.includes(w));
      const smaller = Math.min(kwA.length, kwB.length);
      // Require at least 3 shared keywords AND 30% overlap with the smaller set
      if (shared.length >= 3 && smaller > 0 && (shared.length / smaller) >= 0.3) {
        const pairKey = `${idA}-${idB}`;
        if (!suggestedPairs.has(pairKey)) {
          suggestedPairs.add(pairKey);
          const entryA = entries.find(e => e.id === idA)!;
          const entryB = entries.find(e => e.id === idB)!;
          reviewItems.push({
            id: idA,
            topic: `Related docs`,
            issue: `${shared.length} shared keywords between ${idA} and ${idB}`,
            suggestion: `Consider merging: ${idA}: ${entryA.topic}, ${idB}: ${entryB.topic} (shared: ${shared.slice(0, 5).join(', ')})`,
            priority: 'low',
          });
        }
      }
    }
  }

  // Sort by priority
  const priorityOrder = { high: 0, medium: 1, low: 2 };
  reviewItems.sort((a, b) => priorityOrder[a.priority] - priorityOrder[b.priority]);

  // Generate report
  const highCount = reviewItems.filter(r => r.priority === 'high').length;
  const mediumCount = reviewItems.filter(r => r.priority === 'medium').length;
  const lowCount = reviewItems.filter(r => r.priority === 'low').length;

  let report = `# 📋 Vault Curation Review

**Vault:** ${tier}
**Documents reviewed:** ${entries.length}
**Stale threshold:** ${staleDays} days

---

## Summary

| Priority | Count |
|----------|-------|
| 🔴 High | ${highCount} |
| 🟡 Medium | ${mediumCount} |
| 🟢 Low | ${lowCount} |

`;

  if (reviewItems.length === 0) {
    report += `\n✨ **All clear!** No issues found. Your vault is well-maintained.\n`;
  } else {
    report += `---\n\n## Action Items\n\n`;

    for (const item of reviewItems) {
      const emoji = item.priority === 'high' ? '🔴' : item.priority === 'medium' ? '🟡' : '🟢';
      report += `### ${emoji} ${item.id} - ${item.topic}\n`;
      report += `**Issue:** ${item.issue}\n`;
      report += `**Suggestion:** ${item.suggestion}\n\n`;
    }

    report += `---\n\n## Quick Actions\n\n`;
    report += `- To update a doc: \`ctx_update id="P001"\`\n`;
    report += `- To archive a doc: \`ctx_archive id="P001" reason="..."\`\n`;
    report += `- To read a doc: \`ctx_read id="P001"\`\n`;
  }

  return {
    content: [{ type: 'text', text: report }],
  };
}

// Stop words and type prefixes to exclude from keyword comparison
const STOP_WORDS = new Set([
  'the', 'and', 'for', 'from', 'with', 'that', 'this', 'have', 'has', 'had',
  'are', 'was', 'were', 'been', 'being', 'will', 'would', 'could', 'should',
  'not', 'but', 'its', 'into', 'than', 'then', 'when', 'what', 'where', 'which',
  'each', 'every', 'some', 'more', 'also', 'just', 'about', 'over', 'after',
  'before', 'between', 'under', 'above', 'such', 'only', 'other', 'very',
  'used', 'use', 'using', 'uses', 'file', 'files', 'code', 'docs', 'document',
  'current', 'understanding', 'summary', 'last', 'updated', 'date', 'topic',
  'learning', 'intel', 'snippet', 'error', 'decision', 'plan', 'type',
  'content', 'section', 'key', 'points', 'details', 'notes', 'history',
]);

function extractContentKeywords(topic: string, content: string): string[] {
  const text = `${topic} ${content}`.toLowerCase();
  // Strip markdown formatting
  const clean = text
    .replace(/[#*`_\[\](){}|>~]/g, ' ')
    .replace(/https?:\/\/\S+/g, ' ')
    .replace(/[^a-z0-9\s]/g, ' ');

  const words = clean.split(/\s+/).filter(w =>
    w.length > 3 && !STOP_WORDS.has(w) && !/^\d+$/.test(w)
  );

  // Deduplicate and return
  return [...new Set(words)];
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
