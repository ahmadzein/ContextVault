#!/bin/bash

#===============================================================================
#
#   ContextVault - External Context Management System for Claude Code
#
#   A two-tier documentation system for efficient context management
#   Inspired by concepts from arxiv:2512.24601
#
#   Usage:
#     ./install-contextvault.sh           # Install ContextVault
#     ./install-contextvault.sh install   # Install ContextVault
#     ./install-contextvault.sh uninstall # Remove ContextVault
#     ./install-contextvault.sh update    # Update to latest version
#     ./install-contextvault.sh status    # Check installation status
#
#   Or via curl:
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

# Paths
CLAUDE_DIR="$HOME/.claude"
VAULT_DIR="$CLAUDE_DIR/vault"
COMMANDS_DIR="$CLAUDE_DIR/commands"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"

# Print functions
print_header() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                                                                  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${BOLD}${WHITE}ContextVault - External Context Management System${NC}            ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${DIM}Version ${VERSION}${NC}                                               ${CYAN}║${NC}"
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

#===============================================================================
# FILE CONTENT FUNCTIONS
#===============================================================================

create_claude_md() {
    cat << 'CLAUDE_MD_EOF'
# Global Claude Instructions

**Version:** 1.0.0
**Last Updated:** $(date +%Y-%m-%d)
**System:** ContextVault - External Context Management

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
  "mode": "full",
  "updated": "$(date +%Y-%m-%d)",
  "modes": {
    "full": "Use both global and project documentation",
    "local": "Project-only, global disabled",
    "global": "Global-only, project disabled"
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

Toggle ContextVault mode between Global+Project, Project-only, or Global-only.

## Usage

```
/ctx-mode [mode]
```

## Arguments

- `mode` (optional): `full`, `local`, `global`, or no argument to show current mode

## Modes

| Mode | Description | What to Read |
|------|-------------|--------------|
| `full` | Use both global and project docs (DEFAULT) | Both indexes |
| `local` | Project-only, ignore global | Only `./.claude/vault/index.md` |
| `global` | Global-only, ignore project | Only `~/.claude/vault/index.md` |

## Instructions

When this command is invoked:

### If No Argument: Show Current Mode

Read `~/.claude/vault/settings.json` and display:

```
┌─────────────────────────────────────────────────────────────┐
│                   CONTEXTVAULT MODE                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Current Mode: [FULL / LOCAL / GLOBAL]                      │
│                                                              │
│  Available modes:                                            │
│  • /ctx-mode full   → Use global + project (default)        │
│  • /ctx-mode local  → Project only, ignore global           │
│  • /ctx-mode global → Global only, ignore project           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### If Argument Provided: Set Mode

1. Validate mode is one of: `full`, `local`, `global`

2. Update `~/.claude/vault/settings.json`:
```json
{
  "mode": "full|local|global",
  "updated": "YYYY-MM-DD"
}
```

3. Confirm change:
```
✓ ContextVault mode changed to [MODE]

What this means:
- full:   Read global + project indexes
- local:  Read only project index, global disabled
- global: Read only global index, project disabled
```

### Behavior Based on Mode

**When mode is `full` (default):**
- Read `~/.claude/vault/index.md` first
- Then read `./.claude/vault/index.md`
- New docs can go to either location

**When mode is `local`:**
- Skip global index entirely
- Only read `./.claude/vault/index.md`
- New docs only go to project
- Useful for: isolated projects, offline work, focused sessions

**When mode is `global`:**
- Only read `~/.claude/vault/index.md`
- Skip project index
- New docs only go to global
- Useful for: building up global knowledge base

## Settings File Location

`~/.claude/vault/settings.json`

## Examples

```
/ctx-mode           → Show current mode
/ctx-mode local     → Switch to project-only
/ctx-mode global    → Switch to global-only
/ctx-mode full      → Switch back to both (default)
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
│                      CONTEXTVAULT                                │
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
│  full     Use global + project docs (default)                   │
│  local    Project-only, global OFF                              │
│  global   Global-only, project OFF                              │
│                                                                  │
│  QUICK REFERENCE                                                 │
│  ─────────────────────────────────────────────────────────────  │
│  • Global docs:  ~/.claude/vault/    (G### prefix)              │
│  • Project docs: ./.claude/vault/    (P### prefix)              │
│  • Max load: 2 indexes + 1 doc                                  │
│  • Limits: 50 entries/index, 100 lines/doc, 15 words/summary    │
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
    local backup_dir="$HOME/.claude_backup_$timestamp"

    if [ -d "$CLAUDE_DIR" ]; then
        print_step "Backing up existing ~/.claude to $backup_dir"
        cp -r "$CLAUDE_DIR" "$backup_dir"
        print_success "Backup created"
    fi
}

install_contextvault() {
    print_header
    echo -e "${BOLD}Installing ContextVault...${NC}"
    echo ""

    # Check for existing installation
    if [ -f "$CLAUDE_MD" ] && [ -f "$VAULT_DIR/index.md" ]; then
        print_warning "ContextVault appears to be already installed."
        echo ""
        read -p "Do you want to reinstall? This will backup and overwrite existing files. (y/N) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Installation cancelled."
            exit 0
        fi
        backup_existing
    fi

    # Create directories
    print_step "Creating directories..."
    mkdir -p "$CLAUDE_DIR"
    mkdir -p "$VAULT_DIR/archive"
    mkdir -p "$VAULT_DIR/_project_init_template"
    mkdir -p "$COMMANDS_DIR"
    print_success "Directories created"

    # Create CLAUDE.md
    print_step "Creating global CLAUDE.md..."
    create_claude_md | sed "s/\$(date +%Y-%m-%d)/$(date +%Y-%m-%d)/g" > "$CLAUDE_MD"
    print_success "Created $CLAUDE_MD"

    # Create vault files
    print_step "Creating ContextVault index and documents..."
    create_global_index | sed "s/\$(date +%Y-%m-%d)/$(date +%Y-%m-%d)/g" > "$VAULT_DIR/index.md"
    create_settings_json | sed "s/\$(date +%Y-%m-%d)/$(date +%Y-%m-%d)/g" > "$VAULT_DIR/settings.json"
    create_template > "$VAULT_DIR/_template.md"
    create_g001_contextvault_system | sed "s/\$(date +%Y-%m-%d)/$(date +%Y-%m-%d)/g" > "$VAULT_DIR/G001_contextvault_system.md"
    create_project_index_template > "$VAULT_DIR/_project_init_template/index.md"
    print_success "ContextVault files created"

    # Create commands
    print_step "Creating custom commands..."
    create_cmd_ctx_init > "$COMMANDS_DIR/ctx-init.md"
    create_cmd_ctx_status > "$COMMANDS_DIR/ctx-status.md"
    create_cmd_ctx_mode > "$COMMANDS_DIR/ctx-mode.md"
    create_cmd_ctx_help > "$COMMANDS_DIR/ctx-help.md"
    create_cmd_ctx_new > "$COMMANDS_DIR/ctx-new.md"
    create_cmd_ctx_doc > "$COMMANDS_DIR/ctx-doc.md"
    create_cmd_ctx_update > "$COMMANDS_DIR/ctx-update.md"
    create_cmd_ctx_search > "$COMMANDS_DIR/ctx-search.md"
    create_cmd_ctx_read > "$COMMANDS_DIR/ctx-read.md"
    print_success "9 custom commands created"

    # Done
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}                                                                  ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}   ${BOLD}${WHITE}ContextVault Installation Complete!${NC}                          ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}                                                                  ${GREEN}║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BOLD}What was installed:${NC}"
    echo -e "  ${CYAN}•${NC} ~/.claude/CLAUDE.md          ${DIM}(Global instructions)${NC}"
    echo -e "  ${CYAN}•${NC} ~/.claude/vault/             ${DIM}(Global documentation)${NC}"
    echo -e "  ${CYAN}•${NC} ~/.claude/commands/          ${DIM}(9 slash commands)${NC}"
    echo ""
    echo -e "${BOLD}Available Commands:${NC}"
    echo -e "  ${YELLOW}/ctx-help${NC}     Show all commands"
    echo -e "  ${YELLOW}/ctx-status${NC}   Check system status"
    echo -e "  ${YELLOW}/ctx-init${NC}     Initialize ContextVault in a project"
    echo -e "  ${YELLOW}/ctx-mode${NC}     Toggle global/local/full mode"
    echo -e "  ${YELLOW}/ctx-new${NC}      Create new document"
    echo -e "  ${YELLOW}/ctx-doc${NC}      Quick document after task"
    echo -e "  ${YELLOW}/ctx-search${NC}   Search all indexes"
    echo -e "  ${YELLOW}/ctx-read${NC}     Read document by ID"
    echo -e "  ${YELLOW}/ctx-update${NC}   Update existing document"
    echo ""
    echo -e "${BOLD}Quick Start:${NC}"
    echo -e "  1. Open any project in Claude Code"
    echo -e "  2. Run ${YELLOW}/ctx-init${NC} to initialize project vault"
    echo -e "  3. Run ${YELLOW}/ctx-help${NC} to see all commands"
    echo ""
    echo -e "${DIM}Documentation: ~/.claude/CLAUDE.md${NC}"
    echo ""
}

