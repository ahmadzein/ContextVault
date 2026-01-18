# 🏰 ContextVault

> *Your knowledge, perfectly organized. Your context, never lost.*

**External Context Management System for Claude Code** 🤖

A two-tier documentation system that gives Claude Code a **persistent memory** across all your projects. No more re-explaining things. No more lost context. Just smooth, continuous collaboration.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

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

### One-liner (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/ahmadzein/ContextVault/main/install-contextvault.sh | bash
```

### Manual Install

```bash
# Download
curl -O https://raw.githubusercontent.com/ahmadzein/ContextVault/main/install-contextvault.sh

# Make executable
chmod +x install-contextvault.sh

# Run it! 🎉
./install-contextvault.sh
```

---

## 🗑️ Uninstall

Changed your mind? No hard feelings! 😢

### One-liner

```bash
curl -fsSL https://raw.githubusercontent.com/ahmadzein/ContextVault/main/uninstall-contextvault.sh | bash
```

### Manual Uninstall

```bash
curl -O https://raw.githubusercontent.com/ahmadzein/ContextVault/main/uninstall-contextvault.sh
chmod +x uninstall-contextvault.sh
./uninstall-contextvault.sh
```

> 💡 Don't worry - we create a backup before removing anything!

---

## 📦 What Gets Installed

```
~/.claude/
├── 📄 CLAUDE.md                 # Global brain instructions
├── 📁 commands/                 # Your new superpowers ⚡
│   ├── ctx-init.md
│   ├── ctx-status.md
│   ├── ctx-mode.md
│   ├── ctx-help.md
│   ├── ctx-new.md
│   ├── ctx-doc.md
│   ├── ctx-update.md
│   ├── ctx-search.md
│   └── ctx-read.md
└── 📁 vault/                    # Global knowledge storage
    ├── index.md                 # 📇 Quick lookup table
    ├── settings.json            # ⚙️ Mode settings
    ├── _template.md             # 📝 Doc template
    └── G001_contextvault.md     # 📚 First doc!
```

---

## 🎮 Commands Reference

After installation, you get **9 powerful slash commands** in Claude Code:

### 🏠 Setup & Status

| Command | Description | When to Use |
|---------|-------------|-------------|
| `/ctx-help` | 📖 Show all commands | When you forget what's available |
| `/ctx-status` | 📊 Check vault status | Start of session, see what exists |
| `/ctx-init` | 🎬 Initialize project vault | First time in a new project |
| `/ctx-mode` | 🔄 Switch modes | Change global/local behavior |

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

---

## 📚 Detailed Command Documentation

### `/ctx-help` 📖

**Shows all available commands and quick reference.**

```
Usage: /ctx-help
```

When you run this, you'll see a beautiful command reference card with:
- All 9 commands and their purposes
- Mode options explained
- Quick reference for limits and rules
- Routing guide (global vs project)

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
1. Creates `.claude/vault/` folder in your project
2. Sets up the project index
3. Copies the document template

**Run this once per project.** After that, you can create P### docs!

---

### `/ctx-mode` 🔄

**Switch between different operating modes.**

```
Usage: /ctx-mode [mode]

Modes:
  full   - Use global + project docs (default)
  local  - Project only, ignore global
  global - Global only, ignore project
```

**When to use each mode:**

| Mode | Best For |
|------|----------|
| `full` | Normal work - access everything |
| `local` | Isolated project, no cross-contamination |
| `global` | Building up your personal knowledge base |

**Examples:**
```
/ctx-mode         → Show current mode
/ctx-mode local   → Switch to project-only
/ctx-mode full    → Back to normal
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

**The routing question:**
```
┌─────────────────────────────────────────────────────────────┐
│              WHERE SHOULD THIS DOCUMENT GO?                  │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  [1] GLOBAL (G###) - ~/.claude/vault/                       │
│      → Reusable patterns, tools, best practices             │
│      → Available in ALL your projects                       │
│                                                              │
│  [2] PROJECT (P###) - ./.claude/vault/                      │
│      → This project's architecture                           │
│      → Configs specific to here only                        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
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

---

## 🏗️ How It Works

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

### 📏 Size Limits

| What | Limit | Why |
|------|-------|-----|
| Index entries | 50 max | Keep it scannable |
| Document lines | 100 max | Focused knowledge |
| Summary words | 15 max | Quick decisions |

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
└─→ Done! 🎉
```

---

## 💡 Pro Tips

### 🎨 Naming Documents

Good names are searchable:
```
✅ G001_docker_compose_patterns.md
✅ P001_user_authentication_flow.md
✅ G002_typescript_utility_types.md

❌ G001_stuff.md
❌ P001_notes.md
❌ G002_misc.md
```

### 🔄 When to Update vs Create New

```
Ask yourself: "Is this the SAME topic?"

YES → /ctx-update [ID]
NO  → /ctx-new [topic]

Examples:
• "More Docker tips" → Update existing Docker doc
• "Kubernetes basics" → New doc (different topic!)
```

### 🌍 Global vs Project Decision

```
Will I use this in OTHER projects?
│
├─→ YES: Global (G###)
│   • Design patterns
│   • Tool knowledge
│   • Language features
│
└─→ NO: Project (P###)
    • This app's architecture
    • Specific configs
    • Local decisions
```

---

## 🔧 Installer Commands

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

---

## 🆘 Troubleshooting

### Commands not showing up?

Make sure you're in **Claude Code CLI**, not the web interface!

```bash
# This is Claude Code CLI
claude

# Not this (web browser)
# https://claude.ai
```

### Permission denied?

```bash
chmod +x install-contextvault.sh
chmod +x uninstall-contextvault.sh
```

### Want to start fresh?

```bash
./install-contextvault.sh uninstall
./install-contextvault.sh install
```

---

## 📋 Requirements

- ✅ Claude Code CLI installed
- ✅ Bash shell (macOS, Linux, WSL)
- ✅ That's it!

---

## 🌟 Origin Story

I was already using a similar approach - documenting findings in separate files while working with Claude Code and loading only relevant docs when needed. When I discovered the "Recursive Language Models" paper (arxiv:2512.24601), I realized the concepts aligned with what I was doing intuitively.

This project combines my practical workflow with the theoretical framework from the paper, resulting in a structured two-tier system with proper tooling.

**This is an independent implementation and is not affiliated with or endorsed by the paper's authors.**

---

## 🤝 Contributing

Found a bug? Have an idea?

1. Fork it 🍴
2. Branch it 🌿
3. Fix it 🔧
4. PR it 🎁

---

## 📄 License

MIT - Do whatever you want! Just don't blame me if your vault becomes sentient. 🤖

---

<div align="center">

**Made with 💜 and too much ☕**

*Star ⭐ if ContextVault saved your context!*

[Report Bug](https://github.com/ahmadzein/ContextVault/issues) · [Request Feature](https://github.com/ahmadzein/ContextVault/issues)

</div>
