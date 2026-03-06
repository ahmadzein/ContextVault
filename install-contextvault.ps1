#Requires -Version 5.1
<#
.SYNOPSIS
    ContextVault Installer for Windows
.DESCRIPTION
    Installs ContextVault - External Context Management for Claude Code
    Works on Windows (PowerShell), with hooks requiring Git Bash or WSL
.LINK
    https://ctx-vault.com
    https://github.com/ahmadzein/ContextVault
#>

$ErrorActionPreference = "Stop"
$VERSION = "1.9.0"

# Colors
function Write-Color {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Write-Step {
    param([string]$Text)
    Write-Host "  → " -ForegroundColor DarkGray -NoNewline
    Write-Host $Text -ForegroundColor White
}

function Write-Success {
    param([string]$Text)
    Write-Host "  ✓ " -ForegroundColor Green -NoNewline
    Write-Host $Text -ForegroundColor Gray
}

function Write-Warning {
    param([string]$Text)
    Write-Host "  ⚠ " -ForegroundColor Yellow -NoNewline
    Write-Host $Text -ForegroundColor Gray
}

# Banner
Clear-Host
Write-Host ""
Write-Color "  ╔══════════════════════════════════════════════════════════════╗" Cyan
Write-Color "  ║                                                              ║" Cyan
Write-Color "  ║   🏰 ContextVault                                            ║" Cyan
Write-Color "  ║   External Context Management System                         ║" Cyan
Write-Color "  ║   Version $VERSION (Windows)                                    ║" Cyan
Write-Color "  ║                                                              ║" Cyan
Write-Color "  ╚══════════════════════════════════════════════════════════════╝" Cyan
Write-Host ""

# Paths
$CLAUDE_DIR = Join-Path $env:USERPROFILE ".claude"
$VAULT_DIR = Join-Path $CLAUDE_DIR "vault"
$COMMANDS_DIR = Join-Path $CLAUDE_DIR "commands"
$HOOKS_DIR = Join-Path $CLAUDE_DIR "hooks"
$CLAUDE_MD = Join-Path $CLAUDE_DIR "CLAUDE.md"
$SETTINGS_FILE = Join-Path $CLAUDE_DIR "settings.json"
$TODAY = Get-Date -Format "yyyy-MM-dd"

# Check for Git Bash (needed for hooks)
$GIT_BASH = $null
$gitPaths = @(
    "C:\Program Files\Git\bin\bash.exe",
    "C:\Program Files (x86)\Git\bin\bash.exe",
    (Join-Path $env:LOCALAPPDATA "Programs\Git\bin\bash.exe")
)
foreach ($path in $gitPaths) {
    if (Test-Path $path) {
        $GIT_BASH = $path
        break
    }
}

Write-Color "🚀 Starting installation..." White
Write-Host ""
Write-Host "   Installing to: $CLAUDE_DIR" -ForegroundColor DarkGray
Write-Host ""

# Check existing installation
if (Test-Path $VAULT_DIR) {
    Write-Warning "Existing installation detected"
    $response = Read-Host "   Upgrade to v$VERSION? (y/N)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-Host "   Installation cancelled." -ForegroundColor Gray
        exit 0
    }
}

# Create directories
Write-Step "Creating directories..."
$dirs = @($CLAUDE_DIR, $VAULT_DIR, $COMMANDS_DIR, $HOOKS_DIR,
          (Join-Path $VAULT_DIR "archive"),
          (Join-Path $VAULT_DIR "_project_init_template"))
foreach ($dir in $dirs) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}
Write-Success "Directories created"

# Create CLAUDE.md
Write-Step "Writing global instructions..."
$CLAUDE_MD_CONTENT = @"
# Global Claude Instructions

**Version:** $VERSION | **System:** ContextVault | **Updated:** $TODAY

---

## Session Start (Automatic, Silent)

1. Read ``~/.claude/vault/settings.json`` → note mode
2. Read indexes based on mode:
   - ``local`` (default): ``./.claude/vault/index.md`` only
   - ``full``: both global + project indexes
   - ``global``: ``~/.claude/vault/index.md`` only
