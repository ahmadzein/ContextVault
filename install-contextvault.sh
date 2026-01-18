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
VERSION="1.5.1"

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
# Usage: version_compare "1.5.1" "1.5.0" -> returns 0 (1.5.1 is newer)
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
# Usage: is_newer_version "1.5.1" "1.5.0" && echo "yes"
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
echo "   📖 Read indexes now!"
echo "   ✍️  DOCUMENT after each task! (Don't wait!)"
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
    echo "📝 ContextVault"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   Did you document your learnings?"
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
    echo "   ℹ️  No docs modified this session"
    echo "   💡 Use /ctx-doc to capture learnings"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
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

    # The hooks JSON content - uses full path with $HOME for proper expansion
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
            \"command\": \"$HOME/.claude/hooks/ctx-session-end.sh\"
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

            # Safely merge: ensure .hooks exists, then replace SessionStart and Stop
            local merged
            merged=$(echo "$existing" | jq --argjson new_hooks "$hooks_json" '
                # Ensure hooks object exists
                .hooks //= {} |
                # Replace SessionStart and Stop with our hooks
                .hooks.SessionStart = $new_hooks.hooks.SessionStart |
                .hooks.Stop = $new_hooks.hooks.Stop
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

# Generate project hooks JSON for ctx-init
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
            "command": "echo \"\\n💾 Project Documentation Reminder\\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\nDocument project-specific learnings!\\nUse /ctx-doc with P### prefix\\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\n\""
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

**Version:** 1.5.1
**Last Updated:** $(date +%Y-%m-%d)
**System:** ContextVault - External Context Management

---

# ⚡ CRITICAL: DOCUMENT AS YOU WORK ⚡

```
╔═══════════════════════════════════════════════════════════════════╗
║  AFTER *EVERY* COMPLETED TASK — ASK YOURSELF:                     ║
║                                                                   ║
║  Did I learn something? Fix a bug? Make a decision? Find a quirk?║
║                                                                   ║
║  → If YES: DOCUMENT IT NOW. Not later. NOW.                       ║
║  → Search index → UPDATE existing OR CREATE new                   ║
║  → Tell user: "Documented to [ID]_topic.md"                       ║
║                                                                   ║
║  ⚠️  DO NOT WAIT until session end. Document IMMEDIATELY.         ║
╚═══════════════════════════════════════════════════════════════════╝
```

---

## ⚠️ BEFORE STARTING ANY WORK (MANDATORY)

**At the START of every session, BEFORE doing anything else:**

```
┌─────────────────────────────────────────────────────────────────┐
│                    PRE-WORK CHECKLIST                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  STEP 1: Read settings                                          │
│  ────────────────────                                           │
│  → Read ~/.claude/vault/settings.json                           │
│  → Note the mode: local | full | global                         │
│                                                                 │
│  STEP 2: Read index(es) based on mode                           │
│  ────────────────────────────────────                           │
│  → local mode:  Read ./.claude/vault/index.md ONLY              │
│  → full mode:   Read BOTH global + project indexes              │
│  → global mode: Read ~/.claude/vault/index.md ONLY              │
│                                                                 │
│  STEP 3: Note existing knowledge                                │
│  ───────────────────────────────                                │
│  → What docs exist? What do they cover?                         │
│  → Use this knowledge throughout the session                    │
│                                                                 │
│  STEP 4: Check if project initialized                           │
│  ─────────────────────────────────────                          │
│  → Does ./.claude/vault/index.md exist?                         │
│  → If NO: Suggest "/ctx-init" once, then continue               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**This is AUTOMATIC and SILENT. Do not announce these steps.**

---

## ⚠️ AFTER COMPLETING ANY WORK (MANDATORY)

**After EVERY task, bug fix, exploration, or decision:**

```
┌─────────────────────────────────────────────────────────────────┐
│                   POST-WORK CHECKLIST                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  STEP 1: Assess - Did I learn something?                        │
│  ───────────────────────────────────────                        │
│  Ask yourself:                                                  │
│  □ Did I understand how something works?                        │
│  □ Did I find a bug and fix it?                                 │
│  □ Did I make a decision with reasoning?                        │
│  □ Did I discover a pattern or best practice?                   │
│  □ Did I configure or set up something?                         │
│  □ Did I find a gotcha, edge case, or quirk?                    │
│  □ Did I explore code and learn the architecture?               │
│                                                                 │
│  → If ANY checkbox = YES → MUST DOCUMENT                        │
│  → If ALL checkboxes = NO → Skip documentation                  │
│                                                                 │
│  STEP 2: Search - Does related doc exist?                       │
│  ─────────────────────────────────────────                      │
│  → Search index for: exact topic, related terms, synonyms       │
│  → Examples: auth/login/signin = SAME topic                     │
│              docker/container/image = SAME topic                │
│                                                                 │
│  STEP 3: Decide - UPDATE or CREATE?                             │
│  ──────────────────────────────────                             │
│                                                                 │
│       ┌─── Related doc EXISTS? ───┐                             │
│       │                           │                             │
│      YES                         NO                             │
│       │                           │                             │
│       ▼                           ▼                             │
│    UPDATE IT                   CREATE NEW                       │
│    (Rule 2: No duplicates)     (with proper routing)            │
│                                                                 │
│  STEP 4: Route - Global or Project?                             │
│  ──────────────────────────────────                             │
│  (Only if creating NEW doc)                                     │
│                                                                 │
│       ┌─── Reusable in OTHER projects? ───┐                     │
│       │                                    │                    │
│      YES                                  NO                    │
│       │                                    │                    │
│       ▼                                    ▼                    │
│    GLOBAL (G###)                      PROJECT (P###)            │
│    ~/.claude/vault/                   ./.claude/vault/          │
│    • Patterns                         • This codebase only      │
│    • Best practices                   • Architecture here       │
│    • Tool configs                     • Local decisions         │
│    • Reusable knowledge               • Project-specific        │
│                                                                 │
│  STEP 5: Save - Write the document                              │
│  ─────────────────────────────────                              │
│  → Follow document template structure                           │
│  → Max 100 lines per document                                   │
│  → Be concise, factual, actionable                              │
│                                                                 │
│  STEP 6: Index - Update the index IMMEDIATELY                   │
│  ─────────────────────────────────────────────                  │
│  → Add/update entry in the correct index                        │
│  → Summary: max 15 words, reflect current state                 │
│  → Update "Last updated" date                                   │
│                                                                 │
│  STEP 7: Confirm - Brief notification                           │
│  ────────────────────────────────────                           │
│  → Tell user: "Documented to P001_topic.md"                     │
│  → Do NOT ask permission, just confirm it's done                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🚫 NEVER DO THESE THINGS

```
❌ NEVER ask: "Should I document this?"
❌ NEVER ask: "Want me to save this to the vault?"
❌ NEVER ask: "I could create a doc for this..."
❌ NEVER create a doc without checking if one exists
❌ NEVER forget to update the index after changes
❌ NEVER create duplicates (same topic, different doc)
❌ NEVER append contradicting info (replace outdated info)
❌ NEVER load multiple docs "just in case"
```

---

## ✅ ALWAYS DO THESE THINGS

```
✅ ALWAYS read indexes at session start
✅ ALWAYS search before creating
✅ ALWAYS update existing docs instead of creating duplicates
✅ ALWAYS update the index after any doc change
✅ ALWAYS use correct prefix (G### global, P### project)
✅ ALWAYS keep docs under 100 lines
✅ ALWAYS keep summaries under 15 words
✅ ALWAYS confirm: "Documented to [ID]" (don't ask, just inform)
```

---

## 📝 HOW TO UPDATE AN EXISTING DOCUMENT

When you find a related doc exists, UPDATE it like this:

```
1. READ the existing document fully
2. IDENTIFY what section needs updating:
   → New info? Add to "Current Understanding"
   → Outdated info? Replace it, move old to "History"
   → Bug fix? Add to "Gotchas" or "History"
3. PRESERVE the document structure
4. UPDATE the "Last Updated" date
5. UPDATE the index summary if meaning changed
```

**Example update:**
```markdown
## Current Understanding
- Auth uses JWT tokens (15min expiry)     ← EXISTING
- Refresh tokens stored in Redis          ← EXISTING
- Added: Password reset uses email link   ← NEW (you add this)

## History
- 2026-01-18: Added password reset flow   ← LOG THE CHANGE
- 2026-01-15: Initial auth documentation
```

---

## 📝 HOW TO CREATE A NEW DOCUMENT

When no related doc exists, CREATE new:

```
1. DETERMINE routing:
   → Reusable? → Global G### in ~/.claude/vault/
   → Project-only? → Project P### in ./.claude/vault/

2. GET next ID:
   → Read index, find highest ID, increment
   → Global: G001, G002, G003...
   → Project: P001, P002, P003...

3. CREATE file with template structure:
   → Location: [vault]/[ID]_topic_name.md
   → Example: ./.claude/vault/P003_payment_integration.md

4. WRITE content:
   → Summary (1 paragraph)
   → Current Understanding (the facts)
   → Key Points (bullet points)
   → Gotchas (if any)
   → History (creation date)

5. UPDATE index:
   → Add row to "Active Documents" table
   → Add related terms to "Related Terms Map"
   → Update "Quick Stats" count

6. CONFIRM to user:
   → "Created P003_payment_integration.md"
```

---

## 📊 DOCUMENT TEMPLATE

Every document should follow this structure:

```markdown
# [ID] - [Topic Title]

> **Status:** Active
> **Created:** YYYY-MM-DD
> **Last Updated:** YYYY-MM-DD

---

## Summary

[One paragraph: What is this about? Why does it matter?]

---

## Current Understanding

[The current, accurate facts. Always up-to-date truth.]

### Key Points
- Point 1
- Point 2
- Point 3

### Details
[Deeper explanation if needed]

---

## Gotchas & Edge Cases

[Things that surprised you, bugs found, quirks]

- Gotcha 1: explanation
- Edge case: how to handle

---

## History

| Date | Change |
|------|--------|
| YYYY-MM-DD | Initial creation |
| YYYY-MM-DD | Added X, updated Y |

---
```

---

## 📊 Respect Settings

Always check `~/.claude/vault/settings.json`:

```json
{
  "mode": "local",      ← Determines what indexes to read/write
  "limits": {
    "max_global_docs": 50,    ← Don't exceed these
    "max_project_docs": 50,
    "max_doc_lines": 100,
    "max_summary_words": 15
  }
}
```

**Mode behavior:**
- `local` (default): Only use project vault, ignore global
- `full`: Use both global and project vaults
- `global`: Only use global vault, ignore project

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
| 1.4.0 | $(date +%Y-%m-%d) | Enhanced instructions with clear checklists |
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

## ContextVault - MANDATORY

**This project uses ContextVault. You MUST follow these rules.**

### AUTOMATIC BEHAVIOR (Do not ask, just do):

1. **Session Start**: Read `./.claude/vault/index.md` immediately
2. **After Tasks**: Document findings to vault automatically
3. **After Exploring Code**: Document architecture/patterns found
4. **After Fixing Bugs**: Document the issue and solution
5. **After Decisions**: Document the reasoning

### RULES:
- NEVER ask "Should I document this?" → Just document it
- NEVER ask "Want me to save this?" → Just save it
- Project docs → `./.claude/vault/` with P### prefix
- Update index after every change

### COMMANDS:
`/ctx-status` `/ctx-new` `/ctx-doc` `/ctx-update` `/ctx-search` `/ctx-read`
```

#### OPTION 2: If ./CLAUDE.md EXISTS but has NO "ContextVault" section → APPEND TO IT

1. Use the **Read tool** to read the current content of `./CLAUDE.md`
2. Check if the text "ContextVault" appears anywhere in the file
3. If "ContextVault" is NOT found, use the **Edit tool** to APPEND this block at the END of the file:

```markdown

---

## ContextVault - MANDATORY

**This project uses ContextVault. You MUST follow these rules.**

### AUTOMATIC BEHAVIOR (Do not ask, just do):

1. **Session Start**: Read `./.claude/vault/index.md` immediately
2. **After Tasks**: Document findings to vault automatically
3. **After Exploring Code**: Document architecture/patterns found
4. **After Fixing Bugs**: Document the issue and solution
5. **After Decisions**: Document the reasoning

### RULES:
- NEVER ask "Should I document this?" → Just document it
- NEVER ask "Want me to save this?" → Just save it
- Project docs → `./.claude/vault/` with P### prefix
- Update index after every change

### COMMANDS:
`/ctx-status` `/ctx-new` `/ctx-doc` `/ctx-update` `/ctx-search` `/ctx-read`
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
            "command": "echo \"\\n💾 Project Documentation Reminder\\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\nDocument project-specific learnings!\\nUse /ctx-doc with P### prefix\\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\n\""
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

## Step 6: Display completion message

**Only show this AFTER you have completed Steps 1-5:**

```
✅ ContextVault initialized for this project!

Created/Updated:
├── ./CLAUDE.md                ← ContextVault instructions (FORCES ctx usage!)
├── .claude/vault/index.md     ← Project documentation index
├── .claude/vault/_template.md ← Document template
└── .claude/settings.json      ← Project hooks (SessionStart + Stop)

🪝 Hooks installed:
   SessionStart → Reminds to read project vault
   Stop         → Reminds to document learnings

Claude will now AUTOMATICALLY:
• Read project vault at session start (enforced by hook!)
• Document findings without asking
• Use P### prefix for project docs

Run /ctx-status to verify setup.
```

---

## Final Verification Checklist

Before reporting success, confirm ALL of these are true:

- [ ] `./CLAUDE.md` exists in project root AND contains "ContextVault - MANDATORY" section
- [ ] `.claude/vault/index.md` exists
- [ ] `.claude/vault/_template.md` exists
- [ ] `.claude/settings.json` exists AND contains project hooks

**If any checkbox is false, go back and complete that step!**
CMD_EOF
}

create_cmd_ctx_status() {
    # Use unquoted CMD_EOF to allow VERSION substitution
    cat << CMD_EOF
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
│  SHARING & IMPORT                                                │
│  ─────────────────────────────────────────────────────────────  │
│  /ctx-share     Export vault to ZIP (-local/-global/-all)       │
│  /ctx-import    Import vault from shared ZIP file               │
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

create_cmd_ctx_share() {
    cat << 'CMD_EOF'
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
  "contextvault_version": "1.5.1",
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
Version: 1.5.1

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
            echo -e "   ${CYAN}⚡${NC} ~/.claude/commands/          ${DIM}(11 slash commands)${NC}"
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
        esac

        printf " ${GREEN}✓${NC}\n"
        sleep 0.1 2>/dev/null || true
    done

    echo ""
    print_success "11 commands installed"

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
    echo -e "   ${CYAN}⚡${NC} ~/.claude/commands/          ${DIM}(11 slash commands)${NC}"
    echo -e "   ${CYAN}🪝${NC} ~/.claude/settings.json      ${DIM}(Auto-hooks: SessionStart + Stop)${NC}"
    echo ""
    echo -e "${BOLD}🪝 Hooks installed:${NC}"
    echo -e "   ${GREEN}SessionStart${NC} → Reminds to read vault indexes"
    echo -e "   ${GREEN}Stop${NC}         → Reminds to document learnings"
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
        for cmd in ctx-init ctx-status ctx-mode ctx-help ctx-new ctx-doc ctx-update ctx-search ctx-read ctx-share ctx-import; do
            [ -f "$COMMANDS_DIR/$cmd.md" ] && ((cmd_count++))
        done
        [ $cmd_count -eq 11 ] && print_success "  └── All 11 commands ✓" || print_warning "  └── $cmd_count/11 commands"
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
