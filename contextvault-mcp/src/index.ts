#!/usr/bin/env node
import { ContextVaultServer } from './server.js';

const server = new ContextVaultServer();
server.run().catch((err) => {
  console.error('ContextVault MCP Server error:', err);
  process.exit(1);
});
