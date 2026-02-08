import * as fs from 'node:fs';
import * as path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function getVersion(): string {
  const pkgPath = path.resolve(__dirname, '..', 'package.json');
  try {
    const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf-8'));
    return pkg.version ?? 'unknown';
  } catch {
    return 'unknown';
  }
}

async function checkForUpdate(currentVersion: string): Promise<void> {
  const https = await import('node:https');

  return new Promise((resolve) => {
    const req = https.get(
      'https://registry.npmjs.org/contextvault-mcp/latest',
      { headers: { Accept: 'application/json' }, timeout: 5000 },
      (res) => {
        let data = '';
        res.on('data', (chunk: Buffer) => { data += chunk; });
        res.on('end', () => {
          try {
            const latest = JSON.parse(data).version;
            if (latest && latest !== currentVersion) {
              process.stderr.write(`\n  Update available: ${currentVersion} → ${latest}\n`);
              process.stderr.write(`  Run: npx contextvault-mcp@latest --version\n`);
              process.stderr.write(`  Or clear cache: rm -rf ~/.npm/_npx && restart your MCP client\n\n`);
            } else {
              process.stderr.write(`\n  You are on the latest version (${currentVersion}).\n\n`);
            }
          } catch {
            process.stderr.write('\n  Could not parse registry response.\n\n');
          }
          resolve();
        });
      }
    );
    req.on('error', () => {
      process.stderr.write('\n  Could not reach npm registry. Check your network.\n\n');
      resolve();
    });
    req.on('timeout', () => {
      req.destroy();
      process.stderr.write('\n  Request to npm registry timed out.\n\n');
      resolve();
    });
  });
}

function printBanner(version: string): void {
  process.stderr.write(`
  ContextVault MCP Server  v${version}
  ────────────────────────────────

  Status:  Running (stdio transport)
  Docs:    https://ctx-vault.com
  GitHub:  https://github.com/ahmadzein/ContextVault

  This server communicates over stdin/stdout using the
  Model Context Protocol. It is not meant to be used
  interactively in a terminal.

  Setup — add to your MCP client config:

    {
      "mcpServers": {
        "contextvault": {
          "command": "npx",
          "args": ["-y", "contextvault-mcp"]
        }
      }
    }

  Flags:
    --version, -v       Show version number
    --help, -h          Show this help message
    --check-update      Check for newer versions on npm

  Press Ctrl+C to exit.
\n`);
}

function printHelp(version: string): void {
  process.stdout.write(`
  contextvault-mcp v${version}
  MCP server for persistent AI context management.

  Usage:
    contextvault-mcp              Start MCP server (stdio)
    contextvault-mcp --version    Show version
    contextvault-mcp --help       Show this help
    contextvault-mcp --check-update  Check for updates

  Configuration:
    Add to your MCP client's config file:

    {
      "mcpServers": {
        "contextvault": {
          "command": "npx",
          "args": ["-y", "contextvault-mcp"]
        }
      }
    }

  Documentation: https://ctx-vault.com
  Issues:        https://github.com/ahmadzein/ContextVault/issues
\n`);
}

export async function main(): Promise<void> {
  const args = process.argv.slice(2);
  const version = getVersion();

  // --version / -v
  if (args.includes('--version') || args.includes('-v')) {
    process.stdout.write(version + '\n');
    process.exit(0);
  }

  // --help / -h
  if (args.includes('--help') || args.includes('-h')) {
    printHelp(version);
    process.exit(0);
  }

  // --check-update
  if (args.includes('--check-update')) {
    process.stderr.write(`  Current version: ${version}\n`);
    process.stderr.write('  Checking npm registry...\n');
    await checkForUpdate(version);
    process.exit(0);
  }

  // TTY detection: show banner when run interactively
  if (process.stdin.isTTY) {
    printBanner(version);
  }

  // Start the MCP server
  const { ContextVaultServer } = await import('./server.js');
  const server = new ContextVaultServer(version);
  await server.run();
}
