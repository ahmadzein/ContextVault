# Changelog

All notable changes to ContextVault will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.7.6] - 2026-01-25

### Fixed
- **Hook Deduplication** - Claude Code runs hooks twice per tool use, causing counters to increment by 2
  - Added deduplication using timestamp-based key tracking
  - PreToolUse and PostToolUse now skip duplicate executions within same second
  - DOC_THRESHOLD reverted from 4 to 2 (dedup handles double-run properly)
  - Uses `/tmp/ctx-hook-seen` to track seen operations

### Enhanced
- **Smarter `/ctx-bootstrap` Detection** - Now parses actual code, not just directories
  - Package.json dependency parsing for framework detection (React, Vue, Express, NestJS, Prisma, etc.)
  - Code pattern grep commands for API routes, React components, database models, services
  - Architecture template now shows "Detected From" column
  - Feature template now includes "Patterns Detected" section

---

## [1.7.5] - 2026-01-25

### Added
- **`/ctx-bootstrap` Command** - Auto-scan codebase and generate comprehensive documentation
  - Crawls entire codebase structure automatically
  - Detects language, framework, and dependencies
  - Identifies features/modules (components, services, api, etc.)
  - Auto-creates `P001_architecture.md` + `P00X_[feature].md` for each feature
  - Supports `--interactive` flag to ask before creating each doc
  - Updates index.md with all new entries

### Changed
- Command count: 24 → 25
- Fixed status check command count (was outdated at 17)

### When to Use
Run `/ctx-bootstrap` after `/ctx-init` to jumpstart documentation on any codebase.

---

## [1.7.4] - 2026-01-25

### Fixed
- **Stop Enforcer Session Fallback** - Bug where `docs_modified` was always 0 when no session file
  - When `session_start = 0` (no session file found), the `find -newermt` never ran
  - Now falls back to checking docs modified in last 30 minutes (`-mmin -30`)
  - Prevents false blocking when session files are missing

### Why This Was Needed
Investigation revealed that when sessions continued from context compaction, the session file from
the previous conversation was already cleaned up. This caused the stop enforcer to report 0 docs
modified even when vault files had been edited.

---

## [1.7.3] - 2026-01-25

### Added
- **APPEND vs ARCHIVE Decision Tree** - Visual guide for choosing the right approach
  - ADDING functionality → APPEND (keep all, add new lines)
  - REMOVING/REPLACING behavior → ARCHIVE (move details to archive/, note in main)
- **Clear Examples** for both scenarios showing before/after

### Why This Was Needed
User asked: "Is it clear when to APPEND vs when to ARCHIVE?"
Answer: Now it is, with a decision tree and examples.

---

## [1.7.2] - 2026-01-25

### Added
- **Core Rule: APPEND, NEVER REPLACE** - Prevents accidental info loss when editing
  - New section in CLAUDE.md with visual guide
  - Added to NEVER/ALWAYS rules
  - Created G002_editing_rules.md global doc for persistence

### Why This Was Needed
During v1.7.1 implementation, rapid editing caused 3 history entries to be accidentally
replaced instead of appended. This rule ensures it never happens again.

### The Rule
When editing docs (especially History sections):
- `old_string` MUST include ALL existing content being touched
- `new_string` MUST include ALL that content PLUS new additions
- NEVER select partial content to replace it

---

## [1.7.1] - 2026-01-25

### Added
- **`/ctx-plan` Command** - Document multi-step implementation plans
  - Auto-suggested when TodoWrite creates 3+ items
  - Tracks goals, tasks, progress, and related docs
  - Auto-detects planning activity via PostToolUse hooks
- **Archive Mechanism** - Don't lose historical content when updating docs
  - Removed content moves to `archive/[SAME_FILENAME]`
  - Main doc stays lean with "Archived: [date]" reference
  - Historical details accessible but out of main context

### Changed
- **PostToolUse now monitors TodoWrite** - Detects multi-step tasks
- **CLAUDE.md Template** - Added "How to Archive Removed Content" section
- Command count: 23 → 24

### Technical
- New hook matcher: TodoWrite in PostToolUse
- Work type tracking: "planning" added
- Archive folder: `.claude/vault/archive/` (already created by installer)

