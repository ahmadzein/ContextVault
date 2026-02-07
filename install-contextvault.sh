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
VERSION="1.8.7"

#===============================================================================
# 🔒 SECURITY & VALIDATION
#===============================================================================

# Validate HOME environment variable
validate_environment() {
    # Check HOME is set
    if [ -z "$HOME" ]; then
        echo "ERROR: HOME environment variable is not set!" >&2
        echo "Cannot determine installation directory." >&2
        exit 1
    fi

    # Check HOME exists and is a directory
    if [ ! -d "$HOME" ]; then
        echo "ERROR: HOME directory does not exist: $HOME" >&2
        exit 1
    fi

    # Security check: Ensure we're not operating on root filesystem
    if [ "$HOME" = "/" ]; then
        echo "ERROR: HOME cannot be root filesystem!" >&2
        exit 1
    fi

    # Validate HOME is an absolute path
    case "$HOME" in
        /*) ;; # OK - absolute path
        *)
            echo "ERROR: HOME must be an absolute path: $HOME" >&2
            exit 1
            ;;
    esac
}

# Run validation immediately
validate_environment

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
SETTINGS_JSON="$CLAUDE_DIR/settings.json"

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
# 📁 SAFE FILE OPERATIONS
#===============================================================================

# Safe directory creation with error handling
safe_mkdir() {
    local dir="$1"
    local desc="${2:-directory}"

    if [ -d "$dir" ]; then
        return 0  # Already exists
    fi

    if mkdir -p "$dir" 2>/dev/null; then
        return 0
    else
        print_error "Failed to create $desc: $dir"
        return 1
    fi
}

# Safe file write with validation
safe_write_file() {
    local file="$1"
    local content="$2"
    local desc="${3:-file}"

    # Ensure parent directory exists
    local parent_dir=$(dirname "$file")
    if [ ! -d "$parent_dir" ]; then
        if ! safe_mkdir "$parent_dir" "parent directory"; then
            return 1
        fi
    fi

    # Write to temp file first, then move (atomic operation)
    local temp_file="${file}.tmp.$$"

    if echo "$content" > "$temp_file" 2>/dev/null; then
        if mv "$temp_file" "$file" 2>/dev/null; then
            return 0
        else
            rm -f "$temp_file" 2>/dev/null
            print_error "Failed to write $desc: $file"
            return 1
        fi
    else
        rm -f "$temp_file" 2>/dev/null
        print_error "Failed to create $desc: $file"
        return 1
    fi
}

# Safe file copy with error handling
safe_copy() {
    local src="$1"
    local dest="$2"
    local desc="${3:-file}"

    if cp "$src" "$dest" 2>/dev/null; then
        return 0
    else
        print_error "Failed to copy $desc: $src -> $dest"
        return 1
    fi
}

# Set secure file permissions
secure_file() {
    local file="$1"
    local mode="${2:-600}"
    chmod "$mode" "$file" 2>/dev/null || true
}

# Set secure directory permissions
secure_dir() {
    local dir="$1"
    local mode="${2:-700}"
    chmod "$mode" "$dir" 2>/dev/null || true
}

#===============================================================================
# 🔍 VERSION DETECTION
#===============================================================================

# Detect installed version with validation
get_installed_version() {
    local installed_version=""

    # Try to get version from hook script first (most reliable)
    if [ -f "$CLAUDE_DIR/hooks/ctx-session-start.sh" ]; then
        # Extract version and validate format (X.Y.Z)
        installed_version=$(grep -m1 'VERSION=' "$CLAUDE_DIR/hooks/ctx-session-start.sh" 2>/dev/null | \
                          grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    fi

    # Fallback: try ctx-status.md which has version
    if [ -z "$installed_version" ] && [ -f "$COMMANDS_DIR/ctx-status.md" ]; then
        installed_version=$(grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' "$COMMANDS_DIR/ctx-status.md" 2>/dev/null | \
                          head -1 | tr -d 'v')
    fi

    # Final fallback: detect from CLAUDE.md patterns
    if [ -z "$installed_version" ] && [ -f "$CLAUDE_MD" ]; then
        if grep -q "PRE-WORK CHECKLIST" "$CLAUDE_MD" 2>/dev/null; then
            installed_version="1.4.0"
        elif grep -q "ContextVault" "$CLAUDE_MD" 2>/dev/null; then
            installed_version="1.3.0"
        fi
    fi

    # Validate version format before returning
    if [[ "$installed_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "$installed_version"
    fi
}

# Compare two semver versions: returns 0 if v1 > v2, 1 if v1 = v2, 2 if v1 < v2
# Usage: version_compare "1.5.2" "1.5.0" -> returns 0 (1.5.2 is newer)
version_compare() {
    local v1="$1"
    local v2="$2"

    # Split versions into arrays
    IFS='.' read -r v1_major v1_minor v1_patch <<< "$v1"
    IFS='.' read -r v2_major v2_minor v2_patch <<< "$v2"

    # Compare major
    if [ "$v1_major" -gt "$v2_major" ] 2>/dev/null; then return 0; fi
    if [ "$v1_major" -lt "$v2_major" ] 2>/dev/null; then return 2; fi

    # Compare minor
    if [ "$v1_minor" -gt "$v2_minor" ] 2>/dev/null; then return 0; fi
    if [ "$v1_minor" -lt "$v2_minor" ] 2>/dev/null; then return 2; fi

    # Compare patch
    if [ "$v1_patch" -gt "$v2_patch" ] 2>/dev/null; then return 0; fi
    if [ "$v1_patch" -lt "$v2_patch" ] 2>/dev/null; then return 2; fi

    # Equal
    return 1
}

# Check if version1 is newer than version2
# Usage: is_newer_version "1.5.2" "1.5.0" && echo "yes"
is_newer_version() {
    version_compare "$1" "$2"
    [ $? -eq 0 ]
}

# Check for updates with proper error handling
check_for_updates() {
    local current_version="$1"
    local timeout=3
    local url="https://raw.githubusercontent.com/ahmadzein/ContextVault/main/install-contextvault.sh"

    # Try to fetch latest version
    local response
    response=$(curl -sfL --max-time "$timeout" "$url" 2>/dev/null) || return 1

    # Check for error responses
    if [ -z "$response" ]; then
        return 1
    fi

    # Extract version safely
    local latest
    latest=$(echo "$response" | grep -m1 'VERSION=' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)

    # Validate version format
    if [[ "$latest" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        if [ "$latest" != "$current_version" ]; then
            echo "$latest"
            return 0
        fi
    fi

    return 1
}

#===============================================================================
# HOOKS CONFIGURATION
#===============================================================================

# Create the ctx-session-start hook script
create_session_start_script() {
    local script_path="$CLAUDE_DIR/hooks/ctx-session-start.sh"
    safe_mkdir "$CLAUDE_DIR/hooks" "hooks directory"

    cat << 'SCRIPT_EOF' > "$script_path"
#!/bin/bash
# ContextVault Session Start Hook
# Shows status, version, and checks for updates

VERSION="__VERSION_PLACEHOLDER__"
VAULT_DIR="$HOME/.claude/vault"
PROJECT_VAULT="./.claude/vault"

# Create unique session file using PPID (parent process ID) for reliable matching
# This ensures the end hook finds the correct session file even with multiple sessions
SESSION_ID="${PPID:-$$}_$(date +%s)"
SESSION_FILE="/tmp/ctx_session_${SESSION_ID}"

# Save session start time and ID for tracking modifications
echo "$SESSION_ID $(date +%s)" > "$SESSION_FILE" 2>/dev/null
chmod 600 "$SESSION_FILE" 2>/dev/null

# Count global docs
global_count=0
if [ -d "$VAULT_DIR" ]; then
    global_count=$(find "$VAULT_DIR" -maxdepth 1 -name "G*.md" 2>/dev/null | wc -l | tr -d ' ')
fi

# Count project docs
project_count=0
project_status="Not initialized"
if [ -d "$PROJECT_VAULT" ]; then
    project_count=$(find "$PROJECT_VAULT" -maxdepth 1 -name "P*.md" 2>/dev/null | wc -l | tr -d ' ')
    project_status="Active"
fi

# Check for updates (non-blocking, timeout 2s)
update_msg=""
latest=$(curl -sfL --max-time 2 "https://raw.githubusercontent.com/ahmadzein/ContextVault/main/install-contextvault.sh" 2>/dev/null | grep -m1 'VERSION=' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
if [ -n "$latest" ] && [ "$latest" != "$VERSION" ]; then
    update_msg="\n   ⬆️  Update available: v$latest (you have v$VERSION)"
fi

# Output status
echo ""
echo "🏰 ContextVault v$VERSION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   📚 Global:  $global_count docs  (~/.claude/vault/)"
echo "   📂 Project: $project_count docs  ($project_status)"
if [ -n "$update_msg" ]; then
    echo -e "$update_msg"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   📖 Read indexes NOW before starting work!"
echo ""
echo "   🚨 AFTER EVERY TASK:"
echo "   → Fixed bug?      /ctx-error"
echo "   → Decision?       /ctx-decision"
echo "   → Learned?        /ctx-doc"
echo "   → Ending?         /ctx-handoff"
echo ""
SCRIPT_EOF

    # Replace version placeholder with actual version using temp file (safer)
    local temp_file="${script_path}.tmp"
    if sed "s/__VERSION_PLACEHOLDER__/$VERSION/g" "$script_path" > "$temp_file" 2>/dev/null; then
        mv "$temp_file" "$script_path"
    else
        rm -f "$temp_file" 2>/dev/null
        print_error "Failed to set version in hook script"
    fi
    chmod +x "$script_path"
    secure_file "$script_path" 755
}

# Create the ctx-session-end hook script
create_session_end_script() {
    local script_path="$CLAUDE_DIR/hooks/ctx-session-end.sh"
    safe_mkdir "$CLAUDE_DIR/hooks" "hooks directory"

    cat << 'SCRIPT_EOF' > "$script_path"
#!/bin/bash
# ContextVault Session End Hook
# Reports if any docs were created/modified during session

VAULT_DIR="$HOME/.claude/vault"
PROJECT_VAULT="./.claude/vault"

# Find the correct session file by matching PPID prefix
# This prevents race conditions with multiple concurrent sessions
session_start=0
session_file=""
my_ppid="${PPID:-0}"

# Look for session file matching our parent process
for f in /tmp/ctx_session_${my_ppid}_* /tmp/ctx_session_*; do
    if [ -f "$f" ]; then
        # Read session data (format: "session_id timestamp")
        session_data=$(cat "$f" 2>/dev/null)
        session_start=$(echo "$session_data" | awk '{print $2}')
        session_file="$f"

        # If we found a file matching our PPID, use it and stop
        if [[ "$f" == *"${my_ppid}_"* ]]; then
            break
        fi
    fi
done

# Clean up the session file
if [ -n "$session_file" ] && [ -f "$session_file" ]; then
    rm -f "$session_file" 2>/dev/null
fi

# If no session file or invalid timestamp, just show reminder
if [ -z "$session_start" ] || [ "$session_start" = "0" ]; then
    echo ""
    echo "📝 ContextVault - Session End"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   ⚠️  Did you document your learnings?"
    echo ""
    echo "   Quick commands:"
    echo "   → /ctx-doc       Document what you learned"
    echo "   → /ctx-handoff   Create session summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    exit 0
fi

# Find modified files since session start
modified_global=""
modified_project=""

if [ -d "$VAULT_DIR" ]; then
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            modified_global="$modified_global $(basename "$file")"
        fi
    done < <(find "$VAULT_DIR" -maxdepth 1 -name "G*.md" -newermt "@$session_start" 2>/dev/null)
fi

if [ -d "$PROJECT_VAULT" ]; then
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            modified_project="$modified_project $(basename "$file")"
        fi
    done < <(find "$PROJECT_VAULT" -maxdepth 1 -name "P*.md" -newermt "@$session_start" 2>/dev/null)
fi

# Output results
echo ""
echo "📝 ContextVault Session Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -n "$modified_global" ] || [ -n "$modified_project" ]; then
    echo "   ✅ Documentation updated:"
    if [ -n "$modified_global" ]; then
        echo "      Global:$modified_global"
    fi
    if [ -n "$modified_project" ]; then
        echo "      Project:$modified_project"
    fi
else
    echo "   ⚠️  NO DOCS MODIFIED THIS SESSION!"
    echo ""
    echo "   Did you learn anything? Document it!"
    echo "   → /ctx-doc       Quick documentation"
    echo "   → /ctx-error     Bug fix you did"
    echo "   → /ctx-decision  Choice you made"
fi
echo ""
echo "   🤝 /ctx-handoff → Create session summary for next time"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
SCRIPT_EOF

    chmod +x "$script_path"
    secure_file "$script_path" 755
}

# Create the Stop enforcer hook (v1.8.2 - Smart blocking at session end)
# Only blocks for SIGNIFICANT undocumented work. Trivial changes pass through.
create_stop_enforcer_script() {
    local script_path="$CLAUDE_DIR/hooks/ctx-stop-enforcer.sh"
    safe_mkdir "$CLAUDE_DIR/hooks" "hooks directory"

    cat << 'SCRIPT_EOF' > "$script_path"
#!/bin/bash
# ContextVault Stop Hook v1.8.4
# SMART BLOCKING: Only blocks when significant work is undocumented
# Trivial changes (version bumps, typos, config) → pass through
# Already documented this session → pass through
# Significant work + zero docs → block once, then let go

PROJECT_VAULT="./.claude/vault"
GLOBAL_VAULT="$HOME/.claude/vault"
FILES_CHANGED="/tmp/ctx-files-changed"
MILESTONE_FILE="/tmp/ctx-milestones"
STOP_REMINDED="/tmp/ctx-stop-reminded"

# Count files changed this session
total_edits=0
unique_files=0
new_files=0
if [ -f "$FILES_CHANGED" ]; then
    total_edits=$(wc -l < "$FILES_CHANGED" 2>/dev/null | tr -d ' ')
    unique_files=$(sort -u "$FILES_CHANGED" 2>/dev/null | wc -l | tr -d ' ')
fi
# Check for new files created (tracked by PostToolUse Write handler)
[ -f "/tmp/ctx-new-files" ] && new_files=$(wc -l < "/tmp/ctx-new-files" 2>/dev/null | tr -d ' ')

# Count research activity this session
research_count=0
research_areas=0
[ -f "/tmp/ctx-research-count" ] && research_count=$(wc -l < "/tmp/ctx-research-count" 2>/dev/null | tr -d ' ')
[ -f "/tmp/ctx-research-areas" ] && research_areas=$(sort -u "/tmp/ctx-research-areas" 2>/dev/null | wc -l | tr -d ' ')

# Detect session start for doc counting
session_file=""
session_start=0
my_ppid="${PPID:-0}"
for f in /tmp/ctx_session_${my_ppid}_* /tmp/ctx_session_*; do
    if [ -f "$f" ]; then
        session_data=$(cat "$f" 2>/dev/null)
        session_start=$(echo "$session_data" | awk '{print $2}')
        session_file="$f"
        [[ "$f" == *"${my_ppid}_"* ]] && break
    fi
done

# Count docs modified this session
docs_modified=0
if [ "$session_start" -gt 0 ]; then
    [ -d "$PROJECT_VAULT" ] && docs_modified=$((docs_modified + $(find "$PROJECT_VAULT" -maxdepth 1 -name "P*.md" -newermt "@$session_start" 2>/dev/null | wc -l)))
    [ -d "$GLOBAL_VAULT" ] && docs_modified=$((docs_modified + $(find "$GLOBAL_VAULT" -maxdepth 1 -name "G*.md" -newermt "@$session_start" 2>/dev/null | wc -l)))
else
    [ -d "$PROJECT_VAULT" ] && docs_modified=$((docs_modified + $(find "$PROJECT_VAULT" -maxdepth 1 -name "P*.md" -mmin -30 2>/dev/null | wc -l)))
    [ -d "$GLOBAL_VAULT" ] && docs_modified=$((docs_modified + $(find "$GLOBAL_VAULT" -maxdepth 1 -name "G*.md" -mmin -30 2>/dev/null | wc -l)))
fi

# Determine if work was SIGNIFICANT (worth documenting)
# Significant = (5+ edits across 2+ files) OR (any new code files created)
#            OR (significant research: 15+ lookups across 5+ areas)
significant=0
if [ "$total_edits" -ge 5 ] && [ "$unique_files" -ge 2 ]; then
    significant=1
fi
if [ "$new_files" -gt 0 ]; then
    significant=1
fi
if [ "$research_areas" -ge 5 ] && [ "$research_count" -ge 15 ]; then
    significant=1
fi

# DECISION: Block, pass, or summary?
if [ "$significant" -eq 1 ] && [ "$docs_modified" -eq 0 ] && [ ! -f "$STOP_REMINDED" ]; then
    # BLOCK: Significant work with zero docs, first attempt
    # Create reminder file so second attempt passes (one-time block)
    touch "$STOP_REMINDED"

    reason="📋 You did significant work this session but haven't documented anything.\n\n"
    reason+="📊 Session: $total_edits edits across $unique_files files"
    [ "$new_files" -gt 0 ] && reason+=", $new_files new files"
    reason+="\n\n"
    reason+="Quick options (pick one):\n"
    reason+="  /ctx-doc      → Document feature or learning\n"
    reason+="  /ctx-error    → Document a bug fix\n"
    reason+="  /ctx-handoff  → Session summary for next time\n\n"
    reason+="Or if nothing meaningful was learned, just try stopping again."

    printf '{\n  "decision": "block",\n  "reason": "%s"\n}' "$reason"
    exit 0
fi

# PASS: Show summary (trivial work, already documented, or second attempt)
echo ""
echo "📊 ContextVault Session Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Changes: $total_edits edits, $unique_files files"
[ "$new_files" -gt 0 ] && echo "  New files: $new_files"
[ "$research_count" -gt 0 ] && echo "  Research: $research_count lookups, $research_areas areas"
echo "  Docs: $docs_modified updated"
if [ "$docs_modified" -gt 0 ]; then
    echo "  ✅ Documentation captured"
elif [ "$total_edits" -eq 0 ]; then
    echo "  ℹ️  No code changes this session"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Clean up ALL temp files
rm -f "$FILES_CHANGED" "$MILESTONE_FILE" /tmp/ctx-hook-seen /tmp/ctx-new-files \
      "$STOP_REMINDED" /tmp/ctx-edit-count /tmp/ctx-write-count \
      /tmp/ctx-first-edit-done /tmp/ctx-work-type /tmp/ctx-plan-reminded \
      /tmp/ctx-research-count /tmp/ctx-research-areas 2>/dev/null
[ -n "$session_file" ] && rm -f "$session_file" 2>/dev/null

exit 0
SCRIPT_EOF

    chmod +x "$script_path"
    secure_file "$script_path" 755
}

# PreToolUse hook removed in v1.8.0 - no more mid-work blocking
# Keeping function as no-op for clean upgrade path
create_pre_tool_script() {
    local script_path="$CLAUDE_DIR/hooks/ctx-pre-tool.sh"
    # Remove old blocking script if it exists
    rm -f "$script_path" 2>/dev/null
}

# Create the ctx-post-tool hook script (v1.8.4 - configurable enforcement + research tracking)
create_post_tool_script() {
    local script_path="$CLAUDE_DIR/hooks/ctx-post-tool.sh"
    safe_mkdir "$CLAUDE_DIR/hooks" "hooks directory"

    cat << 'SCRIPT_EOF' > "$script_path"
#!/bin/bash
# ContextVault PostToolUse Hook v1.8.4
# Configurable enforcement: light | balanced (default) | strict
# Edit/Write: track files + block when threshold reached (balanced/strict)
# Read/Grep/Glob/WebSearch/WebFetch: track research + non-blocking nudge
# TodoWrite: gentle non-blocking reminder
# Bash: gentle non-blocking reminder on git commit

FILES_CHANGED="/tmp/ctx-files-changed"
NEW_FILES="/tmp/ctx-new-files"
MILESTONE_FILE="/tmp/ctx-milestones"
DEDUP_FILE="/tmp/ctx-hook-seen"
RESEARCH_COUNT="/tmp/ctx-research-count"
RESEARCH_AREAS="/tmp/ctx-research-areas"

# Read enforcement level from vault settings (fast grep, no jq needed)
ENFORCEMENT="balanced"
VAULT_SETTINGS="$HOME/.claude/vault/settings.json"
if [ -f "$VAULT_SETTINGS" ]; then
    level=$(grep -o '"enforcement"[[:space:]]*:[[:space:]]*"[^"]*"' "$VAULT_SETTINGS" 2>/dev/null | sed 's/.*"\([^"]*\)"$/\1/')
    [ -n "$level" ] && ENFORCEMENT="$level"
fi

# Set thresholds based on enforcement level
case "$ENFORCEMENT" in
    "light")  EDIT_THRESH=999; FILE_THRESH=999; RESEARCH_THRESH=999; AREA_THRESH=999 ;;
    "strict") EDIT_THRESH=4;   FILE_THRESH=2;   RESEARCH_THRESH=12;  AREA_THRESH=3 ;;
    *)        EDIT_THRESH=8;   FILE_THRESH=2;   RESEARCH_THRESH=20;  AREA_THRESH=5 ;;
esac

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:.*"\([^"]*\)".*/\1/')
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:.*"\([^"]*\)".*/\1/')
COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:.*"\([^"]*\)".*/\1/')
PATTERN=$(echo "$INPUT" | grep -o '"pattern"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:.*"\([^"]*\)".*/\1/')
QUERY=$(echo "$INPUT" | grep -o '"query"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:.*"\([^"]*\)".*/\1/')
URL=$(echo "$INPUT" | grep -o '"url"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:.*"\([^"]*\)".*/\1/')

