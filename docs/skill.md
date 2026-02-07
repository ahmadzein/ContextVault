# ContextVault SKILL.md

```yaml
package:
  name: contextvault
  version: 1.0.5
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

## Documentation

| Resource | URL |
|----------|-----|
| Main Site | https://ctx-vault.com |
| Getting Started | https://ctx-vault.com/docs/getting-started.html |
| Commands Reference | https://ctx-vault.com/docs/commands.html |
| Configuration | https://ctx-vault.com/docs/configuration.html |
| Architecture | https://ctx-vault.com/docs/architecture.html |
| Changelog | https://ctx-vault.com/docs/changelog.html |
| GitHub | https://github.com/ahmadzein/ContextVault |

---

## Installation

### Option 1: MCP Server (Recommended for Cursor, Windsurf, Cline, etc.)

```bash
npm install -g contextvault-mcp
```

Add to your MCP settings:
```json
{
  "mcpServers": {
    "contextvault": {
      "command": "contextvault-mcp"
    }
  }
}
```

### Option 2: Native (Claude Code CLI)

```bash
curl -fsSL https://raw.githubusercontent.com/ahmadzein/ContextVault/main/install-contextvault.sh | bash
```

### Option 3: Windows PowerShell

```powershell
irm https://raw.githubusercontent.com/ahmadzein/ContextVault/main/install-contextvault.ps1 | iex
```

---

## Commands Reference

### Core Documentation Commands

#### ctx_doc
Document a learning, exploration finding, or code snippet.

```
Parameters:
  topic: string (required) - Topic name
  content: string (required) - What you learned or the code
  type: "learning" | "intel" | "snippet" (default: "learning")
  vault: "global" | "project" (default: project, snippets default to global)
  language: string (for snippets) - Programming language
  use_case: string (for snippets) - When to use this

Examples:
  ctx_doc topic="Auth System" content="Uses JWT with 24h expiry, refresh tokens in Redis"
  ctx_doc topic="Retry Pattern" content="async def retry()..." type="snippet" language="python"
  ctx_doc topic="API Layer" content="All endpoints use middleware chain" type="intel"
```

#### ctx_error
Document a bug fix with error message, root cause, solution.

```
Parameters:
  error_message: string (required) - The error encountered
  root_cause: string (required) - What caused it
  solution: string (required) - How it was fixed
  prevention: string (optional) - How to prevent in future

Example:
  ctx_error error_message="401 on refresh" root_cause="Token rotation race condition" solution="Added mutex lock"
```

#### ctx_decision
Document an architectural or technical decision with reasoning.

```
Parameters:
  decision: string (required) - What was decided
  reasoning: string (required) - Why this option was chosen
  options: string (optional) - Options that were considered
  tradeoffs: string (optional) - Trade-offs and downsides

Example:
  ctx_decision decision="Redis over Memcached" reasoning="Need persistence for sessions" tradeoffs="Slower but durable"
```

#### ctx_plan
Document an implementation plan for multi-step tasks.

```
Parameters:
  goal: string (required) - What the plan aims to achieve
  steps: string (required) - Implementation steps (markdown list)
  status: string (default: "In Progress") - Current status

Example:
  ctx_plan goal="Implement OAuth2" steps="1. Add provider config\n2. Create callback route\n3. Store tokens"
```

#### ctx_handoff
Create session handoff summary for seamless continuation.

```
Parameters:
  completed: string (required) - What was completed this session
  next_steps: string (required) - What should be done next
  in_progress: string (optional) - What is still in progress

Example:
  ctx_handoff completed="Auth endpoints done" next_steps="Add rate limiting, write tests"
```

### Search & Retrieval Commands

#### ctx_search
Search across vault documents by keyword.

```
Parameters:
  query: string (required) - Search query

Returns: List of matching documents with ID, topic, summary
```

#### ctx_read
Read a vault document by ID.

```
Parameters:
  id: string (required) - Document ID (e.g. "P001", "G003")

Returns: Full document content
```

#### ctx_update
Update an existing vault document.

```
Parameters:
  id: string (required) - Document ID to update
  content: string (required) - New content to add
  section: string (optional) - Section to update (e.g. "Notes", "Current Understanding")
```

### Vault Management Commands

#### ctx_init
Initialize ContextVault in current project.

```
Parameters:
  force: boolean (default: false) - Force reinitialize even if vault exists

Creates: .contextvault/ directory with index.md and settings.json
```

#### ctx_status
Show vault status: document counts, paths, mode, enforcement level.

```
No parameters required.

Returns: Vault statistics, paths, current settings
```

#### ctx_mode
Switch vault mode or enforcement level.

```
Parameters:
  mode: "local" | "global" | "full" (optional) - Which vaults to use
  enforcement: "light" | "balanced" | "strict" (optional) - Reminder aggressiveness

Modes:
  local: Project vault only (default)
  full: Both global + project vaults
  global: Global vault only

Enforcement:
  light: No mid-work reminders
  balanced: Remind after 8 edits across 2+ files (default)
  strict: Remind after 4 edits across 2+ files
```

#### ctx_health
Check vault health: orphaned docs, index mismatches, size limits.

```
No parameters required.

