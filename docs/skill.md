# ContextVault SKILL.md

```yaml
package:
  name: contextvault
  version: 1.8.7
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
| **MCP Server** | Cursor, Windsurf, Cline, any MCP-compatible tool | `ctx_doc`, `ctx_error`, etc. | `npm install -g contextvault-mcp` |
| **Native CLI** | Claude Code CLI | `/ctx-doc`, `/ctx-error`, etc. | `curl -fsSL https://ctx-vault.com/install \| bash` |

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
| Global | G### | `~/.claude/vault/` | Reusable patterns, best practices |
| Project | P### | `./.claude/vault/` | Project-specific architecture, decisions |

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

### v1.8.7 / MCP v1.0.5 - 2026-02-07
- **Feature Consolidation**: 28 → 23 commands
- `ctx_snippet` and `ctx_intel` merged into `ctx_doc` with `type` parameter
- `ctx_note` removed (use `ctx_update section="Notes"`)
- `ctx_explain` removed (use `ctx_doc`)
- `ctx_ask` removed (use `ctx_search` + `ctx_read`)

### v1.8.6 / MCP v1.0.4 - 2026-02-06
- Added `ctx_archive`, `ctx_review`
- Code-drift detection in health checks
- Semantic clustering for research tracking

---

*ContextVault — Documentation that survives session death.*