3. Note what docs exist — use throughout session
4. If ``./.claude/vault/index.md`` missing → suggest ``/ctx-init`` once, then continue

Do not announce these steps.

---

## After Completing Work — Document at Milestones

At natural stopping points (feature complete, bug fixed, decision made, session ending):

**Step 1 — Assess.** Did you:
- Understand how something works?
- Find and fix a bug?
- Make a decision with reasoning?
- Discover a pattern or best practice?
- Configure or set up something?
- Find a gotcha, edge case, or quirk?
- Explore code and learn architecture?

If ALL = NO → skip documentation. If ANY = YES → continue:

**Step 2 — Search.** Check index for existing doc on this topic.
Search exact terms + synonyms (auth/login/signin = same topic, docker/container/image = same).

**Step 3 — Update or Create.** Related doc exists → UPDATE it. No match → CREATE new.

**Step 4 — Route** (new docs only).
- Reusable across projects → Global ``G###`` in ``~/.claude/vault/`` (patterns, best practices, tool configs)
- Project-specific → Project ``P###`` in ``./.claude/vault/`` (architecture, configs, local decisions)

**Step 5 — Write.** Follow ``_template.md`` structure. Max 100 lines. Concise, factual, actionable.

**Step 6 — Index.** Update the correct index IMMEDIATELY. Summary: max 15 words.

**Step 7 — Confirm.** Tell user: "Documented to [ID]_topic.md" — don't ask permission, just inform.

**Skip documentation for:** trivial edits, version bumps, typos, mid-refactor, nothing learned.

---

## Core Rules

1. **Read indexes first** — Always at session start. Search BOTH before creating any doc.
2. **No duplicates** — Check both indexes for exact topic + related terms + synonyms. Exists anywhere → UPDATE.
3. **No redundancy** — One topic = one document. Merge related info. If unsure → UPDATE existing.
4. **No conflicts** — Replace outdated info, don't append contradictions. "Current Understanding" = current truth only.
5. **Correct routing** — Reusable knowledge → Global ``G###``. Project-specific → Project ``P###``.
6. **Minimal context** — Load: indexes + ONE doc max. Never load multiple docs "just in case."
7. **Size limits** — Index: 50 entries. Doc: 100 lines. Summary: 15 words.
8. **Always update index** — After ANY doc change, immediately.

---

## Commands

| Command | When to use |
|---------|-------------|
| ``/ctx-doc`` | Built a feature, learned something (type=intel for exploration, type=snippet for code) |
| ``/ctx-error`` | Fixed a bug (error, root cause, solution) |
| ``/ctx-decision`` | Made architecture/design choice |
| ``/ctx-plan`` | Working on multi-step task |
| ``/ctx-bootstrap`` | New project — auto-generate all docs |
| ``/ctx-handoff`` | Ending session (summary for next time) |
| ``/ctx-search`` | Find existing docs |
| ``/ctx-read`` | Read doc by ID |
| ``/ctx-mode`` | Change mode or enforcement level |
| ``/ctx-init`` | Initialize vault in project |
| ``/ctx-status`` | Show vault status |
| ``/ctx-help`` | Show all commands |

---

## Never

- Ask "Should I document this?" — just do it
- Create a doc without checking if one exists first
- Forget to update the index after changes
- Create duplicates (same topic, different doc)
- Load multiple docs "just in case"

---

*ContextVault v$VERSION — https://ctx-vault.com*
"@
Set-Content -Path $CLAUDE_MD -Value $CLAUDE_MD_CONTENT -Encoding UTF8
Write-Success "CLAUDE.md created"

# Create vault index
Write-Step "Building your vault..."
$INDEX_CONTENT = @"
# ContextVault Index — Global

> **Last Updated:** $TODAY
> **Mode:** local
> **Docs:** 1

---

## Active Documents

| ID | File | Summary | Updated |
|----|------|---------|---------|
| G001 | G001_contextvault_system.md | ContextVault system overview and core concepts | $TODAY |

---

## Related Terms Map