Checks:
  - Orphaned documents not in index
  - Index entries missing documents
  - Documents over size limits
  - Broken file references in docs
```

#### ctx_bootstrap
Auto-scan codebase and generate initial documentation.

```
Parameters:
  interactive: boolean (default: false) - Show scan results before creating docs

Creates: Architecture doc, key files doc, initial project documentation
```

### Utility Commands

#### ctx_new
Create a new document with custom title and content.

```
Parameters:
  title: string (required) - Document title
  content: string (required) - Document content
  vault: "global" | "project" (default: "project")
```

#### ctx_link
Link two related documents together.

```
Parameters:
  from_id: string (required) - Source document ID
  to_id: string (required) - Target document ID
```

#### ctx_archive
Archive a deprecated document.

```
Parameters:
  id: string (required) - Document ID to archive
  reason: string (required) - Reason for archiving

Moves document to archive/ folder with reason header
```

#### ctx_review
Run curation review on vault.

```
Parameters:
  vault: "global" | "project" (default: "project")
  stale_days: number (default: 30) - Days without update to consider stale

Identifies: Stale docs, short docs, potential merges
```

#### ctx_quiz
Test knowledge retention from vault documents.

```
Parameters:
  topic: string (optional) - Specific topic to quiz on

Generates questions based on stored documentation
```

#### ctx_changelog
Show ContextVault version history.

```
No parameters required.

Returns: Version history and notable changes
```

#### ctx_upgrade
Upgrade vault format to latest version.

```
No parameters required.

Fixes structure issues and migrates to new format
```

#### ctx_share
Export vault documents for sharing.

```
Parameters:
  ids: string[] (required) - Document IDs to export
  format: "md" | "json" (default: "md")
```

#### ctx_import
Import documents from external source.

```
Parameters:
  source_path: string (required) - Path to import from (use "legacy" for .claude/vault/)
```

#### ctx_help
Show all commands and descriptions.

```
No parameters required.
```

---

## MCP Resources

These resources are automatically available when using the MCP server:

| URI | Description |
|-----|-------------|
| `contextvault://global/index` | Global vault index |
| `contextvault://project/index` | Project vault index |
| `contextvault://settings` | Current vault settings |
| `contextvault://instructions` | Documentation rules for AI |
| `contextvault://doc/{id}` | Individual document by ID |

---

## Document Structure

All documents follow this structure:

```markdown
# [ID] - [Title]

**Last Updated:** YYYY-MM-DD
**Status:** Active | Complete | Archived
**Summary:** One-line description

---

## Current Understanding

### Key Points
- Point 1
- Point 2

### Details
[Detailed content]

---

## Gotchas
- Known issues or edge cases

---

## History
| Date | Change |
|------|--------|
| YYYY-MM-DD | Initial creation |
```

---

## Best Practices

### When to Document
- Feature complete (not mid-edit)
- Bug fix solved and verified
- Architecture decision made
- Session ending

### When NOT to Document
- Trivial edits (version bumps, typos)
- Mid-refactor (wait until done)
- Nothing meaningful learned

### Document Routing
- **Global vault (G###)**: Reusable patterns, best practices, tool configs
- **Project vault (P###)**: Architecture, configs, local decisions

### Size Limits
- Index: 50 entries max
- Document: 100 lines max
- Summary: 15 words max

---

## Changelog (Recent)

### v1.0.5 (MCP) / v1.8.5 (Native) - 2026-02-07
- **Feature Consolidation**: 28 → 23 commands
- `ctx_snippet` and `ctx_intel` merged into `ctx_doc` with `type` parameter
- `ctx_note` removed (use `ctx_update section="Notes"`)
- `ctx_explain` removed (use `ctx_doc`)
- `ctx_ask` removed (use `ctx_search` + `ctx_read`)

### v1.0.4 / v1.8.6 - 2026-02-06
- Added `ctx_archive`, `ctx_review`, `ctx_ask`
- Code-drift detection in health checks
- Semantic clustering for research tracking

### v1.0.3 / v1.8.5 - 2026-02-06
- Research insight detection
- Non-blocking nudges for exploration without documentation
- Domain-aware research categorization

### v1.0.2 / v1.8.4 - 2026-02-03
- Optimized CLAUDE.md (775 → 170 lines)
- Configurable enforcement levels

### v1.0.1 / v1.8.0 - 2026-02-02
- "Remind, Don't Block" enforcement model
- Milestone-based reminders
- Smart blocking at session end only

---

## For AI Agents

### Session Start Workflow
1. Read vault index(es) based on mode setting
2. Note what documentation exists
3. Use that knowledge throughout session

### Session End Workflow
1. Review what was accomplished
2. Document significant learnings with appropriate command
3. Create handoff summary with `ctx_handoff`

### Core Rules
1. **Search before creating** — avoid duplicates
2. **Update existing docs** — don't create new for same topic
3. **Document at milestones** — not every trivial edit
4. **Route correctly** — global for reusable, project for specific

### Response After Documentation
After documenting, confirm: "Documented to [ID]_topic.md"

---

## Support

- **Issues**: https://github.com/ahmadzein/ContextVault/issues
- **Website**: https://ctx-vault.com

---

*ContextVault — Documentation that survives session death.*
