import { ToolResponse } from '../vault/types.js';

export function handleChangelog(): ToolResponse {
  const text = `# ContextVault Changelog

## v1.0.0 (MCP Server)
- Initial MCP server release
- 23 tools mirroring all /ctx-* commands
- 4 MCP resources (global index, project index, settings, instructions)
- Resource templates for individual documents
- Server-side enforcement engine (no hooks needed)
- CLI-agnostic vault paths (~/.contextvault/, ./.contextvault/)
- Backward compatible with legacy .claude/vault/ locations
- Works with: Claude Code, Cursor, Windsurf, OpenCode, Cline, Continue, Copilot CLI

## Based on ContextVault v1.8.4 (Bash Installer)
- v1.8.4: CLAUDE.md optimization (775 → 221 lines)
- v1.8.3: Configurable enforcement levels (light/balanced/strict)
- v1.8.2: Smart blocking at session end
- v1.8.1: Completion-triggered reminders
- v1.8.0: "Remind, Don't Block" enforcement
- v1.7.6: Hook deduplication + smarter bootstrap
- v1.7.5: /ctx-bootstrap auto-scan
- v1.7.0: Smart detection, context-aware suggestions
- v1.6.9: Blocking PreToolUse enforcement
- v1.6.0: 6 new commands (health, note, changelog, link, quiz, explain)
- v1.5.3: /ctx-upgrade command
- v1.5.0: Share/import with ZIP support
- v1.4.0: Enhanced instructions with checklists
`;

  return { content: [{ type: 'text', text }] };
}
