# ContextVault SKILL.md

```yaml
package:
  name: contextvault
  version: 1.9.0
  description: External memory system for AI coding assistants. Persistent documentation that survives session death.
  category: productivity
  emoji: 🏰
  website: https://ctx-vault.com
  repository: https://github.com/ahmadzein/ContextVault
```

---

## Overview

ContextVault solves the **Session Death Problem** — every AI coding session starts fresh, forgetting what was learned in previous sessions. ContextVault provides:

- **Persistent documentation** that survives context window resets
- **Structured knowledge capture** (decisions, errors, learnings, plans)
- **Cross-session continuity** via session handoffs
- **Two vault system**: Global (reusable patterns) + Project (codebase-specific)

**Philosophy**: Document at milestones, not every edit. Quality over quantity.

---

## Two Integration Modes

| Mode | Best For | Syntax | Installation |
|------|----------|--------|--------------|
| **MCP Server** | Cursor, Windsurf, Cline, OpenCode, any MCP client | `ctx_doc`, `ctx_error`, etc. | `npm install -g contextvault-mcp` |
| **Native CLI** | Claude Code (slash commands + hooks) | `/ctx-doc`, `/ctx-error`, etc. | `curl -fsSL https://ctx-vault.com/install \| bash` |

**Choose your path:**
- **[skill_mcp.md](skill_mcp.md)** — Full MCP Server documentation
- **[skill_native.md](skill_native.md)** — Full Native CLI documentation

---

## Quick Reference (Both Modes)

| Purpose | MCP Tool | Native Command |
|---------|----------|----------------|
| Document learning/intel/snippet | `ctx_doc` | `/ctx-doc` |
| Document bug fix | `ctx_error` | `/ctx-error` |
| Document decision | `ctx_decision` | `/ctx-decision` |
| Document plan | `ctx_plan` | `/ctx-plan` |
| Create handoff | `ctx_handoff` | `/ctx-handoff` |
| Search vault | `ctx_search` | `/ctx-search` |
| Read document | `ctx_read` | `/ctx-read` |
| Update document | `ctx_update` | `/ctx-update` |
| Initialize vault | `ctx_init` | `/ctx-init` |
| Check status | `ctx_status` | `/ctx-status` |
| Bootstrap project | `ctx_bootstrap` | `/ctx-bootstrap` |
| Health check | `ctx_health` | `/ctx-health` |
| Archive doc | `ctx_archive` | `/ctx-archive` |
| Review vault | `ctx_review` | `/ctx-review` |
| Link docs | `ctx_link` | `/ctx-link` |
| Quiz knowledge | `ctx_quiz` | `/ctx-quiz` |
| Show help | `ctx_help` | `/ctx-help` |
| Change mode | `ctx_mode` | `/ctx-mode` |
| Create new doc | `ctx_new` | `/ctx-new` |
| Import docs | `ctx_import` | `/ctx-import` |
| Export/share | `ctx_share` | `/ctx-share` |
| Show changelog | `ctx_changelog` | `/ctx-changelog` |
| Upgrade vault | `ctx_upgrade` | `/ctx-upgrade` |

**Total: 23 commands**

---

## Core Concepts

### Document Types

The `ctx_doc` / `/ctx-doc` command supports three types:

| Type | Use When | Default Vault |
|------|----------|---------------|
| `learning` | Learned something, built a feature | project |
| `intel` | Explored codebase, found patterns | project |
| `snippet` | Found reusable code worth saving | global |

### Vault System

| Vault | Prefix | Location | Contains |
|-------|--------|----------|----------|
| Global | G### | `~/.contextvault/` (MCP) or `~/.claude/vault/` (native) | Reusable patterns, best practices |
| Project | P### | `./.contextvault/` (MCP) or `./.claude/vault/` (native) | Project-specific architecture, decisions |

### Enforcement Levels

| Level | Behavior |
|-------|----------|
| `light` | No mid-work reminders |
| `balanced` | Remind after 8 edits across 2+ files (default) |
| `strict` | Remind after 4 edits across 2+ files |

---

## Documentation Links

| Resource | URL |
|----------|-----|
| Main Site | https://ctx-vault.com |
| Getting Started | https://ctx-vault.com/docs/getting-started.html |
| Commands Reference | https://ctx-vault.com/docs/commands.html |
| Configuration | https://ctx-vault.com/docs/configuration.html |
| Changelog | https://ctx-vault.com/docs/changelog.html |
| GitHub | https://github.com/ahmadzein/ContextVault |

---

## Changelog (Recent)

### v1.9.0 / MCP v2.0.0 - 2026-03-06
- **McpServer + registerTool API**: Modern MCP SDK pattern with Zod input schemas
- **Tool annotations**: readOnlyHint, destructiveHint, idempotentHint, openWorldHint on all 23 tools
- **structuredContent**: Machine-readable stats on ctx_status
- **Self-contained descriptions**: Every tool works standalone with any AI client
- **Slash commands rewrite**: ~3,400 → ~477 lines, all delegate to MCP tools
- SDK ^1.6.1, zod ^3.23.8, 54 tests pass

### v1.8.8 / MCP v1.0.8 - 2026-02-08
- **CLI UX**: TTY detection, `--version`, `--help`, `--check-update` flags
- **Health score breakdown**: Per-category scoring (Index, Files, Size, Drift)
- **Smarter merge suggestions**: Content keyword comparison, not type prefix
- Dynamic version from package.json
- 54 tests, all pass

### v1.8.7 / MCP v1.0.7 - 2026-02-08
- **Bug fixes**: Health check no longer flags archived entries, respects mode, filters false positives
- **Feature Consolidation**: 28 → 23 commands
- `ctx_snippet` and `ctx_intel` merged into `ctx_doc` with `type` parameter
- `ctx_note`, `ctx_explain`, `ctx_ask` removed
- Added `parseActiveEntries()`, npm README
- 49 tests

### v1.8.6 / MCP v1.0.4 - 2026-02-06
- Added `ctx_archive`, `ctx_review`
- Code-drift detection in health checks
- Semantic clustering for research tracking

---

*ContextVault v1.9.0 — Documentation that survives session death.*
