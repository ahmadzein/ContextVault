# ContextVault MCP Server - SKILL.md

```yaml
package:
  name: contextvault-mcp
  version: 1.0.6
  description: MCP Server for ContextVault - External memory for AI coding assistants
  category: productivity
  emoji: 🏰
  npm: https://www.npmjs.com/package/contextvault-mcp
  repository: https://github.com/ahmadzein/ContextVault
```

---

## Installation

```bash
npm install -g contextvault-mcp
```

Add to your MCP settings (Cursor, Windsurf, Cline, etc.):

```json
{
  "mcpServers": {
    "contextvault": {
      "command": "contextvault-mcp"
    }
  }
}
```

---

## MCP Tools Reference (23 total)

### Core Documentation

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
  ctx_doc topic="Auth System" content="Uses JWT with 24h expiry"
  ctx_doc topic="Retry Pattern" content="async def retry()..." type="snippet" language="python"
  ctx_doc topic="API Layer" content="All endpoints use middleware" type="intel"
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
  ctx_error error_message="401 on refresh" root_cause="Token rotation race" solution="Added mutex lock"
```

#### ctx_decision
Document an architectural or technical decision with reasoning.

```
Parameters:
  decision: string (required) - What was decided
  reasoning: string (required) - Why this option was chosen
  options: string (optional) - Options considered
  tradeoffs: string (optional) - Trade-offs and downsides

Example:
  ctx_decision decision="Redis over Memcached" reasoning="Need persistence" tradeoffs="Slower but durable"
```

#### ctx_plan
Document an implementation plan for multi-step tasks.

```
Parameters:
  goal: string (required) - What the plan aims to achieve
  steps: string (required) - Implementation steps (markdown list)
  status: string (default: "In Progress") - Current status

Example:
  ctx_plan goal="Implement OAuth2" steps="1. Add config\n2. Create callback\n3. Store tokens"
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

### Search & Retrieval

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

### Vault Management

#### ctx_init
Initialize ContextVault in current project.

```
Parameters:
  force: boolean (default: false) - Force reinitialize

Creates: .contextvault/ directory with index.md and settings.json
```

#### ctx_status
Show vault status: document counts, paths, mode, enforcement level.

```
No parameters required.
```

#### ctx_mode
Switch vault mode or enforcement level.

```
Parameters:
  mode: "local" | "global" | "full" (optional)
  enforcement: "light" | "balanced" | "strict" (optional)
```

#### ctx_health
Check vault health: orphaned docs, index mismatches, size limits.

```
No parameters required.
```

#### ctx_bootstrap
Auto-scan codebase and generate initial documentation.

```
Parameters:
  interactive: boolean (default: false) - Show scan results before creating
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
```

#### ctx_review
Run curation review on vault.

```
Parameters:
  vault: "global" | "project" (default: "project")
  stale_days: number (default: 30) - Days to consider stale
```

#### ctx_quiz
Test knowledge retention from vault documents.

```
Parameters:
  topic: string (optional) - Specific topic to quiz on
```

#### ctx_changelog
Show ContextVault version history.

```
No parameters required.
```

#### ctx_upgrade
Upgrade vault format to latest version.

```
No parameters required.
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

These resources are automatically available:

| URI | Description |
|-----|-------------|
| `contextvault://global/index` | Global vault index |
| `contextvault://project/index` | Project vault index |
| `contextvault://settings` | Current vault settings |
| `contextvault://instructions` | Documentation rules for AI |
| `contextvault://doc/{id}` | Individual document by ID |

---

## For AI Agents

### Session Start Workflow
1. Read vault index(es) based on mode setting
2. Note what documentation exists
3. Use that knowledge throughout session

### Session End Workflow
1. Review what was accomplished
2. Document significant learnings with `ctx_doc`, `ctx_error`, or `ctx_decision`
3. Create handoff summary with `ctx_handoff`

### Core Rules
1. **Search before creating** — avoid duplicates
2. **Update existing docs** — don't create new for same topic
3. **Document at milestones** — not every trivial edit
4. **Route correctly** — global for reusable, project for specific

---

*ContextVault MCP Server v1.0.6 — Documentation that survives session death.*