# DEDUP: Skip duplicate runs within same second (Claude Code double-execution bug)
DEDUP_KEY="POST_${TOOL_NAME}_$(date +%s)"
if grep -qxF "$DEDUP_KEY" "$DEDUP_FILE" 2>/dev/null; then
    exit 0
fi
echo "$DEDUP_KEY" >> "$DEDUP_FILE"
tail -50 "$DEDUP_FILE" 2>/dev/null > "$DEDUP_FILE.tmp" && mv "$DEDUP_FILE.tmp" "$DEDUP_FILE" 2>/dev/null

# Skip vault file operations silently
if [[ "$FILE_PATH" == *"vault/"* ]] && [[ "$FILE_PATH" == *".md" ]]; then
    exit 0
fi

is_code_file() {
    case "$1" in
        *.ts|*.tsx|*.js|*.jsx|*.py|*.go|*.rs|*.java|*.rb|*.php|*.swift|*.kt|*.c|*.cpp|*.h|*.cs|*.vue|*.svelte|*.astro|*.sh|*.bash) return 0 ;;
        *) return 1 ;;
    esac
}

already_reminded() {
    grep -qxF "$1" "$MILESTONE_FILE" 2>/dev/null
}

mark_reminded() {
    echo "$1" >> "$MILESTONE_FILE"
}

# Check if any vault docs were modified this session (only called at threshold)
docs_modified_this_session() {
    local project_vault="./.claude/vault"
    local global_vault="$HOME/.claude/vault"
    local session_start=0
    local my_ppid="${PPID:-0}"
    local docs=0
    for f in /tmp/ctx_session_${my_ppid}_* /tmp/ctx_session_*; do
        if [ -f "$f" ]; then
            session_start=$(cat "$f" 2>/dev/null | awk '{print $2}')
            [[ "$f" == *"${my_ppid}_"* ]] && break
        fi
    done
    if [ "$session_start" -gt 0 ]; then
        [ -d "$project_vault" ] && docs=$((docs + $(find "$project_vault" -maxdepth 1 -name "P*.md" -newermt "@$session_start" 2>/dev/null | wc -l)))
        [ -d "$global_vault" ] && docs=$((docs + $(find "$global_vault" -maxdepth 1 -name "G*.md" -newermt "@$session_start" 2>/dev/null | wc -l)))
    else
        [ -d "$project_vault" ] && docs=$((docs + $(find "$project_vault" -maxdepth 1 -name "P*.md" -mmin -30 2>/dev/null | wc -l)))
        [ -d "$global_vault" ] && docs=$((docs + $(find "$global_vault" -maxdepth 1 -name "G*.md" -mmin -30 2>/dev/null | wc -l)))
    fi
    echo "$docs"
}

# Check threshold and block if needed (for Edit/Write)
check_threshold_block() {
    if [ ! -f "$FILES_CHANGED" ]; then return; fi

    local total_edits=$(wc -l < "$FILES_CHANGED" 2>/dev/null | tr -d ' ')
    local unique_files=$(sort -u "$FILES_CHANGED" 2>/dev/null | wc -l | tr -d ' ')

    # Only check when threshold reached and not already reminded
    if [ "$total_edits" -ge "$EDIT_THRESH" ] && [ "$unique_files" -ge "$FILE_THRESH" ] && ! already_reminded "threshold_block"; then
        # Now do the expensive docs check (only runs once per session)
        local docs=$(docs_modified_this_session)
        if [ "$docs" -eq 0 ]; then
            mark_reminded "threshold_block"
            local reason="📋 $total_edits changes across $unique_files files without documentation.\n\n"
            reason+="Quick options:\n"
            reason+="  /ctx-doc      → Document feature or learning\n"
            reason+="  /ctx-error    → Document a bug fix\n"
            reason+="  /ctx-handoff  → Session summary\n\n"
            reason+="Document something, then continue editing."
            printf '{\n  "decision": "block",\n  "reason": "%s"\n}' "$reason"
            exit 0
        fi
    fi
}

# Track a research action (area identifier as $1)
track_research() {
    local area="$1"
    echo "1" >> "$RESEARCH_COUNT"
    if [ -n "$area" ]; then
        echo "$area" >> "$RESEARCH_AREAS"
    fi
}

# Non-blocking nudge when research threshold is reached
check_research_threshold() {
    if [ ! -f "$RESEARCH_COUNT" ]; then return; fi

    local total_research=$(wc -l < "$RESEARCH_COUNT" 2>/dev/null | tr -d ' ')
    local unique_areas=0
    [ -f "$RESEARCH_AREAS" ] && unique_areas=$(sort -u "$RESEARCH_AREAS" 2>/dev/null | wc -l | tr -d ' ')

    if [ "$total_research" -ge "$RESEARCH_THRESH" ] && [ "$unique_areas" -ge "$AREA_THRESH" ] && ! already_reminded "research_remind"; then
        local docs=$(docs_modified_this_session)
        if [ "$docs" -eq 0 ]; then
            mark_reminded "research_remind"
            echo ""
            echo "🔍 ContextVault: $total_research lookups across $unique_areas areas without documenting findings"
            echo "   Consider: /ctx-doc or /ctx-doc type=intel"
            echo ""
        fi
    fi
}

case "$TOOL_NAME" in
    "Write")
        if is_code_file "$FILE_PATH"; then
            echo "$FILE_PATH" >> "$FILES_CHANGED"
            echo "$FILE_PATH" >> "$NEW_FILES"
            check_threshold_block
        fi
        ;;
    "Edit")
        if is_code_file "$FILE_PATH"; then
            echo "$FILE_PATH" >> "$FILES_CHANGED"
            check_threshold_block
        fi
        ;;
    "TodoWrite")
        # Non-blocking completion reminder
        if [ -f "$FILES_CHANGED" ]; then
            total_edits=$(wc -l < "$FILES_CHANGED" 2>/dev/null | tr -d ' ')
            unique_files=$(sort -u "$FILES_CHANGED" 2>/dev/null | wc -l | tr -d ' ')
            if [ "$total_edits" -gt 0 ] && ! already_reminded "todo_complete"; then
                mark_reminded "todo_complete"
                echo ""
                echo "📋 ContextVault: $total_edits changes across $unique_files files this session"
                echo "   When tasks are done → /ctx-doc, /ctx-error, or /ctx-handoff"
                echo ""
            fi
        fi
        ;;
    "Bash")
        # Non-blocking reminder on git commit
        CMD_LOWER=$(echo "$COMMAND" | tr '[:upper:]' '[:lower:]')
        if echo "$CMD_LOWER" | grep -qE 'git commit' && ! already_reminded "commit"; then
            mark_reminded "commit"
            echo ""
            echo "📋 ContextVault: Code committed — worth documenting?"
            echo "   → /ctx-doc, /ctx-error, or /ctx-decision"
            echo ""
        fi
        ;;
    "Read")
        # Skip vault reads
        if [[ "$FILE_PATH" == *"vault/"* ]] && [[ "$FILE_PATH" == *".md" ]]; then
            exit 0
        fi
        # Track research: area = parent dir / basename
        local_area=$(basename "$(dirname "$FILE_PATH")")/$(basename "$FILE_PATH")
        track_research "$local_area"
        check_research_threshold
        ;;
    "Grep")
        track_research "$PATTERN"
        check_research_threshold
        ;;
    "Glob")
        track_research "$PATTERN"
        check_research_threshold
        ;;
    "WebSearch")
        track_research "$QUERY"
        check_research_threshold
        ;;
    "WebFetch")
        # Track by domain
        domain=$(echo "$URL" | sed 's|https\?://||' | sed 's|/.*||')
        track_research "$domain"
        check_research_threshold
        ;;
esac
exit 0
SCRIPT_EOF

    chmod +x "$script_path"
    secure_file "$script_path" 755
}

# Create global hooks in ~/.claude/settings.json
create_global_hooks() {
    local settings_file="$SETTINGS_JSON"

    # First create/update the hook scripts (always recreate to ensure latest version)
    create_session_start_script
    create_session_end_script
    create_stop_enforcer_script
    create_pre_tool_script    # v1.8.0: removes old blocking script
    create_post_tool_script

    # The hooks JSON content - uses full path with $HOME for proper expansion
    # v1.8.4: Configurable enforcement (light/balanced/strict) + research tracking
    # Stop: smart blocking for significant undocumented work
    # PostToolUse Edit/Write: blocking (threshold-based, reads enforcement from settings)
    # PostToolUse Bash/TodoWrite: non-blocking reminders
    # PostToolUse Read/Grep/Glob/WebSearch/WebFetch: non-blocking research tracking
    local hooks_json="{
  \"hooks\": {
    \"SessionStart\": [
      {
        \"hooks\": [
          {
            \"type\": \"command\",
            \"command\": \"$HOME/.claude/hooks/ctx-session-start.sh\"
          }
        ]
      }
    ],
    \"Stop\": [
      {
        \"hooks\": [
          {
            \"type\": \"command\",
            \"command\": \"$HOME/.claude/hooks/ctx-stop-enforcer.sh\",
            \"blocking\": true
          }
        ]
      }
    ],
    \"PostToolUse\": [
      {
        \"matcher\": \"Edit\",
        \"hooks\": [
          {
            \"type\": \"command\",
            \"command\": \"$HOME/.claude/hooks/ctx-post-tool.sh\",
            \"blocking\": true
          }
        ]
      },
      {
        \"matcher\": \"Write\",
        \"hooks\": [
          {
            \"type\": \"command\",
            \"command\": \"$HOME/.claude/hooks/ctx-post-tool.sh\",
            \"blocking\": true
          }
        ]
      },
      {
        \"matcher\": \"Bash\",
        \"hooks\": [
          {
            \"type\": \"command\",
            \"command\": \"$HOME/.claude/hooks/ctx-post-tool.sh\"
          }
        ]
      },
      {
        \"matcher\": \"TodoWrite\",
        \"hooks\": [
          {
            \"type\": \"command\",
            \"command\": \"$HOME/.claude/hooks/ctx-post-tool.sh\"
          }
        ]
      },
      {
        \"matcher\": \"Read\",
        \"hooks\": [
          {
            \"type\": \"command\",
            \"command\": \"$HOME/.claude/hooks/ctx-post-tool.sh\"
          }
        ]
      },
      {
        \"matcher\": \"Grep\",
        \"hooks\": [
          {
            \"type\": \"command\",
            \"command\": \"$HOME/.claude/hooks/ctx-post-tool.sh\"
          }
        ]
      },
      {
        \"matcher\": \"Glob\",
        \"hooks\": [
          {
            \"type\": \"command\",
            \"command\": \"$HOME/.claude/hooks/ctx-post-tool.sh\"
          }
        ]
      },
      {
        \"matcher\": \"WebSearch\",
        \"hooks\": [
          {
            \"type\": \"command\",
            \"command\": \"$HOME/.claude/hooks/ctx-post-tool.sh\"
          }
        ]
      },
      {
        \"matcher\": \"WebFetch\",
        \"hooks\": [
          {
            \"type\": \"command\",
            \"command\": \"$HOME/.claude/hooks/ctx-post-tool.sh\"
          }
        ]
      }
    ]
  }
}"

    # Check if settings.json already exists
    if [ -f "$settings_file" ]; then
        # Backup existing settings
        safe_copy "$settings_file" "${settings_file}.backup" "settings backup"

        # Try to merge hooks with existing settings using jq if available
        if command -v jq &> /dev/null; then
            local existing
            existing=$(cat "$settings_file" 2>/dev/null)

            # Validate existing JSON first
            if ! echo "$existing" | jq empty 2>/dev/null; then
                print_warning "Existing settings.json is invalid JSON - recreating"
                if safe_write_file "$settings_file" "$hooks_json" "settings.json"; then
                    print_success "Global hooks created (replaced invalid JSON)"
                fi
                return
            fi

            # Safely merge: ensure .hooks exists, then replace all ContextVault hooks
            local merged
            merged=$(echo "$existing" | jq --argjson new_hooks "$hooks_json" '
                # Ensure hooks object exists
                .hooks //= {} |
                # v1.8.0: Replace hooks, remove PreToolUse blocking
                .hooks.SessionStart = $new_hooks.hooks.SessionStart |
                .hooks.Stop = $new_hooks.hooks.Stop |
                del(.hooks.PreToolUse) |
                .hooks.PostToolUse = $new_hooks.hooks.PostToolUse
            ' 2>/dev/null)

            # Validate merged output before writing
            if [ -n "$merged" ] && echo "$merged" | jq empty 2>/dev/null; then
                if safe_write_file "$settings_file" "$merged" "settings.json"; then
                    print_success "Global hooks updated to v${VERSION}"
                else
                    print_error "Failed to write settings.json (backup at ${settings_file}.backup)"
                fi
            else
                print_error "Failed to merge hooks (backup at ${settings_file}.backup)"
                print_info "Manually update ~/.claude/settings.json if needed"
            fi
        else
            # No jq - try to preserve other settings by simple replacement if possible
            # Otherwise just inform user
            print_warning "jq not found - cannot safely merge settings"
            print_info "Backup saved at ${settings_file}.backup"

            # Only overwrite if file appears to be ContextVault-only
            if grep -q '"hooks"' "$settings_file" && ! grep -q '"mcpServers"\|"mode"\|"alwaysThinking"' "$settings_file" 2>/dev/null; then
                if safe_write_file "$settings_file" "$hooks_json" "settings.json"; then
                    print_success "Global hooks updated"
                fi
            else
                print_warning "Cannot update - other settings exist. Install jq for safe merging."
            fi
        fi
    else
        # Create new settings.json
        if safe_write_file "$settings_file" "$hooks_json" "settings.json"; then
            print_success "Global hooks created"
        fi
    fi

    # Set secure permissions on settings file
    secure_file "$settings_file" 600
}

