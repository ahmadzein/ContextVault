# ContextVault MCP Server

**External memory for AI coding assistants.** Give your AI persistent context that survives session death.

Works with: **Claude Code** | **Cursor** | **Windsurf** | **Cline** | **OpenCode** | **Continue** | any MCP client

[![npm version](https://img.shields.io/npm/v/contextvault-mcp.svg)](https://www.npmjs.com/package/contextvault-mcp)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## Quick Start

### Claude Code
```bash
claude mcp add contextvault -- npx -y contextvault-mcp
```

### Cursor / Windsurf / Cline
Add to your MCP settings:
```json
{
  "mcpServers": {
    "contextvault": {
      "command": "npx",
      "args": ["-y", "contextvault-mcp"]
    }
  }
}
```

### Global Install
```bash
npm install -g contextvault-mcp
```

---

## What It Does

ContextVault solves the **Session Death Problem** — every AI session starts fresh, forgetting what was learned before.

- **Persistent documentation** that survives context resets
- **Two-vault system**: Global (reusable patterns) + Project (codebase-specific)
- **23 tools** for documentation, search, and knowledge management
- **Structured capture**: decisions, errors, learnings, plans, handoffs

---

## Tools (23 total)

### Core Documentation
| Tool | Purpose |
|------|---------|
| `ctx_doc` | Document learning, intel, or code snippet |
| `ctx_error` | Capture bug fix with root cause & solution |
| `ctx_decision` | Log architectural decision with rationale |
| `ctx_plan` | Document multi-step implementation plan |
| `ctx_handoff` | Create session summary for continuity |

### Search & Retrieval
| Tool | Purpose |
|------|---------|
| `ctx_search` | Search across vault documents |
| `ctx_read` | Read document by ID (P001, G003) |
| `ctx_update` | Update existing document |

### Vault Management
| Tool | Purpose |
|------|---------|
| `ctx_init` | Initialize vault in current project |
| `ctx_status` | Show vault statistics |
| `ctx_mode` | Switch local/global/full mode |
| `ctx_health` | Check vault health |
| `ctx_bootstrap` | Auto-scan codebase and generate docs |

### Utilities
| Tool | Purpose |
|------|---------|
| `ctx_new` | Create new document |
| `ctx_link` | Link related documents |
| `ctx_archive` | Archive deprecated document |
| `ctx_review` | Run curation review |
| `ctx_quiz` | Test knowledge retention |
| `ctx_share` | Export docs for sharing |
| `ctx_import` | Import external docs |
| `ctx_upgrade` | Upgrade vault format |
| `ctx_changelog` | Show version history |
| `ctx_help` | Show all commands |

---

## MCP Resources

| URI | Description |
|-----|-------------|
| `contextvault://global/index` | Global vault index |
| `contextvault://project/index` | Project vault index |
| `contextvault://settings` | Current vault settings |
| `contextvault://instructions` | AI documentation rules |
| `contextvault://doc/{id}` | Individual document |

---

## Example Usage

```
# Initialize vault in your project
ctx_init

# Document a learning
ctx_doc topic="Auth System" content="Uses JWT with 24h expiry"

# Document a bug fix
ctx_error error_message="401 on refresh" root_cause="Token race" solution="Added mutex"

# Search for docs
ctx_search query="authentication"

# Create session handoff
ctx_handoff completed="Auth done" next_steps="Add rate limiting"
```

---

## Vault Locations

| Vault | Location | Prefix |
|-------|----------|--------|
| Global | `~/.contextvault/` | G### |
| Project | `./.contextvault/` | P### |

Legacy `.claude/vault/` locations are auto-detected for backward compatibility.

---

## Links

- **Website**: [ctx-vault.com](https://ctx-vault.com)
- **Documentation**: [ctx-vault.com/docs](https://ctx-vault.com/docs)
- **GitHub**: [github.com/ahmadzein/ContextVault](https://github.com/ahmadzein/ContextVault)
- **Native CLI**: For Claude Code with hooks & slash commands, use the [bash installer](https://ctx-vault.com/install)

---

## License

MIT

---

*Documentation that survives session death.*
