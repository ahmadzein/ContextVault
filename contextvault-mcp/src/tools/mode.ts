import { VaultManager } from '../vault/manager.js';
import { ToolResponse } from '../vault/types.js';

export function handleMode(vault: VaultManager, params: Record<string, unknown>): ToolResponse {
  const mode = params.mode as string | undefined;
  const enforcement = params.enforcement as string | undefined;

  if (!mode && !enforcement) {
    const settings = vault.settings.load();
    return {
      content: [{
        type: 'text',
        text: `Current mode: **${settings.mode}** | Enforcement: **${settings.enforcement}**\n\nUse mode parameter (local/global/full) or enforcement parameter (light/balanced/strict) to change.`,
      }],
    };
  }

  const updates: Record<string, string> = {};
  if (mode && ['local', 'global', 'full'].includes(mode)) {
    updates.mode = mode;
  }
  if (enforcement && ['light', 'balanced', 'strict'].includes(enforcement)) {
    updates.enforcement = enforcement;
  }

  const updated = vault.settings.update(updates as { mode?: 'local' | 'global' | 'full'; enforcement?: 'light' | 'balanced' | 'strict' });

  return {
    content: [{
      type: 'text',
      text: `Settings updated:\n- **Mode:** ${updated.mode}\n- **Enforcement:** ${updated.enforcement}`,
    }],
  };
}
