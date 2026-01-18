#!/bin/bash

#===============================================================================
#
#   🗑️  ContextVault Uninstaller
#
#   Safely removes ContextVault from your system
#   (We'll offer to create a backup first!)
#
#   Usage:
#     ./uninstall-contextvault.sh           # Interactive (asks for confirmation)
#     ./uninstall-contextvault.sh --force   # Non-interactive (no prompt, with backup)
#     ./uninstall-contextvault.sh -y        # Same as --force
#
#   One-liner (non-interactive):
#     curl -fsSL https://raw.githubusercontent.com/ahmadzein/ContextVault/main/uninstall-contextvault.sh -o /tmp/uninstall.sh && bash /tmp/uninstall.sh --force
#
#   Note: Your data is backed up to ~/.contextvault_backup_* before removal.
#         When you reinstall, ContextVault will offer to restore from backup!
#
#===============================================================================

set -e

VERSION="1.4.0"

# Parse arguments
FORCE_MODE=false
for arg in "$@"; do
    case $arg in
        --force|-y|--yes)
            FORCE_MODE=true
            ;;
    esac
done

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

# Paths
CLAUDE_DIR="$HOME/.claude"
VAULT_DIR="$CLAUDE_DIR/vault"
COMMANDS_DIR="$CLAUDE_DIR/commands"
HOOKS_DIR="$CLAUDE_DIR/hooks"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
SETTINGS_JSON="$CLAUDE_DIR/settings.json"

# Track backup location for final message
BACKUP_LOCATION=""

print_header() {
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC}                                                                  ${RED}║${NC}"
    echo -e "${RED}║${NC}   ${BOLD}${WHITE}🗑️  ContextVault Uninstaller v${VERSION}${NC}                           ${RED}║${NC}"
    echo -e "${RED}║${NC}   ${DIM}Sad to see you go! 😢${NC}                                         ${RED}║${NC}"
    echo -e "${RED}║${NC}                                                                  ${RED}║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════════╝${NC}"
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

# Read input with /dev/tty fallback for curl pipe
read_input() {
    local prompt="$1"
    local default="$2"

    if [ -t 0 ]; then
        # Interactive terminal
        read -p "$prompt" -n 1 -r
    elif [ -e /dev/tty ]; then
        # Piped from curl, use /dev/tty
        echo -n "$prompt"
        read -n 1 -r REPLY < /dev/tty
    else
        # No terminal available, use default
        REPLY="$default"
    fi
}

# Sweeping animation
sweep_animation() {
    local message="$1"
    local frames=("🧹    " " 🧹   " "  🧹  " "   🧹 " "    🧹" "   🧹 " "  🧹  " " 🧹   ")
    local duration=1.5
    local frame_count=${#frames[@]}
    local frame_delay=$(echo "$duration / $frame_count / 2" | bc -l)

    for ((i=0; i<2; i++)); do
        for frame in "${frames[@]}"; do
            printf "\r${YELLOW}  ${frame}${NC} ${message}"
            sleep "$frame_delay" 2>/dev/null || sleep 0.1
        done
    done
    printf "\r%-60s\r" ""
}

# Packing animation for backup
packing_animation() {
    local message="$1"
    local frames=("📦    " "📦📄  " "📦📄📄" "📦📄📄📄" "📦✨  ")

    for frame in "${frames[@]}"; do
        printf "\r${CYAN}  ${frame}${NC} ${message}"
        sleep 0.3
    done
    printf "\r%-60s\r" ""
}

# Waving goodbye animation
wave_animation() {
    local frames=("👋" "🖐️" "👋" "🖐️" "👋")

    for frame in "${frames[@]}"; do
        printf "\r  ${frame} "
        sleep 0.2
    done
    printf "\r    \r"
}

# Sad face animation
sad_animation() {
    local frames=("😊" "😐" "🙁" "😢" "😭")

    echo ""
    for frame in "${frames[@]}"; do
        printf "\r  ${frame} Processing your request..."
        sleep 0.3
    done
    printf "\r%-50s\r" ""
    echo ""
}

# Success celebration (smaller, for uninstall)
goodbye_celebration() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}                                                                  ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}   ${BOLD}${WHITE}✅ ContextVault has been uninstalled successfully!${NC}            ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}                                                                  ${GREEN}║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Failure message
show_failure() {
    local error_msg="$1"
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC}                                                                  ${RED}║${NC}"
    echo -e "${RED}║${NC}   ${BOLD}${WHITE}❌ Uninstall Failed${NC}                                            ${RED}║${NC}"
    echo -e "${RED}║${NC}   ${DIM}${error_msg}${NC}                                                  ${RED}║${NC}"
    echo -e "${RED}║${NC}                                                                  ${RED}║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "Please try again or report this issue at:"
    echo -e "${CYAN}https://github.com/ahmadzein/ContextVault/issues${NC}"
    echo ""
}