| Term | Related | See Doc |
|------|---------|---------|
| contextvault, context, documentation, vault | system overview | G001 |

---

## Quick Stats

- Total docs: 1
- Last activity: $TODAY
"@
Set-Content -Path (Join-Path $VAULT_DIR "index.md") -Value $INDEX_CONTENT -Encoding UTF8

# Create settings.json
$SETTINGS_CONTENT = @"
{
  "mode": "local",
  "enforcement": "balanced",
  "updated": "$TODAY",
  "limits": {
    "max_global_docs": 50,
    "max_project_docs": 50,
    "max_doc_lines": 100,
    "max_summary_words": 15
  },
  "enforcement_levels": {
    "light": "No mid-work blocking, only Stop hook at session end",
    "balanced": "Block after 8 edits across 2+ files if undocumented (default)",
    "strict": "Block after 4 edits across 2+ files if undocumented"
  }
}
"@
Set-Content -Path (Join-Path $VAULT_DIR "settings.json") -Value $SETTINGS_CONTENT -Encoding UTF8

# Create template
$TEMPLATE_CONTENT = @"
# [ID] - [Topic Title]

> **Status:** Active
> **Created:** YYYY-MM-DD
> **Last Updated:** YYYY-MM-DD

---

## Summary

[One paragraph: What is this about? Why does it matter?]

---

## Current Understanding

[The current, accurate facts.]

### Key Points
- Point 1
- Point 2
- Point 3

---

## Gotchas & Edge Cases

- Gotcha 1: explanation
- Edge case: how to handle

---

## History

| Date | Change |
|------|--------|
| YYYY-MM-DD | Initial creation |

---
"@
Set-Content -Path (Join-Path $VAULT_DIR "_template.md") -Value $TEMPLATE_CONTENT -Encoding UTF8

# Create G001
$G001_CONTENT = @"
# G001 - ContextVault System

> **Status:** Active
> **Created:** $TODAY
> **Last Updated:** $TODAY

---

## Summary

ContextVault is a two-tier external context management system for Claude Code. It maintains knowledge across sessions through global (cross-project) and project-specific documentation.

---

## Current Understanding

### Two-Tier System
- **Global vault** (``~/.claude/vault/``): Cross-project knowledge, patterns, best practices
- **Project vault** (``./.claude/vault/``): Project-specific architecture, decisions, configs

### Core Workflow
1. Session start: Read indexes automatically
2. During work: Document at natural milestones
3. Session end: Run ``/ctx-handoff`` for continuity

### Key Commands
- ``/ctx-doc`` — Quick document
- ``/ctx-error`` — Bug fixes
- ``/ctx-decision`` — Architecture decisions
- ``/ctx-handoff`` — Session summary
- ``/ctx-bootstrap`` — Auto-generate docs for new projects

---

## History

| Date | Change |
|------|--------|
| $TODAY | Initial installation |

---
"@
Set-Content -Path (Join-Path $VAULT_DIR "G001_contextvault_system.md") -Value $G001_CONTENT -Encoding UTF8

# Create project init template
$PROJECT_INDEX_TEMPLATE = @"
# ContextVault Index - Project

> **Project-specific knowledge. Only relevant to THIS project.**

---

## Active Documents

| ID | File | Summary | Updated |
|----|------|---------|---------|
| - | - | - | - |

---

## Related Terms Map

| Term | Related | See Doc |
|------|---------|---------|
| - | - | - |

---

## Quick Stats

- Total docs: 0
- Last activity: -
"@
Set-Content -Path (Join-Path $VAULT_DIR "_project_init_template" "index.md") -Value $PROJECT_INDEX_TEMPLATE -Encoding UTF8
Write-Success "Vault constructed"

# Create commands
Write-Step "Installing slash commands..."
Write-Host ""

# Helper function for creating command files
function Create-Command {
    param(
        [string]$Name,
        [string]$Icon,
        [string]$Content
    )
    $path = Join-Path $COMMANDS_DIR "$Name.md"
    Set-Content -Path $path -Value $Content -Encoding UTF8
    Write-Host "     $Icon $Name" -ForegroundColor DarkGray
}