# Generate project hooks JSON for ctx-init (v1.8.0: non-blocking, milestone-based)
generate_project_hooks_json() {
    cat << 'HOOKS_EOF'
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "echo \"\\n📂 Project ContextVault\\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\n📖 Read: ./.claude/vault/index.md\\n🏷️  Use P### prefix for project docs\\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\n\""
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/ctx-stop-enforcer.sh",
            "blocking": true
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/ctx-post-tool.sh",
            "blocking": true
          }
        ]
      },
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/ctx-post-tool.sh",
            "blocking": true
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/ctx-post-tool.sh"
          }
        ]
      },
      {
        "matcher": "TodoWrite",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/ctx-post-tool.sh"
          }
        ]
      },
      {
        "matcher": "Read",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/ctx-post-tool.sh"
          }
        ]
      },
      {
        "matcher": "Grep",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/ctx-post-tool.sh"
          }
        ]
      },
      {
        "matcher": "Glob",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/ctx-post-tool.sh"
          }
        ]
      },
      {
        "matcher": "WebSearch",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/ctx-post-tool.sh"
          }
        ]
      },
      {
        "matcher": "WebFetch",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/ctx-post-tool.sh"
          }
        ]
      }
    ]
  }
}
HOOKS_EOF
}

#===============================================================================
# FILE CONTENT FUNCTIONS
#===============================================================================

create_claude_md() {
    cat << 'CLAUDE_MD_EOF'
# Global Claude Instructions

**Version:** 1.8.4 | **System:** ContextVault | **Updated:** $(date +%Y-%m-%d)

---

## Session Start (Automatic, Silent)

1. Read `~/.claude/vault/settings.json` → note mode
2. Read indexes based on mode:
   - `local` (default): `./.claude/vault/index.md` only
   - `full`: both global + project indexes
   - `global`: `~/.claude/vault/index.md` only
3. Note what docs exist — use throughout session
4. If `./.claude/vault/index.md` missing → suggest `/ctx-init` once, then continue

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
- Reusable across projects → Global `G###` in `~/.claude/vault/` (patterns, best practices, tool configs)
- Project-specific → Project `P###` in `./.claude/vault/` (architecture, configs, local decisions)

**Step 5 — Write.** Follow `_template.md` structure. Max 100 lines. Concise, factual, actionable.

**Step 6 — Index.** Update the correct index IMMEDIATELY. Summary: max 15 words.

**Step 7 — Confirm.** Tell user: "Documented to [ID]_topic.md" — don't ask permission, just inform.

**Skip documentation for:** trivial edits, version bumps, typos, mid-refactor, nothing learned.

---

## Core Rules

1. **Read indexes first** — Always at session start. Search BOTH before creating any doc.
2. **No duplicates** — Check both indexes for exact topic + related terms + synonyms. Exists anywhere → UPDATE.
3. **No redundancy** — One topic = one document. Merge related info. If unsure → UPDATE existing.
4. **No conflicts** — Replace outdated info, don't append contradictions. "Current Understanding" = current truth only. Move old info to History with date.
5. **Correct routing** — Reusable knowledge → Global `G###`. Project-specific → Project `P###`.
6. **Minimal context** — Load: indexes + ONE doc max. Never load multiple docs "just in case."
7. **Size limits** — Index: 50 entries. Doc: 100 lines. Summary: 15 words.
8. **Always update index** — After ANY doc change, immediately. Summary must reflect current state.

---

## Editing Rules

### APPEND (adding, enhancing, updating without removing)

Keep ALL existing lines, add new below. Include ALL existing content in old_string when using Edit tool.

```
old_string:                        new_string:
| 2026-01-25 | Did thing A |      | 2026-01-25 | Did thing A |  ← KEPT
| 2026-01-25 | Did thing B |      | 2026-01-25 | Did thing B |  ← KEPT
---                                | 2026-01-26 | Did thing C |  ← ADDED
                                   ---
```

If you lose information while editing, you MUST restore it.

### ARCHIVE (removing, replacing, deprecating)

1. Move removed content to `./.claude/vault/archive/[SAME_FILENAME]` with date + reason header
2. Add note in main doc: "Archived: [date] - [what was removed]"
3. Write new behavior in main doc

```markdown
# Main doc (lean):
- Feature now does X and Y (v2.0)
- Archived: 2026-01-25 - old v1.0 implementation

# archive/P001_feature.md:
## Archived 2026-01-25
**Reason:** Feature rewritten for v2.0
[Full old content preserved here]
```

Why archive: keeps vault lean, history accessible, documents why things changed.

---

## Document Granularity

Each topic gets its OWN document — never lump everything into one doc.

| Type | Contains | Does NOT contain |
|------|----------|------------------|
| P001_architecture | Tech stack, structure, design | Feature details |
| P00X_feature_* | How ONE feature works | Other features |
| P00X_plan_* | Steps, progress, decisions | Implementation code |
| P00X_error_* | Error, root cause, solution | Unrelated bugs |
| P00X_decision_* | What, why, trade-offs | Other decisions |

- Same feature + more details → UPDATE existing
- New feature/bug/decision → CREATE new doc
- Anti-pattern: one 200-line doc covering everything

---

## Updating an Existing Document

1. Read the full document
2. New info → add to "Current Understanding". Outdated → replace, move old to "History" with date. Bug → add to "Gotchas"
3. Preserve document structure
4. Update "Last Updated" date + index summary if meaning changed

---

## Creating a New Document

1. Route: `G###` (global, reusable) or `P###` (project-specific)
2. Next ID: read index, find highest, increment
3. Create: `[vault]/[ID]_topic_name.md` using `_template.md` structure
4. Content: Summary, Current Understanding (Key Points, Details), Gotchas, History
5. Index: add to Active Documents table + Related Terms Map + update Quick Stats
6. Confirm: "Created P003_topic.md"

---

## Settings

Read from `~/.claude/vault/settings.json`:

| Setting | Values | Effect |
|---------|--------|--------|
| mode | `local` / `full` / `global` | Which indexes to read/write |
| enforcement | `light` / `balanced` / `strict` | How aggressively hooks block |
| limits | max_docs: 50, max_lines: 100, max_summary: 15w | Document size caps |

**Enforcement:** light = no mid-work blocking, balanced = blocks after 8 edits across 2+ files (default), strict = blocks after 4 edits. Change: `/ctx-mode enforcement [level]`

**Mode:** local = project vault only (default), full = both vaults, global = global vault only.

---

## System Structure

```
~/.claude/vault/      Global docs (G### prefix) — cross-project, reusable
./.claude/vault/      Project docs (P### prefix) — this project only
~/.claude/commands/   Slash commands (/ctx-*)
~/.claude/hooks/      Hook scripts (session, stop, post-tool)
```

---

## Commands

| Command | When to use |
|---------|-------------|
| `/ctx-doc` | Built a feature, learned something (type=intel for exploration, type=snippet for code) |
| `/ctx-error` | Fixed a bug (error, root cause, solution) |
| `/ctx-decision` | Made architecture/design choice (options, trade-offs) |
| `/ctx-plan` | Working on multi-step task (goals, progress) |
| `/ctx-bootstrap` | New project — auto-generate all docs |
| `/ctx-handoff` | Ending session (summary for next time) |
| `/ctx-search` | Find existing docs |
| `/ctx-read` | Read doc by ID |
| `/ctx-update` | Update doc by ID |
| `/ctx-new` | Create doc with guided routing |
| `/ctx-mode` | Change mode or enforcement level |
| `/ctx-init` | Initialize vault in project |
| `/ctx-status` | Show vault status |
| `/ctx-help` | Show all commands |

---

## Never

- Ask "Should I document this?" or "Want me to save this?" — just do it
- Create a doc without checking if one exists first
- Forget to update the index after changes
- Create duplicates (same topic, different doc)
- Load multiple docs "just in case"
- Replace content when editing — always APPEND (or ARCHIVE if removing)

---

*Inspired by arxiv:2512.24601. Independent implementation.*

| Version | Date | Changes |
|---------|------|---------|
| 1.8.4 | $(date +%Y-%m-%d) | Optimized CLAUDE.md: 775 to ~170 lines, zero info loss |
| 1.8.3 | 2026-02-02 | Configurable enforcement levels (light/balanced/strict) |
| 1.8.2 | 2026-02-02 | Smart blocking at session end for significant work |
| 1.8.1 | 2026-02-02 | Completion-triggered reminders (TodoWrite + git commit) |
| 1.8.0 | 2026-02-02 | Remind Don't Block - milestone-based enforcement |
| 1.7.5 | 2026-02-02 | /ctx-bootstrap: Auto-scan codebase and generate docs |
| 1.7.4 | 2026-01-25 | Bug fix: Stop enforcer session fallback |
| 1.7.3 | 2026-01-25 | APPEND vs ARCHIVE decision tree |
| 1.7.2 | 2026-01-25 | Core rule: APPEND, NEVER REPLACE |
| 1.7.1 | 2026-01-25 | /ctx-plan + archive mechanism |
| 1.7.0 | 2026-01-25 | Smart detection - suggests right command |
| 1.6.0 | 2026-01-18 | Added 6 new commands |
| 1.5.3 | 2026-01-18 | Added /ctx-upgrade command |
| 1.4.0 | 2026-01-17 | Enhanced instructions with clear checklists |
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
  "enforcement": "balanced",
  "updated": "$(date +%Y-%m-%d)",
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
---
description: Initialize ContextVault in current project
---

# /ctx-init

Initialize ContextVault documentation system in the current project.

## Usage

```
/ctx-init
```

---

## CRITICAL INSTRUCTIONS

**You MUST complete ALL steps below. DO NOT skip any step.**

**The MOST important step is Step 1 - updating ./CLAUDE.md. This MUST be done FIRST.**

---

## Step 1: UPDATE ./CLAUDE.md (MANDATORY - DO THIS FIRST!)

> **⚠️ THIS IS THE MOST CRITICAL STEP. DO NOT SKIP. DO NOT PROCEED TO OTHER STEPS UNTIL THIS IS DONE.**

The file `./CLAUDE.md` in the **project root** (NOT .claude/CLAUDE.md) MUST contain ContextVault instructions.

### Action Required:

**A) First, check if `./CLAUDE.md` exists:**

Use the Read tool to check if `./CLAUDE.md` exists in the project root.

**B) Then do ONE of these:**

#### OPTION 1: If ./CLAUDE.md does NOT exist → CREATE IT

Use the **Write tool** to create `./CLAUDE.md` with this EXACT content:

```markdown
# Project Instructions

## 🚨 CONTEXTVAULT - MANDATORY (DO NOT SKIP!) 🚨

**STOP. READ THIS. FOLLOW IT.**

### ⚡ AFTER EVERY TASK - DOCUMENT IMMEDIATELY ⚡

┌─────────────────────────────────────────────────────────────────┐
│  COMPLETED A TASK? → DOCUMENT IT NOW!                           │
│                                                                 │
│  ✅ Fixed a bug?        → /ctx-error or /ctx-doc                │
│  ✅ Made a decision?    → /ctx-decision                         │
│  ✅ Learned something?  → /ctx-doc                              │
│  ✅ Found useful code?  → /ctx-doc type=snippet                 │
│  ✅ Explored codebase?  → /ctx-doc type=intel                   │
│  ✅ Ending session?     → /ctx-handoff                          │
│                                                                 │
│  💭 Not every edit needs documenting                             │
│  💭 Document at milestones, not mid-edit                         │
│  💭 Skip if nothing meaningful was learned                       │
└─────────────────────────────────────────────────────────────────┘

### SESSION START (AUTOMATIC):
1. Read `./.claude/vault/index.md` immediately
2. Review what's already documented
3. Use that knowledge in your work

### WHEN TO DOCUMENT:
- Feature complete → /ctx-doc
- Bug fix solved → /ctx-error
- Architecture decision → /ctx-decision
- Session ending → /ctx-handoff
- NOT: trivial edits, version bumps, mid-refactor

### RULES:
- Project docs → `./.claude/vault/` with P### prefix
- ALWAYS update index after doc changes
- Search before creating (no duplicates)

### COMMANDS:
`/ctx-doc` `/ctx-error` `/ctx-decision` `/ctx-handoff` `/ctx-search` `/ctx-read` `/ctx-bootstrap` `/ctx-plan`
```

#### OPTION 2: If ./CLAUDE.md EXISTS but has NO "ContextVault" section → APPEND TO IT

1. Use the **Read tool** to read the current content of `./CLAUDE.md`
2. Check if the text "ContextVault" appears anywhere in the file
3. If "ContextVault" is NOT found, use the **Edit tool** to APPEND this block at the END of the file:

```markdown

---

## 🚨 CONTEXTVAULT - MANDATORY (DO NOT SKIP!) 🚨

**STOP. READ THIS. FOLLOW IT.**

### ⚡ AFTER EVERY TASK - DOCUMENT IMMEDIATELY ⚡

┌─────────────────────────────────────────────────────────────────┐
│  COMPLETED A TASK? → DOCUMENT IT NOW!                           │
│                                                                 │
│  ✅ Fixed a bug?        → /ctx-error or /ctx-doc                │
│  ✅ Made a decision?    → /ctx-decision                         │
│  ✅ Learned something?  → /ctx-doc                              │
│  ✅ Found useful code?  → /ctx-doc type=snippet                 │
│  ✅ Explored codebase?  → /ctx-doc type=intel                   │
│  ✅ Ending session?     → /ctx-handoff                          │
│                                                                 │
│  💭 Not every edit needs documenting                             │
│  💭 Document at milestones, not mid-edit                         │
│  💭 Skip if nothing meaningful was learned                       │
└─────────────────────────────────────────────────────────────────┘

### SESSION START (AUTOMATIC):
1. Read `./.claude/vault/index.md` immediately
2. Review what's already documented
3. Use that knowledge in your work

### WHEN TO DOCUMENT:
- Feature complete → /ctx-doc
- Bug fix solved → /ctx-error
- Architecture decision → /ctx-decision
- Session ending → /ctx-handoff
- NOT: trivial edits, version bumps, mid-refactor

### RULES:
- Project docs → `./.claude/vault/` with P### prefix
- ALWAYS update index after doc changes
- Search before creating (no duplicates)

### COMMANDS:
`/ctx-doc` `/ctx-error` `/ctx-decision` `/ctx-handoff` `/ctx-search` `/ctx-read` `/ctx-bootstrap` `/ctx-plan`
```

#### OPTION 3: If ./CLAUDE.md EXISTS and ALREADY has "ContextVault" section → SKIP

Inform user: "ContextVault instructions already present in ./CLAUDE.md"

### ⛔ STOP CHECK:

**Before proceeding to Step 2, VERIFY:**
- [ ] You used Read tool to check ./CLAUDE.md
- [ ] You used Write or Edit tool to add ContextVault section (or confirmed it exists)
- [ ] The ./CLAUDE.md file NOW contains "ContextVault - MANDATORY" section

**DO NOT PROCEED if ./CLAUDE.md was not updated!**

---

## Step 2: Check if vault already exists

Check if `.claude/vault/index.md` already exists in the current project.

- If EXISTS: Skip to Step 5 (vault already set up)
- If NOT EXISTS: Continue to Step 3

---

## Step 3: Create folder structure

Use Bash tool to run:
```bash
mkdir -p .claude/vault/archive
```

---

## Step 4: Create project index

Use the **Write tool** to create `.claude/vault/index.md` with this content:

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

Also create `.claude/vault/_template.md` with the standard document template.

---

## Step 5: Create project hooks (IMPORTANT!)

Create `.claude/settings.json` with project-specific hooks for automatic enforcement.

### Action Required:

**A) Check if `.claude/settings.json` exists:**

**B) If it does NOT exist → CREATE IT:**

