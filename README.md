<div align="center">

# 🏰 ContextVault

### *Your knowledge, perfectly organized. Your context, never lost.*

<br>

```
   🏰🏰🏰🏰🏰🏰🏰🏰🏰🏰🏰🏰🏰🏰🏰
   🏰                           🏰
   🏰   WELCOME TO THE VAULT    🏰
   🏰   Where Context Lives     🏰
   🏰   Forever! ✨              🏰
   🏰                           🏰
   🏰🏰🏰🏰🏰🏰🏰🏰🏰🏰🏰🏰🏰🏰🏰
```

<br>

**Give Claude Code a persistent memory across ALL your projects** 🧠

[![Version](https://img.shields.io/badge/version-1.8.3-blue.svg)](https://github.com/ahmadzein/ContextVault)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude-Code-blueviolet)](https://claude.ai)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/ahmadzein/ContextVault/pulls)

<br>

[**Quick Install**](#-quick-install) • [**Commands**](#-commands-reference) • [**How It Works**](#%EF%B8%8F-how-it-works) • [**Pro Tips**](#-pro-tips)

</div>

<br>

---

## ✨ Why ContextVault?

| Without ContextVault 😫 | With ContextVault 😎 |
|------------------------|---------------------|
| "Claude, remember that Docker fix we did?" | Claude already knows! |
| Re-explain your project structure every session | Instant project context |
| Lost that brilliant solution from last week | Saved forever in your vault |
| "What was that API pattern again?" | `/ctx-search api` → Found! |

### 🤖 Automatic Documentation

**Claude documents automatically - no asking, no prompting!**

```
❌ OLD WAY: "Should I document this?" → You: "Yes" → Finally documents

✅ NEW WAY: Claude just does it → "Documented to P001_auth_system.md"
```

Claude will automatically:
- 📖 Read indexes at session start
- 📝 Document findings after tasks
- 🔄 Update existing docs when relevant
- 💾 Save new knowledge without asking

<br>

---

## 🎯 What is ContextVault?

Ever wished Claude could **remember** what you taught it last session? That's ContextVault!

```
📁 Global Knowledge (everywhere)     📁 Project Knowledge (here only)
   ~/.claude/vault/                     ./.claude/vault/
   ├── G001_docker_tips.md              ├── P001_auth_system.md
   ├── G002_git_workflows.md            ├── P002_database.md
   └── ...patterns you use often        └── ...this project's secrets
```

**The magic:** Claude loads just the index (~50 lines) + 1 relevant doc. Minimal context, maximum knowledge! 🧠

---

## 🚀 Quick Install

<div align="center">

### ⚡ One command. That's it. ⚡

```bash
curl -fsSL https://raw.githubusercontent.com/ahmadzein/ContextVault/main/install-contextvault.sh | bash
```

**Watch the magic happen!** 🎩✨

</div>

<details>
<summary>📦 <b>Manual Install</b> (click to expand)</summary>

<br>

```bash
# Download
curl -O https://raw.githubusercontent.com/ahmadzein/ContextVault/main/install-contextvault.sh

# Make executable
chmod +x install-contextvault.sh

# Run it! 🎉
./install-contextvault.sh
```

</details>

---

<details>
<summary>🗑️ <b>Uninstall</b> (hopefully you won't need this!)</summary>

<br>

Changed your mind? No hard feelings! 😢

**One-liner (no prompts):**
```bash
curl -fsSL https://raw.githubusercontent.com/ahmadzein/ContextVault/main/uninstall-contextvault.sh -o /tmp/uninstall.sh && bash /tmp/uninstall.sh --force
```

**Interactive (asks for confirmation):**
```bash
curl -fsSL https://raw.githubusercontent.com/ahmadzein/ContextVault/main/uninstall-contextvault.sh -o /tmp/uninstall.sh && bash /tmp/uninstall.sh
```

> 💡 Don't worry - we create a backup at `~/.contextvault_backup_*` before removing anything!
>
> 💡 When you reinstall, ContextVault will detect your backup and offer to restore it!

</details>

---

## 🌟 Features at a Glance

<table>
<tr>
<td align="center" width="25%">

### 🧠
**Persistent Memory**

Claude remembers across sessions

</td>
<td align="center" width="25%">

### 🌍
**Two-Tier System**

Global + Project knowledge

</td>
<td align="center" width="25%">

### ⚡
**25 Commands**

Full control at your fingertips

</td>
<td align="center" width="25%">

### 🪶
**Minimal Context**

~200 lines max loaded

</td>
</tr>
<tr>
<td align="center">

### 🔍
**Smart Search**

Find anything instantly

</td>
<td align="center">

### 🔄
**Mode Switching**

Full / Local / Global

</td>
<td align="center">

### 🪝
**Auto-Hooks**

SessionStart + PostToolUse + Stop

</td>
<td align="center">

### 🛡️
**Backup Safety**

Never lose your docs

</td>
</tr>
</table>

---

## 📦 What Gets Installed

### Global Installation (by installer)
```
~/.claude/
├── 📄 CLAUDE.md                 # Global instructions (all projects)
├── 📄 settings.json             # 🪝 Global hooks (SessionStart + Stop + PostToolUse)
├── 📁 hooks/                    # Hook scripts (v1.8.3)
│   ├── ctx-session-start.sh    # Session start status
│   ├── ctx-session-end.sh      # Session end reminder
│   ├── ctx-stop-enforcer.sh    # Session summary & self-assessment
│   └── ctx-post-tool.sh        # Milestone-based reminders
├── 📁 commands/                 # Your new superpowers ⚡
│   ├── ctx-init.md
│   ├── ctx-status.md
│   ├── ctx-mode.md
│   ├── ctx-help.md
│   ├── ctx-new.md
│   ├── ctx-doc.md
│   ├── ctx-update.md
│   ├── ctx-search.md
│   ├── ctx-read.md
│   ├── ctx-share.md
│   ├── ctx-import.md
│   ├── ctx-handoff.md           # v1.5.2
│   ├── ctx-intel.md             # v1.5.2
│   ├── ctx-error.md             # v1.5.2
│   ├── ctx-snippet.md           # v1.5.2
│   ├── ctx-decision.md          # v1.5.2
│   ├── ctx-plan.md              # v1.7.1
│   ├── ctx-bootstrap.md         # v1.7.5 - Auto-scan codebase
│   ├── ctx-upgrade.md           # v1.5.3
│   ├── ctx-health.md            # NEW in v1.6.0
│   ├── ctx-note.md              # NEW in v1.6.0
│   ├── ctx-changelog.md         # NEW in v1.6.0
│   ├── ctx-link.md              # NEW in v1.6.0
│   ├── ctx-quiz.md              # NEW in v1.6.0
│   └── ctx-explain.md           # NEW in v1.6.0
└── 📁 vault/                    # Global knowledge storage
    ├── index.md                 # 📇 Quick lookup table
    ├── settings.json            # ⚙️ Mode & limits config
    ├── _template.md             # 📝 Doc template
    └── G001_contextvault.md     # 📚 First doc!
```

### Project Installation (by `/ctx-init`)
```
your-project/
├── 📄 CLAUDE.md                 # ⚠️ Project instructions (FORCES ctx usage!)
└── 📁 .claude/
    ├── 📄 settings.json         # 🪝 Project hooks (SessionStart + Stop)
    └── 📁 vault/                # Project knowledge storage
        ├── index.md             # 📇 Project lookup table
        ├── _template.md         # 📝 Doc template
        └── P001_*.md            # 📚 Project docs
```

> **Important:** There are TWO separate CLAUDE.md files:
> - `~/.claude/CLAUDE.md` - Global (created by installer)
> - `./CLAUDE.md` - Project root (created by `/ctx-init`) - **This is what forces ctx usage!**

---

## 🎮 Commands Reference

After installation, you get **25 powerful slash commands** in Claude Code:

### 🏠 Setup & Status

| Command | Description | When to Use |
|---------|-------------|-------------|
| `/ctx-help` | 📖 Show all commands | When you forget what's available |
| `/ctx-status` | 📊 Check vault status | Start of session, see what exists |
| `/ctx-init` | 🎬 Initialize project vault | First time in a new project |
| `/ctx-upgrade` | ⬆️ Upgrade project to latest | After ContextVault update |
| `/ctx-mode` | 🔄 Switch modes & limits | Change mode or configure limits |

### 📝 Documentation

| Command | Description | When to Use |
|---------|-------------|-------------|
| `/ctx-new` | ✨ Create new document | Document something new |
| `/ctx-doc` | 📸 Quick document | Just finished a task, capture it! |
| `/ctx-update` | 🔧 Update existing doc | Add info to existing topic |

### 🔍 Search & Read

| Command | Description | When to Use |
|---------|-------------|-------------|
| `/ctx-search` | 🔎 Search all indexes | Find if something exists |
| `/ctx-read` | 📖 Read doc by ID | Load specific document |

### 📤 Sharing & Import

| Command | Description | When to Use |
|---------|-------------|-------------|
| `/ctx-share` | 📤 Export vault to ZIP (with `-upload` for link) | Share knowledge with team |
| `/ctx-import` | 📥 Import vault from ZIP | Receive shared knowledge |

### 🧠 Session & Codebase

| Command | Description | When to Use |
|---------|-------------|-------------|
| `/ctx-handoff` | 🤝 Generate session handoff summary | Before ending session, for seamless continuation |
| `/ctx-intel` | 🧠 Generate codebase intelligence file | First time in new codebase, understand structure |
| `/ctx-error` | 🐛 Capture error and solution | After fixing a tricky bug |
| `/ctx-snippet` | 📎 Save reusable code snippet | Found code worth reusing |
| `/ctx-decision` | ⚖️ Log decision with rationale | Made architectural choice |
| `/ctx-plan` | 📋 Document multi-step plan | Working on complex multi-task work |
| `/ctx-bootstrap` | 🚀 Auto-scan and document codebase | After /ctx-init, jumpstart documentation |

### 🏥 Vault Maintenance (NEW in v1.6.0!)

| Command | Description | When to Use |
|---------|-------------|-------------|
| `/ctx-health` | 🏥 Diagnose vault health issues | Check for stale docs, over-limit files, orphans |
| `/ctx-note` | 📝 Quick one-liner notes | Small learnings that don't need full docs |
| `/ctx-changelog` | 📜 Generate changelog from history | See all doc changes over time |
| `/ctx-link` | 🔗 Analyze doc bidirectional links | Find relationships between docs |

### 🎯 Knowledge Tools (NEW in v1.6.0!)

| Command | Description | When to Use |
|---------|-------------|-------------|
| `/ctx-quiz` | 🎯 Quiz yourself on project knowledge | Verify documentation accuracy |
| `/ctx-explain` | 📖 Generate project explanation | Create onboarding docs, project overview |

---

<details>
<summary><h2>📚 Detailed Command Documentation</h2> <i>(click to expand)</i></summary>

### `/ctx-help` 📖

**Shows all available commands and quick reference.**

```
Usage: /ctx-help
```

When you run this, you'll see a beautiful command reference card with:
- All 25 commands and their purposes
- Mode options explained
- Quick reference for limits and rules
- Routing guide (global vs project)

**Sample usage:**
```
You: /ctx-help

Claude:
┌─────────────────────────────────────────────────────────────────┐
│                   🏰 CONTEXTVAULT                                │
│                   Command Reference                              │
├─────────────────────────────────────────────────────────────────┤
│  SETUP: /ctx-init  /ctx-status  /ctx-mode  /ctx-help            │
│  DOCS:  /ctx-new   /ctx-doc     /ctx-update                     │
│  FIND:  /ctx-search  /ctx-read                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Pro tip:** Run this at the start of any session to refresh your memory!

---

### `/ctx-status` 📊

**Check the health of your vault system.**

```
Usage: /ctx-status
```

Shows you:
- 🌍 Global vault: How many docs, last updated
- 📁 Project vault: Initialized? How many docs?
- ⚡ Quick actions you can take

**Example output:**
```
┌─────────────────────────────────────────────────────────────┐
│                   CONTEXTVAULT STATUS                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  GLOBAL (~/.claude/vault/)                                  │
│  ├── Status: Active ✅                                      │
│  ├── Documents: 5 / 50 max                                  │
│  └── Last updated: 2025-01-18                               │
│                                                              │
│  PROJECT (./.claude/vault/)                                 │
│  ├── Status: Not Initialized ❌                             │
│  └── Run /ctx-init to set up                                │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

### `/ctx-init` 🎬

**Initialize ContextVault in your current project.**

```
Usage: /ctx-init
```

What it does:
1. **Creates/Updates `./CLAUDE.md`** in project root with mandatory ctx instructions
2. Creates `.claude/vault/` folder in your project
3. Sets up the project index
4. Copies the document template
5. **Creates `.claude/settings.json`** with project hooks (SessionStart + Stop)
6. **Installs Git pre-commit hook** (v1.5.2+) - reminds Claude to document when you commit!

**The key:** It adds ContextVault instructions to your project's `./CLAUDE.md` AND installs hooks that **force** Claude to use ctx!

**Sample usage:**
```
You: /ctx-init

Claude:
🎬 Initializing ContextVault for this project...

✅ ContextVault initialized for this project!

Created/Updated:
├── ./CLAUDE.md                ← ContextVault instructions (FORCES ctx usage!)
├── .claude/vault/index.md     ← Project documentation index
├── .claude/vault/_template.md ← Document template
├── .claude/settings.json      ← Project hooks (SessionStart + Stop)
└── .git/hooks/pre-commit      ← Git hook (documentation reminder)

🪝 Hooks installed:
   SessionStart → Reminds to read project vault
   Stop         → Reminds to document learnings
   Git Commit   → Reminds to document changes

Claude will now AUTOMATICALLY:
• Read project vault at session start (enforced by hook!)
• Document findings without asking
• Use P### prefix for project docs

Run /ctx-status to verify setup.
```

**If `./CLAUDE.md` already exists:** The ctx instructions are **appended** to it.
**If `./CLAUDE.md` doesn't exist:** It's **created** with ctx instructions.

**Run this once per project.** Claude will then be **forced** to use ContextVault!

---

### `/ctx-mode` 🔄

**Switch modes and configure limits.**

```
Usage: /ctx-mode [mode|limit] [value]

Modes:
  local  - Project only, ignore global (DEFAULT)
  full   - Use global + project docs
  global - Global only, ignore project

Limits:
  max-global N   - Max global docs (default: 50)
  max-project N  - Max project docs (default: 50)
  max-lines N    - Max lines per doc (default: 100)
  max-summary N  - Max summary words (default: 15)
```

**When to use each mode:**

| Mode | Best For |
|------|----------|
| `local` | Focused project work (default) |
| `full` | Access everything - global + project |
| `global` | Building up your personal knowledge base |

**Examples:**
```
/ctx-mode              → Show current mode & limits
/ctx-mode local        → Switch to project-only (default)
/ctx-mode full         → Enable global + project
/ctx-mode max-global 100   → Allow up to 100 global docs
/ctx-mode max-project 25   → Allow up to 25 project docs
```

---

### `/ctx-new` ✨

**Create a new document with guided routing.**

```
Usage: /ctx-new [topic]
```

This command:
1. 🔍 Searches both indexes for existing docs
2. ❓ Asks you: Global or Project?
3. 📝 Creates the doc with proper ID (G### or P###)
4. 📇 Updates the index automatically

**Sample usage:**
```
You: /ctx-new Docker Compose patterns

Claude:
🔍 Searching existing docs for "Docker Compose"...
   No existing docs found.

Where should this document go?

┌─────────────────────────────────────────────────────────────┐
│  [1] GLOBAL  - Reusable across all projects                 │
│  [2] PROJECT - Only for this project                        │
└─────────────────────────────────────────────────────────────┘

You: 1

Claude:
✅ Created G002_docker_compose_patterns.md

📄 Document created at: ~/.claude/vault/G002_docker_compose_patterns.md
📇 Index updated with: G002 | Docker Compose patterns | ...

What would you like to document about Docker Compose patterns?
```

---

### `/ctx-doc` 📸

**Quick documentation after completing a task.**

```
Usage: /ctx-doc
```

The fastest way to capture knowledge! Just run it after finishing something, and it will:

1. 💬 Ask what you learned
2. 🔍 Check if related docs exist
3. 🤔 Ask: Update existing or create new?
4. 📝 Do the right thing automatically

**Sample usage:**
```
You: /ctx-doc

Claude:
📸 Quick Documentation Mode

What did you just learn or figure out?

You: I found that using Docker multi-stage builds reduces image size by 60%

Claude:
🔍 Searching for related docs...
   Found: G002 - Docker Compose patterns

What would you like to do?
  [1] Update G002 (add to existing Docker doc)
  [2] Create new document

You: 1

Claude:
✅ Updated G002_docker_compose_patterns.md

Added to "Current Understanding" section:
  • Multi-stage builds reduce image size by 60%

📇 Index summary updated.
```

**Perfect for:** "I just figured this out, let me save it before I forget!"

---

### `/ctx-update` 🔧

**Update an existing document by ID.**

```
Usage: /ctx-update [ID]

Examples:
  /ctx-update G001
  /ctx-update P003
```

What it does:
1. 📖 Reads the current document
2. 📋 Shows you what's there
3. ❓ Asks what needs updating
4. ✏️ Updates correctly (replaces outdated, adds new)
5. 📇 Updates the index summary

**Sample usage:**
```
You: /ctx-update G001

Claude:
📖 Reading G001_contextvault.md...

Current contents:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ContextVault Setup
- Two-tier system: global + project
- 9 slash commands available
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

What would you like to update?

You: Add that the default mode is now "local" instead of "full"

Claude:
✅ Updated G001_contextvault.md

Changes made:
  • Added: Default mode is "local" (project-focused)
  • Previous info moved to History section

📇 Index summary updated.
```

**Important:** Old info goes to History section with a date!

---

### `/ctx-search` 🔎

**Search across all your documentation.**

```
Usage: /ctx-search [query]

Examples:
  /ctx-search authentication
  /ctx-search docker
  /ctx-search database
```

Searches:
- 📋 Topic names
- 📝 Summaries
- 🏷️ Related terms map

**Example output:**
```
┌─────────────────────────────────────────────────────────────┐
│            CONTEXTVAULT SEARCH: "auth"                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  GLOBAL MATCHES:                                             │
│  └── G003: JWT Patterns - Token auth best practices         │
│                                                              │
│  PROJECT MATCHES:                                            │
│  └── P001: Auth System - OAuth2 implementation details      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

### `/ctx-read` 📖

**Read a specific document by ID.**

```
Usage: /ctx-read [ID]

Examples:
  /ctx-read G001
  /ctx-read P002
```

Quick way to load a document when you know its ID.

- `G###` → Reads from global vault
- `P###` → Reads from project vault

**Sample usage:**
```
You: /ctx-read G001

Claude:
📖 Loading G001_contextvault.md...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ContextVault Setup

**ID:** G001
**Last updated:** 2025-01-18
**Status:** Active

## Current Understanding

ContextVault is a two-tier documentation system:
- Global tier (~/.claude/vault/) for cross-project knowledge
- Project tier (./.claude/vault/) for project-specific docs
- Default mode is "local" (project-focused)
- 25 slash commands: ctx-init, ctx-status, ctx-mode, ctx-handoff, ctx-bootstrap, etc.

## Key Commands

- /ctx-new: Create new document
- /ctx-doc: Quick documentation
- /ctx-search: Find existing docs
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Document loaded! How can I help you with this?
```

---

### `/ctx-share` 📤

**Export your vault to a shareable ZIP file with optional cloud upload.**

```
Usage: /ctx-share [-local] [-global] [-all] [-upload] [-email]

Scope (pick one):
  -local   Export project vault only (default)
  -global  Export global vault only
  -all     Export both vaults

Sharing (optional):
  -upload  Upload to transfer.sh (free, 14-day link)
  -email   Open email client with instructions
```

**Storage:** `./ctx-export/` folder in project root (git-trackable)

**File naming:** `ctx_{type}_{project}_{timestamp}.zip`
- `ctx_local_myproject_20260118_143022.zip`
- `ctx_global_20260118_143022.zip`
- `ctx_all_myproject_20260118_143022.zip`

**Sample usage:**
```
You: /ctx-share -all -upload

Claude:
📤 Exporting ContextVault...

📦 Creating export package...
   ├── manifest.json (metadata)
   ├── global/ (3 docs)
   └── project/ (2 docs)

✅ Export complete!

📁 Saved to:
   ./ctx-export/ctx_all_myproject_20260118_143022.zip

🔗 Shareable Link (valid 14 days):
   https://transfer.sh/abc123/ctx_all_myproject_20260118_143022.zip

📥 Recipient imports with:
   /ctx-import ./ctx_all_myproject_20260118_143022.zip
```

**Examples:**
```
/ctx-share                → Export project, save locally
/ctx-share -upload        → Export project + get shareable link
/ctx-share -all -upload   → Export both + upload to transfer.sh
/ctx-share -global -email → Export global + open email client
```

**Use cases:**
- 🤝 Share project knowledge with teammates (use `-upload`)
- 💾 Backup your vault before major changes
- 🔄 Transfer knowledge between machines
- 📧 Email context to collaborators (use `-email`)

---

### `/ctx-import` 📥

**Import a vault from a shared ZIP file.**

```
Usage: /ctx-import <path-to-zip>

Examples:
  /ctx-import ~/Desktop/contextvault_export_20260118_143022.zip
  /ctx-import /path/to/team-context.zip
  /ctx-import ./shared-knowledge.zip
```

What it does:
1. 📖 Reads the ZIP and validates the manifest
2. 🔍 Detects what's inside (global, project, or both)
3. ⚠️ Checks for conflicts with existing docs
4. ❓ Asks how to handle conflicts (if any)

**Conflict Resolution Options:**

| Option | What It Does |
|--------|--------------|
| **Skip** | Keep existing, ignore incoming |
| **Overwrite** | Replace existing with incoming |
| **Merge** | Combine both (adds to existing) |
| **Backup & Overwrite** | Backup existing, then overwrite |

**Sample usage:**
```
You: /ctx-import ~/Desktop/team-context.zip

Claude:
📥 Importing ContextVault export...

📦 Reading: team-context.zip
   ├── manifest.json ✓
   ├── global/ (3 docs)
   └── project/ (2 docs)

⚠️  Conflicts detected:
   • G001 exists locally (different content)
   • P001 exists locally (different content)

How would you like to handle conflicts?
  [1] Skip     - Keep my existing docs
  [2] Overwrite - Replace with incoming
  [3] Merge    - Combine both versions
  [4] Backup & Overwrite - Backup mine, then replace

You: 3

Claude:
✅ Import complete!

   Imported: 5 documents
   Merged: 2 documents (G001, P001)
   Skipped: 0 documents

📇 Indexes updated automatically.
```

**Perfect for:** Receiving knowledge from team members or restoring backups!

</details>

---

## 🏗️ How It Works

### The Setup Flow

```
1️⃣  INSTALL (one time)
    curl ... | bash
    ├── Creates ~/.claude/ with CLAUDE.md, commands, vault
    └── Installs global hooks (SessionStart + Stop + PostToolUse) 🪝

2️⃣  INIT PROJECT (once per project)
    /ctx-init
    ├── Creates ./CLAUDE.md (FORCES ctx in this project!)
    ├── Creates ./.claude/vault/ (project docs)
    └── Installs project hooks (SessionStart + Stop) 🪝

3️⃣  EVERY SESSION (automatic via hooks!)
    🪝 SessionStart hook fires → "Read vault indexes now!"
    Claude reads indexes → Knows your context
    You work on your task → Claude helps
    🪝 PostToolUse hooks fire → Reminds during work (v1.6.9+)
    🪝 Stop hook fires → "Document learnings!"
    Claude documents automatically → No asking!
```

### The Two-Tier System

```
🌍 GLOBAL TIER (~/.claude/vault/)
│
│  Cross-project knowledge that travels with you:
│  • Design patterns you use often
│  • Tool configurations (Docker, Git, etc.)
│  • Best practices you've learned
│  • Framework knowledge
│
│  Documents: G001, G002, G003...
│
└──────────────────────────────────────────

📁 PROJECT TIER (./.claude/vault/)
│
│  Project-specific knowledge stays here:
│  • This app's architecture
│  • Database schema details
│  • API contracts
│  • Team decisions
│
│  Documents: P001, P002, P003...
│
└──────────────────────────────────────────
```

### 🧠 Smart Context Loading

**The secret sauce:** We never load everything!

```
Maximum in context at any time:
┌─────────────────────────────────────┐
│  📇 Global Index    (~50 lines)    │
│  📇 Project Index   (~50 lines)    │
│  📄 ONE Document    (~100 lines)   │
├─────────────────────────────────────┤
│  TOTAL: ~200 lines                  │
│  vs loading EVERYTHING: 💥🔥😱      │
└─────────────────────────────────────┘
```

### 🪝 Automatic Hooks (v1.7.6)

**Claude Code hooks enforce ContextVault automatically!**

```
┌──────────────────────────────────────────────────────────────┐
│                   GLOBAL HOOKS (v1.8.3)                       │
│              ~/.claude/settings.json                          │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  SessionStart → 🔐 ContextVault Active                        │
│                 📚 Read vault indexes at session start        │
│                    Global:  ~/.claude/vault/index.md          │
│                    Project: ./.claude/vault/index.md          │
│                                                               │
│  PostToolUse  → 📝 Configurable Enforcement (v1.8.3)          │
│                 Edit/Write: BLOCKING (threshold-based)        │
│                   light=off, balanced=8 edits, strict=4 edits│
│                   Only blocks if zero docs + 2+ files        │
│                 TodoWrite: non-blocking completion reminder   │
│                 Bash: non-blocking git commit reminder        │
│                 Set level: /ctx-mode enforcement [level]      │
│                                                               │
│  Stop         → 🛡️ Smart Blocking (significant work only)    │
│                 5+ edits, 2+ files, no docs → blocks once    │
│                 New files created, no docs → blocks once      │
│                 Trivial work or already documented → passes   │
│                 Second attempt always passes (escape valve)   │
│                                                               │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                   PROJECT HOOKS (v1.8.3)                      │
│              .claude/settings.json                            │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  SessionStart → 📂 Project ContextVault                       │
│                 📖 Read: ./.claude/vault/index.md             │
│                 🏷️  Use P### prefix for project docs          │
│                                                               │
│  PostToolUse  → 📝 Same as global (configurable enforcement)  │
│                 Edit/Write blocking, TodoWrite/Bash reminders │
│                                                               │
│  Stop         → 🛡️ Same as global (smart blocking)           │
│                 Catches significant undocumented work         │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

**Two layers of gentle enforcement:**
- **Global hooks** → Installed by the installer, apply to ALL projects
- **Project hooks** → Installed by `/ctx-init`, apply to THIS project

### 📏 Size Limits (Configurable!)

| What | Default | Configurable Via |
|------|---------|------------------|
| Global docs | 50 max | `/ctx-mode max-global N` |
| Project docs | 50 max | `/ctx-mode max-project N` |
| Document lines | 100 max | `/ctx-mode max-lines N` |
| Summary words | 15 max | `/ctx-mode max-summary N` |

> 💡 **Need more space?** Just run `/ctx-mode max-global 100` to allow 100 global docs!

---

## 📜 The 8 Golden Rules

1. **📖 Read indexes first** - Always check what exists
2. **🚫 No duplicates** - Update existing, don't create new
3. **🎯 No redundancy** - One topic = one document
4. **⚔️ No conflicts** - Replace outdated info, don't append
5. **🛤️ Correct routing** - Global vs Project, choose wisely
6. **🪶 Minimal loading** - Max 2 indexes + 1 doc
7. **📏 Size limits** - Stay within bounds
8. **📇 Always update index** - Keep it current!

---

## 🎯 Quick Start Guide

### First Time Setup (2 minutes!)

```bash
# 1. Install ContextVault
curl -fsSL https://raw.githubusercontent.com/ahmadzein/ContextVault/main/install-contextvault.sh | bash

# 2. Start Claude Code in any project
claude

# 3. Check it worked!
/ctx-status

# 4. Initialize project vault (optional)
/ctx-init

# 5. See all commands
/ctx-help
```

### Daily Workflow

```
🌅 START SESSION
│
├─→ /ctx-status          # What do I have?
│
├─→ /ctx-search [topic]  # Does this exist?
│
├─→ Work on your task... # Do the thing!
│
├─→ /ctx-doc             # Capture what you learned
│
├─→ /ctx-share (optional) # Share with team
│
└─→ Done! 🎉
```

---

## 💡 Pro Tips

> **🤖 Good news!** The commands handle most of this automatically. These tips help you understand *why* things work the way they do.

### 🎨 Naming Documents

**Handled by:** `/ctx-new` and `/ctx-doc` — they auto-generate proper names!

```
Auto-generated names look like:
✅ G001_docker_compose_patterns.md
✅ P001_user_authentication_flow.md
✅ G002_typescript_utility_types.md

You just provide the topic, we handle the rest!
```

### 🔄 When to Update vs Create New

**Handled by:** `/ctx-doc` — it searches first and asks you!

```
When you run /ctx-doc, it will:
1. 🔍 Search for existing related docs
2. 📋 Show you what it found
3. ❓ Ask: "Update existing or create new?"

No need to remember - just run /ctx-doc!
```

### 🌍 Global vs Project Decision

**Handled by:** `/ctx-new` — it shows you a routing guide!

```
When you run /ctx-new, it asks:
┌─────────────────────────────────────────┐
│   WHERE SHOULD THIS DOCUMENT GO?        │
├─────────────────────────────────────────┤
│   [1] GLOBAL - Use in ALL projects      │
│   [2] PROJECT - Only here               │
└─────────────────────────────────────────┘

The command guides you through it!
```

---

<details>
<summary>🔧 <b>Installer Commands & Troubleshooting</b></summary>

### Installer Commands

```bash
# Install
./install-contextvault.sh
./install-contextvault.sh install

# Uninstall
./install-contextvault.sh uninstall
./uninstall-contextvault.sh

# Update (reinstall)
./install-contextvault.sh update

# Check status
./install-contextvault.sh status

# Help
./install-contextvault.sh help
```

### Troubleshooting

**Commands not showing up?**

Make sure you're in **Claude Code CLI**, not the web interface!

```bash
# This is Claude Code CLI
claude

# Not this (web browser)
# https://claude.ai
```

**Permission denied?**

```bash
chmod +x install-contextvault.sh
chmod +x uninstall-contextvault.sh
```

**Want to start fresh?**

```bash
./install-contextvault.sh uninstall
./install-contextvault.sh install
```

### Edge Cases & Recovery

**Running `/ctx-init` twice in the same project?**
- Safe! It will detect existing files and skip them
- CLAUDE.md section will only be added once
- Your existing docs are preserved

**Accidentally deleted the vault?**
```bash
# Check for backups (created on every reinstall/uninstall)
ls -la ~/.contextvault_backup_*

# Restore from backup
cp -r ~/.contextvault_backup_XXXXXX/vault ~/.claude/vault
```

**Corrupt `.claude/` directory?**
```bash
# Uninstall will backup first
./uninstall-contextvault.sh

# Then reinstall - it will offer to restore from backup
./install-contextvault.sh
```

**Multiple Claude sessions running?**
- Each session uses unique session IDs
- No race conditions - sessions won't interfere with each other

**Missing `jq` tool?**
- Installer works without jq but is safer with it
- Install jq for best experience: `brew install jq` (macOS) or `apt install jq` (Linux)

**Hooks not showing output?**
- Claude Code hooks send output to Claude's context, not your terminal
- This is by design - Claude sees the info, you don't
- Use `/ctx-status` to see vault status manually

</details>

---

## 📋 Requirements & Platform Support

### Requirements

| # | Requirement | Status |
|---|-------------|--------|
| 1 | Claude Code CLI installed | ✅ |
| 2 | Bash shell | ✅ |
| 3 | A desire for organized knowledge | ✅ |

### Platform Support

| Platform | Support | Install Location |
|----------|---------|------------------|
| **macOS** | ✅ Native | `~/.claude` |
| **Linux** | ✅ Native | `~/.claude` |
| **Windows + WSL** | ✅ Full | `~/.claude` (in WSL) |
| **Windows + Git Bash** | ✅ Full | `~/.claude` |
| **Windows Native (CMD/PowerShell)** | ⚠️ See below | N/A |

### 🪟 Windows Users

**Recommended: Use WSL (Windows Subsystem for Linux)**

Claude Code works best with WSL. Here's how to set up:

```powershell
# 1. Install WSL (run in PowerShell as Admin)
wsl --install

# 2. Restart your computer

# 3. Open WSL terminal and install ContextVault
curl -fsSL https://raw.githubusercontent.com/ahmadzein/ContextVault/main/install-contextvault.sh | bash
```

**Alternative: Use Git Bash**

If you have [Git for Windows](https://git-scm.com/download/win) installed:

```bash
# Open Git Bash and run:
curl -fsSL https://raw.githubusercontent.com/ahmadzein/ContextVault/main/install-contextvault.sh | bash
```

> 💡 **Note:** Native Windows (CMD/PowerShell without WSL or Git Bash) is not supported because the installer is a bash script. WSL is recommended for the best Claude Code experience on Windows anyway!

### Where Does It Install?

```
macOS:      /Users/yourname/.claude/
Linux:      /home/yourname/.claude/
WSL:        /home/yourname/.claude/
Git Bash:   C:\Users\yourname\.claude\
```

**That's it!** No extra dependencies. No config files. No hassle.

---

## 🌟 Origin Story

I was already using a similar approach - documenting findings in separate files while working with Claude Code and loading only relevant docs when needed. When I discovered the "Recursive Language Models" paper (arxiv:2512.24601), I realized the concepts aligned with what I was doing intuitively.

This project combines my practical workflow with the theoretical framework from the paper, resulting in a structured two-tier system with proper tooling.

**This is an independent implementation and is not affiliated with or endorsed by the paper's authors.**

---

## 🤝 Contributing

Found a bug? Have an idea? We'd love your help!

```
    🍴 Fork it
       ↓
    🌿 Branch it
       ↓
    🔧 Fix it
       ↓
    🎁 PR it
       ↓
    🎉 Celebrate!
```

All contributions welcome - from typo fixes to new features!

---

## 📄 License

**MIT** - Do whatever you want! Just don't blame me if your vault becomes sentient. 🤖

---

<div align="center">

<br>

```
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   Made with 💜 and mass consumption of ☕                 ║
║                                                           ║
║   If ContextVault saved your context...                   ║
║   ⭐ Star it! ⭐                                          ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
```

<br>

**Questions?** [Open an Issue](https://github.com/ahmadzein/ContextVault/issues) | **Ideas?** [Start a Discussion](https://github.com/ahmadzein/ContextVault/issues)

<br>

*Happy documenting!* 📝✨

</div>
