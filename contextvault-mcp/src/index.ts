#!/usr/bin/env node
import { main } from './cli.js';

main().catch((err) => {
  console.error('ContextVault MCP Server error:', err);
  process.exit(1);
});
