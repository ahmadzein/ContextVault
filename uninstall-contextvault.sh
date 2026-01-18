#!/bin/bash

#===============================================================================
#
#   🗑️  ContextVault Uninstaller
#
#   Safely removes ContextVault from your system
#   (Don't worry, we'll create a backup first!)
#
#   Usage:
#     ./uninstall-contextvault.sh           # Interactive (asks for confirmation)
#     ./uninstall-contextvault.sh --force   # Non-interactive (no prompt)
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
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"

print_header() {
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC}                                                                  ${RED}║${NC}"
    echo -e "${RED}║${NC}   ${BOLD}${WHITE}🗑️  ContextVault Uninstaller${NC}                                  ${RED}║${NC}"
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

backup_existing() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$HOME/.contextvault_backup_$timestamp"

    print_step "📦 Creating backup at $backup_dir"

    mkdir -p "$backup_dir"

    if [ -f "$CLAUDE_MD" ]; then
        cp "$CLAUDE_MD" "$backup_dir/"
    fi

    if [ -d "$VAULT_DIR" ]; then
        cp -r "$VAULT_DIR" "$backup_dir/"
    fi

    if [ -d "$COMMANDS_DIR" ]; then
        mkdir -p "$backup_dir/commands"
        for cmd in ctx-init ctx-status ctx-mode ctx-help ctx-new ctx-doc ctx-update ctx-search ctx-read; do
            if [ -f "$COMMANDS_DIR/$cmd.md" ]; then
                cp "$COMMANDS_DIR/$cmd.md" "$backup_dir/commands/"
            fi
        done
    fi

    print_success "Backup created at: $backup_dir"
    echo ""
}

uninstall() {
    print_header

    # Check if installed
    if [ ! -f "$CLAUDE_MD" ] && [ ! -d "$VAULT_DIR" ]; then
        echo -e "${YELLOW}🤔 ContextVault doesn't seem to be installed.${NC}"
        echo ""
        echo "Nothing to uninstall! Have a great day! 👋"
        echo ""
        exit 0
    fi

    echo -e "${BOLD}This will remove:${NC}"
    echo ""
    echo -e "  ${RED}•${NC} ~/.claude/CLAUDE.md"
    echo -e "  ${RED}•${NC} ~/.claude/vault/ ${DIM}(your global docs!)${NC}"
    echo -e "  ${RED}•${NC} ~/.claude/commands/ctx-*.md ${DIM}(9 commands)${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  Your global documentation will be removed!${NC}"
    echo -e "${DIM}   (But don't worry, we'll create a backup first)${NC}"
    echo ""

    # Skip confirmation if --force flag is provided
    if [ "$FORCE_MODE" = false ]; then
        read -p "Are you sure you want to uninstall ContextVault? (y/N) " -n 1 -r
        echo ""

        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo ""
            echo -e "${GREEN}😅 Phew! Uninstall cancelled.${NC}"
            echo "ContextVault lives to document another day! 📝"
            echo ""
            exit 0
        fi
        echo ""
    else
        echo -e "${CYAN}ℹ${NC} Running in non-interactive mode (--force)"
        echo ""
    fi

    # Create backup first
    backup_existing

    # Remove files
    print_step "🧹 Removing ContextVault files..."

    if [ -f "$CLAUDE_MD" ]; then
        rm "$CLAUDE_MD"
        print_success "Removed CLAUDE.md"
    fi

    if [ -d "$VAULT_DIR" ]; then
        rm -rf "$VAULT_DIR"
        print_success "Removed vault directory"
    fi

    # Remove commands
    local removed_count=0
    for cmd in ctx-init ctx-status ctx-mode ctx-help ctx-new ctx-doc ctx-update ctx-search ctx-read; do
        if [ -f "$COMMANDS_DIR/$cmd.md" ]; then
            rm "$COMMANDS_DIR/$cmd.md"
            ((removed_count++))
        fi
    done

    if [ $removed_count -gt 0 ]; then
        print_success "Removed $removed_count commands"
    fi

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}                                                                  ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}   ${BOLD}${WHITE}✅ ContextVault has been uninstalled${NC}                          ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}                                                                  ${GREEN}║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "📦 Your backup is safe at: ${CYAN}~/.contextvault_backup_*${NC}"
    echo ""
    echo -e "${DIM}We hope to see you again! 👋${NC}"
    echo -e "${DIM}Reinstall anytime: ${CYAN}curl -fsSL https://raw.githubusercontent.com/ahmadzein/ContextVault/main/install-contextvault.sh | bash${NC}"
    echo ""
}

uninstall
