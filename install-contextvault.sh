#!/bin/bash

#===============================================================================
#
#   🏰 ContextVault Installer
#
#   Your knowledge, perfectly organized. Your context, never lost.
#
#   Works from ANY directory! Just run it and we'll set up everything
#   in ~/.claude/ automagically! ✨
#
#   Usage:
#     ./install-contextvault.sh           # Install ContextVault
#     ./install-contextvault.sh install   # Install ContextVault
#     ./install-contextvault.sh uninstall # Remove ContextVault
#     ./install-contextvault.sh update    # Update to latest version
#     ./install-contextvault.sh status    # Check installation status
#
#   Or via curl (from anywhere!):
#     curl -fsSL https://raw.githubusercontent.com/ahmadzein/ContextVault/main/install-contextvault.sh | bash
#
#===============================================================================

set -e

# Version
VERSION="1.0.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'
DIM='\033[2m'

# Paths (Always installs to ~/.claude - works from any directory!)
CLAUDE_DIR="$HOME/.claude"
VAULT_DIR="$CLAUDE_DIR/vault"
COMMANDS_DIR="$CLAUDE_DIR/commands"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"

#===============================================================================
# 🎨 FUN ANIMATION FUNCTIONS
#===============================================================================

# Spinner animation
spin() {
    local pid=$1
    local delay=0.1
    local spinstr='🌑🌒🌓🌔🌕🌖🌗🌘'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Progress bar
progress_bar() {
    local duration=$1
    local steps=20
    local sleep_time=$(echo "scale=3; $duration / $steps" | bc 2>/dev/null || echo "0.05")

    printf "  ["
    for ((i=0; i<steps; i++)); do
        printf "▓"
        sleep $sleep_time 2>/dev/null || sleep 0.05
    done
    printf "] ✓\n"
}

# Typing effect
type_text() {
    local text="$1"
    local delay=${2:-0.03}
    for ((i=0; i<${#text}; i++)); do
        printf "%s" "${text:$i:1}"
        sleep $delay 2>/dev/null || true
    done
    printf "\n"
}

# Celebration animation
celebrate() {
    local frames=(
        "🎉"
        "🎊"
        "✨"
        "🌟"
        "💫"
        "⭐"
        "🎆"
        "🎇"
    )

    for i in {1..3}; do
        for frame in "${frames[@]}"; do
            printf "\r  $frame $frame $frame  Installing magic...  $frame $frame $frame  "
            sleep 0.1 2>/dev/null || true
        done
    done
    printf "\r                                                    \r"
}

# Castle animation
draw_castle() {
    echo ""
    echo -e "${CYAN}"
    cat << 'CASTLE'
                        🏴                    🏴
                      ░░░░░░                ░░░░░░
                     ░░░░░░░░              ░░░░░░░░
                    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
                    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
                    ░░░░  ░░░░░░░░░░░░░░░░░░░░  ░░░░
                    ░░░░  ░░░░░░░░░░░░░░░░░░░░  ░░░░
                    ░░░░░░░░░░░░░░    ░░░░░░░░░░░░░░
                    ░░░░░░░░░░░░░░    ░░░░░░░░░░░░░░
                    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
CASTLE
    echo -e "${NC}"
}

# Mini castle for header
mini_castle() {
    echo -e "${CYAN}     🏰${NC}"
}

# Rocket launch animation
rocket_launch() {
    local frames=(
        "    🚀    "
        "   🚀     "
        "  🚀      "
        " 🚀       "
        "🚀        "
        "          "
    )

    echo ""
    for i in {1..2}; do
        for frame in "${frames[@]}"; do
            printf "\r  %s  Launching ContextVault..." "$frame"
            sleep 0.15 2>/dev/null || true
        done
    done
    printf "\r                                              \r"
}

# Print functions with flair
print_header() {
    clear 2>/dev/null || true
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                                                                  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${BOLD}${WHITE}🏰 ContextVault${NC}                                               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${DIM}External Context Management System${NC}                            ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${DIM}Version ${VERSION}${NC}                                               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                                  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${YELLOW}Your knowledge, perfectly organized.${NC}                          ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${YELLOW}Your context, never lost.${NC}                                     ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                                  ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}▶${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

print_sparkle() {
    echo -e "${MAGENTA}✨${NC} $1"
}

#===============================================================================
# FILE CONTENT FUNCTIONS
#===============================================================================

create_claude_md() {
    cat << 'CLAUDE_MD_EOF'
# Global Claude Instructions

**Version:** 1.1.0
**Last Updated:** $(date +%Y-%m-%d)
**System:** ContextVault - External Context Management

---

## MANDATORY: AUTO-DOCUMENTATION BEHAVIOR

**YOU MUST AUTOMATICALLY document knowledge to ContextVault. This is NOT optional.**

### When to Auto-Document (DO THIS AUTOMATICALLY):

1. **After completing ANY task** → Run /ctx-doc mentally and save learnings
2. **After exploring/understanding code** → Document architecture, patterns found
3. **After fixing bugs** → Document the issue and solution
4. **After making decisions** → Document the reasoning
5. **After discovering project structure** → Document it to P### docs
6. **After learning reusable patterns** → Document it to G### docs

### How to Auto-Document:

1. Check mode in `~/.claude/vault/settings.json`
2. Read the appropriate index(es) based on mode
3. Search for existing related docs
4. If exists → UPDATE that doc
5. If not exists → CREATE new doc with proper routing
6. ALWAYS update the index after changes

### NEVER Ask "Should I document this?" - JUST DO IT!

```
❌ WRONG: "Want me to document this to ContextVault?"
❌ WRONG: "Should I save this to the vault?"
❌ WRONG: "I could create a P001 doc for this..."

✅ RIGHT: *silently documents* "I've documented the frontend architecture to P001."
✅ RIGHT: *silently updates* "I've updated G003 with the new Docker pattern."
✅ RIGHT: "Documented to P002_auth_system.md"
```

### Session Start Behavior (AUTOMATIC):

At the START of every session or when entering a new project:

1. **Read** `~/.claude/vault/settings.json` to check current mode
2. **Read** indexes based on mode:
   - `local` mode → Only `./.claude/vault/index.md`
   - `full` mode → Both global and project indexes
   - `global` mode → Only `~/.claude/vault/index.md`
3. **Silently note** what knowledge exists for this project
4. **Use** existing knowledge to inform your responses

### Session End / Task Completion (AUTOMATIC):

Before ending a session or after completing significant tasks:

1. **Identify** new knowledge gained during the session
2. **Check** if related docs exist
3. **Create or Update** docs as needed
4. **Confirm** to user: "Documented to [ID]" (brief, not asking permission)

---

## Overview

This document defines a **two-tier documentation system** for efficient context management across all projects. Inspired by concepts from arxiv:2512.24601, this system ensures:

- Minimal context loading (max: 2 indexes + 1 doc)
- No information loss across sessions
- No duplicates, conflicts, or redundancy
- Cross-project knowledge retention
- Project-specific isolation when needed

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                   TWO-TIER CONTEXTVAULT SYSTEM                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   TIER 1: GLOBAL (~/.claude/vault/)                            │
│   ├── Cross-project knowledge                                   │
│   ├── Patterns, best practices, tools                          │
│   ├── Reusable learnings                                        │
│   └── Available in ALL projects                                 │
│                                                                 │
│   TIER 2: PROJECT (./.claude/vault/)                           │
│   ├── Project-specific knowledge                                │
│   ├── This codebase's architecture, configs                    │
│   ├── Local decisions and implementations                       │
│   └── Only relevant to THIS project                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Folder Structure

```
~/.claude/                          # GLOBAL (all projects)
├── CLAUDE.md                       # This file (global instructions)
├── commands/                       # Custom slash commands
│   ├── ctx-init.md
│   ├── ctx-status.md
│   ├── ctx-mode.md
│   ├── ctx-help.md
│   ├── ctx-new.md
│   ├── ctx-doc.md
│   ├── ctx-update.md
│   ├── ctx-search.md
│   └── ctx-read.md
└── vault/
    ├── index.md                    # Global knowledge index
    ├── settings.json               # Mode settings
    ├── _template.md                # Template for new docs
    ├── G001_topic.md               # Global docs (G prefix)
    └── archive/                    # Deprecated global docs

./.claude/                          # PROJECT-SPECIFIC (per project)
└── vault/
    ├── index.md                    # Project knowledge index
    ├── P001_topic.md               # Project docs (P prefix)
    └── archive/                    # Deprecated project docs
```

### Naming Convention

| Prefix | Meaning | Location | Example |
|--------|---------|----------|---------|
| `G###` | Global knowledge | `~/.claude/vault/` | `G001_docker_patterns.md` |
| `P###` | Project knowledge | `./.claude/vault/` | `P001_auth_system.md` |

---

## Core Rules (NEVER BREAK)

### Rule 1: READ INDEXES FIRST
- **Always** read global index: `~/.claude/vault/index.md`
- **Then** read project index (if exists): `./.claude/vault/index.md`
- Search BOTH before creating any doc

### Rule 2: NO DUPLICATES
- Check BOTH indexes for exact topic
- Check for RELATED terms (auth/login/signin = same)
- Check for SYNONYMS and similar concepts
- If exists ANYWHERE → UPDATE, don't create

### Rule 3: NO REDUNDANCY
- One topic = One document (globally unique)
- Merge related info into existing doc
- If unsure → UPDATE existing rather than create new

### Rule 4: NO CONFLICTS
- When updating → REPLACE outdated info (don't append contradictions)
- "Current Understanding" = ONLY current truth
- Move old info to History section with date
- If info contradicts existing → UPDATE that doc

### Rule 5: CORRECT ROUTING
Document to the RIGHT location:

| If knowledge is... | Route to... | Prefix |
|-------------------|-------------|--------|
| General pattern, reusable | Global `~/.claude/vault/` | G### |
| Tool/tech best practice | Global `~/.claude/vault/` | G### |
| Project architecture | Project `./.claude/vault/` | P### |
| Project-specific config | Project `./.claude/vault/` | P### |
| This codebase only | Project `./.claude/vault/` | P### |

### Rule 6: MINIMAL CONTEXT LOADING
- Load: Global index + Project index + ONE doc
- **NEVER** load multiple docs "just in case"
- **NEVER** load all docs from either location

### Rule 7: SIZE LIMITS
| Item | Max Size |
|------|----------|
| Global index | 50 entries |
| Project index | 50 entries |
| Each document | 100 lines |
| Index summary | 15 words |

### Rule 8: ALWAYS UPDATE INDEX
- After ANY doc change → Update that doc's index IMMEDIATELY
- Index summary must reflect CURRENT state
- Index is source of truth

---

## Available Commands

| Command | Description |
|---------|-------------|
| `/ctx-init` | Initialize ContextVault in current project |
| `/ctx-status` | Show global and project status |
| `/ctx-mode` | Toggle mode: full / local / global |
| `/ctx-help` | Show all ContextVault commands |
| `/ctx-new` | Create new document with routing |
| `/ctx-doc` | Quick document after task |
| `/ctx-update` | Update existing document by ID |
| `/ctx-search` | Search both indexes |
| `/ctx-read` | Read document by ID |

---

## Quick Reference

```
┌─────────────────────────────────────────────────────────────────┐
│                 CONTEXTVAULT QUICK REFERENCE                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ START:    Read ~/.claude/vault/index.md (global)               │
│           Read ./.claude/vault/index.md (project, if exists)   │
│                                                                 │
│ SEARCH:   Check BOTH indexes for exact + related + synonyms    │
│                                                                 │
│ LOAD:     2 indexes + ONE doc maximum                          │
│                                                                 │
│ EXISTS:   UPDATE existing doc (never create duplicate)         │
│                                                                 │
│ NEW:      Complete pre-creation checklist first                │
│           Route: Global (G###) or Project (P###)               │
│                                                                 │
│ ALWAYS:   Update index after any doc change                    │
│                                                                 │
│ LIMITS:   Index: 50 entries | Doc: 100 lines | Summary: 15w    │
│                                                                 │
│ NEVER:    Duplicate | Load all | Append conflicts | Skip index │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Task Tracking Integration

In addition to ContextVault documentation:
- Always document before starting task
- Mark tasks as done when completed
- Use TodoWrite for complex multi-step tasks

---

## Acknowledgments

This project is inspired by concepts from:
- "Recursive Language Models" (arxiv:2512.24601)

This is an independent implementation and is not affiliated with or endorsed by the paper's authors.

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | $(date +%Y-%m-%d) | Initial ContextVault installation |
CLAUDE_MD_EOF
}

create_global_index() {
    cat << 'INDEX_EOF'
# ContextVault Index - Global

> **Cross-project knowledge. Available in ALL projects.**
> Read this first, then project index (if exists).

---

## Active Documents

| ID   | Topic | Status | Summary (15 words max) |
|------|-------|--------|------------------------|
| G001 | ContextVault System | Active | Two-tier documentation system for context management across all projects |

---

## Related Terms Map

> Find existing docs when search terms vary

| If searching for... | Check doc... |
|---------------------|--------------|
| contextvault, documentation, context, memory | G001 |

---

## Archived

| ID | Topic | Archived | Reason |
|----|-------|----------|--------|
| - | - | - | - |

---

## Quick Stats

- **Entries:** 1 / 50 max
- **Last updated:** $(date +%Y-%m-%d)

---

## Notes

- G### prefix = Global docs (this folder)
- P### prefix = Project docs (./.claude/vault/)
- Always search BOTH indexes before creating
INDEX_EOF
}

create_settings_json() {
    cat << 'SETTINGS_EOF'
{
  "mode": "local",
  "updated": "$(date +%Y-%m-%d)",
  "limits": {
    "max_global_docs": 50,
    "max_project_docs": 50,
    "max_doc_lines": 100,
    "max_summary_words": 15
  },
  "modes": {
    "full": "Use both global and project documentation",
    "local": "Project-only, ignore global (default)",
    "global": "Global-only, ignore project"
  }
}
SETTINGS_EOF
}

create_template() {
    cat << 'TEMPLATE_EOF'
# [Topic Name]

**ID:** G### or P###
**Last updated:** YYYY-MM-DD
**Status:** Active | Working | Deprecated

---

## Current Understanding

[What is true NOW. Replace this entirely when updating - no outdated info here.]

---

## Key Details

[Specifics, configurations, code snippets if relevant]

---

## Related Topics

- See also: [G### or P###]_related_topic.md

---

## History

- YYYY-MM-DD: What changed (old value → new value)
- YYYY-MM-DD: Initial documentation

---

**Lines: ~XX / 100 max**
TEMPLATE_EOF
}

create_g001_contextvault_system() {
    cat << 'G001_EOF'
# ContextVault Documentation System

**ID:** G001
**Last updated:** $(date +%Y-%m-%d)
**Status:** Active

---

## Current Understanding

Two-tier documentation system for efficient context management. Inspired by concepts from arxiv:2512.24601.

**Core Principle:** Don't load everything into context. Document as you work, store externally, load selectively via indexes.

**Two Tiers:**
1. **Global** (`~/.claude/vault/`) - Cross-project knowledge, patterns, best practices
2. **Project** (`./.claude/vault/`) - Project-specific knowledge, architecture, configs

---

## Key Details

**Naming:**
- `G###` prefix = Global docs
- `P###` prefix = Project docs

**Limits:**
- Index: 50 entries max
- Doc: 100 lines max
- Summary: 15 words max

**Context Loading:**
- Global index + Project index + ONE doc = Maximum loaded at any time

**Rules:**
1. Read both indexes first
2. Search for related terms before creating
3. UPDATE existing, never duplicate
4. Route correctly (global vs project)
5. Always update index after changes

---

## Related Topics

- See project-specific implementations in each project's `./.claude/vault/`

---

## History

- $(date +%Y-%m-%d): Initial global system setup with two-tier architecture

---

**Lines: ~45 / 100 max**
G001_EOF
}

create_project_index_template() {
    cat << 'PROJ_INDEX_EOF'
# ContextVault Index - Project

> **Project-specific knowledge. Only relevant to THIS project.**
> Read global index (~/.claude/vault/index.md) first.

---

## Active Documents

| ID   | Topic | Status | Summary (15 words max) |
|------|-------|--------|------------------------|
| - | - | - | - |

---

## Related Terms Map

> Find existing docs when search terms vary

| If searching for... | Check doc... |
|---------------------|--------------|
| - | - |

---

## Archived

| ID | Topic | Archived | Reason |
|----|-------|----------|--------|
| - | - | - | - |

---

## Quick Stats

- **Entries:** 0 / 50 max
- **Last updated:** YYYY-MM-DD

---

## Notes

- P### prefix = Project docs (this folder)
- G### prefix = Global docs (~/.claude/vault/)
- Always search BOTH indexes before creating
PROJ_INDEX_EOF
}

#===============================================================================
# COMMAND FILES
#===============================================================================

create_cmd_ctx_init() {
    cat << 'CMD_EOF'
# /ctx-init

Initialize ContextVault documentation system in the current project.

## Usage

```
/ctx-init
```

## Instructions

When this command is invoked, perform the following steps:

### Step 1: Check if ContextVault already exists

Check if `.claude/vault/index.md` already exists in the current project.

- If EXISTS: Inform user "ContextVault already initialized in this project" and show current status
- If NOT EXISTS: Proceed to Step 2

### Step 2: Create folder structure

```bash
mkdir -p .claude/vault/archive
```

### Step 3: Create project index

Create `.claude/vault/index.md` with this content:

```markdown
# ContextVault Index - Project

> **Project-specific knowledge. Only relevant to THIS project.**
> Read global index (~/.claude/vault/index.md) FIRST.

---

## Active Documents

| ID   | Topic | Status | Summary (15 words max) |
|------|-------|--------|------------------------|
| - | - | - | - |

---

## Related Terms Map

| If searching for... | Check doc... |
|---------------------|--------------|
| - | - |

---

## Archived

| ID | Topic | Archived | Reason |
|----|-------|----------|--------|
| - | - | - | - |

---

## Quick Stats

- **Entries:** 0 / 50 max
- **Last updated:** [TODAY'S DATE]

---

## Notes

- P### prefix = Project docs (this folder)
- G### prefix = Global docs (~/.claude/vault/)
- Always search BOTH indexes before creating
```

### Step 4: Copy template

Create `.claude/vault/_template.md` with the standard document template.

### Step 5: Confirm completion

Tell the user:
- ContextVault initialized successfully
- Project docs go in `.claude/vault/` with P### prefix
- Global docs go in `~/.claude/vault/` with G### prefix
- Always read both indexes before starting work
CMD_EOF
}

create_cmd_ctx_status() {
    cat << 'CMD_EOF'
# /ctx-status

Show current ContextVault documentation system status.

## Usage

```
/ctx-status
```

## Instructions

When this command is invoked, perform the following:

### Step 1: Check Global ContextVault

Read `~/.claude/vault/index.md` and report:
- Number of global documents (G### entries)
- Status of global system

### Step 2: Check Project ContextVault

Check if `.claude/vault/index.md` exists in current project:
- If EXISTS: Read and report number of project documents (P### entries)
- If NOT EXISTS: Report "Project ContextVault not initialized. Run /ctx-init to set up."

### Step 3: Display Status Summary

Format output like:

```
┌─────────────────────────────────────────────────────────────┐
│                   CONTEXTVAULT STATUS                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  GLOBAL (~/.claude/vault/)                                  │
│  ├── Status: Active                                         │
│  ├── Documents: X / 50 max                                  │
│  └── Last updated: YYYY-MM-DD                               │
│                                                              │
│  PROJECT (./.claude/vault/)                                 │
│  ├── Status: Active / Not Initialized                       │
│  ├── Documents: X / 50 max                                  │
│  └── Last updated: YYYY-MM-DD                               │
│                                                              │
│  QUICK ACTIONS:                                              │
│  • /ctx-init     - Initialize project ContextVault          │
│  • /ctx-new      - Create new document                      │
│  • /ctx-search   - Search both indexes                      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```
CMD_EOF
}

create_cmd_ctx_mode() {
    cat << 'CMD_EOF'
# /ctx-mode

Toggle ContextVault mode and configure limits.

## Usage

```
/ctx-mode [mode|limit] [value]
```

## Arguments

- No args: Show current mode and limits
- `mode`: `full`, `local`, `global` - change mode
- `limit`: `max-global`, `max-project`, `max-lines`, `max-summary` - change limits

## Modes

| Mode | Description | What to Read |
|------|-------------|--------------|
| `local` | Project-only, ignore global (DEFAULT) | Only `./.claude/vault/index.md` |
| `full` | Use both global and project docs | Both indexes |
| `global` | Global-only, ignore project | Only `~/.claude/vault/index.md` |

## Instructions

When this command is invoked:

### If No Argument: Show Current Settings

Read `~/.claude/vault/settings.json` and display:

```
┌─────────────────────────────────────────────────────────────┐
│                 CONTEXTVAULT SETTINGS                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  MODE: [LOCAL / FULL / GLOBAL]                              │
│                                                              │
│  LIMITS:                                                     │
│  ├── Max global docs:   50                                  │
│  ├── Max project docs:  50                                  │
│  ├── Max doc lines:     100                                 │
│  └── Max summary words: 15                                  │
│                                                              │
│  COMMANDS:                                                   │
│  • /ctx-mode local        → Project only (default)          │
│  • /ctx-mode full         → Use global + project            │
│  • /ctx-mode global       → Global only                     │
│  • /ctx-mode max-global 100  → Change global doc limit      │
│  • /ctx-mode max-project 30  → Change project doc limit     │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### If Mode Argument: Set Mode

1. Validate mode is one of: `full`, `local`, `global`

2. Update `~/.claude/vault/settings.json` mode field

3. Confirm change:
```
✓ ContextVault mode changed to [MODE]
```

### If Limit Argument: Set Limit

Valid limit commands:
- `/ctx-mode max-global 100` → Set max global docs to 100
- `/ctx-mode max-project 30` → Set max project docs to 30
- `/ctx-mode max-lines 150` → Set max lines per doc to 150
- `/ctx-mode max-summary 20` → Set max summary words to 20

Update `~/.claude/vault/settings.json` limits section and confirm:
```
✓ Max global docs changed to 100
```

### Behavior Based on Mode

**When mode is `local` (default):**
- Skip global index entirely
- Only read `./.claude/vault/index.md`
- New docs only go to project
- Useful for: focused project work, isolated context

**When mode is `full`:**
- Read `~/.claude/vault/index.md` first
- Then read `./.claude/vault/index.md`
- New docs can go to either location

**When mode is `global`:**
- Only read `~/.claude/vault/index.md`
- Skip project index
- New docs only go to global
- Useful for: building up global knowledge base

## Settings File

`~/.claude/vault/settings.json`
```json
{
  "mode": "local",
  "limits": {
    "max_global_docs": 50,
    "max_project_docs": 50,
    "max_doc_lines": 100,
    "max_summary_words": 15
  }
}
```

## Examples

```
/ctx-mode              → Show current mode and limits
/ctx-mode local        → Switch to project-only (default)
/ctx-mode full         → Switch to global + project
/ctx-mode global       → Switch to global-only
/ctx-mode max-global 100   → Allow up to 100 global docs
/ctx-mode max-project 25   → Allow up to 25 project docs
```
CMD_EOF
}

create_cmd_ctx_help() {
    cat << 'CMD_EOF'
# /ctx-help

Show all available ContextVault commands and quick reference.

## Usage

```
/ctx-help
```

## Instructions

When this command is invoked, display:

```
┌─────────────────────────────────────────────────────────────────┐
│                   🏰 CONTEXTVAULT                                │
│                   Command Reference                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  SETUP & STATUS                                                  │
│  ─────────────────────────────────────────────────────────────  │
│  /ctx-init      Initialize ContextVault in current project      │
│  /ctx-status    Show status of global and project vault         │
│  /ctx-mode      Toggle mode: full / local / global              │
│  /ctx-help      Show this help message                          │
│                                                                  │
│  DOCUMENTATION                                                   │
│  ─────────────────────────────────────────────────────────────  │
│  /ctx-new       Create new document (guided routing)            │
│  /ctx-doc       Quick document after completing task            │
│  /ctx-update    Update existing document by ID                  │
│                                                                  │
│  SEARCH & READ                                                   │
│  ─────────────────────────────────────────────────────────────  │
│  /ctx-search    Search indexes for a topic                      │
│  /ctx-read      Read a document by ID (G001, P002)              │
│                                                                  │
│  MODE OPTIONS (/ctx-mode)                                        │
│  ─────────────────────────────────────────────────────────────  │
│  local    Project-only, global OFF (default)                    │
│  full     Use global + project docs                             │
│  global   Global-only, project OFF                              │
│                                                                  │
│  CONFIGURABLE LIMITS (/ctx-mode max-*)                           │
│  ─────────────────────────────────────────────────────────────  │
│  max-global N    Max global docs (default: 50)                  │
│  max-project N   Max project docs (default: 50)                 │
│  max-lines N     Max lines per doc (default: 100)               │
│  max-summary N   Max words in summary (default: 15)             │
│                                                                  │
│  QUICK REFERENCE                                                 │
│  ─────────────────────────────────────────────────────────────  │
│  • Global docs:  ~/.claude/vault/    (G### prefix)              │
│  • Project docs: ./.claude/vault/    (P### prefix)              │
│  • Max load: 2 indexes + 1 doc                                  │
│  • Default limits: 50 docs, 100 lines, 15-word summary          │
│                                                                  │
│  ROUTING GUIDE                                                   │
│  ─────────────────────────────────────────────────────────────  │
│  → GLOBAL: Reusable patterns, tools, best practices             │
│  → PROJECT: This project's architecture, configs only           │
│                                                                  │
│  WORKFLOW                                                        │
│  ─────────────────────────────────────────────────────────────  │
│  1. /ctx-mode      → Set mode (full/local/global)               │
│  2. /ctx-status    → Check current state                        │
│  3. /ctx-search    → Find existing docs                         │
│  4. Work on task                                                 │
│  5. /ctx-doc       → Document findings                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

Full documentation: ~/.claude/CLAUDE.md
```
CMD_EOF
}

create_cmd_ctx_new() {
    cat << 'CMD_EOF'
# /ctx-new

Create a new ContextVault document with guided routing (global vs project).

## Usage

```
/ctx-new [topic]
```

## Arguments

- `topic` (optional): The topic name for the new document

## Instructions

When this command is invoked:

### Step 1: Read Both Indexes

1. Read `~/.claude/vault/index.md` (global)
2. Read `./.claude/vault/index.md` (project, if exists)

### Step 2: Check for Existing Topic

Search BOTH indexes for:
- Exact topic match
- Related terms
- Synonyms

If found, inform user:
"Topic already exists in [location]. Use UPDATE instead of creating new."
Show the existing document ID and offer to open it.

### Step 3: If Topic is New, Ask Routing Question

Ask the user:

```
┌─────────────────────────────────────────────────────────────┐
│              WHERE SHOULD THIS DOCUMENT GO?                  │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Is this knowledge reusable across multiple projects?        │
│                                                              │
│  [1] GLOBAL (G###) - ~/.claude/vault/                       │
│      → General patterns, best practices                      │
│      → Tool/technology knowledge                             │
│      → Reusable across projects                              │
│                                                              │
│  [2] PROJECT (P###) - ./.claude/vault/                      │
│      → This project's architecture                           │
│      → Project-specific configs                              │
│      → Only relevant here                                    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

Use AskUserQuestion tool to get user's choice.

### Step 4: Determine Next ID

Based on routing choice:
- If GLOBAL: Find highest G### number in global index, increment by 1
- If PROJECT: Find highest P### number in project index, increment by 1

### Step 5: Create Document

Create the document using the template:

**Location:**
- Global: `~/.claude/vault/G###_[topic_name].md`
- Project: `./.claude/vault/P###_[topic_name].md`

**Content:** Use standard template from `_template.md`

### Step 6: Update Index

Add entry to the appropriate index:
- Global: `~/.claude/vault/index.md`
- Project: `./.claude/vault/index.md`

### Step 7: Confirm

Tell user:
- Document created at [path]
- Added to [global/project] index
- Remind to fill in the content
CMD_EOF
}

create_cmd_ctx_doc() {
    cat << 'CMD_EOF'
# /ctx-doc

Quick command to document current findings after completing a task.

## Usage

```
/ctx-doc
```

## Instructions

When this command is invoked, guide the user through the documentation process:

### Step 1: Ask What Was Learned

Ask user:
"What did you learn or accomplish that should be documented?"

### Step 2: Read Both Indexes

1. Read `~/.claude/vault/index.md` (global)
2. Read `./.claude/vault/index.md` (project, if exists)

### Step 3: Check for Existing Documentation

Based on user's response, search both indexes for:
- Related existing topics
- Similar terms
- Parent topics

### Step 4: Determine Action

**If related topic exists:**
- Show the existing document
- Ask: "Should I UPDATE this existing document, or is this a NEW topic?"
- If UPDATE: Open the doc, help user add new information, update index summary
- If NEW: Proceed to step 5

**If no related topic:**
- Proceed to step 5

### Step 5: Route New Documentation

Ask routing question:

```
Is this knowledge:

[1] GLOBAL - Reusable in other projects?
    (patterns, best practices, tool knowledge)

[2] PROJECT - Specific to this project only?
    (architecture, configs, local decisions)
```

### Step 6: Create/Update Document

Based on choice:
- Create new document with proper ID (G### or P###)
- OR update existing document

### Step 7: Update Index

Ensure the appropriate index is updated with:
- New entry (if created)
- Updated summary (if modified)

### Step 8: Confirm

Show summary:
```
✓ Documentation complete
  - Location: [global/project]
  - Document: [ID]_[topic].md
  - Index: Updated
```
CMD_EOF
}

create_cmd_ctx_update() {
    cat << 'CMD_EOF'
# /ctx-update

Update an existing ContextVault document.

## Usage

```
/ctx-update [ID]
```

## Arguments

- `ID`: Document ID to update (e.g., G001, P003)

## Instructions

When this command is invoked:

### Step 1: Find and Read Document

1. Parse ID prefix (G### = global, P### = project)
2. Find document file
3. Read current contents

### Step 2: Show Current State

Display:
- Current "Current Understanding" section
- Last updated date
- Ask: "What needs to be updated?"

### Step 3: Get Update Information

Ask user what new information should be added or what should be changed.

### Step 4: Apply Updates

Following ContextVault rules:
- **REPLACE** outdated info in "Current Understanding" (don't append contradictions)
- **ADD** new details to "Key Details" section
- **MOVE** old info to "History" section with date
- **UPDATE** "Last updated" date to today

### Step 5: Update Index

After document is updated:
1. Read the appropriate index
2. Update the summary for this document ID (max 15 words)
3. Save index

### Step 6: Confirm

Show:
```
✓ Document updated: [ID]
✓ Index updated

Changes made:
- [summary of changes]

History entry added:
- [date]: [change description]
```
CMD_EOF
}

create_cmd_ctx_search() {
    cat << 'CMD_EOF'
# /ctx-search

Search both global and project ContextVault indexes for a topic.

## Usage

```
/ctx-search [query]
```

## Arguments

- `query`: Search term(s) to look for

## Instructions

When this command is invoked:

### Step 1: Read Both Indexes

1. Read `~/.claude/vault/index.md` (global)
2. Read `./.claude/vault/index.md` (project, if exists)

### Step 2: Search for Matches

Search in both indexes for:
- Exact matches in Topic column
- Partial matches in Topic column
- Matches in Summary column
- Matches in Related Terms Map

### Step 3: Display Results

Format output:

```
┌─────────────────────────────────────────────────────────────┐
│            CONTEXTVAULT SEARCH: "[query]"                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  GLOBAL MATCHES:                                             │
│  ├── G001: Topic Name - Summary here                        │
│  └── G003: Other Topic - Summary here                       │
│                                                              │
│  PROJECT MATCHES:                                            │
│  ├── P002: Project Topic - Summary here                     │
│  └── (none)                                                  │
│                                                              │
│  RELATED TERMS MATCHES:                                      │
│  └── "search term" → G001, P002                             │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Step 4: Offer Actions

If matches found:
- Offer to load a specific document
- "Would you like me to read [ID]?"

If no matches:
- "No existing documentation found for '[query]'"
- "Would you like to create a new document? Run /ctx-new [query]"
CMD_EOF
}

create_cmd_ctx_read() {
    cat << 'CMD_EOF'
# /ctx-read

Quick read a ContextVault document by ID.

## Usage

```
/ctx-read [ID]
```

## Arguments

- `ID`: Document ID (e.g., G001, P003)

## Instructions

When this command is invoked:

### Step 1: Parse ID

Determine location from prefix:
- `G###` → Global: `~/.claude/vault/`
- `P###` → Project: `./.claude/vault/`

### Step 2: Find Document

Search for file matching pattern `[ID]_*.md` in the appropriate location.

### Step 3: Read and Display

If found:
- Read the document
- Display contents to user

If not found:
- "Document [ID] not found"
- Suggest: "Run /ctx-search to find available documents"

### Example

```
/ctx-read G001
→ Reads ~/.claude/vault/G001_contextvault_system.md

/ctx-read P002
→ Reads ./.claude/vault/P002_database_schema.md
```
CMD_EOF
}

#===============================================================================
# INSTALLATION FUNCTIONS
#===============================================================================

backup_existing() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$HOME/.contextvault_backup_$timestamp"

    if [ -d "$CLAUDE_DIR" ]; then
        print_step "📦 Creating backup..."
        cp -r "$CLAUDE_DIR" "$backup_dir" 2>/dev/null || true
        print_success "Backup saved to $backup_dir"
    fi
}

install_contextvault() {
    print_header

    echo -e "${BOLD}🚀 Starting installation...${NC}"
    echo ""
    echo -e "${DIM}   Installing to: ~/.claude/${NC}"
    echo -e "${DIM}   Works from any directory!${NC}"
    echo ""

    # Check for existing installation
    if [ -f "$CLAUDE_MD" ] && [ -f "$VAULT_DIR/index.md" ]; then
        print_warning "ContextVault is already installed!"
        echo ""
        read -p "   🔄 Reinstall? (This will backup existing files) (y/N) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo ""
            echo -e "${GREEN}👍 Keeping existing installation. You're all set!${NC}"
            echo ""
            exit 0
        fi
        echo ""
        backup_existing
        echo ""
    fi

    # Fun animation
    rocket_launch

    # Create directories
    print_step "📁 Creating directories..."
    sleep 0.3 2>/dev/null || true
    mkdir -p "$CLAUDE_DIR"
    mkdir -p "$VAULT_DIR/archive"
    mkdir -p "$VAULT_DIR/_project_init_template"
    mkdir -p "$COMMANDS_DIR"
    print_success "Directories created"

    # Create CLAUDE.md with animation
    print_step "📜 Writing global instructions..."
    sleep 0.2 2>/dev/null || true
    create_claude_md | sed "s/\$(date +%Y-%m-%d)/$(date +%Y-%m-%d)/g" > "$CLAUDE_MD"
    print_success "CLAUDE.md created"

    # Create vault files
    print_step "🏰 Building your vault..."
    sleep 0.2 2>/dev/null || true
    create_global_index | sed "s/\$(date +%Y-%m-%d)/$(date +%Y-%m-%d)/g" > "$VAULT_DIR/index.md"
    create_settings_json | sed "s/\$(date +%Y-%m-%d)/$(date +%Y-%m-%d)/g" > "$VAULT_DIR/settings.json"
    create_template > "$VAULT_DIR/_template.md"
    create_g001_contextvault_system | sed "s/\$(date +%Y-%m-%d)/$(date +%Y-%m-%d)/g" > "$VAULT_DIR/G001_contextvault_system.md"
    create_project_index_template > "$VAULT_DIR/_project_init_template/index.md"
    print_success "Vault constructed"

    # Create commands with progress
    print_step "⚡ Installing slash commands..."
    echo ""

    local commands=(
        "ctx-init:🎬"
        "ctx-status:📊"
        "ctx-mode:🔄"
        "ctx-help:📖"
        "ctx-new:✨"
        "ctx-doc:📸"
        "ctx-update:🔧"
        "ctx-search:🔎"
        "ctx-read:📖"
    )

    for cmd_info in "${commands[@]}"; do
        IFS=':' read -r cmd emoji <<< "$cmd_info"
        printf "   ${DIM}%s${NC} /%s" "$emoji" "$cmd"

        case "$cmd" in
            ctx-init) create_cmd_ctx_init > "$COMMANDS_DIR/ctx-init.md" ;;
            ctx-status) create_cmd_ctx_status > "$COMMANDS_DIR/ctx-status.md" ;;
            ctx-mode) create_cmd_ctx_mode > "$COMMANDS_DIR/ctx-mode.md" ;;
            ctx-help) create_cmd_ctx_help > "$COMMANDS_DIR/ctx-help.md" ;;
            ctx-new) create_cmd_ctx_new > "$COMMANDS_DIR/ctx-new.md" ;;
            ctx-doc) create_cmd_ctx_doc > "$COMMANDS_DIR/ctx-doc.md" ;;
            ctx-update) create_cmd_ctx_update > "$COMMANDS_DIR/ctx-update.md" ;;
            ctx-search) create_cmd_ctx_search > "$COMMANDS_DIR/ctx-search.md" ;;
            ctx-read) create_cmd_ctx_read > "$COMMANDS_DIR/ctx-read.md" ;;
        esac

        printf " ${GREEN}✓${NC}\n"
        sleep 0.1 2>/dev/null || true
    done

    echo ""
    print_success "9 commands installed"

    # Celebration!
    echo ""
    sleep 0.3 2>/dev/null || true

    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}                                                                  ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}   ${BOLD}${WHITE}🎉 ContextVault Installation Complete! 🎉${NC}                     ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}                                                                  ${GREEN}║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BOLD}📦 What was installed:${NC}"
    echo -e "   ${CYAN}📄${NC} ~/.claude/CLAUDE.md          ${DIM}(Global brain)${NC}"
    echo -e "   ${CYAN}🏰${NC} ~/.claude/vault/             ${DIM}(Your knowledge vault)${NC}"
    echo -e "   ${CYAN}⚡${NC} ~/.claude/commands/          ${DIM}(9 slash commands)${NC}"
    echo ""
    echo -e "${BOLD}🎮 Your new commands:${NC}"
    echo -e "   ${YELLOW}/ctx-help${NC}     📖 See all commands"
    echo -e "   ${YELLOW}/ctx-status${NC}   📊 Check vault status"
    echo -e "   ${YELLOW}/ctx-init${NC}     🎬 Initialize in a project"
    echo -e "   ${YELLOW}/ctx-doc${NC}      📸 Quick document"
    echo -e "   ${YELLOW}/ctx-search${NC}   🔎 Search your knowledge"
    echo ""
    echo -e "${BOLD}🚀 Quick Start:${NC}"
    echo -e "   1. Start Claude Code: ${CYAN}claude${NC}"
    echo -e "   2. Check status:      ${YELLOW}/ctx-status${NC}"
    echo -e "   3. See all commands:  ${YELLOW}/ctx-help${NC}"
    echo ""
    echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${DIM}Documentation: ~/.claude/CLAUDE.md${NC}"
    echo -e "${DIM}GitHub: https://github.com/ahmadzein/ContextVault${NC}"
    echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${MAGENTA}✨ Your context will never be lost again! ✨${NC}"
    echo ""
}

uninstall_contextvault() {
    print_header
    echo -e "${BOLD}🗑️  Uninstalling ContextVault...${NC}"
    echo ""

    print_warning "This will remove:"
    echo "   • ~/.claude/CLAUDE.md"
    echo "   • ~/.claude/vault/ ${DIM}(your global docs!)${NC}"
    echo "   • ~/.claude/commands/ctx-*.md"
    echo ""

    read -p "   😢 Are you sure? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${GREEN}😅 Phew! Uninstall cancelled.${NC}"
        echo ""
        exit 0
    fi

    echo ""
    backup_existing
    echo ""

    print_step "🧹 Removing files..."

    if [ -f "$CLAUDE_MD" ]; then
        rm "$CLAUDE_MD"
        print_success "Removed CLAUDE.md"
    fi

    if [ -d "$VAULT_DIR" ]; then
        rm -rf "$VAULT_DIR"
        print_success "Removed vault directory"
    fi

    for cmd in ctx-init ctx-status ctx-mode ctx-help ctx-new ctx-doc ctx-update ctx-search ctx-read; do
        if [ -f "$COMMANDS_DIR/$cmd.md" ]; then
            rm "$COMMANDS_DIR/$cmd.md"
        fi
    done
    print_success "Removed commands"

    echo ""
    echo -e "${GREEN}✅ ContextVault has been uninstalled.${NC}"
    echo ""
    echo -e "${DIM}Your backup is at: ~/.contextvault_backup_*${NC}"
    echo -e "${DIM}We hope to see you again! 👋${NC}"
    echo ""
}

check_status() {
    print_header
    echo -e "${BOLD}📊 Installation Status${NC}"
    echo ""

    local installed=true

    if [ -f "$CLAUDE_MD" ]; then
        print_success "CLAUDE.md exists"
    else
        print_error "CLAUDE.md not found"
        installed=false
    fi

    if [ -d "$VAULT_DIR" ]; then
        print_success "Vault directory exists"

        [ -f "$VAULT_DIR/index.md" ] && print_success "  └── index.md ✓" || { print_error "  └── index.md ✗"; installed=false; }
        [ -f "$VAULT_DIR/settings.json" ] && print_success "  └── settings.json ✓" || { print_error "  └── settings.json ✗"; installed=false; }
        [ -f "$VAULT_DIR/_template.md" ] && print_success "  └── _template.md ✓" || { print_error "  └── _template.md ✗"; installed=false; }
    else
        print_error "Vault directory not found"
        installed=false
    fi

    if [ -d "$COMMANDS_DIR" ]; then
        print_success "Commands directory exists"
        local cmd_count=0
        for cmd in ctx-init ctx-status ctx-mode ctx-help ctx-new ctx-doc ctx-update ctx-search ctx-read; do
            [ -f "$COMMANDS_DIR/$cmd.md" ] && ((cmd_count++))
        done
        [ $cmd_count -eq 9 ] && print_success "  └── All 9 commands ✓" || print_warning "  └── $cmd_count/9 commands"
    else
        print_error "Commands directory not found"
        installed=false
    fi

    echo ""
    if [ "$installed" = true ]; then
        echo -e "${GREEN}${BOLD}🎉 ContextVault is fully installed and ready!${NC}"
    else
        echo -e "${YELLOW}${BOLD}⚠️  ContextVault needs to be installed/repaired.${NC}"
        echo -e "${DIM}   Run: ./install-contextvault.sh${NC}"
    fi
    echo ""
}

show_help() {
    print_header
    echo -e "${BOLD}📖 Usage:${NC}"
    echo "   ./install-contextvault.sh [command]"
    echo ""
    echo -e "${BOLD}🎮 Commands:${NC}"
    echo -e "   ${GREEN}install${NC}     🚀 Install ContextVault (default)"
    echo -e "   ${RED}uninstall${NC}   🗑️  Remove ContextVault"
    echo -e "   ${BLUE}update${NC}      🔄 Update to latest version"
    echo -e "   ${CYAN}status${NC}      📊 Check installation status"
    echo -e "   ${YELLOW}help${NC}        📖 Show this help"
    echo ""
    echo -e "${BOLD}📝 Examples:${NC}"
    echo "   ./install-contextvault.sh           # Install"
    echo "   ./install-contextvault.sh uninstall # Remove"
    echo "   ./install-contextvault.sh status    # Check"
    echo ""
    echo -e "${BOLD}🌐 One-liner install:${NC}"
    echo -e "   ${CYAN}curl -fsSL https://raw.githubusercontent.com/ahmadzein/ContextVault/main/install-contextvault.sh | bash${NC}"
    echo ""
    echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${DIM}🏰 ContextVault - Your knowledge, perfectly organized.${NC}"
    echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

#===============================================================================
# MAIN
#===============================================================================

main() {
    local command="${1:-install}"

    case "$command" in
        install)
            install_contextvault
            ;;
        uninstall|remove)
            uninstall_contextvault
            ;;
        update|upgrade)
            install_contextvault
            ;;
        status|check)
            check_status
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@"