Use the **Write tool** to create `.claude/settings.json` with this EXACT content:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/ctx-session-start.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/ctx-stop-enforcer.sh",
            "blocking": true
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/ctx-post-tool.sh",
            "blocking": true
          }
        ]
      },
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/ctx-post-tool.sh",
            "blocking": true
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/ctx-post-tool.sh"
          }
        ]
      },
      {
        "matcher": "TodoWrite",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/ctx-post-tool.sh"
          }
        ]
      },
      {
        "matcher": "Read",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/ctx-post-tool.sh"
          }
        ]
      },
      {
        "matcher": "Grep",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/ctx-post-tool.sh"
          }
        ]
      },
      {
        "matcher": "Glob",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/ctx-post-tool.sh"
          }
        ]
      },
      {
        "matcher": "WebSearch",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/ctx-post-tool.sh"
          }
        ]
      },
      {
        "matcher": "WebFetch",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/ctx-post-tool.sh"
          }
        ]
      }
    ]
  }
}
```

**C) If `.claude/settings.json` EXISTS:**

1. Read the existing content
2. Check if "Project ContextVault" appears in any hook command
3. If NOT found, you need to merge the hooks - add the SessionStart and Stop hooks to the existing hooks object
4. If already present, inform user: "Project hooks already configured"

---

## Step 6: Install Git Pre-Commit Hook (Documentation Reminder)

> **Purpose**: Automatically remind Claude to document when user commits code

**A) Check if this is a git repository:**

Use Bash tool to run:
```bash
[ -d .git ] && echo "IS_GIT_REPO" || echo "NOT_GIT_REPO"
```

**B) If IS_GIT_REPO → Install the pre-commit hook:**

Use the **Write tool** to create `.git/hooks/pre-commit` with this EXACT content:

```bash
#!/bin/bash
# ContextVault Pre-Commit Documentation Reminder
# This hook reminds Claude to document changes being committed

# Get summary of staged changes
STAGED_FILES=$(git diff --cached --name-only 2>/dev/null | head -10)
STAGED_COUNT=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')

if [ "$STAGED_COUNT" -gt 0 ]; then
    echo ""
    echo "📝 ContextVault Documentation Reminder"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   Committing $STAGED_COUNT file(s):"
    echo "$STAGED_FILES" | sed 's/^/   • /'
    [ "$STAGED_COUNT" -gt 10 ] && echo "   ... and $((STAGED_COUNT - 10)) more"
    echo ""
    echo "   ✍️  Did you document what you learned/changed?"
    echo "   💡 If not, run /ctx-doc after this commit"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
fi

# Always allow commit to proceed
exit 0
```

Then make it executable:
```bash
chmod +x .git/hooks/pre-commit
```

**C) If NOT_GIT_REPO → Skip this step:**

Inform user: "Not a git repository - skipping pre-commit hook installation"

**D) If `.git/hooks/pre-commit` already exists:**

1. Read the existing file
2. Check if "ContextVault" appears in it
3. If NOT found, BACKUP the existing hook and create a wrapper:
   - Rename existing to `.git/hooks/pre-commit.original`
   - Create new pre-commit that runs BOTH the original AND the ContextVault reminder
4. If "ContextVault" already present, inform user: "Git hook already installed"

---

## Step 7: Display completion message

**Only show this AFTER you have completed Steps 1-6:**

```
✅ ContextVault initialized for this project!

Created/Updated:
├── ./CLAUDE.md                ← ContextVault instructions (FORCES ctx usage!)
├── .claude/vault/index.md     ← Project documentation index
├── .claude/vault/_template.md ← Document template
├── .claude/settings.json      ← Project hooks (SessionStart + Stop + PostToolUse)
└── .git/hooks/pre-commit      ← Git hook (documentation reminder on commit)

🪝 Hooks installed:
   SessionStart → Reminds to read project vault
   Stop         → Reminds to document learnings
   Git Commit   → Reminds to document changes (shows in Claude's context!)

Claude will now AUTOMATICALLY:
• Read project vault at session start (enforced by hook!)
• Document findings without asking
• Use P### prefix for project docs
• See documentation reminder when you run git commit

Run /ctx-status to verify setup.
```

---

## Final Verification Checklist

Before reporting success, confirm ALL of these are true:

- [ ] `./CLAUDE.md` exists in project root AND contains "ContextVault - MANDATORY" section
- [ ] `.claude/vault/index.md` exists
- [ ] `.claude/vault/_template.md` exists
- [ ] `.claude/settings.json` exists AND contains project hooks
- [ ] `.git/hooks/pre-commit` exists (if this is a git repo)

**If any checkbox is false, go back and complete that step!**
CMD_EOF
}

create_cmd_ctx_status() {
    # Use unquoted CMD_EOF to allow VERSION substitution
    cat << CMD_EOF
---
description: Show vault status and statistics
---

# /ctx-status

Show current ContextVault documentation system status with version and update check.

## Usage

\`\`\`
/ctx-status
\`\`\`

## Instructions

When this command is invoked, perform the following:

### Step 1: Get Version Info

Current installed version: **v${VERSION}**

Check for updates by reading \`~/.claude/hooks/ctx-session-start.sh\` and extracting the VERSION.
Then check if newer version is available at GitHub (optional - only if user asks).

### Step 2: Check Current Mode

Read the mode from \`~/.claude/CLAUDE.md\` (look for MODE: line) or default to "local".
Modes: \`full\` (both), \`local\` (project only), \`global\` (global only)

### Step 3: Check Global ContextVault

Read \`~/.claude/vault/index.md\` and report:
- Number of global documents (G### entries in the Active Documents table)
- Status of global system

### Step 4: Check Project ContextVault

Check if \`.claude/vault/index.md\` exists in current project:
- If EXISTS: Read and report number of project documents (P### entries)
- If NOT EXISTS: Report "Not initialized - run /ctx-init"

### Step 5: Display Status Summary

Format output like:

\`\`\`
┌─────────────────────────────────────────────────────────────┐
│  🏰 CONTEXTVAULT STATUS                          v${VERSION}  │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ⚙️  MODE: local (project-focused)                          │
│                                                              │
│  📚 GLOBAL (~/.claude/vault/)                               │
│  ├── Status: Active                                         │
│  ├── Documents: X / 50 max                                  │
│  └── Last updated: YYYY-MM-DD                               │
│                                                              │
│  📂 PROJECT (./.claude/vault/)                              │
│  ├── Status: Active / Not Initialized                       │
│  ├── Documents: X / 50 max                                  │
│  └── Last updated: YYYY-MM-DD                               │
│                                                              │
│  🔄 UPDATE: ✅ Up to date / ⬆️ v1.X.X available             │
│                                                              │
│  QUICK ACTIONS:                                              │
│  • /ctx-mode     - Change mode (full/local/global)          │
│  • /ctx-init     - Initialize project ContextVault          │
│  • /ctx-new      - Create new document                      │
│  • /ctx-search   - Search both indexes                      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
\`\`\`

### Step 6: Check for Updates (Optional)

If checking for updates, fetch the latest version from:
\`https://raw.githubusercontent.com/ahmadzein/ContextVault/main/install-contextvault.sh\`

Look for the VERSION= line and compare with current v${VERSION}.
If newer version available, show upgrade command.
CMD_EOF
}

create_cmd_ctx_mode() {
    cat << 'CMD_EOF'
---
description: Switch between local, global, or full mode
---

# /ctx-mode

Toggle ContextVault mode, enforcement level, and limits.

## Usage

```
/ctx-mode [mode|enforcement|limit] [value]
```

## Arguments

- No args: Show current mode, enforcement, and limits
- `mode`: `full`, `local`, `global` - change mode
- `enforcement`: `light`, `balanced`, `strict` - change enforcement level
- `limit`: `max-global`, `max-project`, `max-lines`, `max-summary` - change limits

## Modes

| Mode | Description | What to Read |
|------|-------------|--------------|
| `local` | Project-only, ignore global (DEFAULT) | Only `./.claude/vault/index.md` |
| `full` | Use both global and project docs | Both indexes |
| `global` | Global-only, ignore project | Only `~/.claude/vault/index.md` |

## Enforcement Levels

| Level | PostToolUse (Edit/Write) | Research Nudge | Stop Hook |
|-------|--------------------------|----------------|-----------|
| `light` | No mid-work blocking | Disabled | Smart block (significant work only) |
| `balanced` | Block after 8 edits, 2+ files (DEFAULT) | Nudge after 20 lookups, 5+ areas | Smart block (significant work only) |
| `strict` | Block after 4 edits, 2+ files | Nudge after 12 lookups, 3+ areas | Smart block (significant work only) |

## Instructions

When this command is invoked:

### If No Argument: Show Current Settings

Read `~/.claude/vault/settings.json` and display:

```
┌─────────────────────────────────────────────────────────────┐
│                 CONTEXTVAULT SETTINGS                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  MODE:        [LOCAL / FULL / GLOBAL]                       │
│  ENFORCEMENT: [LIGHT / BALANCED / STRICT]                   │
│                                                              │
│  LIMITS:                                                     │
│  ├── Max global docs:   50                                  │
│  ├── Max project docs:  50                                  │
│  ├── Max doc lines:     100                                 │
│  └── Max summary words: 15                                  │
│                                                              │
│  COMMANDS:                                                   │
│  • /ctx-mode local              → Project only (default)    │
│  • /ctx-mode full               → Use global + project      │
│  • /ctx-mode global             → Global only               │
│  • /ctx-mode enforcement light  → No mid-work blocking      │
│  • /ctx-mode enforcement balanced → Block after 8 edits     │
│  • /ctx-mode enforcement strict → Block after 4 edits       │
│  • /ctx-mode max-global 100     → Change global doc limit   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### If Mode Argument: Set Mode

1. Validate mode is one of: `full`, `local`, `global`
2. Update `~/.claude/vault/settings.json` mode field
3. Confirm: `✓ ContextVault mode changed to [MODE]`

### If Enforcement Argument: Set Enforcement Level

1. Validate level is one of: `light`, `balanced`, `strict`
2. Update `~/.claude/vault/settings.json` enforcement field
3. Confirm: `✓ Enforcement changed to [LEVEL] — [description]`

Descriptions:
- `light`: "No mid-work blocking. Stop hook catches significant work at session end."
- `balanced`: "Blocks after 8 edits across 2+ files if undocumented."
- `strict`: "Blocks after 4 edits across 2+ files if undocumented."

### If Limit Argument: Set Limit

Valid limit commands:
- `/ctx-mode max-global 100` → Set max global docs to 100
- `/ctx-mode max-project 30` → Set max project docs to 30
- `/ctx-mode max-lines 150` → Set max lines per doc to 150
- `/ctx-mode max-summary 20` → Set max summary words to 20

Update `~/.claude/vault/settings.json` limits section and confirm.

### Behavior Based on Mode

**When mode is `local` (default):**
- Skip global index entirely
- Only read `./.claude/vault/index.md`
- New docs only go to project

**When mode is `full`:**
- Read `~/.claude/vault/index.md` first
- Then read `./.claude/vault/index.md`
- New docs can go to either location

**When mode is `global`:**
- Only read `~/.claude/vault/index.md`
- Skip project index
- New docs only go to global

## Settings File

`~/.claude/vault/settings.json`
```json
{
  "mode": "local",
  "enforcement": "balanced",
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
/ctx-mode                        → Show current settings
/ctx-mode local                  → Switch to project-only (default)
/ctx-mode full                   → Switch to global + project
/ctx-mode enforcement light      → Disable mid-work blocking
/ctx-mode enforcement balanced   → Default (block after 8 edits)
/ctx-mode enforcement strict     → Aggressive (block after 4 edits)
/ctx-mode max-global 100         → Allow up to 100 global docs
```
CMD_EOF
}