uninstall_contextvault() {
    print_header
    echo -e "${BOLD}Uninstalling ContextVault...${NC}"
    echo ""

    print_warning "This will remove:"
    echo "  • ~/.claude/CLAUDE.md"
    echo "  • ~/.claude/vault/ (entire directory)"
    echo "  • ~/.claude/commands/ctx-*.md (all ContextVault commands)"
    echo ""

    read -p "Are you sure you want to uninstall ContextVault? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Uninstall cancelled."
        exit 0
    fi

    # Backup first
    backup_existing

    # Remove files
    print_step "Removing ContextVault files..."

    if [ -f "$CLAUDE_MD" ]; then
        rm "$CLAUDE_MD"
        print_success "Removed CLAUDE.md"
    fi

    if [ -d "$VAULT_DIR" ]; then
        rm -rf "$VAULT_DIR"
        print_success "Removed vault directory"
    fi

    # Remove commands
    for cmd in ctx-init ctx-status ctx-mode ctx-help ctx-new ctx-doc ctx-update ctx-search ctx-read; do
        if [ -f "$COMMANDS_DIR/$cmd.md" ]; then
            rm "$COMMANDS_DIR/$cmd.md"
        fi
    done
    print_success "Removed ContextVault commands"

    echo ""
    print_success "ContextVault has been uninstalled."
    print_info "A backup was created before uninstall."
    echo ""
}