# ctx-init
Create-Command "ctx-init" "🎬" @"
---
description: Initialize ContextVault in current project
---

# /ctx-init — Initialize Project Vault

## Steps

1. Check if ``./.claude/vault/`` exists
2. If exists: inform user, offer to show status
3. If not: create the structure:

``````
./.claude/vault/
├── index.md
└── archive/
``````

4. Create ``./CLAUDE.md`` with ContextVault instructions
5. Confirm: "ContextVault initialized for this project"

## Project CLAUDE.md Content

``````markdown
# ContextVault Project Instructions

## Document at Meaningful Milestones

- Fixed a bug? → /ctx-error
- Made a decision? → /ctx-decision
- Learned something? → /ctx-doc
- Ending session? → /ctx-handoff

### Session Start
Read ``./.claude/vault/index.md`` immediately

### Project Docs
- Location: ``./.claude/vault/``
- Prefix: P### (P001, P002, etc.)
``````
"@

# ctx-doc
Create-Command "ctx-doc" "📝" @"
---
description: Quick document a learning, feature, or finding
---

# /ctx-doc — Quick Document

## Steps

1. Ask: "What did you learn or build?"
2. Search index for existing related doc
3. If exists: UPDATE that doc
4. If not: CREATE new with next P### ID
5. Update index immediately
6. Confirm: "Documented to [ID]_topic.md"
"@

# ctx-error
Create-Command "ctx-error" "🐛" @"
---
description: Document a bug fix or error resolution
---

# /ctx-error — Document Bug Fix

## Steps

1. Ask for: error message, root cause, solution
2. Search index for existing error docs
3. Create P###_error_[description].md with:
   - Error message
   - Root cause
   - Solution
   - Prevention tips
4. Update index
5. Confirm: "Bug fix documented"
"@

# ctx-decision
Create-Command "ctx-decision" "🤔" @"
---
description: Document an architectural or technical decision
---

# /ctx-decision — Document Decision

## Steps

1. Ask for: what was decided, options considered, why this choice
2. Create P###_decision_[topic].md with:
   - Decision made
   - Options considered
   - Reasoning
   - Trade-offs
4. Update index
5. Confirm: "Decision documented"
"@

# ctx-plan
Create-Command "ctx-plan" "📋" @"
---
description: Document implementation plan for multi-step tasks
---

# /ctx-plan — Document Plan

## Steps

1. Ask for: goal, tasks, current progress
2. Create P###_plan_[task].md with:
   - Goal
   - Tasks (checkbox style)
   - Progress notes
   - Blockers
3. Update index
4. Confirm: "Plan documented"
"@

# ctx-snippet and ctx-intel removed - use ctx-doc with type=snippet or type=intel

# ctx-bootstrap
Create-Command "ctx-bootstrap" "🚀" @"
---
description: Auto-scan codebase and generate comprehensive documentation
---

# /ctx-bootstrap — Auto-Generate Docs

## Steps