# Cancelled message
show_cancelled() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}                                                                  ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}   ${BOLD}${WHITE}😅 Phew! Uninstall cancelled${NC}                                  ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}   ${DIM}ContextVault lives to document another day! 📝${NC}                ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}                                                                  ${GREEN}║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

backup_existing() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$HOME/.contextvault_backup_$timestamp"

    # Fun packing animation
    packing_animation "Packing up your memories..."

    print_step "📦 Creating backup at $backup_dir"

    mkdir -p "$backup_dir"

    local backed_up=0

    if [ -f "$CLAUDE_MD" ]; then
        cp "$CLAUDE_MD" "$backup_dir/"
        ((backed_up++))
        print_success "Backed up CLAUDE.md"
    fi

    if [ -d "$VAULT_DIR" ]; then
        cp -r "$VAULT_DIR" "$backup_dir/"
        local doc_count=$(find "$backup_dir/vault" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
        ((backed_up++))
        print_success "Backed up vault ($doc_count documents)"
    fi

    if [ -d "$COMMANDS_DIR" ]; then
        mkdir -p "$backup_dir/commands"
        local cmd_count=0
        for cmd in ctx-init ctx-status ctx-mode ctx-help ctx-new ctx-doc ctx-update ctx-search ctx-read; do
            if [ -f "$COMMANDS_DIR/$cmd.md" ]; then
                cp "$COMMANDS_DIR/$cmd.md" "$backup_dir/commands/"
                ((cmd_count++))
            fi
        done
        if [ $cmd_count -gt 0 ]; then
            ((backed_up++))
            print_success "Backed up $cmd_count commands"
        fi
    fi

    if [ -d "$HOOKS_DIR" ]; then
        mkdir -p "$backup_dir/hooks"
        local hook_count=0
        for hook in ctx-session-start.sh ctx-session-end.sh; do
            if [ -f "$HOOKS_DIR/$hook" ]; then
                cp "$HOOKS_DIR/$hook" "$backup_dir/hooks/"
                ((hook_count++))
            fi
        done
        if [ $hook_count -gt 0 ]; then
            ((backed_up++))
            print_success "Backed up $hook_count hook scripts"
        fi
    fi

    if [ -f "$SETTINGS_JSON" ]; then
        cp "$SETTINGS_JSON" "$backup_dir/"
        ((backed_up++))
        print_success "Backed up settings.json (hooks)"
    fi

    if [ $backed_up -gt 0 ]; then
        BACKUP_LOCATION="$backup_dir"
        echo ""
        print_success "✨ Backup complete! Your data is safe."
    else
        print_warning "Nothing to backup"
    fi
    echo ""
}

