import * as fs from 'node:fs';
import * as path from 'node:path';
import * as os from 'node:os';
import { VaultSettings, VaultTier, VaultStats, SearchResult, DocumentMeta, EnforcementState, DEFAULT_SETTINGS } from './types.js';
import { IndexManager } from './index-manager.js';
import { SettingsManager } from './settings.js';

export class VaultManager {
  private _globalPath: string;
  private _projectPath: string;
  private _settings: SettingsManager;
  private _globalIndex: IndexManager;
  private _projectIndex: IndexManager;
  private _enforcement: EnforcementState;

  constructor(projectRoot?: string) {
    const root = projectRoot ?? process.cwd();

    // Auto-detect vault paths: prefer legacy .claude/vault/ if it exists,
    // fall back to .contextvault/ for new installations
    this._globalPath = this.detectGlobalPath();
    this._projectPath = this.detectProjectPath(root);

    this._settings = new SettingsManager(this._globalPath);
    this._globalIndex = new IndexManager(this._globalPath, 'global');
    this._projectIndex = new IndexManager(this._projectPath, 'project');
    this._enforcement = {
      editCount: 0,
      filesEdited: new Set(),
      lastDocTime: Date.now(),
      sessionStart: Date.now(),
      researchCount: 0,
      areasExplored: new Set(),
      lastResearchTime: Date.now(),
    };
  }

  private detectGlobalPath(): string {
    // Check legacy Claude Code path first
    const legacyPath = path.join(os.homedir(), '.claude', 'vault');
    if (fs.existsSync(path.join(legacyPath, 'index.md'))) {
      return legacyPath;
    }
    // Then check new CLI-agnostic path
    return path.join(os.homedir(), '.contextvault');
  }

  private detectProjectPath(root: string): string {
    // Check legacy Claude Code path first
    const legacyPath = path.join(root, '.claude', 'vault');
    if (fs.existsSync(path.join(legacyPath, 'index.md'))) {
      return legacyPath;
    }
    // Then check new CLI-agnostic path
    return path.join(root, '.contextvault');
  }

  get globalPath(): string { return this._globalPath; }
  get projectPath(): string { return this._projectPath; }
  get settings(): SettingsManager { return this._settings; }
  get globalIndex(): IndexManager { return this._globalIndex; }
  get projectIndex(): IndexManager { return this._projectIndex; }
  get enforcement(): EnforcementState { return this._enforcement; }

  // --- Vault existence checks ---

  globalExists(): boolean {
    return this._globalIndex.exists();
  }

  projectExists(): boolean {
    return this._projectIndex.exists();
  }

  // --- Initialize vaults ---

  initGlobal(): void {
    if (!fs.existsSync(this._globalPath)) {
      fs.mkdirSync(this._globalPath, { recursive: true });
    }
    if (!this._globalIndex.exists()) {
      this._globalIndex.initialize();
    }
    // Create default settings if missing
    const settingsPath = path.join(this._globalPath, 'settings.json');
    if (!fs.existsSync(settingsPath)) {
      this._settings.save(DEFAULT_SETTINGS);
    }
  }

  initProject(force = false): string {
    if (this._projectIndex.exists() && !force) {
      return 'Project vault already initialized. Use force=true to reinitialize.';
    }

    // Ensure global vault exists too
    this.initGlobal();

    if (!fs.existsSync(this._projectPath)) {
      fs.mkdirSync(this._projectPath, { recursive: true });
    }
    this._projectIndex.initialize();
    return `Vault initialized at ${this._projectPath}`;
  }

  // --- Read/Write documents ---

  readDocument(id: string): string | null {
    const filePath = this.findDocPath(id);
    if (!filePath) return null;
    return fs.readFileSync(filePath, 'utf-8');
  }

  findDocPath(id: string): string | null {
    const tier = id.startsWith('G') ? 'global' : 'project';
    const vaultPath = tier === 'global' ? this._globalPath : this._projectPath;

    if (!fs.existsSync(vaultPath)) return null;

    const files = fs.readdirSync(vaultPath);
    const match = files.find(f => f.startsWith(id + '_') && f.endsWith('.md'));
    if (match) return path.join(vaultPath, match);

    return null;
  }

