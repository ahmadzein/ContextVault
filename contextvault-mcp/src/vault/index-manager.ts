import * as fs from 'node:fs';
import * as path from 'node:path';
import { IndexEntry, VaultTier } from './types.js';

export class IndexManager {
  private vaultPath: string;
  private tier: VaultTier;

  constructor(vaultPath: string, tier: VaultTier) {
    this.vaultPath = vaultPath;
    this.tier = tier;
  }

  private get indexPath(): string {
    return path.join(this.vaultPath, 'index.md');
  }

  private get prefix(): string {
    return this.tier === 'global' ? 'G' : 'P';
  }

  private get projectName(): string {
    if (this.tier === 'global') return 'Global';
    return path.basename(path.resolve(this.vaultPath, '..', '..'));
  }

  exists(): boolean {
    return fs.existsSync(this.indexPath);
  }

  readRaw(): string {
    if (!this.exists()) return '';
    return fs.readFileSync(this.indexPath, 'utf-8');
  }

  parseEntries(): IndexEntry[] {
    const content = this.readRaw();
    if (!content) return [];

    const entries: IndexEntry[] = [];
    const lines = content.split('\n');
    let inTable = false;
    let headerPassed = false;

    for (const line of lines) {
      if (line.includes('| ID') && line.includes('| Topic')) {
        inTable = true;
        continue;
      }
      if (inTable && line.match(/^\|[-\s|]+\|$/)) {
        headerPassed = true;
        continue;
      }
      if (inTable && headerPassed && line.startsWith('|')) {
        const cells = line.split('|').map(c => c.trim()).filter(Boolean);
        if (cells.length >= 4 && cells[0].match(/^[GP]\d{3}$/)) {
          entries.push({
            id: cells[0],
            topic: cells[1],
            status: cells[2],
            summary: cells[3],
          });
        }
      }
      if (inTable && headerPassed && !line.startsWith('|') && line.trim() !== '') {
        inTable = false;
        headerPassed = false;
      }
    }

    return entries;
  }

  getNextId(): string {
    const entries = this.parseEntries();
    if (entries.length === 0) return `${this.prefix}001`;

    const nums = entries
      .map(e => parseInt(e.id.slice(1), 10))
      .filter(n => !isNaN(n));

    const maxNum = nums.length > 0 ? Math.max(...nums) : 0;
    return `${this.prefix}${String(maxNum + 1).padStart(3, '0')}`;
  }

  getEntryCount(): number {
    return this.parseEntries().length;
  }

  addEntry(entry: IndexEntry): void {
    const content = this.readRaw();
    const today = new Date().toISOString().split('T')[0];
    const newRow = `| ${entry.id} | ${entry.topic} | ${entry.status} | ${entry.summary} |`;

    // Find the end of the Active Documents table
    const lines = content.split('\n');
    let insertIdx = -1;

    for (let i = 0; i < lines.length; i++) {
      if (lines[i].includes('| ID') && lines[i].includes('| Topic')) {
        // Find end of this table
        for (let j = i + 2; j < lines.length; j++) {
          if (!lines[j].startsWith('|') || lines[j].trim() === '') {
            insertIdx = j;
            break;
          }
        }
        if (insertIdx === -1) insertIdx = lines.length;
        break;
      }
    }

    if (insertIdx === -1) {
      // No table found - shouldn't happen if index was initialized
      return;
    }

    lines.splice(insertIdx, 0, newRow);

    // Update Quick Stats
    const updatedContent = this.updateStats(lines.join('\n'), today);
    fs.writeFileSync(this.indexPath, updatedContent, 'utf-8');
  }

  updateEntry(id: string, updates: Partial<IndexEntry>): void {
    const content = this.readRaw();
    const today = new Date().toISOString().split('T')[0];
    const lines = content.split('\n');

    for (let i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('|') && lines[i].includes(id)) {
        const cells = lines[i].split('|').map(c => c.trim()).filter(Boolean);
        if (cells[0] === id) {
          const entry: IndexEntry = {
            id: cells[0],
            topic: updates.topic ?? cells[1],
            status: updates.status ?? cells[2],
            summary: updates.summary ?? cells[3],
          };
          lines[i] = `| ${entry.id} | ${entry.topic} | ${entry.status} | ${entry.summary} |`;
          break;
        }
      }
    }

