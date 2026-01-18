# ContextVault

**External Context Management System for Claude Code**

A two-tier documentation system for efficient context management across all your projects. Inspired by concepts from arxiv:2512.24601.

---

## Quick Install

### One-liner (when hosted)

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/install-contextvault.sh | bash
```

### Manual Install

```bash
# Download the installer
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/install-contextvault.sh

# Make it executable
chmod +x install-contextvault.sh

# Run it
./install-contextvault.sh
```

### Local Install

If you have the file locally:

```bash
chmod +x install-contextvault.sh
./install-contextvault.sh
```

---

## What Gets Installed

```
~/.claude/
├── CLAUDE.md                    # Global instructions (read by Claude in all projects)
├── commands/                    # Custom slash commands
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
    ├── index.md                 # Global knowledge index
    ├── settings.json            # Mode settings
    ├── _template.md             # Document template
    ├── G001_contextvault_system.md  # First global doc
    └── _project_init_template/  # Template for new projects
```

---

## Available Commands

After installation, these commands are available in Claude Code:

| Command | Description |
|---------|-------------|
| `/ctx-help` | Show all commands and quick reference |
| `/ctx-status` | Check global and project status |
| `/ctx-init` | Initialize ContextVault in current project |
| `/ctx-mode` | Toggle between full/local/global mode |
| `/ctx-new` | Create new document with guided routing |
| `/ctx-doc` | Quick document after completing a task |
| `/ctx-update` | Update existing document by ID |
| `/ctx-search` | Search both indexes for a topic |
| `/ctx-read` | Read a document by ID |

---

## How It Works

### Two-Tier System

1. **Global Tier** (`~/.claude/vault/`)
   - Cross-project knowledge
   - Reusable patterns, best practices
   - Available in ALL projects
   - Documents use `G###` prefix (e.g., `G001`, `G002`)

2. **Project Tier** (`./.claude/vault/`)
   - Project-specific knowledge
   - Architecture, configs for THIS project only
   - Created per-project with `/ctx-init`
   - Documents use `P###` prefix (e.g., `P001`, `P002`)

### Context Management

- **Maximum in context:** 2 indexes + 1 document (~200 lines)
- **Index:** Quick reference with 15-word summaries
- **Document:** Detailed info, max 100 lines each
- **No duplicates:** Update existing docs, never create duplicates

### Modes

| Mode | Description |
|------|-------------|
| `full` | Use both global + project (default) |
| `local` | Project only, ignore global |
| `global` | Global only, ignore project |

Switch modes with: `/ctx-mode [full|local|global]`

---

## Quick Start

### 1. Install ContextVault

```bash
./install-contextvault.sh
```

### 2. Start Claude Code in any project

```bash
claude
```

### 3. Initialize project vault (optional)

```
/ctx-init
```

### 4. Check status

```
/ctx-status
```

### 5. Document as you work

```
/ctx-doc
```

---

## Workflow Example

```
# Start session
> /ctx-status                    # Check what docs exist

# Work on a task...
# (Claude reads relevant docs from indexes)

# After completing task
> /ctx-doc                       # Document what you learned

# Search for existing knowledge
> /ctx-search authentication     # Find related docs

# Read specific document
> /ctx-read G001                 # Read by ID

# Update existing document
> /ctx-update G001               # Add new info to existing doc
```

---

## Core Rules

1. **Read indexes first** - Always check what exists
2. **No duplicates** - Update existing, don't create new
3. **No redundancy** - One topic = one document
4. **No conflicts** - Replace outdated info, don't append
5. **Correct routing** - Global vs Project
6. **Minimal loading** - Max 2 indexes + 1 doc
7. **Size limits** - 50 entries/index, 100 lines/doc
8. **Always update index** - Keep it current

---

## Installer Commands

```bash
./install-contextvault.sh              # Install (default)
./install-contextvault.sh install      # Install
./install-contextvault.sh uninstall    # Remove ContextVault
./install-contextvault.sh update       # Reinstall/update
./install-contextvault.sh status       # Check installation
./install-contextvault.sh help         # Show help
```

---

## Uninstall

```bash
./install-contextvault.sh uninstall
```

This creates a backup before removing files.

---

## Troubleshooting

### Commands not showing up

Make sure you're running Claude Code (the CLI), not Claude.ai web interface. Commands are only available in Claude Code.

### Permission denied

```bash
chmod +x install-contextvault.sh
```

### Existing CLAUDE.md

The installer will ask before overwriting. It creates a timestamped backup.

### Check installation

```bash
./install-contextvault.sh status
```

---

## Requirements

- Claude Code CLI installed
- Bash shell
- macOS or Linux

---

## Acknowledgments

Inspired by concepts from:
- "Recursive Language Models" (arxiv:2512.24601)

This is an independent implementation and is not affiliated with or endorsed by the paper's authors.

---

## License

MIT