  writeDocument(id: string, filename: string, content: string, tier: VaultTier): string {
    const vaultPath = tier === 'global' ? this._globalPath : this._projectPath;
    const filePath = path.join(vaultPath, filename);

    if (!fs.existsSync(vaultPath)) {
      fs.mkdirSync(vaultPath, { recursive: true });
    }

    fs.writeFileSync(filePath, content, 'utf-8');
    this.resetEnforcement();
    return filePath;
  }

  // --- Search ---

  search(query: string): SearchResult[] {
    const settings = this._settings.load();
    const results: SearchResult[] = [];

    if (settings.mode !== 'global' && this.projectExists()) {
      const projectEntries = this._projectIndex.search(query);
      for (const entry of projectEntries) {
        results.push({
          id: entry.id,
          topic: entry.topic,
          summary: entry.summary,
          vault: 'project',
          relevance: 1,
        });
      }
    }

    if (settings.mode !== 'local' && this.globalExists()) {
      const globalEntries = this._globalIndex.search(query);
      for (const entry of globalEntries) {
        results.push({
          id: entry.id,
          topic: entry.topic,
          summary: entry.summary,
          vault: 'global',
          relevance: 1,
        });
      }
    }

    return results;
  }

  // --- Stats ---

  getStats(): VaultStats {
    const settings = this._settings.load();
    return {
      globalDocs: this.globalExists() ? this._globalIndex.getEntryCount() : 0,
      projectDocs: this.projectExists() ? this._projectIndex.getEntryCount() : 0,
      globalMaxDocs: settings.limits.max_global_docs,
      projectMaxDocs: settings.limits.max_project_docs,
      globalPath: this._globalPath,
      projectPath: this._projectPath,
      globalExists: this.globalExists(),
      projectExists: this.projectExists(),
      mode: settings.mode,
      enforcement: settings.enforcement,
    };
  }

  // --- Enforcement ---

  trackEdit(filePath?: string): void {
    this._enforcement.editCount++;
    if (filePath) {
      this._enforcement.filesEdited.add(filePath);
    }
  }

  trackResearch(identifier?: string): void {
    this._enforcement.researchCount++;
    this._enforcement.lastResearchTime = Date.now();
    if (identifier) {
      this._enforcement.areasExplored.add(identifier);
    }
  }

  // --- Semantic Clustering: Domain categorization ---

  private categorizeDomain(identifier: string): string {
    const lower = identifier.toLowerCase();

    // Frontend domains
    if (/\/(components?|ui|views?|pages?|layouts?|widgets?)\//.test(lower) ||
        /\.(tsx|jsx|vue|svelte)$/.test(lower) ||
        /css|style|theme|tailwind/.test(lower)) {
      return 'frontend';
    }

    // Backend/API domains
    if (/\/(api|routes?|controllers?|handlers?|middleware|endpoints?)\//.test(lower) ||
        /server|express|fastify|nest/.test(lower)) {
      return 'backend';
    }

    // Database/ORM domains
    if (/\/(models?|schemas?|migrations?|seeds?|entities|repositories)\//.test(lower) ||
        /prisma|drizzle|typeorm|sequelize|mongoose|sql|database/.test(lower)) {
      return 'database';
    }

    // Testing domains
    if (/\/(tests?|__tests__|spec|e2e|integration|unit)\//.test(lower) ||
        /\.(test|spec)\.(ts|js|tsx|jsx)$/.test(lower) ||
        /jest|vitest|mocha|cypress|playwright/.test(lower)) {
      return 'testing';
    }

    // Config/DevOps domains
    if (/\/(config|configs|\.config|settings)\//.test(lower) ||
        /dockerfile|docker-compose|\.yml$|\.yaml$|webpack|vite|tsconfig|package\.json/.test(lower)) {
      return 'config';
    }

    // Utilities/Helpers
    if (/\/(utils?|helpers?|lib|common|shared)\//.test(lower)) {
      return 'utils';
    }

    // Services/Business logic
    if (/\/(services?|usecases?|domains?|core)\//.test(lower)) {
      return 'services';
    }

    // Types/Interfaces
    if (/\/(types?|interfaces?|dtos?)\//.test(lower) ||
        /\.d\.ts$/.test(lower)) {
      return 'types';
    }

    // Documentation/Content
    if (/\.(md|mdx|txt|rst)$/.test(lower) ||
        /\/(docs?|documentation|content)\//.test(lower)) {
      return 'docs';
    }

    return 'other';
  }

