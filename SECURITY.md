# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.8.x   | Yes       |
| < 1.8   | No        |

## Reporting a Vulnerability

If you discover a security vulnerability in ContextVault, please report it responsibly:

1. **Do NOT** open a public GitHub issue
2. **Email**: Open a private security advisory via [GitHub Security Advisories](https://github.com/ahmadzein/ContextVault/security/advisories/new)
3. Include: description, steps to reproduce, potential impact

We will respond within 48 hours and work with you on a fix before public disclosure.

## Security Considerations

ContextVault is a local-first documentation system. Key security notes:

- **All data stays local** — vault docs are stored in `~/.claude/vault/` and `./.claude/vault/`
- **No network calls** — the installer and hooks make zero external requests
- **No credentials stored** — ContextVault does not handle auth tokens or secrets
- **Hook scripts** run locally as bash scripts with your user permissions
- **The installer** should be reviewed before running (`curl | bash` — always inspect first)

## Scope

The following are in scope for security reports:
- Command injection via hook scripts
- Path traversal in vault operations
- Unintended file access or modification
- Data leakage to unintended locations
