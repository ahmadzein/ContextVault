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
  const topicGroups: Map<string, string[]> = new Map();

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

    // Check 3: Collect topics for merge suggestions
    const topicWords = entry.topic.toLowerCase().split(/[\s_-]+/);
    for (const word of topicWords) {
      if (word.length > 3) {
        if (!topicGroups.has(word)) topicGroups.set(word, []);
        topicGroups.get(word)!.push(entry.id);
      }
    }
  }

  // Check 4: Find potentially related documents that could be merged
  for (const [word, ids] of topicGroups) {
    if (ids.length >= 2 && ids.length <= 4) {
      // Only suggest if 2-4 docs share a keyword (not too many)
      const relevantEntries = entries.filter(e => ids.includes(e.id));
      const topics = relevantEntries.map(e => `${e.id}: ${e.topic}`).join(', ');

      // Avoid duplicate suggestions
      const existingMergeSuggestion = reviewItems.find(
        r => r.issue.includes('potential merge') && ids.some(id => r.id === id)
      );

      if (!existingMergeSuggestion) {
        reviewItems.push({
          id: ids[0],
          topic: `Related docs: ${word}`,
          issue: `${ids.length} docs share keyword "${word}"`,
          suggestion: `Consider merging: ${topics}`,
          priority: 'low',
        });
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