  getDomainsExplored(): Set<string> {
    const domains = new Set<string>();
    for (const area of this._enforcement.areasExplored) {
      domains.add(this.categorizeDomain(area));
    }
    return domains;
  }

  getDomainDiversityScore(): number {
    const domains = this.getDomainsExplored();
    // Score: 1.0 for 1 domain, up to 2.0 for 5+ domains
    // Cross-domain exploration is more significant
    const domainCount = domains.size;
    if (domainCount <= 1) return 1.0;
    if (domainCount === 2) return 1.25;
    if (domainCount === 3) return 1.5;
    if (domainCount === 4) return 1.75;
    return 2.0; // 5+ domains
  }

  resetEnforcement(): void {
    this._enforcement.editCount = 0;
    this._enforcement.filesEdited.clear();
    this._enforcement.lastDocTime = Date.now();
    this._enforcement.researchCount = 0;
    this._enforcement.areasExplored.clear();
    this._enforcement.lastResearchTime = Date.now();
  }

  getEnforcementReminder(): string | null {
    const settings = this._settings.load();
    const { editCount, filesEdited } = this._enforcement;

    let editThreshold: number;
    let fileThreshold: number;

    switch (settings.enforcement) {
      case 'light':
        return null; // No mid-work reminders
      case 'strict':
        editThreshold = 4;
        fileThreshold = 2;
        break;
      case 'balanced':
      default:
        editThreshold = 8;
        fileThreshold = 2;
        break;
    }

    if (editCount >= editThreshold && filesEdited.size >= fileThreshold) {
      return `\n\n---\n**ContextVault Reminder:** You've made ${editCount} edits across ${filesEdited.size} files without documenting. Consider using ctx_doc, ctx_error, or ctx_decision to capture what you've learned.`;
    }

    return null;
  }

  getResearchReminder(): string | null {
    const settings = this._settings.load();
    const { researchCount, areasExplored, lastDocTime } = this._enforcement;

    let researchThreshold: number;
    let areaThreshold: number;
    let timeSinceDocMinutes: number;

    switch (settings.enforcement) {
      case 'light':
        return null; // No research reminders
      case 'strict':
        researchThreshold = 6;
        areaThreshold = 3;
        timeSinceDocMinutes = 5;
        break;
      case 'balanced':
      default:
        researchThreshold = 10;
        areaThreshold = 4;
        timeSinceDocMinutes = 10;
        break;
    }

    const minutesSinceDoc = (Date.now() - lastDocTime) / (1000 * 60);

    // Apply domain diversity weighting
    // Cross-domain exploration (frontend + backend + db) is more significant
    const diversityScore = this.getDomainDiversityScore();
    const effectiveResearchCount = Math.round(researchCount * diversityScore);
    const domainsExplored = this.getDomainsExplored();

    if (
      effectiveResearchCount >= researchThreshold &&
      areasExplored.size >= areaThreshold &&
      minutesSinceDoc >= timeSinceDocMinutes
    ) {
      const domainList = Array.from(domainsExplored).slice(0, 4).join(', ');
      const domainMsg = domainsExplored.size > 1 ? ` across ${domainsExplored.size} domains (${domainList})` : '';
      return `\n\n---\n**ContextVault Nudge:** You've explored ${areasExplored.size} areas${domainMsg} with ${researchCount} lookups without documenting findings. Consider using ctx_doc (type=intel) to capture what you've discovered.`;
    }

    return null;
  }

  // --- Document template generation ---

