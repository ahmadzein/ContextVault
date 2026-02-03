# Contributing to ContextVault

Thanks for your interest in contributing! Here's how to get started.

## Quick Start

1. **Fork** the repository
2. **Clone** your fork: `git clone https://github.com/YOUR_USERNAME/ContextVault.git`
3. **Create a branch**: `git checkout -b feature/your-feature`
4. **Make changes** to `install-contextvault.sh` (main installer)
5. **Test locally**: `bash install-contextvault.sh`
6. **Commit**: `git commit -m "feat: description of change"`
7. **Push**: `git push origin feature/your-feature`
8. **Open a PR** against `main`

## Project Structure

```
install-contextvault.sh    Main installer (all commands, hooks, templates)
uninstall-contextvault.sh  Uninstaller with backup support
README.md                  Documentation
CHANGELOG.md               Version history
```

The installer is a single bash script that generates all files (CLAUDE.md, slash commands, hooks, vault templates). Each command is a function like `create_cmd_ctx_doc()` that outputs a markdown heredoc.

## Adding a New Command

See vault doc P003 or search the installer for an existing command like `create_cmd_ctx_doc` and follow the same pattern. You need to:

1. Add `create_cmd_ctx_YOURCOMMAND()` function
2. Add it to the command array in `install_contextvault()`
3. Add it to the uninstaller's command list
4. Add it to `/ctx-help` output
5. Update command count references

## Commit Messages

Use conventional commits:
- `feat:` — new feature
- `fix:` — bug fix
- `docs:` — documentation only
- `refactor:` — code change that doesn't add feature or fix bug

## Reporting Issues

- Use [GitHub Issues](https://github.com/ahmadzein/ContextVault/issues)
- Include your OS, Claude Code version, and steps to reproduce
- Attach relevant hook output if applicable

## Code Style

- Bash scripts: use `local` for variables, quote all expansions, use `[[ ]]` over `[ ]`
- Keep heredoc templates readable — they become user-facing files
- Test on both macOS and Linux if possible