create_cmd_ctx_help() {
    cat << 'CMD_EOF'
---
description: Show all ContextVault commands and usage
---

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
│  /ctx-upgrade   Upgrade existing project to latest version      │
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
│  SHARING & IMPORT                                                │
│  ─────────────────────────────────────────────────────────────  │
│  /ctx-share     Export vault to ZIP (-local/-global/-all)       │
│  /ctx-import    Import vault from shared ZIP file               │
│                                                                  │
│  SESSION & CODEBASE                                              │
│  ─────────────────────────────────────────────────────────────  │
│  /ctx-handoff   Generate session handoff summary                 │
│  /ctx-intel     Generate codebase intelligence file              │
│  /ctx-bootstrap Auto-scan codebase and generate docs (NEW!)      │
│  /ctx-plan      Document multi-step implementation plans         │
│  /ctx-error     Capture error and solution to database           │
│  /ctx-snippet   Save reusable code snippet with context          │
│  /ctx-decision  Log decision with rationale and alternatives     │
│                                                                  │
│  VAULT MAINTENANCE                                               │
│  ─────────────────────────────────────────────────────────────  │
│  /ctx-health    Diagnose vault health issues                     │
│  /ctx-note      Quick one-liner notes (no full doc needed)       │
│  /ctx-changelog Generate changelog from doc history              │
│  /ctx-link      Analyze and create doc bidirectional links       │
│                                                                  │
│  KNOWLEDGE TOOLS                                                 │
│  ─────────────────────────────────────────────────────────────  │
│  /ctx-quiz      Quiz yourself on project knowledge               │
│  /ctx-explain   Generate comprehensive project explanation       │
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
│  6. /ctx-share     → Share knowledge with team (optional)       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

Full documentation: ~/.claude/CLAUDE.md
```
CMD_EOF
}

create_cmd_ctx_new() {
    cat << 'CMD_EOF'
---
description: Create a new document with guided routing
---

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
---
description: Document a learning, exploration finding, or code snippet
---

# /ctx-doc

Document learnings, codebase exploration findings, or reusable code snippets.

## Usage

```
/ctx-doc                    # Default: learning (project vault)
/ctx-doc type=intel         # Codebase exploration (project vault)
/ctx-doc type=snippet       # Reusable code (global vault)
```

## Document Types

| Type | Use When | Default Vault |
|------|----------|---------------|
| `learning` | Learned something, built a feature | project |
| `intel` | Explored codebase, found patterns | project |
| `snippet` | Found reusable code worth saving | global |

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
---
description: Update an existing document by ID
---

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
---
description: Search across vault documents
---

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
---
description: Read a document by ID
---

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

create_cmd_ctx_share() {
    cat << 'CMD_EOF'
---
description: Export vault docs for sharing
---

# /ctx-share

Export ContextVault documents to a shareable ZIP file with optional cloud upload.

## Usage

```
/ctx-share [-global] [-local] [-all] [-upload] [-email]
```

## Scope Flags (pick one)

- `-local` (default): Export project vault only (./.claude/vault/)
- `-global`: Export global vault only (~/.claude/vault/)
- `-all`: Export both global and project vaults

## Sharing Flags (optional)

- `-upload`: Upload to transfer.sh and get shareable URL (free, no signup, 14-day link)
- `-email`: Open default email client with file attached (macOS/Linux)

If no flags specified, defaults to `-local` with local save only.

## Storage Location

Exports are saved to `./ctx-export/` in project root (git-trackable).

## File Naming Convention

Format: `ctx_{type}_{project}_{YYYYMMDD_HHMMSS}.zip`

Examples:
- `ctx_local_myproject_20260118_143022.zip` (local export from "myproject")
- `ctx_global_20260118_143022.zip` (global only, no project name)
- `ctx_all_myproject_20260118_143022.zip` (both vaults from "myproject")

## Instructions

When this command is invoked, perform the following:

### Step 1: Parse Flags

Determine scope and sharing options:
- Scope: `-local` (default), `-global`, or `-all`
- Sharing: `-upload` and/or `-email` (both optional)

### Step 2: Validate Source

Check that the requested vaults exist and have documents:
- For local: Check `./.claude/vault/index.md` exists
- For global: Check `~/.claude/vault/index.md` exists

If vault doesn't exist or is empty, warn user and abort.

### Step 3: Determine File Name

Use Bash to get project name and create filename:

```bash
# Get project name from current directory
project_name=$(basename "$(pwd)" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')
timestamp=$(date +%Y%m%d_%H%M%S)

# Build filename based on scope
# -local or default: ctx_local_{project}_{timestamp}.zip
# -global: ctx_global_{timestamp}.zip
# -all: ctx_all_{project}_{timestamp}.zip
```

### Step 4: Create Export Directory

```bash
# Create ctx-export folder in project root
mkdir -p ./ctx-export

# Create temp working directory
temp_dir="/tmp/ctx_export_${timestamp}"
mkdir -p "$temp_dir"
```

### Step 5: Build Export Structure

Create structure in temp directory:

```
/tmp/ctx_export_YYYYMMDD_HHMMSS/
├── manifest.json
├── global/           (if -global or -all)
│   ├── index.md
│   └── G*.md files
└── project/          (if -local or -all)
    ├── index.md
    └── P*.md files
```

Use Bash tool to copy files:
```bash
# For global
if [[ "$scope" == "global" || "$scope" == "all" ]]; then
    mkdir -p "$temp_dir/global"
    cp ~/.claude/vault/index.md "$temp_dir/global/"
    cp ~/.claude/vault/G*.md "$temp_dir/global/" 2>/dev/null
fi

# For local/project
if [[ "$scope" == "local" || "$scope" == "all" ]]; then
    mkdir -p "$temp_dir/project"
    cp ./.claude/vault/index.md "$temp_dir/project/"
    cp ./.claude/vault/P*.md "$temp_dir/project/" 2>/dev/null
fi
```

### Step 6: Generate manifest.json

Create manifest.json with metadata:

```json
{
  "contextvault_version": "1.6.9",
  "export_version": "1.1",
  "exported_at": "2026-01-18T12:34:56Z",
  "scope": "all",
  "includes": {
    "global": true,
    "project": true
  },
  "counts": {
    "global_docs": 5,
    "project_docs": 3
  },
  "source": {
    "project_name": "my-project",
    "project_path": "/path/to/project",
    "exported_by": "user"
  },
  "documents": {
    "global": ["G001_topic.md", "G002_topic.md"],
    "project": ["P001_topic.md", "P002_topic.md"]
  }
}
```

### Step 7: Create ZIP File

```bash
# Create ZIP in ctx-export folder
cd /tmp
zip -r "./ctx-export/${filename}" "ctx_export_${timestamp}/"

# Move to project ctx-export folder
mv "/tmp/ctx-export/${filename}" "./ctx-export/"
```

Or simpler:
```bash
cd /tmp
zip -r "${filename}" "ctx_export_${timestamp}/"
mv "/tmp/${filename}" "./ctx-export/"
```

### Step 8: Handle -upload Flag (if specified)

If `-upload` flag is present, upload to transfer.sh:

```bash
# Upload to transfer.sh (free, no API key, 14-day retention)
upload_url=$(curl --upload-file "./ctx-export/${filename}" "https://transfer.sh/${filename}" 2>/dev/null)

# transfer.sh returns the download URL directly
echo "Upload URL: $upload_url"
```

Display:
```
📤 Uploaded to transfer.sh!

🔗 Shareable Link (valid 14 days):
   https://transfer.sh/abc123/ctx_local_myproject_20260118_143022.zip

📋 Copy this link and share via:
   • Slack/Teams message
   • Email
   • Any chat app

📥 Recipient imports with:
   curl -O <link>
   /ctx-import ./ctx_local_myproject_20260118_143022.zip
```

### Step 9: Handle -email Flag (if specified)

If `-email` flag is present, open default email client:

**macOS:**
```bash
open "mailto:?subject=ContextVault%20Export%20-%20${project_name}&body=I'm%20sharing%20my%20ContextVault%20documentation.%0A%0AFile:%20${filename}%0ALocation:%20$(pwd)/ctx-export/${filename}%0A%0AImport%20with:%20/ctx-import%20path/to/file.zip"
```

**Linux:**
```bash
xdg-open "mailto:?subject=ContextVault%20Export%20-%20${project_name}&body=..."
```

Note: Email clients can't auto-attach files via mailto, so instruct user to attach manually.

Display:
```
📧 Email client opened!

Please attach this file manually:
   ./ctx-export/${filename}

The email body contains import instructions for the recipient.
```

### Step 10: Display Result

```
┌─────────────────────────────────────────────────────────────────┐
│  ✅ CONTEXTVAULT EXPORT COMPLETE                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  📦 Exported:                                                    │
│     Scope: local (project only)                                  │
│     Project docs: 5 documents                                    │
│                                                                  │
│  📁 Saved to:                                                    │
│     ./ctx-export/ctx_local_myproject_20260118_143022.zip        │
│     Size: 12.3 KB                                                │
│                                                                  │
│  📤 Share options:                                               │
│     • Run again with -upload for shareable link                  │
│     • Run again with -email to open email client                 │
│     • Manual: attach file to Slack/Teams/Email                   │
│                                                                  │
│  📥 Import command (for recipient):                              │
│     /ctx-import path/to/ctx_local_myproject_20260118_143022.zip │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

If `-upload` was used, also show:
```
│  🔗 Shareable Link (14 days):                                    │
│     https://transfer.sh/abc123/ctx_local_myproject_....zip      │
```

### Step 11: Cleanup

Remove temporary directory:
```bash
rm -rf "/tmp/ctx_export_${timestamp}"
```

## Examples

```
/ctx-share                    → Export project vault, save locally
/ctx-share -local             → Same as above
/ctx-share -global            → Export global vault only
/ctx-share -all               → Export both vaults
/ctx-share -upload            → Export project + upload to transfer.sh
/ctx-share -all -upload       → Export both + upload
/ctx-share -local -email      → Export project + open email client
/ctx-share -all -upload -email → Export both + upload + email
```

## Output Files

All exports saved to `./ctx-export/` folder:
```
./ctx-export/
├── ctx_local_myproject_20260118_143022.zip
├── ctx_all_myproject_20260119_091500.zip
└── ctx_global_20260120_160000.zip
```

This folder can be:
- Git tracked (for team sharing via repo)
- Git ignored (add to .gitignore if preferred)
CMD_EOF
}

create_cmd_ctx_import() {
    cat << 'CMD_EOF'
---
description: Import external documentation into vault
---

# /ctx-import

Import ContextVault documents from a shared ZIP file.

## Usage

```
/ctx-import <path-to-zip>
```

## Arguments

- `path-to-zip`: Path to the exported ContextVault ZIP file

## Instructions

When this command is invoked, perform the following:

### Step 1: Validate ZIP File

Check that the file exists and is a valid ZIP:

```bash
# Check file exists
ls -la /path/to/file.zip

# Validate ZIP integrity
unzip -t /path/to/file.zip
```

If invalid, show error: "Invalid or corrupted ZIP file"

### Step 2: Extract and Read Manifest

Use Bash to extract to temp directory:

```bash
timestamp=$(date +%s)
mkdir -p /tmp/ctx_import_${timestamp}
unzip /path/to/file.zip -d /tmp/ctx_import_${timestamp}
```

Then read manifest.json to understand contents:
- Check `contextvault_version` for compatibility
- Read `includes` to know what's in the export
- Read `counts` and `documents` for details

### Step 3: Show Import Preview

Display what will be imported:

```
📦 ContextVault Import Preview
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Source: contextvault_export_20260118_123456.zip
Exported: 2026-01-18 12:34:56
Version: 1.6.9

📚 Contents:
├── Global: X documents
│   ├── G001_docker_tips.md
│   ├── G002_git_workflows.md
│   └── ...
└── Project: Y documents
    ├── P001_auth_system.md
    └── ...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 4: Check for Conflicts

Compare imported documents with existing ones:

For global imports:
- Check each G###.md against ~/.claude/vault/
- List files that already exist

For project imports:
- Check each P###.md against ./.claude/vault/
- List files that already exist

If conflicts found, display:
```
⚠️ Conflicts Detected:
   Global:
   • G001 exists: "Docker Tips" (local) vs "Container Patterns" (import)
   Project:
   • P002 exists: "Auth System" (local) vs "Authentication" (import)
```

### Step 5: Ask Conflict Resolution

Use AskUserQuestion tool if conflicts exist:

```
How should I handle conflicting documents?

Options:
1. Skip - Keep existing, only import new documents
2. Overwrite - Replace existing with imported (⚠️ destructive)
3. Merge - Import new docs, keep existing, merge indexes (recommended)
4. Backup & Overwrite - Backup existing first, then overwrite
```

### Step 6: Perform Import

Based on user choice:

**Skip Mode:**
```bash
# Only copy non-existing files
for file in import/global/*.md; do
  [ ! -f ~/.claude/vault/$(basename $file) ] && cp $file ~/.claude/vault/
done
```

**Overwrite Mode:**
```bash
# Copy all, overwriting existing
cp -f import/global/*.md ~/.claude/vault/
```

**Merge Mode:**
- Copy non-conflicting documents
- Keep existing conflicting documents
- Merge index.md: Add new entries from import, keep existing entries

**Backup & Overwrite:**
```bash
# Backup first
cp -r ~/.claude/vault ~/.contextvault_backup_import_$(date +%Y%m%d_%H%M%S)
# Then overwrite
cp -f import/global/*.md ~/.claude/vault/
```

### Step 7: Update Indexes

After importing, update the index.md files:
- Add entries for newly imported documents
- Update Quick Stats counts
- Update "Last updated" date

For merge mode, combine tables:
- Read existing index
- Read imported index
- Merge Active Documents tables
- Merge Related Terms Map tables
- Write combined index

### Step 8: Display Result

```
✅ ContextVault Import Complete!

📥 Imported:
   Global:  X documents (Y new, Z skipped)
   Project: X documents (Y new, Z skipped)

📁 Locations:
   Global:  ~/.claude/vault/
   Project: ./.claude/vault/

✅ Indexes updated

Run /ctx-status to verify.
```

### Step 9: Cleanup

Remove temporary extraction directory:
```bash
rm -rf /tmp/ctx_import_${timestamp}
```

## Conflict Resolution Details

| Mode | Existing Docs | Imported Docs | Index |
|------|---------------|---------------|-------|
| Skip | Kept | Only new IDs imported | Merged (new only) |
| Overwrite | Replaced | All imported | Replaced |
| Merge | Kept | Only new IDs imported | Merged |
| Backup+Overwrite | Backed up then replaced | All imported | Replaced |

## Examples

```
/ctx-import ~/Desktop/contextvault_export_20260118_123456.zip
/ctx-import /path/to/team-context.zip
/ctx-import ./shared-knowledge.zip
```
CMD_EOF
}

create_cmd_ctx_handoff() {
    cat << 'CMD_EOF'
---
description: Create session handoff summary for continuity
---

# /ctx-handoff

Generate a session handoff summary before ending your work. This ensures the next session (or another team member) can pick up exactly where you left off.

## Usage

```
/ctx-handoff
```

---

## When to Use

Run this command:
- Before ending a long session
- When switching context to another task
- Before handing off to another team member
- When context is getting too long and you need to compact

---

## CRITICAL INSTRUCTIONS

**You MUST generate a handoff summary. This is NOT optional.**

---

## Step 1: Gather Session Context

Review your conversation to identify:
1. **What was completed** - List finished tasks
2. **What's in progress** - List unfinished work with current state
3. **Key decisions made** - Important choices and WHY
4. **Blockers/Issues** - Problems encountered and status
5. **Next steps** - Clear action items for continuation

---

## Step 2: Write Handoff Document

Use the **Write tool** to create/update `.claude/vault/session_handoff.md`:

```markdown
# Session Handoff

**Last Updated:** [TODAY'S DATE AND TIME]
**Session Focus:** [Brief description]

---

## Completed This Session

- [Task 1]: [Brief outcome]
- [Task 2]: [Brief outcome]

---

## In Progress

- [Task]: [Current state, what's left to do]
  - Files touched: [list]
  - Next action: [specific]

---

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| [What] | [Why] |

---

## Blockers / Issues

- [Issue]: [Status and workaround if any]

---

## Next Steps

1. [ ] [Specific action item]
2. [ ] [Specific action item]
3. [ ] [Specific action item]

---

## Files Modified This Session

- `path/to/file.ext` - [what changed]

---

## Notes for Next Session

[Any context that would help the next session start quickly]
```

---

## Step 3: Confirm Completion

After writing the handoff document, output:

```
✅ Session Handoff Complete!

📄 Saved to: .claude/vault/session_handoff.md

Summary:
• Completed: X tasks
• In Progress: Y tasks
• Next Steps: Z action items

💡 The next session can read this file to continue seamlessly.
```

---

## Important Notes

- This file is ALWAYS overwritten (not appended) - it's the CURRENT state
- Keep it concise - max 80 lines
- Focus on actionable information
- Include file paths when relevant
- Be specific about next steps
CMD_EOF
}

create_cmd_ctx_intel() {
    cat << 'CMD_EOF'
---
description: Document codebase exploration findings
---

# /ctx-intel

Generate a codebase intelligence file that helps Claude understand the project structure instantly.

## Usage

```
/ctx-intel
```

---

## What This Creates

A `.claude/codebase.md` file containing:
1. **Languages & Frameworks** - What tech stack is used
2. **Key Files** - Entry points, configs, important files
3. **Architecture** - How the code is organized
4. **Patterns** - Common patterns used in the codebase
5. **Dependencies** - Key packages and their purposes

---

## CRITICAL INSTRUCTIONS

**You MUST analyze the codebase and generate an intelligence file.**

---

## Step 1: Detect Languages and Frameworks

Analyze the project to identify:

**Languages** (check file extensions):
- `.js`, `.ts`, `.tsx` → JavaScript/TypeScript
- `.py` → Python
- `.go` → Go
- `.rs` → Rust
- `.java` → Java
- `.rb` → Ruby
- `.php` → PHP
- `.cs` → C#
- `.sh` → Shell

**Frameworks** (check package files and patterns):
- `package.json` → Check for React, Vue, Next.js, Express, etc.
- `requirements.txt`, `pyproject.toml` → Django, Flask, FastAPI
- `go.mod` → Check imports
- `Cargo.toml` → Check dependencies
- `Gemfile` → Rails, Sinatra

---

## Step 2: Map Key Files

Identify and list:
- **Entry points**: main.*, index.*, app.*, server.*
- **Configuration**: .env, config/, settings.*
- **Package files**: package.json, requirements.txt, go.mod, etc.
- **Build config**: webpack.*, vite.config.*, tsconfig.json
- **CI/CD**: .github/workflows/, .gitlab-ci.yml, Dockerfile

---

## Step 3: Understand Architecture

Determine:
- **Project type**: CLI, API, Web app, Library, Monorepo
- **Directory structure**: src/, lib/, app/, components/, etc.
- **State management**: Redux, Context, Zustand, etc.
- **Data layer**: ORM, raw SQL, API calls
- **Testing**: Jest, Pytest, Go test, etc.

---

## Step 4: Write Intelligence File

Use the **Write tool** to create `.claude/codebase.md`:

```markdown
# Codebase Intelligence

**Generated:** [TODAY'S DATE]
**Project:** [Project name from package.json or directory]

---

## Tech Stack

| Category | Technology |
|----------|------------|
| Language | [Primary language] |
| Framework | [Main framework] |
| Runtime | [Node, Python, etc.] |
| Package Manager | [npm, yarn, pip, etc.] |

---

## Key Files

| File | Purpose |
|------|---------|
| `[path]` | [What it does] |
| `[path]` | [What it does] |

---

## Directory Structure

```
[Show relevant directory tree]
```

### Purpose of Key Directories
- `src/` - [Purpose]
- `lib/` - [Purpose]
- `tests/` - [Purpose]

---

## Architecture Patterns

- **[Pattern]**: [Where/how it's used]
- **[Pattern]**: [Where/how it's used]

---

## Dependencies (Key)

| Package | Purpose |
|---------|---------|
| [name] | [What it's used for] |

---

## Entry Points

- **Main**: `[file]` - [What happens here]
- **API**: `[file]` - [Endpoints defined here]
- **Build**: `[command]` - [What it does]

---

## Common Tasks

| Task | Command |
|------|---------|
| Run dev | `[command]` |
| Build | `[command]` |
| Test | `[command]` |

---

## Notes

[Any quirks, gotchas, or important context]
```

---

## Step 5: Confirm Completion

Output:
```
✅ Codebase Intelligence Generated!

📄 Saved to: .claude/codebase.md

Detected:
• Language: [Primary language]
• Framework: [Main framework]
• Type: [API/Web/CLI/Library]
• Key files: [Count] mapped

💡 Claude will now understand this codebase instantly!
```

---

## When to Run

- After cloning a new repo
- When starting work on unfamiliar codebase
- After major architectural changes
- When onboarding new team members
CMD_EOF
}

create_cmd_ctx_error() {
    cat << 'CMD_EOF'
---
description: Document a bug fix or error resolution
---

# /ctx-error

Capture an error and its solution for future reference. Build a searchable database of problems you've solved.

## Usage

```
/ctx-error [brief error description]
```

---

## When to Use

Run this command when:
- You fixed a tricky bug
- An error took time to diagnose
- The solution wasn't obvious
- You want to remember this fix for next time

---

## CRITICAL INSTRUCTIONS

**Capture errors systematically so they can be found later!**

---

## Step 1: Gather Error Information

Identify and collect:
1. **Error message** - The exact error text
2. **Context** - What you were doing when it occurred
3. **Root cause** - What actually caused the problem
4. **Solution** - How you fixed it
5. **Keywords** - Terms someone might search for

---

## Step 2: Check for Existing Error Doc

Check if `.claude/vault/errors.md` exists:
- If YES: Read it and append new entry
- If NO: Create it with the template below

---

## Step 3: Add Error Entry

Use the **Edit tool** (or Write if creating new) to add to `.claude/vault/errors.md`:

```markdown
# Error Solutions Database

**Last Updated:** [TODAY'S DATE]

> Quick reference for solved problems. Search by error message or keyword.

---

## Errors

### [Error Type/Name] - [Brief Description]
**Date:** [TODAY]
**Keywords:** `keyword1`, `keyword2`, `keyword3`

**Error:**
```
[Exact error message]
```

**Context:**
[What you were doing]

**Cause:**
[Root cause of the error]

**Solution:**
[How to fix it - be specific!]

**Prevention:**
[How to avoid this in future, if applicable]

---

### [Next Error Entry...]
```

---

## Step 4: Update Index

After adding an error, check if the project index has an entry for the errors file:
- If NO entry exists for errors.md, add one to the index
- Summary: "Error solutions database with [N] entries"

---

## Step 5: Confirm Capture

Output:
```
✅ Error Captured!

📄 Added to: .claude/vault/errors.md
🏷️  Keywords: [keywords]

Error: [Brief description]
Solution: [1-line summary]

💡 Search errors.md when you see similar issues!
```

---

## Searching Errors

To find a previously solved error, read `.claude/vault/errors.md` and search for:
- The error message text
- Keywords that describe the problem
- The technology/framework involved

---

## Best Practices

- Use specific, searchable keywords
- Include the EXACT error message
- Be specific about the solution steps
- Add prevention tips when relevant
- Keep entries concise but complete
CMD_EOF
}

create_cmd_ctx_snippet() {
    cat << 'CMD_EOF'
---
description: Save a useful code snippet
---

# /ctx-snippet

Save a reusable code snippet with context about when and how to use it.

## Usage

```
/ctx-snippet [brief description]
```

---

## When to Use

- You wrote code you'll want to reuse
- Found a useful pattern worth remembering
- Solved something that took research to figure out
- Created a utility function others might need

---

## Step 1: Check for Existing Snippets File

Check if `.claude/vault/snippets.md` exists:
- If YES: Read it and append new entry
- If NO: Create it with the template below

---

## Step 2: Add Snippet Entry

Use the **Edit tool** (or Write if creating new) to add to `.claude/vault/snippets.md`:

```markdown
# Code Snippets Library

**Last Updated:** [TODAY'S DATE]

> Reusable code patterns with context. Search by language or keyword.

---

## Snippets

### [Title] - [Language]
**Date:** [TODAY]
**Keywords:** `keyword1`, `keyword2`

**When to use:**
[Describe the situation where this is useful]

**Code:**
```[language]
[The actual code snippet]
```

**Usage example:**
```[language]
[How to use it in context]
```

**Gotchas:**
- [Things to watch out for]

---

### [Next Snippet...]
```

---

## Step 3: Confirm Save

Output:
```
✅ Snippet Saved!

📄 Added to: .claude/vault/snippets.md
🏷️  Keywords: [keywords]
🔤 Language: [language]

Title: [title]

💡 Search snippets.md when you need reusable code!
```
CMD_EOF
}

create_cmd_ctx_decision() {
    cat << 'CMD_EOF'
---
description: Document an architectural or technical decision
---

# /ctx-decision

Log a decision with its rationale and alternatives considered. Track WHY, not just WHAT.

## Usage

```
/ctx-decision [brief description]
```

---

## When to Use

- Made an architectural choice
- Chose between multiple approaches
- Selected a library or tool
- Decided on a design pattern
- Made a tradeoff decision

---

## Step 1: Check for Existing Decisions File

Check if `.claude/vault/decisions.md` exists:
- If YES: Read it and append new entry
- If NO: Create it with the template below

---

## Step 2: Add Decision Entry

Use the **Edit tool** (or Write if creating new) to add to `.claude/vault/decisions.md`:

```markdown
# Decision Log

**Last Updated:** [TODAY'S DATE]

> Architectural decisions and their rationale. Remember WHY we chose what we chose.

---

## Decisions

### [Decision Title]
**Date:** [TODAY]
**Status:** Active | Superseded | Revisit
**Keywords:** `keyword1`, `keyword2`

**Context:**
[What problem were we trying to solve?]

**Decision:**
[What did we decide?]

**Alternatives Considered:**
| Option | Pros | Cons |
|--------|------|------|
| [Chosen] | + [pro] | - [con] |
| [Alt 1] | + [pro] | - [con] |
| [Alt 2] | + [pro] | - [con] |

**Rationale:**
[WHY did we choose this option?]

**Consequences:**
- [What are the implications?]
- [What constraints does this create?]

**Revisit When:**
[Conditions that might make us reconsider]

---

### [Next Decision...]
```

---

## Step 3: Confirm Log

Output:
```
✅ Decision Logged!

📄 Added to: .claude/vault/decisions.md

Decision: [title]
Status: Active

💡 Review decisions.md when architecture questions arise!
```
CMD_EOF
}

create_cmd_ctx_plan() {
    cat << 'CMD_EOF'
---
description: Document implementation plan for multi-step tasks
---

# /ctx-plan

Document your implementation plan when working on complex multi-step tasks. Tracks goals, tasks, progress, and related docs created during the plan.

## Usage

```
/ctx-plan [task name]
```

---

## When to Use

- Starting work on multiple related tasks
- User provided a list of features/changes
- Complex implementation requiring coordination
- When TodoWrite has 3+ items to track

**NOTE:** This command is auto-suggested when hooks detect planning activity.

---

## Step 1: Determine Plan Name

Extract a concise name from what's being planned:
- "Add authentication system" → `auth_system`
- "Refactor API endpoints" → `api_refactor`
- "v2.0 features" → `v2_features`

---

## Step 2: Create/Update Plan Document

Check if `.claude/vault/P###_plan_[name].md` exists:
- If YES: Read and update progress
- If NO: Create with next available P### ID

Use the **Write tool** to create `.claude/vault/P[NEXT_ID]_plan_[name].md`:

```markdown
# P### - Plan: [Task Name]

> **Status:** In Progress
> **Created:** [TODAY]
> **Last Updated:** [TODAY]

---

## Goals

[What we're trying to achieve - 2-3 sentences max]

---

## Tasks

| # | Task | Status | Notes |
|---|------|--------|-------|
| 1 | [Task description] | Pending | |
| 2 | [Task description] | Pending | |
| 3 | [Task description] | Pending | |

**Status Legend:** Pending → In Progress → Done → Blocked

---

## Progress Log

| Date | Update |
|------|--------|
| [TODAY] | Plan created with X tasks |

---

## Docs Created During This Plan

| Doc | Purpose |
|-----|---------|
| (none yet) | |

---

## Notes

[Any important context, constraints, or decisions]

---
```

---

## Step 3: Update Index

Add the plan to `.claude/vault/index.md`:
- ID: The P### you used
- Topic: Plan: [name]
- Status: In Progress
- Summary: Planning [brief description], X tasks

---

## Step 4: Confirm Creation

Output:
```
✅ Plan Created!

📄 Saved to: .claude/vault/P###_plan_[name].md

Tasks: X items tracked
Status: In Progress

💡 Update this plan as you complete tasks!
💡 Link docs you create to this plan.
```

---

## Updating Progress

When completing tasks, update the plan:
1. Change task status: Pending → Done
2. Add progress log entry with date
3. Link any new docs to "Docs Created" section

---

## Completing the Plan

When all tasks are done:
1. Change Status header to "Complete"
2. Update index summary
3. Final progress log entry
CMD_EOF
}

create_cmd_ctx_bootstrap() {
    cat << 'CMD_EOF'
---
description: Auto-scan codebase and generate comprehensive documentation
---

# /ctx-bootstrap

Crawl the entire codebase, detect features/modules, and automatically create complete documentation. Run this after `/ctx-init` to jumpstart your vault.

## Usage

```
/ctx-bootstrap              # Auto-create all docs
/ctx-bootstrap --interactive  # Ask before creating each doc
```

---

## What This Creates

| Document | Purpose |
|----------|---------|
| `P001_architecture.md` | Tech stack, structure, entry points |
| `P00X_[feature].md` | One doc per feature/module detected |
| Updates `index.md` | Adds all new entries automatically |

---

## CRITICAL INSTRUCTIONS

**You MUST scan the codebase and create documentation automatically.**

Check for `--interactive` flag in the user's command:
- **Default (no flag)**: Create all docs automatically
- **With `--interactive`**: Use AskUserQuestion for each feature found

---

## Step 1: Verify Vault Exists

Check if `.claude/vault/index.md` exists:
- If NO: Output "Run /ctx-init first!" and stop
- If YES: Continue

---

## Step 2: Detect Project Type

**Check for package/config files:**

| File | Indicates |
|------|-----------|
| `package.json` | Node.js/JavaScript |
| `requirements.txt` / `pyproject.toml` | Python |
| `go.mod` | Go |
| `Cargo.toml` | Rust |
| `Gemfile` | Ruby |
| `pom.xml` / `build.gradle` | Java |
| `composer.json` | PHP |
| `*.csproj` | C#/.NET |

**Check for frameworks** (in package files):
- React, Vue, Angular, Svelte (frontend)
- Express, Fastify, Nest.js (Node backend)
- Django, Flask, FastAPI (Python)
- Rails, Sinatra (Ruby)

**SMART: Parse package.json dependencies (if exists):**

Use Grep to detect actual frameworks:
\`\`\`bash
# Frontend detection
grep -E '"(react|vue|angular|svelte)"' package.json  # → Frontend framework
grep -E '"next"' package.json                        # → Next.js (React SSR)
grep -E '"nuxt"' package.json                        # → Nuxt (Vue SSR)

# Backend detection
grep -E '"express"' package.json                     # → Express.js
grep -E '"fastify"' package.json                     # → Fastify
grep -E '"@nestjs/core"' package.json                # → Nest.js
grep -E '"koa"' package.json                         # → Koa.js

# Database/ORM detection
grep -E '"prisma"|"@prisma"' package.json            # → Prisma ORM
grep -E '"mongoose"' package.json                    # → MongoDB/Mongoose
grep -E '"typeorm"' package.json                     # → TypeORM
grep -E '"sequelize"' package.json                   # → Sequelize
grep -E '"drizzle-orm"' package.json                 # → Drizzle ORM

# Test framework detection
grep -E '"jest"|"vitest"|"mocha"' package.json       # → Test framework
\`\`\`

---

## Step 3: Scan Directory Structure

Use Glob/Bash to list directories. Look for:

**Standard directories to scan:**
```
src/          → Source code
lib/          → Libraries
app/          → Application code
components/   → UI components
services/     → Business logic
api/          → API endpoints
routes/       → Route handlers
controllers/  → Controllers
models/       → Data models
utils/        → Utilities
helpers/      → Helper functions
hooks/        → Custom hooks (React)
store/        → State management
types/        → TypeScript types
tests/        → Test files
```

---

## Step 4: Identify Features/Modules

For each significant directory found, determine if it's a "feature":

**Feature = directory with:**
- 3+ code files, OR
- Has index/main file, OR
- Named after business domain (auth, users, payments, etc.)

**SMART: Scan code for patterns using Grep:**

\`\`\`bash
# API Routes Detection
grep -rEl "app\.(get|post|put|delete|patch)\(" src/     # Express routes
grep -rEl "@(Get|Post|Put|Delete|Controller)" src/      # NestJS/decorators
grep -rEl "router\.(get|post|put|delete)" src/          # Router patterns

# React Components Detection
grep -rEl "export (default )?(function|const) [A-Z]" src/  # Function components
grep -rEl "extends (React\.)?Component" src/               # Class components

# Database Models Detection
grep -rEl "^model [A-Z]" prisma/                         # Prisma models
grep -rEl "new Schema\(\{" src/                          # Mongoose schemas
grep -rEl "@Entity\(\)" src/                             # TypeORM entities
grep -rEl "class .* extends Model" src/                  # Sequelize models

# Service/Business Logic Detection
grep -rEl "@Injectable\(\)" src/                         # NestJS services
grep -rEl "class .*Service" src/                         # Service classes

# Hooks Detection (React)
grep -rEl "^export (const|function) use[A-Z]" src/       # Custom hooks
\`\`\`

**Build feature list from BOTH directories AND code patterns:**
\`\`\`
features_found = [
  { name: "auth", path: "src/auth", files: 5, type: "module" },
  { name: "users", path: "src/users", files: 8, type: "module" },
  { name: "api-routes", path: "src/routes", files: 12, type: "api", patterns: ["express"] },
  { name: "database", path: "prisma/schema.prisma", type: "database", patterns: ["prisma"] },
  ...
]
\`\`\`

---

## Step 5: Check Interactive Mode

**If user included `--interactive` flag:**

For EACH feature found, use AskUserQuestion:
```
"Document the [feature_name] module?"
Options:
- Yes, create P00X_[name].md
- Skip this feature
- Stop bootstrap (keep what's created so far)
```

**If no flag (default):** Create all docs automatically.

---

## Step 6: Create P001_architecture.md

Use the **Write tool** to create `.claude/vault/P001_architecture.md`:

```markdown
# P001 - Project Architecture

> **Status:** Active
> **Created:** [TODAY]
> **Last Updated:** [TODAY]
> **Generated by:** /ctx-bootstrap

---

## Summary

[1-2 sentences: What this project is, its main purpose]

---

## Tech Stack

| Category | Technology | Detected From |
|----------|------------|---------------|
| Language | [Primary language] | [file extensions] |
| Framework | [Main framework] | [package.json deps] |
| Runtime | [Node/Python/etc] | [config files] |
| Package Manager | [npm/yarn/pip/etc] | [lock files] |
| Database/ORM | [If detected] | [code patterns] |
| Testing | [Test framework] | [package.json deps] |
| API Style | [REST/GraphQL/tRPC] | [code patterns] |

---

## Project Structure

```
[directory tree of main folders]
```

### Key Directories

| Directory | Purpose |
|-----------|---------|
| `src/` | [Purpose] |
| `lib/` | [Purpose] |
| [etc] | [Purpose] |

---

## Entry Points

| Type | File | Description |
|------|------|-------------|
| Main | `[path]` | Application entry |
| Config | `[path]` | Configuration |
| Build | `[command]` | Build process |

---

## Features/Modules

| Module | Location | Summary |
|--------|----------|---------|
| [Name] | `[path]` | [Brief description] |
| [Name] | `[path]` | [Brief description] |

---

## Scripts/Commands

| Command | Purpose |
|---------|---------|
| `npm run dev` | [Description] |
| `npm test` | [Description] |

---

## History

| Date | Change |
|------|--------|
| [TODAY] | Generated by /ctx-bootstrap |

---
```

---

## Step 7: Create Feature Documents

For EACH feature identified in Step 4:

**Get next available P### ID** (P002, P003, etc.)

Use the **Write tool** to create `.claude/vault/P[ID]_[feature_name].md`:

```markdown
# P[ID] - [Feature Name] Module

> **Status:** Active
> **Created:** [TODAY]
> **Last Updated:** [TODAY]
> **Generated by:** /ctx-bootstrap

---

## Summary

[1 sentence: What this module does]

---

## Location

`[path/to/feature]`

---

## Files

| File | Purpose |
|------|---------|
| `index.*` | [Entry point] |
| `[file]` | [Purpose] |

---

## Key Components

- **[Component/Class/Function]**: [What it does]
- **[Component/Class/Function]**: [What it does]

---

## Patterns Detected

| Pattern | Location | Details |
|---------|----------|---------|
| [API routes/Components/Models] | [files] | [grep pattern matched] |

---

## Dependencies

- [What this module imports/uses]

---

## Used By

- [What uses this module]

---

## History

| Date | Change |
|------|--------|
| [TODAY] | Generated by /ctx-bootstrap |

---
```

---

## Step 8: Update Index

Add ALL new documents to `.claude/vault/index.md`:

| ID | Topic | Status | Summary |
|----|-------|--------|---------|
| P001 | Project Architecture | Active | Tech stack, structure, [X] modules |
| P002 | [Feature] Module | Active | [Brief summary] |
| P003 | [Feature] Module | Active | [Brief summary] |
| ... | ... | ... | ... |

Also add related terms to the "Related Terms Map":
- Project name, tech stack keywords → P001
- Feature names, related concepts → P00X

---

## Step 9: Output Summary

```
🚀 Bootstrap Complete!

📊 Codebase Scanned:
   • Project type: [Language/Framework]
   • Directories scanned: [count]
   • Features detected: [count]

📄 Documents Created:
   ✅ P001_architecture.md (Tech stack & structure)
   ✅ P002_[feature].md
   ✅ P003_[feature].md
   [... list all ...]

📋 Index Updated: [count] entries added

💡 Next steps:
   • Review generated docs for accuracy
   • Run /ctx-doc to add details
   • Run /ctx-intel for deeper analysis
```

---

## When to Run

- After `/ctx-init` on a new project
- When joining an existing codebase
- After major restructuring
- To regenerate stale documentation

---

## Notes

- Scans are read-only (doesn't modify code)
- Generated docs are starting points - refine them
- Re-running will detect new features (won't overwrite existing docs)
- Use `--interactive` for selective documentation
CMD_EOF
}

create_cmd_ctx_upgrade() {
    cat << 'CMD_EOF'
---
description: Upgrade ContextVault to latest version
---

# /ctx-upgrade

Upgrade ContextVault in the current project to the latest version. Updates instructions and hooks while preserving your documents.

## Usage

```
/ctx-upgrade
```

---

## What This Does

1. **Updates `./CLAUDE.md`** with latest, stronger enforcement instructions
2. **Updates `.claude/settings.json`** with latest hooks
3. **Installs missing hooks** (like git pre-commit)
4. **Preserves ALL your existing documents** (P### files untouched!)

---

## CRITICAL INSTRUCTIONS

**You MUST complete ALL steps. Your documents are SAFE - only instructions are updated.**

---

## Step 1: Backup Current Instructions (Safety)

First, note what exists:
```bash
ls -la ./CLAUDE.md .claude/settings.json .git/hooks/pre-commit 2>/dev/null
```

---

## Step 2: Update ./CLAUDE.md with STRONGER Enforcement

**REPLACE** the ContextVault section in `./CLAUDE.md` (or create if missing) with this STRONGER version:

Use the **Write tool** to create/overwrite `./CLAUDE.md` with this content (if other content exists, preserve it and add this at the TOP):

```markdown
# Project Instructions

## 📝 CONTEXTVAULT - Document at Milestones

### When to Document

```
┌─────────────────────────────────────────────────────────────────┐
│  AT MEANINGFUL MILESTONES:                                       │
│                                                                 │
│  ✅ Fixed a bug?        → /ctx-error                            │
│  ✅ Made a decision?    → /ctx-decision                         │
│  ✅ Built a feature?    → /ctx-doc                              │
│  ✅ Found useful code?  → /ctx-doc type=snippet                 │
│  ✅ Explored codebase?  → /ctx-doc type=intel                   │
│  ✅ Ending session?     → /ctx-handoff                          │
│                                                                 │
│  💭 Not every edit needs documenting                             │
│  💭 Document at milestones, not mid-edit                         │
│  💭 Skip if nothing meaningful was learned                       │
└─────────────────────────────────────────────────────────────────┘
```

### 📖 Session Start (AUTOMATIC)
1. Read `./.claude/vault/index.md` immediately
2. Note what docs exist

### 📝 Session End
1. Run `/ctx-handoff` to create handoff summary

### 🏷️ Project Docs
- Location: `./.claude/vault/`
- Prefix: P### (P001, P002, etc.)
- Update index after doc changes

### Commands
`/ctx-doc` `/ctx-error` `/ctx-decision` `/ctx-handoff` `/ctx-search` `/ctx-read` `/ctx-bootstrap` `/ctx-plan`
```

---

## Step 3: Update .claude/settings.json (Hooks Configuration)

**ASK the user** which enforcement level they want before applying:

| Level | Behavior |
|-------|----------|
| `light` | No mid-work blocking. Only Stop hook at session end. |
| `balanced` (recommended) | Blocks after 8 edits across 2+ files if undocumented. |
| `strict` | Blocks after 4 edits across 2+ files if undocumented. |

Then **REPLACE** `.claude/settings.json` with this content (Edit/Write are blocking for threshold enforcement, Read/Grep/Glob/WebSearch/WebFetch are non-blocking research tracking):

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/ctx-session-start.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/ctx-stop-enforcer.sh",
            "blocking": true
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/ctx-post-tool.sh",
            "blocking": true
          }
        ]
      },
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/ctx-post-tool.sh",
            "blocking": true
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/ctx-post-tool.sh"
          }
        ]
      },
      {
        "matcher": "TodoWrite",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/ctx-post-tool.sh"
          }
        ]
      },
      {
        "matcher": "Read",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/ctx-post-tool.sh"
          }
        ]
      },
      {
        "matcher": "Grep",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/ctx-post-tool.sh"
          }
        ]
      },
      {
        "matcher": "Glob",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/ctx-post-tool.sh"
          }
        ]
      },
      {
        "matcher": "WebSearch",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/ctx-post-tool.sh"
          }
        ]
      },
      {
        "matcher": "WebFetch",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/ctx-post-tool.sh"
          }
        ]
      }
    ]
  }
}
```

---

## Step 4: Install Git Pre-Commit Hook

Check if git repo and install hook:

```bash
[ -d .git ] && echo "IS_GIT_REPO" || echo "NOT_GIT_REPO"
```

If IS_GIT_REPO, create `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# ContextVault Pre-Commit Documentation Reminder

STAGED_COUNT=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')

if [ "$STAGED_COUNT" -gt 0 ]; then
    echo ""
    echo "📝 ContextVault: Committing $STAGED_COUNT file(s)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   ✍️  Did you document what you changed?"
    echo "   💡 Run /ctx-doc if not!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
fi
exit 0
```

Then: `chmod +x .git/hooks/pre-commit`

---

## Step 5: Confirm Upgrade

Output this (replace X.Y.Z with actual version from VERSION variable):
```
ContextVault vX.Y.Z Upgrade Complete!

Updated:
  ./CLAUDE.md              Milestone-based documentation instructions
  .claude/settings.json    Hooks (SessionStart, Stop, PostToolUse)
  .git/hooks/pre-commit    Git commit reminder

Enforcement: [LEVEL]
  light    → No mid-work blocking, Stop at session end only
  balanced → Block after 8 edits/2+ files if undocumented (default)
  strict   → Block after 4 edits/2+ files if undocumented
  Change:  /ctx-mode enforcement [level]

25 slash commands • /ctx-bootstrap • Archive mechanism

Your P### docs are SAFE!

IMPORTANT: Restart Claude session to activate new hooks.
```
CMD_EOF
}

create_cmd_ctx_health() {
    cat << 'CMD_EOF'
---
description: Check vault health and fix issues
---

# /ctx-health

Diagnose ContextVault health issues. Finds stale docs, over-limit files, orphaned entries, and structural problems.

## Usage

```
/ctx-health
```

---

## What This Checks

| Check | Description |
|-------|-------------|
| **Stale docs** | Documents not updated in >30 days |
| **Over-limit** | Docs exceeding 100 line limit |
| **Orphaned index** | Index entries with missing doc files |
| **Missing index** | Doc files not listed in index |
| **Structure** | Missing required sections in docs |

---

## Instructions

### Step 1: Read Both Indexes

Read global index (`~/.claude/vault/index.md`) and project index (`./.claude/vault/index.md` if exists).

### Step 2: List All Doc Files

```bash
ls -la ~/.claude/vault/*.md ./.claude/vault/*.md 2>/dev/null | grep -v index | grep -v _template
```

### Step 3: Check Each Document

For each doc file:
1. Check line count: `wc -l < file` (warn if >100)
2. Check last updated date from header
3. Verify required sections exist:
   - Summary
   - Current Understanding OR Key Points
   - History

### Step 4: Cross-Reference Index

For each index entry:
- Verify doc file exists
- Note any mismatches

For each doc file:
- Verify index entry exists

### Step 5: Output Health Report

```
🏥 ContextVault Health Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Summary:
   Global:  X docs | Project: Y docs

✅ Healthy: X documents
⚠️  Issues: Y documents

Issues Found:
─────────────────────────────────────────
🔸 P001: Over limit (125 lines > 100)
🔸 G002: Stale (last updated 45 days ago)
🔸 P003: Missing from index
🔸 G004: Orphaned (doc file not found)

Recommendations:
─────────────────────────────────────────
• Split P001 into smaller docs
• Review and update G002
• Add P003 to index with /ctx-update
• Remove G004 from index

Overall Health: ⚠️ NEEDS ATTENTION
```

---

## Health Levels

| Level | Icon | Meaning |
|-------|------|---------|
| Healthy | ✅ | No issues found |
| Warning | ⚠️ | Minor issues, vault still functional |
| Critical | ❌ | Major issues requiring immediate fix |
CMD_EOF
}

create_cmd_ctx_note() {
    cat << 'CMD_EOF'
---
description: Add a quick note to existing document
---

# /ctx-note

Quick one-liner notes without full document structure. For small learnings that don't need their own doc.

## Usage

```
/ctx-note "Your quick note here"
/ctx-note Redis needs restart after config change
```

---

## How It Works

Notes are stored in `vault/notes.md` as timestamped entries.

---

## Instructions

### Step 1: Determine Vault Location

Check settings for mode (local/global/full):
- local/full → Use `./.claude/vault/notes.md`
- global → Use `~/.claude/vault/notes.md`

### Step 2: Create or Append to notes.md

If `notes.md` doesn't exist, create with header:

```markdown
# Quick Notes

> Fast captures. No full doc needed.
> Review periodically - promote important ones to full docs!

---

## Notes

| Date | Note | Tags |
|------|------|------|
```

### Step 3: Add the Note

Append to the table:

```markdown
| 2026-01-18 | [User's note content] | #tag |
```

Auto-detect tags from keywords:
- "error", "bug", "fix" → #bug
- "config", "setup" → #config
- "todo", "later" → #todo
- "tip", "trick" → #tip

### Step 4: Confirm

```
📝 Note captured!

→ [Note content preview...]

Saved to: ./.claude/vault/notes.md
Total notes: X

💡 Review notes periodically with /ctx-read notes
   Promote important ones to full docs with /ctx-new
```

---

## Example Output

```
📝 Note captured!

→ "Redis needs restart after config change"

Saved to: ./.claude/vault/notes.md
Total notes: 12
Tags: #config

💡 Review notes periodically with /ctx-read notes
```
CMD_EOF
}

create_cmd_ctx_changelog() {
    cat << 'CMD_EOF'
---
description: View ContextVault changelog and version history
---

# /ctx-changelog

Generate a changelog from document history entries across all vault docs.

## Usage

```
/ctx-changelog              # Full changelog
/ctx-changelog 7            # Last 7 days
/ctx-changelog 2026-01-01   # Since specific date
```

---

## Instructions

### Step 1: Scan All Documents

Read all docs from:
- `~/.claude/vault/*.md` (global)
- `./.claude/vault/*.md` (project, if exists)

Skip: index.md, _template.md, notes.md

### Step 2: Extract History Sections

For each doc, find the "## History" section and extract entries:
- Parse date and change description
- Associate with doc ID

### Step 3: Aggregate by Date

Group all changes by date, newest first.

### Step 4: Apply Date Filter (if provided)

If user specified days or date, filter entries.

### Step 5: Output Formatted Changelog

```
📜 ContextVault Changelog
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 2026-01-18

### Global Vault
- G001: Updated authentication patterns
- G002: Added Docker best practices

### Project Vault (kalta)
- P001: Initial project setup
- P003: Fixed installer patterns
- P004: Completed v1.5.3 roadmap

---

## 2026-01-17

### Global Vault
- G001: Initial creation

---

📊 Summary: 6 changes across 5 documents
🗓️  Date range: 2026-01-17 to 2026-01-18
```

---

## Options

| Argument | Effect |
|----------|--------|
| (none) | Full changelog, all time |
| Number | Last N days |
| Date | Since YYYY-MM-DD |
CMD_EOF
}

create_cmd_ctx_link() {
    cat << 'CMD_EOF'
---
description: Link related documents together
---

# /ctx-link

Analyze and create bidirectional links between related documents.

## Usage

```
/ctx-link              # Analyze all docs for links
/ctx-link P001         # Show links for specific doc
```

---

## What This Does

1. Scans documents for references to other doc IDs (G###, P###)
2. Creates "Related Docs" sections automatically
3. Builds a relationship map
4. Warns when updating docs that others depend on

---

## Instructions

### Step 1: Scan All Documents

Read all docs from both vaults.

### Step 2: Find References

For each doc, search content for patterns:
- `G###` (global doc references)
- `P###` (project doc references)
- Explicit mentions like "see G001" or "related to P003"

### Step 3: Build Link Map

Create bidirectional relationships:
```
P001 → references → G001, P003
G001 ← referenced by ← P001, P002
P003 ← referenced by ← P001
```

### Step 4: Output Link Report

```
🔗 Document Link Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Link Statistics:
   Total docs: 8
   With links: 5
   Orphaned:   3 (no incoming or outgoing links)

🕸️  Link Map:
─────────────────────────────────────────

G001 (ContextVault System)
  ├── Referenced by: P001, P002, P004
  └── References: (none)

P001 (Project Setup)
  ├── Referenced by: P003
  └── References: G001

P003 (Installer Patterns)
  ├── Referenced by: (none)
  └── References: P001

⚠️  Orphaned Documents (no links):
   • G002 - Consider linking or archiving
   • P002 - Consider linking or archiving

💡 Tip: Add "See also: G001" to create explicit links
```

### Step 5: Optionally Update Docs

If user confirms, add "## Related Docs" section to documents:

```markdown
## Related Docs

| Doc | Relationship |
|-----|--------------|
| G001 | References |
| P003 | Referenced by |
```
CMD_EOF
}

create_cmd_ctx_quiz() {
    cat << 'CMD_EOF'
---
description: Test knowledge retention from vault docs
---

# /ctx-quiz

Quiz yourself on project knowledge to verify documentation accuracy and recall.

## Usage

```
/ctx-quiz              # Random questions from all docs
/ctx-quiz P001         # Questions about specific doc
/ctx-quiz 5            # Generate 5 questions
```

---

## How It Works

Generates questions from document content to test knowledge retention.
Fun way to verify that docs are accurate and useful!

---

## Instructions

### Step 1: Select Documents

Based on arguments:
- No args → Random sample from all docs
- Doc ID → Questions from that specific doc
- Number → That many questions total

### Step 2: Read Document Content

Extract key facts from:
- "Current Understanding" sections
- "Key Points" sections
- "Gotchas" sections

### Step 3: Generate Questions

Create questions like:

```
🎯 Question 1/5

According to your docs, what authentication method
does this project use?

   a) Session cookies
   b) JWT tokens
   c) OAuth2
   d) Basic auth

Source: P001 (Auth System)
```

### Step 4: Interactive Quiz

Present questions one at a time:
- Show question and options
- Wait for user answer
- Reveal correct answer with doc reference

### Step 5: Show Results

```
🏆 Quiz Complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Score: 4/5 (80%)

✅ Correct:
   • Auth method: JWT tokens (P001)
   • Database: PostgreSQL (P002)
   • Cache: Redis (P001)
   • Deploy: Docker (G003)

❌ Missed:
   • API rate limit: 1000/hour (P004)
     → You said: 500/hour
     → Review P004 for refresh

📚 Knowledge Level: GOOD

💡 Recommendation: Review P004 for rate limiting details
```

---

## Question Types

| Type | Example |
|------|---------|
| Fact recall | "What database does this project use?" |
| Gotcha check | "What's the gotcha with Redis config?" |
| Decision recall | "Why was React chosen over Vue?" |
CMD_EOF
}

create_cmd_ctx_explain() {
    cat << 'CMD_EOF'
---
description: Explain a concept and save to vault
---

# /ctx-explain

Generate a comprehensive project explanation from all documentation.

## Usage

```
/ctx-explain                    # Full project explanation
/ctx-explain --onboarding       # New team member format
/ctx-explain --architecture     # Technical deep-dive
```

---

## What This Does

Combines all vault documents into a cohesive narrative that explains the entire project.
Perfect for onboarding or creating project overviews.

---

## Instructions

### Step 1: Read All Documents

Load all docs from both vaults:
- Global vault (reusable patterns)
- Project vault (project-specific)

### Step 2: Categorize Content

Group information by topic:
- **Overview**: What is this project?
- **Architecture**: How is it built?
- **Key Decisions**: Why was it built this way?
- **Gotchas**: What to watch out for?
- **Setup**: How to get started?

### Step 3: Generate Narrative

Create flowing explanation:

```markdown
# Project Explanation: [Project Name]

> Auto-generated from ContextVault documentation
> Generated: 2026-01-18

---

## Overview

[Synthesized from P001 and other overview docs]

This project is a [description]. It was built to solve [problem].

---

## Architecture

[Synthesized from architecture-related docs]

### Tech Stack
- **Backend**: Node.js with Express
- **Database**: PostgreSQL with Redis cache
- **Frontend**: React with TypeScript

### Key Components
1. **Auth System** (P001): JWT-based authentication
2. **API Layer** (P003): RESTful endpoints
3. **Cache** (P001): Redis for session storage

---

## Key Decisions

[Synthesized from decision docs and history]

| Decision | Rationale | Doc |
|----------|-----------|-----|
| JWT over sessions | Stateless, scalable | P001 |
| PostgreSQL | ACID compliance needed | P002 |

---

## Gotchas & Tips

[Aggregated from all Gotchas sections]

⚠️ **Watch Out For:**
- Redis needs restart after config changes (P001)
- Rate limit is 1000/hour, not 500 (P004)

💡 **Pro Tips:**
- Always run migrations before deploy
- Use `npm run dev:debug` for verbose logs

---

## Getting Started

[If setup docs exist]

1. Clone the repo
2. Run `npm install`
3. Copy `.env.example` to `.env`
4. Run `docker-compose up`

---

## Document Sources

This explanation was generated from:
- G001: ContextVault System
- P001: Auth System
- P002: Database Setup
- P003: API Patterns
- P004: Decisions Log

---

*Generated by /ctx-explain on 2026-01-18*
```

### Step 4: Output Options

Based on flags:
- `--onboarding`: Focus on setup and getting started
- `--architecture`: Deep technical details
- Default: Balanced overview

### Step 5: Offer Export

```
📖 Project Explanation Generated!

Would you like to:
1. View in terminal (shown above)
2. Save to ./PROJECT_EXPLAINED.md
3. Copy to clipboard

This explanation combines 8 documents into one narrative.
```
CMD_EOF
}

create_cmd_ctx_archive() {
    cat << 'CMD_EOF'
---
description: Archive a vault document
---

# /ctx-archive

Move a document to the archive folder. Use when content is deprecated, replaced, or no longer relevant.

## Usage

```
/ctx-archive [ID] [REASON]
```

## Arguments

- `ID`: Document ID to archive (e.g., P001, G003)
- `REASON`: Why this document is being archived

## Examples

```
/ctx-archive P005 "Replaced by new authentication system"
/ctx-archive G002 "Feature deprecated in v2.0"
/ctx-archive P012 "Merged into P001"
```

---

## Instructions

When this command is invoked:

### Step 1: Validate Input

1. Parse document ID (must match pattern G### or P###)
2. Parse reason (required)
3. If missing, ask user: "Which document do you want to archive and why?"

### Step 2: Find Document

1. Determine vault from prefix (G = global, P = project)
2. Read the appropriate index
3. Find the document entry
4. If not found, show error and list available documents

### Step 3: Confirm with User

Show:
```
📦 Archive Document?

Document: [ID] - [Topic]
Summary: [current summary]
Reason: [provided reason]

This will:
1. Move file to vault/archive/ folder
2. Remove from Active Documents table
3. Add to Archived table with date and reason

Proceed? (y/n)
```

### Step 4: Archive the Document

If confirmed:

1. **Read the document file**
   - Path: `vault/[ID]_topic.md`

2. **Add archive header to document**
   ```markdown
   > **ARCHIVED:** 2026-02-06
   > **Reason:** [reason]

   ---

   [original content]
   ```

3. **Move file to archive folder**
   - From: `vault/[ID]_topic.md`
   - To: `vault/archive/[ID]_topic.md`

4. **Update index - Remove from Active Documents**
   - Find and remove the row `| [ID] | ... |`

5. **Update index - Add to Archived table**
   - Add row: `| [ID] | [Topic] | [Today's Date] | [Reason] |`
   - If placeholder row exists (`| - | - | - | - |`), replace it

6. **Update Quick Stats**
   - Decrement entry count

### Step 5: Confirm Completion

```
✅ Document Archived

📦 [ID] - [Topic]
📁 Moved to: vault/archive/[ID]_topic.md
📋 Reason: [reason]
📅 Archived: [date]

To restore: manually move the file back and update the index.
```

---

## When to Archive

✅ **DO archive:**
- Deprecated features or decisions
- Content replaced by newer documentation
- Merged documents (archive the old ones)
- Outdated configurations or patterns

❌ **DON'T archive:**
- Still-relevant content (use /ctx-update instead)
- Content that might be useful soon (just mark as stale)
- Content you're unsure about (ask first)

---

## Restoring Archived Documents

To restore an archived document:

1. Move file from `vault/archive/` back to `vault/`
2. Remove the archive header from the document
3. Remove entry from Archived table in index
4. Add entry back to Active Documents table
5. Update Quick Stats
CMD_EOF
}

create_cmd_ctx_review() {
    cat << 'CMD_EOF'
---
description: Run curation review on vault
---

# /ctx-review

Weekly curation workflow. Identifies stale documents, suggests merges, and finds cleanup opportunities.

## Usage

```
/ctx-review                    # Review project vault (default)
/ctx-review -global            # Review global vault
/ctx-review -days 60           # Custom stale threshold
```

## Arguments

- `-global`: Review global vault instead of project
- `-days N`: Consider docs stale after N days (default: 30)

---

## Instructions

When this command is invoked:

### Step 1: Determine Scope

Parse arguments:
- No args or `-local`: Review project vault
- `-global`: Review global vault
- `-days N`: Set stale threshold

### Step 2: Load Documents

1. Read the appropriate index
2. For each document, gather metadata:
   - Last modified date (from file stat)
   - Line count
   - Topic keywords

### Step 3: Identify Issues

Check each document for:

**High Priority:**
- Not updated in >90 days

**Medium Priority:**
- Not updated in 30-90 days
- Very short (<15 lines) - might be incomplete

**Low Priority:**
- Multiple docs share keywords (merge candidates)
- Similar topics that could be consolidated

### Step 4: Generate Report

Show summary with priority counts and action items for each issue.

### Step 5: Offer Actions

Suggest:
- /ctx-read [ID] to view document
- /ctx-update [ID] to update document
- /ctx-archive [ID] "reason" to archive document

---

## When to Run

- Weekly: Regular maintenance
- Before releases: Clean up outdated docs
- After major refactors: Find docs referencing old code
- When vault feels cluttered: Identify merge opportunities
CMD_EOF
}

create_cmd_ctx_ask() {
    cat << 'CMD_EOF'
---
description: Ask a question and get answers from vault
---

# /ctx-ask

Ask a natural language question and get a targeted answer from vault documents.

## Usage

```
/ctx-ask What was the authentication decision?
/ctx-ask How does the caching system work?
/ctx-ask Why did we choose PostgreSQL?
```

## Arguments

- `question`: Natural language question about the project

---

## Instructions

When this command is invoked:

### Step 1: Extract Keywords

From the question, extract meaningful keywords:
- Remove stop words (what, how, why, the, a, etc.)
- Keep technical terms and nouns

### Step 2: Search Both Vaults

1. Search project vault index for keyword matches
2. Search global vault index for keyword matches
3. Rank results by relevance
4. Take top 3 most relevant documents

### Step 3: Extract Relevant Content

For each matched document:
1. Read the full document
2. Extract sections that contain the keywords
3. Always include the Summary section
4. Limit output to ~30 lines per doc

### Step 4: Synthesize Answer

Format response with relevant excerpts from each matched document.
Include links to read full documents.

---

## Difference from /ctx-search

| /ctx-search | /ctx-ask |
|-------------|----------|
| Returns list of matching doc IDs | Returns actual content excerpts |
| Good for finding docs | Good for getting answers |
| Shows summaries only | Shows relevant sections |
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

check_and_restore_backup() {
    # Find the most recent backup
    local latest_backup=$(ls -dt "$HOME"/.contextvault_backup_* 2>/dev/null | head -1)

    if [ -n "$latest_backup" ] && [ -d "$latest_backup" ]; then
        local backup_date=$(basename "$latest_backup" | sed 's/\.contextvault_backup_//' | sed 's/_/ /')

        echo ""
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║${NC}  ${BOLD}📦 Previous Backup Found!${NC}                                       ${CYAN}║${NC}"
        echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${CYAN}║${NC}                                                                  ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  Location: ${DIM}$latest_backup${NC}"
        echo -e "${CYAN}║${NC}                                                                  ${CYAN}║${NC}"

        # Show what's in the backup
        if [ -d "$latest_backup/vault" ]; then
            local doc_count=$(ls -1 "$latest_backup/vault/"*.md 2>/dev/null | grep -v "_template\|index" | wc -l | tr -d ' ')
            echo -e "${CYAN}║${NC}  Contains: ${GREEN}$doc_count document(s)${NC} in vault                         ${CYAN}║${NC}"
        fi

        echo -e "${CYAN}║${NC}                                                                  ${CYAN}║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
        echo ""

        # Read from /dev/tty to work even when piped from curl
        local REPLY=""
        if [ -t 0 ]; then
            # stdin is a terminal
            read -p "   🔄 Restore from this backup? (Y/n) " -n 1 -r
            echo ""
        elif [ -e /dev/tty ]; then
            # stdin is not a terminal, but /dev/tty exists
            echo -n "   🔄 Restore from this backup? (Y/n) "
            read -n 1 -r REPLY < /dev/tty
            echo ""
        else
            # No terminal available, default to Yes
            echo -e "   🔄 Restore from this backup? ${GREEN}(Auto: Yes)${NC}"
            REPLY="y"
        fi

        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            echo ""

            # Rocket launch animation (same as fresh install!)
            rocket_launch

            # Create directories first
            mkdir -p "$CLAUDE_DIR"
            mkdir -p "$VAULT_DIR"
            mkdir -p "$COMMANDS_DIR"

            # Fun restore animation with progress
            print_step "📦 Unpacking your memories..."
            echo ""
            sleep 0.3 2>/dev/null || true

            # Restore vault contents
            if [ -d "$latest_backup/vault" ]; then
                printf "   ${DIM}🏰${NC} Vault"
                cp -r "$latest_backup/vault/"* "$VAULT_DIR/" 2>/dev/null || true
                printf " ${GREEN}✓${NC}\n"
                sleep 0.15 2>/dev/null || true
            fi

            # Restore CLAUDE.md
            if [ -f "$latest_backup/CLAUDE.md" ]; then
                printf "   ${DIM}📄${NC} CLAUDE.md"
                cp "$latest_backup/CLAUDE.md" "$CLAUDE_MD"
                printf " ${GREEN}✓${NC}\n"
                sleep 0.15 2>/dev/null || true
            fi

            # Restore commands
            if [ -d "$latest_backup/commands" ]; then
                printf "   ${DIM}⚡${NC} Commands"
                cp -r "$latest_backup/commands/"* "$COMMANDS_DIR/" 2>/dev/null || true
                printf " ${GREEN}✓${NC}\n"
                sleep 0.15 2>/dev/null || true
            fi

            echo ""
            sleep 0.3 2>/dev/null || true

            # Celebration animation
            local restore_frames=("🎉" "✨" "🎊" "💫" "🌟" "🏰")
            for i in {1..3}; do
                for frame in "${restore_frames[@]}"; do
                    printf "\r   ${frame} Restoration complete! ${frame}  "
                    sleep 0.08 2>/dev/null || true
                done
            done
            printf "\n"

            echo ""
            echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${GREEN}║${NC}                                                                  ${GREEN}║${NC}"
            echo -e "${GREEN}║${NC}   ${BOLD}${WHITE}🎉 ContextVault Restored from Backup! 🎉${NC}                     ${GREEN}║${NC}"
            echo -e "${GREEN}║${NC}                                                                  ${GREEN}║${NC}"
            echo -e "${GREEN}║${NC}   ${DIM}Your knowledge is back where it belongs.${NC}                     ${GREEN}║${NC}"
            echo -e "${GREEN}║${NC}                                                                  ${GREEN}║${NC}"
            echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
            echo ""
            echo -e "${BOLD}📦 What was restored:${NC}"
            echo -e "   ${CYAN}📄${NC} ~/.claude/CLAUDE.md          ${DIM}(Global brain)${NC}"
            echo -e "   ${CYAN}🏰${NC} ~/.claude/vault/             ${DIM}(Your knowledge vault)${NC}"
            echo -e "   ${CYAN}⚡${NC} ~/.claude/commands/          ${DIM}(23 slash commands)${NC}"
            echo ""
            echo -e "${BOLD}🚀 Quick Start:${NC}"
            echo -e "   1. Start Claude Code: ${CYAN}claude${NC}"
            echo -e "   2. Check status:      ${YELLOW}/ctx-status${NC}"
            echo -e "   3. See all commands:  ${YELLOW}/ctx-help${NC}"
            echo ""
            echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${DIM}Backup source: $latest_backup${NC}"
            echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            echo -e "${MAGENTA}✨ Your context will never be lost again! ✨${NC}"
            echo ""
            return 0  # Backup was restored
        else
            echo ""
            echo -e "   ${YELLOW}Skipping restore.${NC} Starting fresh install..."
            echo ""
        fi
    fi
    return 1  # No backup restored
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
        local installed_ver=$(get_installed_version)

        if [ -n "$installed_ver" ]; then
            if [ "$installed_ver" = "$VERSION" ]; then
                print_warning "ContextVault v${VERSION} is already installed!"
                echo ""
                echo -e "   ${DIM}Current: v${installed_ver}${NC}"
            elif is_newer_version "$VERSION" "$installed_ver"; then
                # Script version is newer than installed
                print_warning "ContextVault upgrade available!"
                echo ""
                echo -e "   ${YELLOW}Current:${NC} v${installed_ver}"
                echo -e "   ${GREEN}New:${NC}     v${VERSION}"
            else
                # Installed version is newer (user has newer local install)
                print_warning "ContextVault is already installed (newer version)!"
                echo ""
                echo -e "   ${GREEN}Current:${NC} v${installed_ver}"
                echo -e "   ${DIM}Script:${NC}  v${VERSION}"
            fi
        else
            print_warning "ContextVault is already installed!"
            echo ""
            echo -e "   ${DIM}Installing: v${VERSION}${NC}"
        fi
        echo ""

        # Read from /dev/tty to work even when piped from curl
        local REPLY=""
        local prompt_text="   🔄 "
        if [ -n "$installed_ver" ] && is_newer_version "$VERSION" "$installed_ver"; then
            prompt_text="${prompt_text}Upgrade to v${VERSION}? (y/N) "
        else
            prompt_text="${prompt_text}Reinstall? (This will backup existing files) (y/N) "
        fi

        if [ -t 0 ]; then
            read -p "$prompt_text" -n 1 -r
            echo ""
        elif [ -e /dev/tty ]; then
            echo -n "$prompt_text"
            read -n 1 -r REPLY < /dev/tty
            echo ""
        else
            echo -e "   🔄 Reinstall? ${YELLOW}(Auto: No - keeping existing)${NC}"
            REPLY="n"
        fi

        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo ""
            echo -e "${GREEN}👍 Keeping existing installation. You're all set!${NC}"
            echo ""
            exit 0
        fi
        echo ""
        backup_existing
        echo ""
    else
        # No existing installation - check for backups to restore
        if check_and_restore_backup; then
            # Backup was restored, we're done
            exit 0
        fi
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
        "ctx-share:📤"
        "ctx-import:📥"
        "ctx-handoff:🤝"
        "ctx-error:🐛"
        "ctx-decision:⚖️"
        "ctx-plan:📋"
        "ctx-bootstrap:🚀"
        "ctx-upgrade:⬆️"
        "ctx-health:🏥"
        "ctx-changelog:📜"
        "ctx-link:🔗"
        "ctx-quiz:🎯"
        "ctx-archive:📦"
        "ctx-review:📋"
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
            ctx-share) create_cmd_ctx_share > "$COMMANDS_DIR/ctx-share.md" ;;
            ctx-import) create_cmd_ctx_import > "$COMMANDS_DIR/ctx-import.md" ;;
            ctx-handoff) create_cmd_ctx_handoff > "$COMMANDS_DIR/ctx-handoff.md" ;;
            ctx-error) create_cmd_ctx_error > "$COMMANDS_DIR/ctx-error.md" ;;
            ctx-decision) create_cmd_ctx_decision > "$COMMANDS_DIR/ctx-decision.md" ;;
            ctx-plan) create_cmd_ctx_plan > "$COMMANDS_DIR/ctx-plan.md" ;;
            ctx-bootstrap) create_cmd_ctx_bootstrap > "$COMMANDS_DIR/ctx-bootstrap.md" ;;
            ctx-upgrade) create_cmd_ctx_upgrade > "$COMMANDS_DIR/ctx-upgrade.md" ;;
            ctx-health) create_cmd_ctx_health > "$COMMANDS_DIR/ctx-health.md" ;;
            ctx-changelog) create_cmd_ctx_changelog > "$COMMANDS_DIR/ctx-changelog.md" ;;
            ctx-link) create_cmd_ctx_link > "$COMMANDS_DIR/ctx-link.md" ;;
            ctx-quiz) create_cmd_ctx_quiz > "$COMMANDS_DIR/ctx-quiz.md" ;;
            ctx-archive) create_cmd_ctx_archive > "$COMMANDS_DIR/ctx-archive.md" ;;
            ctx-review) create_cmd_ctx_review > "$COMMANDS_DIR/ctx-review.md" ;;
        esac

        printf " ${GREEN}✓${NC}\n"
        sleep 0.1 2>/dev/null || true
    done

    echo ""
    print_success "23 commands installed"

    # Install global hooks
    echo ""
    print_step "🪝 Setting up global hooks..."
    create_global_hooks

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
    echo -e "   ${CYAN}⚡${NC} ~/.claude/commands/          ${DIM}(23 slash commands)${NC}"
    echo -e "   ${CYAN}🪝${NC} ~/.claude/hooks/             ${DIM}(4 hook scripts)${NC}"
    echo -e "   ${CYAN}⚙️${NC} ~/.claude/settings.json      ${DIM}(Hook triggers)${NC}"
    echo ""
    echo -e "${BOLD}🪝 Hooks installed (v${VERSION}):${NC}"
    echo -e "   ${GREEN}SessionStart${NC}  → Loads vault indexes at session start"
    echo -e "   ${GREEN}PostToolUse${NC}   → Tracks edits & research, reminds on milestones"
    echo -e "   ${YELLOW}Stop${NC}          → Smart block: catches significant undocumented work"
    echo ""
    echo -e "${BOLD}🎮 New in v1.8 (23 commands total):${NC}"
    echo -e "   ${YELLOW}/ctx-bootstrap${NC} 🚀 Auto-scan codebase ${DIM}(NEW!)${NC}"
    echo -e "   ${YELLOW}/ctx-plan${NC}      📋 Multi-step task plans"
    echo -e "   ${YELLOW}/ctx-error${NC}     🐛 Bug fix documentation"
    echo -e "   ${YELLOW}/ctx-decision${NC}  ⚖️  Architecture decisions"
    echo -e "   ${YELLOW}/ctx-help${NC}      📖 See all 23 commands"
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

    for cmd in ctx-init ctx-status ctx-mode ctx-help ctx-new ctx-doc ctx-update ctx-search ctx-read ctx-share ctx-import ctx-handoff ctx-error ctx-decision ctx-plan ctx-bootstrap ctx-upgrade ctx-health ctx-changelog ctx-link ctx-quiz ctx-archive ctx-review; do
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
        for cmd in ctx-init ctx-status ctx-mode ctx-help ctx-new ctx-doc ctx-update ctx-search ctx-read ctx-share ctx-import ctx-handoff ctx-error ctx-decision ctx-plan ctx-bootstrap ctx-upgrade ctx-health ctx-changelog ctx-link ctx-quiz ctx-archive ctx-review; do
            [ -f "$COMMANDS_DIR/$cmd.md" ] && ((cmd_count++))
        done
        [ $cmd_count -eq 23 ] && print_success "  └── All 23 commands ✓" || print_warning "  └── $cmd_count/23 commands"
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
