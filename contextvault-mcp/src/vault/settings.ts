import * as fs from 'node:fs';
import * as path from 'node:path';
import { VaultSettings, DEFAULT_SETTINGS } from './types.js';

export class SettingsManager {
  private globalSettingsPath: string;

  constructor(globalVaultPath: string) {
    this.globalSettingsPath = path.join(globalVaultPath, 'settings.json');
  }

  load(): VaultSettings {
    try {
      if (fs.existsSync(this.globalSettingsPath)) {
        const raw = fs.readFileSync(this.globalSettingsPath, 'utf-8');
        const parsed = JSON.parse(raw);
        return {
          mode: parsed.mode ?? DEFAULT_SETTINGS.mode,
          enforcement: parsed.enforcement ?? DEFAULT_SETTINGS.enforcement,
          limits: {
            max_global_docs: parsed.limits?.max_global_docs ?? DEFAULT_SETTINGS.limits.max_global_docs,
            max_project_docs: parsed.limits?.max_project_docs ?? DEFAULT_SETTINGS.limits.max_project_docs,
            max_doc_lines: parsed.limits?.max_doc_lines ?? DEFAULT_SETTINGS.limits.max_doc_lines,
            max_summary_words: parsed.limits?.max_summary_words ?? DEFAULT_SETTINGS.limits.max_summary_words,
          },
        };
      }
    } catch {
      // Fall through to defaults
    }
    return { ...DEFAULT_SETTINGS, limits: { ...DEFAULT_SETTINGS.limits } };
  }

  save(settings: VaultSettings): void {
    const dir = path.dirname(this.globalSettingsPath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    fs.writeFileSync(this.globalSettingsPath, JSON.stringify(settings, null, 2) + '\n', 'utf-8');
  }

  update(partial: Partial<Pick<VaultSettings, 'mode' | 'enforcement'>>): VaultSettings {
    const current = this.load();
    if (partial.mode) current.mode = partial.mode;
    if (partial.enforcement) current.enforcement = partial.enforcement;
    this.save(current);
    return current;
  }
}