check_status() {
    print_header
    echo -e "${BOLD}ContextVault Installation Status${NC}"
    echo ""

    local installed=true

    # Check CLAUDE.md
    if [ -f "$CLAUDE_MD" ]; then
        print_success "CLAUDE.md exists"
    else
        print_error "CLAUDE.md not found"
        installed=false
    fi

    # Check vault directory
    if [ -d "$VAULT_DIR" ]; then
        print_success "Vault directory exists"

        # Check index
        if [ -f "$VAULT_DIR/index.md" ]; then
            print_success "  └── index.md exists"
        else
            print_error "  └── index.md not found"
            installed=false
        fi

        # Check settings
        if [ -f "$VAULT_DIR/settings.json" ]; then
            print_success "  └── settings.json exists"
        else
            print_error "  └── settings.json not found"
            installed=false
        fi

        # Check template
        if [ -f "$VAULT_DIR/_template.md" ]; then
            print_success "  └── _template.md exists"
        else
            print_error "  └── _template.md not found"
            installed=false
        fi
    else
        print_error "Vault directory not found"
        installed=false
    fi

    # Check commands
    if [ -d "$COMMANDS_DIR" ]; then
        print_success "Commands directory exists"
        local cmd_count=0
        for cmd in ctx-init ctx-status ctx-mode ctx-help ctx-new ctx-doc ctx-update ctx-search ctx-read; do
            if [ -f "$COMMANDS_DIR/$cmd.md" ]; then
                ((cmd_count++))
            fi
        done
        if [ $cmd_count -eq 9 ]; then
            print_success "  └── All 9 commands installed"
        else
            print_warning "  └── $cmd_count/9 commands installed"
        fi
    else
        print_error "Commands directory not found"
        installed=false
    fi

    echo ""
    if [ "$installed" = true ]; then
        echo -e "${GREEN}${BOLD}ContextVault is fully installed and ready to use.${NC}"
    else
        echo -e "${YELLOW}${BOLD}ContextVault is not fully installed. Run: ./install-contextvault.sh install${NC}"
    fi
    echo ""
}

show_help() {
    print_header
    echo -e "${BOLD}Usage:${NC}"
    echo "  ./install-contextvault.sh [command]"
    echo ""
    echo -e "${BOLD}Commands:${NC}"
    echo "  install     Install ContextVault (default)"
    echo "  uninstall   Remove ContextVault from your system"
    echo "  update      Update to latest version (reinstall)"
    echo "  status      Check installation status"
    echo "  help        Show this help message"
    echo ""
    echo -e "${BOLD}Examples:${NC}"
    echo "  ./install-contextvault.sh           # Install"
    echo "  ./install-contextvault.sh install   # Install"
    echo "  ./install-contextvault.sh uninstall # Remove"
    echo "  ./install-contextvault.sh status    # Check status"
    echo ""
    echo -e "${BOLD}One-liner install:${NC}"
    echo "  curl -fsSL https://raw.githubusercontent.com/ahmadzein/ContextVault/main/install-contextvault.sh | bash"
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
            show_help
            exit 1
            ;;
    esac
}

main "$@"