---

## [1.7.0] - 2026-01-25

### Added
- **Smart Command Detection** - Hooks now suggest the RIGHT command for your work!
  - Bug fix detected → suggests `/ctx-error`
  - Decision keywords → suggests `/ctx-decision`
  - Utility/helper files → suggests `/ctx-snippet`
  - Exploration (Task tool) → suggests `/ctx-intel`
  - New feature files → suggests `/ctx-doc`
- **"When to Use Which Command" Guide** in CLAUDE.md
  - Visual reference showing which command fits each situation
  - Updated Available Commands table with all 14 commands

### Changed
- **Context-Aware Stop Enforcer** - Blocking messages now show:
  - Exact counts: "3 edits + 1 new files"
  - "BEST MATCH FOR YOUR WORK" with intelligent suggestion
  - Priority: bugfix > decision > snippet > exploration > feature
  - All available commands with descriptions
- **Work Type Tracking** via `/tmp/ctx-work-type`
  - PostToolUse records what type of work was done
  - Stop hook reads this to make smart recommendations
  - Cleaned up on session end

### Technical
- New tracker file: `/tmp/ctx-work-type` for work type detection
- Git commit message parsing for fix/decision detection
- `is_utility_file()` function detects util/helper/lib paths

---

## [1.6.9] - 2026-01-25

### Added
- **BLOCKING PreToolUse Hook** - Blocks further code changes until you document!
  - New script: `~/.claude/hooks/ctx-pre-tool.sh`
  - Fires BEFORE Edit/Write tools - can BLOCK them from running
  - Threshold: 2 changes without docs → BLOCKED
  - Allows vault writes and non-code files

### Changed
- **Mid-session enforcement is now REAL** - Not just reminders!
  - After 2 code changes, Claude CANNOT make more until documenting
  - PreToolUse with `"blocking": true` prevents tool execution
  - PostToolUse still reminds on every change
  - Stop still blocks at session end
- 5 hook scripts installed: session-start, session-end, stop-enforcer, pre-tool, post-tool

### Technical
- PreToolUse hooks fire before Edit/Write with `"blocking": true`
- Returns `{"decision": "block", "reason": "..."}` to prevent tool
- DOC_THRESHOLD=2 in ctx-pre-tool.sh (configurable)

---

## [1.6.8] - 2026-01-19

### Changed
- **MORE AGGRESSIVE Enforcement** - Blocks after ANY code change, not just >2 edits
  - Stop hook now tracks both edits AND new file writes
  - Checks global vault (G*.md) in addition to project vault (P*.md)
  - Blocks if total_changes > 0 AND docs_modified == 0
- **PostToolUse Reminders on EVERY edit** - No more waiting for 3 edits
  - Tracks new file writes separately (WRITE_COUNT_FILE)
  - More urgent messaging with emojis
  - Reminder after every single code change
- **Project settings use `~` paths** - No manual USER_HOME replacement needed
  - Shell expands `~` automatically when executing hooks
  - Simpler setup in ctx-init and ctx-upgrade

### Technical
- New tracker file: `/tmp/ctx-write-count` for Write tool tracking
- Both stop-enforcer and post-tool scripts updated to v1.6.8
- Added `.sh` and `.bash` to code file detection

---

## [1.6.7] - 2026-01-19

### Added
- **BLOCKING Stop Hook** - Claude literally CANNOT stop until documentation is done!
  - Uses `"decision": "block"` JSON response to prevent session end
  - Checks if code was edited (>2 edits) but no P*.md docs created
  - If blocked, Claude receives instructions to run /ctx-doc first
  - New script: `~/.claude/hooks/ctx-stop-enforcer.sh`

### Changed
- Stop hook now uses `blocking: true` in settings.json
- 4 hook scripts installed (was 3): session-start, session-end, stop-enforcer, post-tool
- Claude is now FORCED to document, not just reminded

### Technical
- Stop hook returns `{"decision": "block", "reason": "..."}` to prevent completion
- Based on Claude Code's hook control flow: exit code 2 or decision:block
- References: https://stevekinney.com/courses/ai-development/claude-code-hook-control-flow

