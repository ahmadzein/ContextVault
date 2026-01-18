# Changelog

All notable changes to ContextVault will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[1.5.3]: https://github.com/ahmadzein/ContextVault/releases/tag/v1.5.3
[1.5.2]: https://github.com/ahmadzein/ContextVault/releases/tag/v1.5.2
[1.5.1]: https://github.com/ahmadzein/ContextVault/releases/tag/v1.5.1
[1.5.0]: https://github.com/ahmadzein/ContextVault/releases/tag/v1.5.0
[1.4.0]: https://github.com/ahmadzein/ContextVault/releases/tag/v1.4.0
[1.3.0]: https://github.com/ahmadzein/ContextVault/releases/tag/v1.3.0
[1.2.0]: https://github.com/ahmadzein/ContextVault/releases/tag/v1.2.0
[1.1.0]: https://github.com/ahmadzein/ContextVault/releases/tag/v1.1.0
[1.0.0]: https://github.com/ahmadzein/ContextVault/releases/tag/v1.0.0
