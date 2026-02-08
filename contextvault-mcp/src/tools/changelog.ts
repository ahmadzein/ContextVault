import { ToolResponse } from '../vault/types.js';

export function handleChangelog(): ToolResponse {
  const text = `# ContextVault Changelog

## v1.0.7 (MCP Server)
- Fixed: Health check no longer flags archived entries as "missing file"
- Fixed: Health check respects mode setting (skips global in local mode)
- Fixed: Code drift filters false positives (JS globals, URLs, example paths)
- Fixed: Review tool only counts active documents
- Added: parseActiveEntries() for accurate active-only queries
- Added: README for npm package
- 49 tests, all pass

## v1.0.6 (MCP Server)
- Added README.md for npm display
- Updated all version references

## v1.0.5 (MCP Server)
- Feature consolidation: 28 → 23 tools
- ctx_doc with type=learning|intel|snippet parameter

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