uninstall() {
    print_header

    # Check if installed
    if [ ! -f "$CLAUDE_MD" ] && [ ! -d "$VAULT_DIR" ]; then
        echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║${NC}                                                                  ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}   ${BOLD}${WHITE}🤔 ContextVault doesn't seem to be installed${NC}                   ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}                                                                  ${YELLOW}║${NC}"
        echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "Nothing to uninstall! Have a great day! 👋"
        echo ""
        exit 0
    fi

    # Count what will be removed
    local doc_count=0
    local cmd_count=0

    if [ -d "$VAULT_DIR" ]; then
        doc_count=$(find "$VAULT_DIR" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    fi

    for cmd in ctx-init ctx-status ctx-mode ctx-help ctx-new ctx-doc ctx-update ctx-search ctx-read; do
        if [ -f "$COMMANDS_DIR/$cmd.md" ]; then
            ((cmd_count++))
        fi
    done

    # Check if settings.json has ContextVault hooks
    local has_hooks="no"
    if [ -f "$SETTINGS_JSON" ]; then
        if grep -q "ctx-session-start" "$SETTINGS_JSON" 2>/dev/null || grep -q "ContextVault" "$SETTINGS_JSON" 2>/dev/null; then
            has_hooks="yes"
        fi
    fi

    # Check for hooks directory
    local has_hooks_dir="no"
    local hooks_count=0
    if [ -d "$HOOKS_DIR" ]; then
        hooks_count=$(find "$HOOKS_DIR" -name "ctx-*.sh" 2>/dev/null | wc -l | tr -d ' ')
        if [ "$hooks_count" -gt 0 ]; then
            has_hooks_dir="yes"
        fi
    fi

    echo -e "${BOLD}📋 What will be removed:${NC}"
    echo ""
    echo -e "  ${RED}•${NC} ~/.claude/CLAUDE.md ${DIM}(global instructions)${NC}"
    echo -e "  ${RED}•${NC} ~/.claude/vault/ ${DIM}($doc_count documents)${NC}"
    echo -e "  ${RED}•${NC} ~/.claude/commands/ctx-*.md ${DIM}($cmd_count commands)${NC}"
    if [ "$has_hooks_dir" = "yes" ]; then
        echo -e "  ${RED}•${NC} ~/.claude/hooks/ ${DIM}($hooks_count hook scripts)${NC}"
    fi
    if [ "$has_hooks" = "yes" ]; then
        echo -e "  ${RED}•${NC} ~/.claude/settings.json ${DIM}(ContextVault hooks config)${NC}"
    fi
    echo ""
    echo -e "${YELLOW}⚠️  Your global documentation will be removed!${NC}"
    echo ""

    # Skip all prompts if --force flag is provided
    if [ "$FORCE_MODE" = true ]; then
        print_info "Running in non-interactive mode (--force)"
        echo ""

        # Always backup in force mode
        backup_existing
    else
        # PROMPT 1: Are you sure?
        echo -e "${BOLD}Step 1/2:${NC} Confirmation"
        read_input "Are you sure you want to uninstall ContextVault? (y/N) " "n"
        echo ""

        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            show_cancelled
            exit 0
        fi

        # Sad animation
        sad_animation

        # PROMPT 2: Want to backup?
        echo -e "${BOLD}Step 2/2:${NC} Backup Options"
        echo -e "${DIM}We can save your data so you can restore it later.${NC}"
        echo ""
        read_input "Create a backup before uninstalling? (Y/n) " "y"
        echo ""
        echo ""

        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            backup_existing
        else
            print_warning "Skipping backup (your data will be permanently deleted)"
            echo ""
        fi
    fi

    # Sweeping animation
    sweep_animation "Cleaning up ContextVault..."

    # Remove files with progress
    print_step "🧹 Removing ContextVault files..."
    echo ""

    local removed_count=0
    local errors=0

    # Remove CLAUDE.md
    if [ -f "$CLAUDE_MD" ]; then
        if rm "$CLAUDE_MD" 2>/dev/null; then
            print_success "Removed CLAUDE.md"
            ((removed_count++))
        else
            print_error "Failed to remove CLAUDE.md"
            ((errors++))
        fi
    fi

    # Remove vault
    if [ -d "$VAULT_DIR" ]; then
        if rm -rf "$VAULT_DIR" 2>/dev/null; then
            print_success "Removed vault directory ($doc_count documents)"
            ((removed_count++))
        else
            print_error "Failed to remove vault directory"
            ((errors++))
        fi
    fi

    # Remove commands
    local removed_cmds=0
    for cmd in ctx-init ctx-status ctx-mode ctx-help ctx-new ctx-doc ctx-update ctx-search ctx-read; do
        if [ -f "$COMMANDS_DIR/$cmd.md" ]; then
            if rm "$COMMANDS_DIR/$cmd.md" 2>/dev/null; then
                ((removed_cmds++))
            else
                ((errors++))
            fi
        fi
    done

    if [ $removed_cmds -gt 0 ]; then
        print_success "Removed $removed_cmds commands"
        ((removed_count++))
    fi

    # Remove hooks directory
    if [ -d "$HOOKS_DIR" ]; then
        local hooks_removed=0
        for hook in ctx-session-start.sh ctx-session-end.sh; do
            if [ -f "$HOOKS_DIR/$hook" ]; then
                if rm "$HOOKS_DIR/$hook" 2>/dev/null; then
                    ((hooks_removed++))
                else
                    ((errors++))
                fi
            fi
        done
        if [ $hooks_removed -gt 0 ]; then
            print_success "Removed $hooks_removed hook scripts"
            ((removed_count++))
        fi
        # Remove hooks dir if empty
        rmdir "$HOOKS_DIR" 2>/dev/null
    fi

    # Remove settings.json hooks (only if it contains ContextVault hooks)
    local has_ctx_hooks=false
    if [ -f "$SETTINGS_JSON" ]; then
        if grep -q "ctx-session-start" "$SETTINGS_JSON" 2>/dev/null || grep -q "ContextVault" "$SETTINGS_JSON" 2>/dev/null; then
            has_ctx_hooks=true
        fi
    fi
    if [ "$has_ctx_hooks" = true ]; then
        # Check if settings.json ONLY contains ContextVault hooks (safe to delete entirely)
        # by checking if it has other top-level keys besides "hooks"
        if command -v jq &> /dev/null; then
            local other_keys=$(cat "$SETTINGS_JSON" | jq 'keys | map(select(. != "hooks")) | length' 2>/dev/null || echo "0")
            if [ "$other_keys" = "0" ]; then
                # Only has hooks, safe to remove entirely
                if rm "$SETTINGS_JSON" 2>/dev/null; then
                    print_success "Removed settings.json (ContextVault hooks)"
                    ((removed_count++))
                fi
            else
                # Has other settings, just warn user
                print_warning "settings.json has other settings - ContextVault hooks left in place"
                print_info "Manually remove ContextVault hooks from ~/.claude/settings.json if needed"
            fi
        else
            # No jq, just remove it (was likely only created by us)
            if rm "$SETTINGS_JSON" 2>/dev/null; then
                print_success "Removed settings.json (ContextVault hooks)"
                ((removed_count++))
            fi
        fi
    fi

    sleep 0.5

    # Show result
    if [ $errors -gt 0 ]; then
        show_failure "Some files could not be removed"
        exit 1
    fi

    # Wave goodbye
    wave_animation

    # Success!
    goodbye_celebration

    # Show backup location if created
    if [ -n "$BACKUP_LOCATION" ]; then
        echo -e "📦 ${BOLD}Your backup is safe at:${NC}"
        echo -e "   ${CYAN}$BACKUP_LOCATION${NC}"
        echo ""
        echo -e "${DIM}When you reinstall, ContextVault will offer to restore from this backup!${NC}"
        echo ""
    fi

    echo -e "${DIM}────────────────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "We hope to see you again! 👋"
    echo ""
    echo -e "Reinstall anytime with:"
    echo -e "${CYAN}curl -fsSL https://raw.githubusercontent.com/ahmadzein/ContextVault/main/install-contextvault.sh | bash${NC}"
    echo ""
}

# Run uninstall
uninstall