---

## [1.6.6] - 2026-01-19

### Added
- **STOP-AND-DOCUMENT Rules** - Mandatory stopping points for documentation
  - Stop after creating any file >20 lines
  - Stop after each feature when user asks for multiple
  - Stop after any significant change
  - "Large file (>50 lines) = MANDATORY STOP & DOCUMENT"

### Changed
- New section: "🛑 STOP-AND-DOCUMENT RULES (MANDATORY!)"
- Explicit "WRONG vs RIGHT" example for multiple features
- Clear rule: "NEVER say 'Adding X... Next: Y' - document X first!"
- Prevents batching features without documenting each

### Fixed
- Issue where Claude would create multiple features without stopping to document
- Now explicitly requires: plan doc → feature 1 → doc → feature 2 → doc → etc.

---

## [1.6.5] - 2026-01-19

### Added
- **Document Granularity Rules** - Clear guidance on what goes in what document
  - Architecture doc = ONLY tech stack, file structure, high-level design
  - Each FEATURE = its own separate document
  - Each PLAN = its own document with progress tracking
  - Each ERROR/BUG = its own document
  - Each DECISION = its own document

### Changed
- Added "DOCUMENT GRANULARITY (CRITICAL!)" section to global CLAUDE.md
- Clear "When to CREATE NEW doc vs UPDATE existing" decision tree
- Example project structure showing proper doc organization
- Anti-pattern examples showing what NOT to do
- Prevents "architecture doc bloat" where everything gets lumped into P001

### Fixed
- Issue where Claude would put ALL features into one "architecture" doc
- Now explicitly states: "⛔ NOT features, NOT implementations, NOT details" for architecture

---

## [1.6.4] - 2026-01-19

### Added
- **Large change detection** - Changes with >20 lines trigger immediate reminder
  - Catches significant feature additions like your 69-line synthetic noise generator
  - Message: "LARGE CHANGE (~X lines) - Document this feature NOW"
- **Plan documentation reminders**
  - First edit: "Task started - Document your PLAN first"
  - Second edit: "Multi-step task detected - Document plan & track progress"
- **Progress tracking** - Reminds to update docs with progress every 3 edits

### Changed
- Edit reminders now prioritized: Large change > First edit > Multi-step > Every 3rd
- New tracker file: `PLAN_REMINDED_FILE` (`/tmp/ctx-plan-reminded`)
- All tracker files reset when documenting to vault
- Stronger messaging: "NOW" emphasis on important reminders

### Technical
- Line count estimation via `\\n` counting in JSON input
- Three tracker files: edit count, first edit, plan reminded
- All trackers reset on vault documentation

---

## [1.6.3] - 2026-01-19

### Fixed
- **PostToolUse hooks now installed in PROJECT settings** (critical bug fix)
  - v1.6.1 only installed PostToolUse hooks in global `~/.claude/settings.json`
  - Project settings (`.claude/settings.json`) were missing PostToolUse hooks
  - This caused mid-session reminders to not fire in some projects
  - Now `/ctx-init` and `/ctx-upgrade` install PostToolUse hooks in project settings

### Changed
- **More aggressive feature documentation reminders:**
  - Edit threshold reduced from 5 to 3 (reminds every 3 code changes)
  - Added **first-edit reminder** - now reminds on FIRST code change of session
  - Write reminder now says "FEATURE ADDED" (not wishy-washy "if significant")
  - Messages explicitly mention "add/edit/remove features"
- `/ctx-upgrade` Step 3 now includes full PostToolUse hook configuration
- `/ctx-init` Step 5 now includes PostToolUse hooks in project settings
- Added more file extensions: `.vue`, `.svelte`, `.astro`

### Technical
- Project `.claude/settings.json` now contains: SessionStart, Stop, AND PostToolUse
- Both global and project settings reference `~/.claude/hooks/ctx-post-tool.sh`
- New `FIRST_EDIT_FILE` tracker (`/tmp/ctx-first-edit-done`) resets on documentation
- Ensures mid-session reminders work regardless of which settings file takes precedence

---

## [1.6.1] - 2026-01-18