1. Verify vault exists (suggest /ctx-init if not)
2. Scan project for:
   - package.json, requirements.txt, go.mod, etc. (tech stack)
   - src/*, lib/*, components/* (features)
   - Entry points (main.*, index.*, app.*)
3. Create P001_architecture.md with tech stack overview
4. Create P00X_feature_*.md for each major module found
5. Update index with all new entries
6. Confirm: "Bootstrap complete - X docs created"
"@

# ctx-handoff
Create-Command "ctx-handoff" "👋" @"
---
description: Create session handoff summary for continuity
---

# /ctx-handoff — Session Handoff

## Steps

1. Summarize what was accomplished this session
2. Note any pending tasks or blockers
3. Create/update P###_handoff.md with:
   - Date
   - What was done
   - What's next
   - Context for next session
4. Confirm: "Handoff ready for next session"
"@

# ctx-search
Create-Command "ctx-search" "🔎" @"
---
description: Search across vault documents
---

# /ctx-search — Search Vault

## Steps

1. Ask for search term
2. Search both global and project indexes
3. Search Related Terms Map for synonyms
4. Return matching docs with summaries
5. Offer to read specific doc
"@

# ctx-read
Create-Command "ctx-read" "📖" @"
---
description: Read a document by ID
---

# /ctx-read — Read Document

## Steps

1. Ask for doc ID (G### or P###)
2. Determine vault (global or project)
3. Read and display the document
4. Offer to update if needed
"@

# ctx-status
Create-Command "ctx-status" "📊" @"
---
description: Show vault status and statistics
---

# /ctx-status — Vault Status

## Steps

1. Read global vault index
2. Read project vault index (if exists)
3. Display:
   - Global docs count
   - Project docs count
   - Recent activity
   - Current mode and enforcement level
"@

# ctx-mode
Create-Command "ctx-mode" "🔄" @"
---
description: Switch between local, global, or full mode
---

# /ctx-mode — Change Mode

## Usage

- ``/ctx-mode local`` — Project vault only (default)
- ``/ctx-mode full`` — Both global and project
- ``/ctx-mode global`` — Global vault only
- ``/ctx-mode enforcement light`` — No mid-work blocking
- ``/ctx-mode enforcement balanced`` — Default blocking
- ``/ctx-mode enforcement strict`` — Aggressive blocking

## Steps

1. Parse the mode argument
2. Update ~/.claude/vault/settings.json
3. Confirm: "Mode changed to [mode]"
"@

# ctx-help
Create-Command "ctx-help" "📖" @"
---
description: Show all ContextVault commands and usage
---

# /ctx-help — ContextVault Help

Display this command reference:

| Command | Description |
|---------|-------------|
| /ctx-init | Initialize vault in project |
| /ctx-doc | Quick document learning/feature |
| /ctx-error | Document bug fix |
| /ctx-decision | Document architecture decision |
| /ctx-plan | Document multi-step plan |
| /ctx-bootstrap | Auto-generate docs for codebase |
| /ctx-handoff | Session summary for continuity |
| /ctx-search | Search vault documents |
| /ctx-read | Read document by ID |
| /ctx-status | Show vault statistics |
| /ctx-mode | Change mode or enforcement |
| /ctx-help | Show this help |

**Quick Start:**
1. Run ``/ctx-init`` in your project
2. Work normally
3. Document at milestones with ``/ctx-doc``, ``/ctx-error``, etc.
4. End sessions with ``/ctx-handoff``
"@

# ctx-update
Create-Command "ctx-update" "✏️" @"
---
description: Update an existing document by ID
---

# /ctx-update — Update Document

## Steps

1. Ask for doc ID (G### or P###)
2. Read the existing document
3. Ask what needs updating
4. Make the changes
5. Update the index summary if meaning changed
6. Confirm: "Updated [ID]"
"@

# ctx-new
Create-Command "ctx-new" "✨" @"
---
description: Create a new document with guided routing
---

# /ctx-new — Create New Document

## Steps

1. Ask: "What do you want to document?"
2. Help determine routing:
   - Reusable across projects? → Global (G###)
   - Project-specific? → Project (P###)
3. Get next available ID
4. Create document with template
5. Update index
6. Confirm: "Created [ID]_topic.md"
"@

Write-Host ""
Write-Success "16 commands installed"

# Create hooks (if Git Bash available)
Write-Step "Setting up hooks..."

if ($GIT_BASH) {
    # Create session start hook
    $SESSION_HOOK = @"
#!/bin/bash
# ContextVault Session Start Hook

VAULT_DIR="`$HOME/.claude/vault"
PROJECT_VAULT="./.claude/vault"

global_count=0
project_count=0

if [ -f "`$VAULT_DIR/index.md" ]; then
    global_count=`$(grep -c "^| [GP][0-9]" "`$VAULT_DIR/index.md" 2>/dev/null || echo 0)
fi

if [ -f "`$PROJECT_VAULT/index.md" ]; then
    project_count=`$(grep -c "^| P[0-9]" "`$PROJECT_VAULT/index.md" 2>/dev/null || echo 0)
fi

echo "🏰 ContextVault v$VERSION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   📚 Global:  `$global_count docs"
echo "   📂 Project: `$project_count docs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
"@
    Set-Content -Path (Join-Path $HOOKS_DIR "ctx-session-start.sh") -Value $SESSION_HOOK -Encoding UTF8 -NoNewline

    # Create stop hook
    $STOP_HOOK = @"
#!/bin/bash
# ContextVault Stop Hook - Reminds to document

FILES_CHANGED="/tmp/ctx-files-changed"
STOP_REMINDED="/tmp/ctx-stop-reminded"

if [ -f "`$STOP_REMINDED" ]; then
    rm -f "`$STOP_REMINDED" 2>/dev/null
    exit 0
fi

edit_count=0
file_count=0

if [ -f "`$FILES_CHANGED" ]; then
    edit_count=`$(wc -l < "`$FILES_CHANGED" 2>/dev/null || echo 0)
    file_count=`$(sort -u "`$FILES_CHANGED" 2>/dev/null | wc -l || echo 0)
fi

if [ "`$edit_count" -ge 5 ] && [ "`$file_count" -ge 2 ]; then
    touch "`$STOP_REMINDED"
    echo '{"decision": "block", "reason": "📋 Significant work this session. Document with /ctx-doc or /ctx-handoff, or stop again to exit."}'
    exit 0
fi

rm -f "`$FILES_CHANGED" "`$STOP_REMINDED" /tmp/ctx-research-count /tmp/ctx-research-areas 2>/dev/null
exit 0
"@
    Set-Content -Path (Join-Path $HOOKS_DIR "ctx-stop-enforcer.sh") -Value $STOP_HOOK -Encoding UTF8 -NoNewline

    # Create post-tool hook (v1.8.4 - edit + research tracking)
    $POST_HOOK = @"
#!/bin/bash
# ContextVault PostToolUse Hook v1.8.4

FILES_CHANGED="/tmp/ctx-files-changed"
RESEARCH_COUNT="/tmp/ctx-research-count"
RESEARCH_AREAS="/tmp/ctx-research-areas"

INPUT=`$(cat)
TOOL_NAME=`$(echo "`$INPUT" | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:.*"\([^"]*\)".*/\1/')
FILE_PATH=`$(echo "`$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:.*"\([^"]*\)".*/\1/')
PATTERN=`$(echo "`$INPUT" | grep -o '"pattern"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:.*"\([^"]*\)".*/\1/')
QUERY=`$(echo "`$INPUT" | grep -o '"query"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:.*"\([^"]*\)".*/\1/')

case "`$TOOL_NAME" in
    "Edit"|"Write")
        echo "`$FILE_PATH" >> "`$FILES_CHANGED" 2>/dev/null
        ;;
    "Read")
        echo "1" >> "`$RESEARCH_COUNT"
        [ -n "`$FILE_PATH" ] && echo "`$FILE_PATH" >> "`$RESEARCH_AREAS"
        ;;
    "Grep"|"Glob")
        echo "1" >> "`$RESEARCH_COUNT"
        [ -n "`$PATTERN" ] && echo "`$PATTERN" >> "`$RESEARCH_AREAS"
        ;;
    "WebSearch")
        echo "1" >> "`$RESEARCH_COUNT"
        [ -n "`$QUERY" ] && echo "`$QUERY" >> "`$RESEARCH_AREAS"
        ;;