    const updatedContent = this.updateStats(lines.join('\n'), today);
    fs.writeFileSync(this.indexPath, updatedContent, 'utf-8');
  }

  addRelatedTerms(terms: string, docId: string): void {
    const content = this.readRaw();
    const lines = content.split('\n');

    // Find the Related Terms Map table
    let insertIdx = -1;
    let inRelatedTerms = false;

    for (let i = 0; i < lines.length; i++) {
      if (lines[i].includes('If searching for...') && lines[i].includes('Check doc...')) {
        inRelatedTerms = true;
        continue;
      }
      if (inRelatedTerms && lines[i].match(/^\|[-\s|]+\|$/)) {
        continue;
      }
      if (inRelatedTerms && !lines[i].startsWith('|') && lines[i].trim() !== '') {
        insertIdx = i;
        break;
      }
      if (inRelatedTerms && lines[i].startsWith('|')) {
        insertIdx = i + 1;
      }
    }

    if (insertIdx > 0) {
      const newRow = `| ${terms} | ${docId} |`;
      lines.splice(insertIdx, 0, newRow);
      fs.writeFileSync(this.indexPath, lines.join('\n'), 'utf-8');
    }
  }

  private updateStats(content: string, date: string): string {
    const entryCount = this.countEntriesInContent(content);
    // Update entry count
    content = content.replace(
      /\*\*Entries:\*\*\s*\d+\s*\/\s*\d+\s*max/,
      `**Entries:** ${entryCount} / 50 max`
    );
    // Update last updated
    content = content.replace(
      /\*\*Last updated:\*\*\s*\S+/,
      `**Last updated:** ${date}`
    );
    return content;
  }

  private countEntriesInContent(content: string): number {
    const lines = content.split('\n');
    let count = 0;
    let inTable = false;
    let headerPassed = false;

    for (const line of lines) {
      if (line.includes('| ID') && line.includes('| Topic')) {
        inTable = true;
        continue;
      }
      if (inTable && line.match(/^\|[-\s|]+\|$/)) {
        headerPassed = true;
        continue;
      }
      if (inTable && headerPassed && line.startsWith('|')) {
        const cells = line.split('|').map(c => c.trim()).filter(Boolean);
        if (cells[0]?.match(/^[GP]\d{3}$/)) count++;
      }
      if (inTable && headerPassed && !line.startsWith('|') && line.trim() !== '') {
        break;
      }
    }
    return count;
  }

  initialize(): void {
    const tierLabel = this.tier === 'global' ? 'Global' : `Project (${this.projectName})`;
    const prefixNote = this.tier === 'global'
      ? 'G### prefix = Global docs (this folder)'
      : 'P### prefix = Project docs (this folder)';
    const crossNote = this.tier === 'global'
      ? 'P### prefix = Project docs (./.contextvault/)'
      : 'G### prefix = Global docs (~/.contextvault/)';

    const today = new Date().toISOString().split('T')[0];
    const template = `# ContextVault Index - ${tierLabel}

> **${this.tier === 'global' ? 'Cross-project knowledge. Reusable patterns and best practices.' : 'Project-specific knowledge. Only relevant to THIS project.'}**
${this.tier === 'project' ? '> Read global index (~/.contextvault/index.md) FIRST.\n' : ''}
---

## Active Documents

| ID   | Topic | Status | Summary (15 words max) |
|------|-------|--------|------------------------|

---

## Related Terms Map

> Find existing docs when search terms vary

| If searching for... | Check doc... |
|---------------------|--------------|

---

## Archived

| ID | Topic | Archived | Reason |
|----|-------|----------|--------|
| - | - | - | - |

---

## Quick Stats

- **Entries:** 0 / 50 max
- **Last updated:** ${today}

---

## Notes

- ${prefixNote}
- ${crossNote}
- Always search BOTH indexes before creating
`;

    const dir = this.vaultPath;
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    if (!fs.existsSync(path.join(dir, 'archive'))) {
      fs.mkdirSync(path.join(dir, 'archive'), { recursive: true });
    }
    fs.writeFileSync(this.indexPath, template, 'utf-8');
  }

  search(query: string): IndexEntry[] {
    const entries = this.parseEntries();
    const queryLower = query.toLowerCase();
    const queryTerms = queryLower.split(/\s+/);

    return entries
      .map(entry => {
        const text = `${entry.id} ${entry.topic} ${entry.summary}`.toLowerCase();
        let score = 0;
        for (const term of queryTerms) {
          if (text.includes(term)) score++;
        }
        return { entry, score };
      })
      .filter(r => r.score > 0)
      .sort((a, b) => b.score - a.score)
      .map(r => r.entry);
  }
}