### Added
- **PostToolUse Hooks** - Smart reminders DURING work, not just at session boundaries
  - Fires after Edit, Write, Bash, and Task tools
  - Edit counter: reminds every 5 code file edits
  - Test/build detection: reminds after `npm test`, `cargo build`, etc.
  - Exploration detection: reminds after Task tool usage
  - Counter resets when you document (write to vault/*.md)
- **No jq dependency** - Hook script uses pure bash for portability
- **`/ctx-upgrade` updated** - Now installs PostToolUse hooks

### Changed
- Moved from boundary-only reminders to continuous awareness
- Hook script at `~/.claude/hooks/ctx-post-tool.sh`
- Global settings now include PostToolUse matchers

### Technical
- PostToolUse hooks use tool matchers: Edit, Write, Bash, Task
- State tracked in `/tmp/ctx-edit-count` (resets on documentation)
- Code file detection via extension matching (not all files trigger reminders)

---

## [1.6.0] - 2026-01-18

### Added
- **6 New Commands - Vault Maintenance & Knowledge Tools:**
  - `/ctx-health` - Diagnose vault health issues (stale docs, over-limit files, orphaned entries)
  - `/ctx-note` - Quick one-liner notes without full document structure
  - `/ctx-changelog` - Generate changelog from document history entries
  - `/ctx-link` - Analyze and create bidirectional links between documents
  - `/ctx-quiz` - Quiz yourself on project knowledge to verify documentation accuracy
  - `/ctx-explain` - Generate comprehensive project explanation from all docs

### Changed
- Total commands: 17 → 23
- Updated `/ctx-help` with new "VAULT MAINTENANCE" and "KNOWLEDGE TOOLS" sections
- Updated README with v1.6.0 features and command reference
- Updated uninstaller to handle all 23 commands

### Technical
- All new commands follow established patterns from P003 (installer patterns)
- Commands documented in P005 (v1.6.0 Feature Ideas)

---

## [1.5.3] - 2026-01-18

### Added
- **`/ctx-upgrade` command** - Upgrade existing project installations to latest ContextVault version
  - Updates `./CLAUDE.md` with stronger enforcement language
  - Refreshes project hooks and settings
  - Preserves existing documentation

### Changed
- **Stronger enforcement in `/ctx-init` template**
  - New visual box showing documentation commands after each task type
  - Explicit "NEVER ask, NEVER wait, NEVER skip" rules
  - Command quick-reference for bug fixes, decisions, learnings
- **More forceful session hooks**
  - Start hook now shows command reminders for each task type
  - End hook warns when no docs were modified
  - Clearer prompts for `/ctx-handoff` at session end
- Total commands: 16 → 17

---

## [1.5.2] - 2026-01-18

### Added
- **5 New Commands:**
  - `/ctx-handoff` - Generate session handoff summaries for seamless continuation
  - `/ctx-intel` - Generate codebase intelligence file (tech stack, architecture, key files)
  - `/ctx-error` - Capture errors and solutions to searchable database
  - `/ctx-snippet` - Save reusable code snippets with context and gotchas
  - `/ctx-decision` - Log architectural decisions with rationale and alternatives
- **Git Pre-Commit Hook** integration in `/ctx-init` (Step 6)
  - Reminds Claude to document when committing code
  - Shows staged files count and names
  - Non-blocking (always allows commit to proceed)
- Session-end hook now prompts for `/ctx-handoff`
- CHANGELOG.md file for GitHub release tracking

### Changed
- Total commands: 11 → 16
- Updated `/ctx-help` with new "SESSION & CODEBASE" section
- Updated uninstaller to handle all 16 commands
- `/ctx-init` now has 7 steps (added git hook installation)

---

## [1.5.1] - 2026-01-18

### Added
- Session tracking with modification detection
- Session file created at start (`/tmp/ctx_session_${PPID}_${timestamp}`)
- End hook now reports which docs were modified during session
- Lists specific G*.md and P*.md files that were created/updated

### Changed
- End hook now provides session summary instead of generic reminder
- Improved session file matching using PPID for concurrent session support

---

## [1.5.0] - 2026-01-18

### Added
- External hook scripts replace inline echo commands
- `ctx-session-start.sh` - Full status report with doc counts
- `ctx-session-end.sh` - Session summary with modification tracking
- Automatic update checking from GitHub (2s timeout)
- Version display in session start banner

### Changed
- Hooks moved from inline commands to `~/.claude/hooks/` directory
- Global settings.json now references external scripts

---

## [1.4.0] - 2026-01-18

### Added
- Enhanced instructions with clear visual checklists
- Pre-work checklist (session start)
- Post-work checklist (after tasks)
- ASCII box diagrams for better readability

### Changed
- Restructured CLAUDE.md for clearer workflow guidance
- Improved documentation routing decision tree

---

## [1.3.0] - 2026-01-17

### Added
- Two-tier vault system (Global + Project)
- G### prefix for global docs
- P### prefix for project docs
- Mode settings (local/full/global)

### Changed
- Separated global and project documentation
- Index files now in respective vault folders

---

## [1.2.0] - 2026-01-16

### Added
- `/ctx-init` command for project initialization
- `/ctx-status` command for vault status
- `/ctx-doc` command for quick documentation
- `/ctx-search` command for searching indexes
- `/ctx-read` command for reading docs by ID

### Changed
- Commands moved to `~/.claude/commands/` directory

---

## [1.1.0] - 2026-01-15

### Added
- Index-based documentation system
- Related terms mapping
- Archive system for deprecated docs
- Document template (`_template.md`)

### Changed
- Moved from flat files to structured index + docs

---

## [1.0.0] - 2026-01-14

### Added
- Initial ContextVault implementation
- Basic documentation storage in `.claude/vault/`
- Session start/end hooks
- Core rules (no duplicates, update index, etc.)

---

[1.7.6]: https://github.com/ahmadzein/ContextVault/releases/tag/v1.7.6
[1.7.5]: https://github.com/ahmadzein/ContextVault/releases/tag/v1.7.5
[1.7.4]: https://github.com/ahmadzein/ContextVault/releases/tag/v1.7.4
[1.7.3]: https://github.com/ahmadzein/ContextVault/releases/tag/v1.7.3
[1.7.2]: https://github.com/ahmadzein/ContextVault/releases/tag/v1.7.2
[1.7.1]: https://github.com/ahmadzein/ContextVault/releases/tag/v1.7.1
[1.7.0]: https://github.com/ahmadzein/ContextVault/releases/tag/v1.7.0
[1.6.9]: https://github.com/ahmadzein/ContextVault/releases/tag/v1.6.9
[1.6.8]: https://github.com/ahmadzein/ContextVault/releases/tag/v1.6.8
[1.6.7]: https://github.com/ahmadzein/ContextVault/releases/tag/v1.6.7
[1.6.6]: https://github.com/ahmadzein/ContextVault/releases/tag/v1.6.6
[1.6.5]: https://github.com/ahmadzein/ContextVault/releases/tag/v1.6.5
[1.6.4]: https://github.com/ahmadzein/ContextVault/releases/tag/v1.6.4
[1.6.3]: https://github.com/ahmadzein/ContextVault/releases/tag/v1.6.3
[1.6.1]: https://github.com/ahmadzein/ContextVault/releases/tag/v1.6.1
[1.6.0]: https://github.com/ahmadzein/ContextVault/releases/tag/v1.6.0
[1.5.3]: https://github.com/ahmadzein/ContextVault/releases/tag/v1.5.3
[1.5.2]: https://github.com/ahmadzein/ContextVault/releases/tag/v1.5.2
[1.5.1]: https://github.com/ahmadzein/ContextVault/releases/tag/v1.5.1
[1.5.0]: https://github.com/ahmadzein/ContextVault/releases/tag/v1.5.0
[1.4.0]: https://github.com/ahmadzein/ContextVault/releases/tag/v1.4.0
[1.3.0]: https://github.com/ahmadzein/ContextVault/releases/tag/v1.3.0
[1.2.0]: https://github.com/ahmadzein/ContextVault/releases/tag/v1.2.0
[1.1.0]: https://github.com/ahmadzein/ContextVault/releases/tag/v1.1.0
[1.0.0]: https://github.com/ahmadzein/ContextVault/releases/tag/v1.0.0
