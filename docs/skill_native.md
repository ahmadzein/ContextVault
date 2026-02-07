# ContextVault Native CLI - SKILL.md

```yaml
package:
  name: contextvault
  version: 1.8.7
  description: Native CLI for ContextVault - External memory for Claude Code
  category: productivity
  emoji: 🏰
  website: https://ctx-vault.com
  repository: https://github.com/ahmadzein/ContextVault
```

---

## Installation

### macOS / Linux

```bash
curl -fsSL https://ctx-vault.com/install | bash
```

Or directly from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/ahmadzein/ContextVault/main/install-contextvault.sh | bash
```

### Windows PowerShell

```powershell
irm https://raw.githubusercontent.com/ahmadzein/ContextVault/main/install-contextvault.ps1 | iex
```

---

## Slash Commands Reference (23 total)

### Core Documentation

#### /ctx-doc
Document a learning, exploration finding, or code snippet.

```
Usage:
  /ctx-doc                    # Default: learning (project vault)
  /ctx-doc type=intel         # Codebase exploration (project vault)
  /ctx-doc type=snippet       # Reusable code (global vault)

Document Types:
  learning  - Learned something, built a feature (default)
  intel     - Explored codebase, found patterns
  snippet   - Found reusable code worth saving (defaults to global)
```

#### /ctx-error
Document a bug fix with error message, root cause, solution.

```
Usage:
  /ctx-error

Prompts for:
  - Error message encountered
  - Root cause analysis
  - Solution applied
  - Prevention tips (optional)
```

#### /ctx-decision
Document an architectural or technical decision with reasoning.

```
Usage:
  /ctx-decision

Prompts for:
  - What was decided
  - Why this option was chosen
  - Alternatives considered
  - Trade-offs accepted
```

#### /ctx-plan
Document an implementation plan for multi-step tasks.

```
Usage:
  /ctx-plan

Prompts for:
  - Goal description
  - Implementation steps
  - Current status
```

#### /ctx-handoff
Create session handoff summary for seamless continuation.

```
Usage:
  /ctx-handoff

Creates session summary with:
  - What was completed
  - What's in progress
  - Next steps for continuation
```

### Search & Retrieval

#### /ctx-search
Search across vault documents by keyword.

```
Usage:
  /ctx-search auth
  /ctx-search "database migration"

Returns: List of matching documents with ID, topic, summary
```

#### /ctx-read
Read a vault document by ID.

```
Usage:
  /ctx-read P001
  /ctx-read G005

Returns: Full document content
```

#### /ctx-update
Update an existing vault document.

```
Usage:
  /ctx-update P003
  /ctx-update P005 section="Notes"

Opens document for editing, appends to history
```

### Vault Management

#### /ctx-init
Initialize ContextVault in current project.

```
Usage:
  /ctx-init
  /ctx-init --force    # Reinitialize existing vault

Creates: .claude/vault/ directory with index.md and settings
```

#### /ctx-status
Show vault status: document counts, paths, mode, enforcement level.

```
Usage:
  /ctx-status
```

#### /ctx-mode
Switch vault mode or enforcement level.

```
Usage:
  /ctx-mode local              # Project vault only (default)
  /ctx-mode full               # Both global + project
  /ctx-mode global             # Global vault only
  /ctx-mode enforcement light  # No mid-work reminders
  /ctx-mode enforcement strict # Remind after 4 edits
```

#### /ctx-health
Check vault health: orphaned docs, index mismatches, size limits.

```
Usage:
  /ctx-health
```

#### /ctx-bootstrap
Auto-scan codebase and generate initial documentation.

```
Usage:
  /ctx-bootstrap
  /ctx-bootstrap --interactive   # Ask before each doc
```

### Utility Commands

#### /ctx-new
Create a new document with custom title and content.

```
Usage:
  /ctx-new

Guides through: Topic, Vault selection, Template
```

#### /ctx-link
Link two related documents together.

```
Usage:
  /ctx-link P003 P007

Adds "Related: P007" to P003 and vice versa
```

#### /ctx-archive
Archive a deprecated document.

```
Usage:
  /ctx-archive P005 "Replaced by new auth system"

Moves document to archive/ with reason header
```

#### /ctx-review
Run curation review on vault.

```
Usage:
  /ctx-review
  /ctx-review --stale-days 14

Identifies: Stale docs, short docs, potential merges
```

#### /ctx-quiz
Test knowledge retention from vault documents.

```
Usage:
  /ctx-quiz
  /ctx-quiz auth

Generates questions based on stored documentation
```

#### /ctx-changelog
Show ContextVault version history.

```
Usage:
  /ctx-changelog
```

#### /ctx-upgrade
Upgrade vault format to latest version.

```
Usage:
  /ctx-upgrade
```

#### /ctx-share
Export vault documents for sharing.

```
Usage:
  /ctx-share P001 P003 P007
  /ctx-share P001 --format json
```

#### /ctx-import
Import documents from external source.

```
Usage:
  /ctx-import ./docs/guide.md
  /ctx-import legacy           # Import from old .claude/vault/ location
```

#### /ctx-help
Show all commands and descriptions.

```
Usage:
  /ctx-help
```

---

## File Locations

| Component | Path |
|-----------|------|
| Global Vault | `~/.claude/vault/` |
| Project Vault | `./.claude/vault/` |
| Commands | `~/.claude/commands/` |
| Hooks | `~/.claude/hooks/` |
| Settings | `~/.claude/settings.json` |
| CLAUDE.md | `~/.claude/CLAUDE.md` |

---

## Hook System

The native CLI uses Claude Code hooks for enforcement:

| Hook | Trigger | Purpose |
|------|---------|---------|
| SessionStart | Session begins | Show vault status, load indexes |
| PostToolUse | After Edit/Write | Track edits, remind to document |
| Stop | Session ends | Block if undocumented work |

---

## For AI Agents

### Session Start (Automatic)
1. Read `~/.claude/vault/settings.json` → note mode
2. Read indexes based on mode
3. Note what docs exist — use throughout session

### Session End
1. Review what was accomplished
2. Document with `/ctx-doc`, `/ctx-error`, or `/ctx-decision`
3. Create handoff with `/ctx-handoff`

### Core Rules
1. **Search before creating** — avoid duplicates
2. **Update existing docs** — don't create new for same topic
3. **Document at milestones** — not every trivial edit
4. **Route correctly** — global for reusable, project for specific

---

*ContextVault Native CLI v1.8.7 — Documentation that survives session death.*