esac

exit 0
"@
    Set-Content -Path (Join-Path $HOOKS_DIR "ctx-post-tool.sh") -Value $POST_HOOK -Encoding UTF8 -NoNewline

    # Update Claude settings.json with hooks
    $HOOKS_JSON = @{
        hooks = @{
            SessionStart = @(@{
                hooks = @(@{
                    type = "command"
                    command = "$HOOKS_DIR/ctx-session-start.sh" -replace '\\', '/'
                })
            })
            Stop = @(@{
                hooks = @(@{
                    type = "command"
                    command = "$HOOKS_DIR/ctx-stop-enforcer.sh" -replace '\\', '/'
                    blocking = $true
                })
            })
            PostToolUse = @(
                @{
                    matcher = "Edit"
                    hooks = @(@{
                        type = "command"
                        command = "$HOOKS_DIR/ctx-post-tool.sh" -replace '\\', '/'
                    })
                },
                @{
                    matcher = "Write"
                    hooks = @(@{
                        type = "command"
                        command = "$HOOKS_DIR/ctx-post-tool.sh" -replace '\\', '/'
                    })
                },
                @{
                    matcher = "Read"
                    hooks = @(@{
                        type = "command"
                        command = "$HOOKS_DIR/ctx-post-tool.sh" -replace '\\', '/'
                    })
                },
                @{
                    matcher = "Grep"
                    hooks = @(@{
                        type = "command"
                        command = "$HOOKS_DIR/ctx-post-tool.sh" -replace '\\', '/'
                    })
                },
                @{
                    matcher = "Glob"
                    hooks = @(@{
                        type = "command"
                        command = "$HOOKS_DIR/ctx-post-tool.sh" -replace '\\', '/'
                    })
                },
                @{
                    matcher = "WebSearch"
                    hooks = @(@{
                        type = "command"
                        command = "$HOOKS_DIR/ctx-post-tool.sh" -replace '\\', '/'
                    })
                },
                @{
                    matcher = "WebFetch"
                    hooks = @(@{
                        type = "command"
                        command = "$HOOKS_DIR/ctx-post-tool.sh" -replace '\\', '/'
                    })
                }
            )
        }
    }

    # Merge with existing settings if present
    if (Test-Path $SETTINGS_FILE) {
        try {
            $existing = Get-Content $SETTINGS_FILE -Raw | ConvertFrom-Json -AsHashtable
            foreach ($key in $HOOKS_JSON.Keys) {
                $existing[$key] = $HOOKS_JSON[$key]
            }
            $existing | ConvertTo-Json -Depth 10 | Set-Content $SETTINGS_FILE -Encoding UTF8
        } catch {
            $HOOKS_JSON | ConvertTo-Json -Depth 10 | Set-Content $SETTINGS_FILE -Encoding UTF8
        }
    } else {
        $HOOKS_JSON | ConvertTo-Json -Depth 10 | Set-Content $SETTINGS_FILE -Encoding UTF8
    }

    Write-Success "Hooks configured (using Git Bash)"
} else {
    Write-Warning "Git Bash not found - hooks require Git Bash or WSL"
    Write-Host "        Install Git for Windows to enable hooks" -ForegroundColor DarkGray

    # Create minimal settings without hooks
    if (-not (Test-Path $SETTINGS_FILE)) {
        @{ } | ConvertTo-Json | Set-Content $SETTINGS_FILE -Encoding UTF8
    }
}