  generateDocContent(params: {
    id: string;
    title: string;
    type: 'doc' | 'error' | 'decision' | 'plan' | 'snippet' | 'intel' | 'handoff' | 'explain';
    sections: Record<string, string>;
  }): string {
    const today = new Date().toISOString().split('T')[0];
    let content = `# ${params.id} - ${params.title}\n\n`;
    content += `> **Status:** Active\n`;
    content += `> **Created:** ${today}\n`;
    content += `> **Last Updated:** ${today}\n\n---\n\n`;

    switch (params.type) {
      case 'error':
        content += `## Error\n\n${params.sections['error_message'] ?? 'N/A'}\n\n`;
        content += `## Root Cause\n\n${params.sections['root_cause'] ?? 'N/A'}\n\n`;
        content += `## Solution\n\n${params.sections['solution'] ?? 'N/A'}\n\n`;
        content += `## Prevention\n\n${params.sections['prevention'] ?? 'N/A'}\n\n`;
        break;

      case 'decision':
        content += `## Decision\n\n${params.sections['decision'] ?? 'N/A'}\n\n`;
        content += `## Options Considered\n\n${params.sections['options'] ?? 'N/A'}\n\n`;
        content += `## Reasoning\n\n${params.sections['reasoning'] ?? 'N/A'}\n\n`;
        content += `## Trade-offs\n\n${params.sections['tradeoffs'] ?? 'N/A'}\n\n`;
        break;

      case 'plan':
        content += `## Goal\n\n${params.sections['goal'] ?? 'N/A'}\n\n`;
        content += `## Steps\n\n${params.sections['steps'] ?? 'N/A'}\n\n`;
        content += `## Status\n\n${params.sections['status'] ?? 'In Progress'}\n\n`;
        break;

      case 'snippet':
        content += `## Use Case\n\n${params.sections['use_case'] ?? 'N/A'}\n\n`;
        content += `## Code\n\n\`\`\`${params.sections['language'] ?? ''}\n${params.sections['code'] ?? ''}\n\`\`\`\n\n`;
        break;

      case 'intel':
        content += `## Area Explored\n\n${params.sections['area'] ?? 'N/A'}\n\n`;
        content += `## Findings\n\n${params.sections['findings'] ?? 'N/A'}\n\n`;
        break;

      case 'handoff':
        content += `## Completed\n\n${params.sections['completed'] ?? 'N/A'}\n\n`;
        content += `## In Progress\n\n${params.sections['in_progress'] ?? 'N/A'}\n\n`;
        content += `## Next Steps\n\n${params.sections['next_steps'] ?? 'N/A'}\n\n`;
        break;

      case 'explain':
        content += `## Concept\n\n${params.sections['concept'] ?? 'N/A'}\n\n`;
        content += `## Explanation\n\n${params.sections['explanation'] ?? 'N/A'}\n\n`;
        break;

      case 'doc':
      default:
        content += `## Summary\n\n${params.sections['content'] ?? 'N/A'}\n\n`;
        content += `## Key Points\n\n${params.sections['key_points'] ?? '- See summary above'}\n\n`;
        break;
    }

    content += `---\n\n## History\n\n| Date | Change |\n|------|--------|\n| ${today} | Initial creation |\n\n---\n`;

    return content;
  }

  // --- File listing for health checks ---

  listDocFiles(tier: VaultTier): string[] {
    const vaultPath = tier === 'global' ? this._globalPath : this._projectPath;
    if (!fs.existsSync(vaultPath)) return [];

    return fs.readdirSync(vaultPath)
      .filter(f => f.match(/^[GP]\d{3}_.*\.md$/) && !f.startsWith('index'));
  }

  // --- Import from legacy .claude/vault/ ---

  findLegacyVault(type: 'global' | 'project'): string | null {
    const legacyPath = type === 'global'
      ? path.join(os.homedir(), '.claude', 'vault')
      : path.join(process.cwd(), '.claude', 'vault');

    return fs.existsSync(legacyPath) ? legacyPath : null;
  }

  importFromLegacy(legacyPath: string, targetTier: VaultTier): { imported: number; skipped: number } {
    const targetPath = targetTier === 'global' ? this._globalPath : this._projectPath;
    let imported = 0;
    let skipped = 0;

    if (!fs.existsSync(legacyPath)) return { imported: 0, skipped: 0 };

    const files = fs.readdirSync(legacyPath);

    for (const file of files) {
      if (!file.match(/^[GP]\d{3}_.*\.md$/) && file !== 'index.md' && file !== 'settings.json') continue;

      const source = path.join(legacyPath, file);
      const dest = path.join(targetPath, file);

      if (fs.existsSync(dest)) {
        skipped++;
        continue;
      }

      if (!fs.existsSync(targetPath)) {
        fs.mkdirSync(targetPath, { recursive: true });
      }

      fs.copyFileSync(source, dest);
      imported++;
    }

    return { imported, skipped };
  }
}