# Complete
Write-Host ""
Write-Color "═══════════════════════════════════════════════════════════════" Green
Write-Host ""
Write-Color "  ✅ ContextVault v$VERSION installed successfully!" Green
Write-Host ""
Write-Host "  📁 Location: $CLAUDE_DIR" -ForegroundColor Gray
Write-Host ""
Write-Host "  Quick Start:" -ForegroundColor White
Write-Host "    1. Open Claude Code in any project" -ForegroundColor Gray
Write-Host "    2. Run " -ForegroundColor Gray -NoNewline
Write-Color "/ctx-init" Yellow -NoNewline
Write-Host " to initialize project vault" -ForegroundColor Gray
Write-Host "    3. Document as you work with " -ForegroundColor Gray -NoNewline
Write-Color "/ctx-doc" Yellow -NoNewline
Write-Host ", " -ForegroundColor Gray -NoNewline
Write-Color "/ctx-error" Yellow -NoNewline
Write-Host ", etc." -ForegroundColor Gray
Write-Host "    4. End sessions with " -ForegroundColor Gray -NoNewline
Write-Color "/ctx-handoff" Yellow
Write-Host ""
Write-Host "  Run " -ForegroundColor Gray -NoNewline
Write-Color "/ctx-help" Yellow -NoNewline
Write-Host " for all commands" -ForegroundColor Gray
Write-Host ""
Write-Color "═══════════════════════════════════════════════════════════════" Green
Write-Host ""
