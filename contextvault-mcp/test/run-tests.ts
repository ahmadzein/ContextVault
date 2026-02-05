#!/usr/bin/env npx tsx
/**
 * ContextVault MCP Server - Integration Tests
 * Tests all 25 tools via direct function calls
 */

import * as fs from 'node:fs';
import * as path from 'node:path';
import * as os from 'node:os';
import { VaultManager } from '../src/vault/manager.js';
import { handleInit } from '../src/tools/init.js';
import { handleStatus } from '../src/tools/status.js';
import { handleDoc } from '../src/tools/doc.js';
import { handleError } from '../src/tools/error.js';
import { handleDecision } from '../src/tools/decision.js';
import { handleSearch } from '../src/tools/search.js';
import { handleRead } from '../src/tools/read.js';
import { handleHandoff } from '../src/tools/handoff.js';
import { handlePlan } from '../src/tools/plan.js';
import { handleBootstrap } from '../src/tools/bootstrap.js';
import { handleSnippet } from '../src/tools/snippet.js';
import { handleIntel } from '../src/tools/intel.js';
import { handleUpdate } from '../src/tools/update.js';
import { handleNew } from '../src/tools/new.js';
import { handleMode } from '../src/tools/mode.js';
import { handleHelp } from '../src/tools/help.js';
import { handleHealth } from '../src/tools/health.js';
import { handleNote } from '../src/tools/note.js';
import { handleChangelog } from '../src/tools/changelog.js';
import { handleLink } from '../src/tools/link.js';
import { handleQuiz } from '../src/tools/quiz.js';
import { handleExplain } from '../src/tools/explain.js';
import { handleUpgrade } from '../src/tools/upgrade.js';
import { handleShare } from '../src/tools/share.js';
import { handleImport } from '../src/tools/import.js';

// --- Test Infrastructure ---

const TEST_DIR = path.join(os.tmpdir(), `contextvault-test-${Date.now()}`);
const GLOBAL_DIR = path.join(TEST_DIR, 'global');
let passed = 0;
let failed = 0;
const failures: string[] = [];

function test(name: string, fn: () => void) {
  try {
    fn();
    passed++;
    console.log(`  PASS  ${name}`);
  } catch (err) {
    failed++;
    const msg = err instanceof Error ? err.message : String(err);
    failures.push(`${name}: ${msg}`);
    console.log(`  FAIL  ${name}: ${msg}`);
  }
}

function assert(condition: boolean, msg: string) {
  if (!condition) throw new Error(msg);
}

function assertContains(text: string, needle: string, label?: string) {
  if (!text.includes(needle)) {
    throw new Error(`${label ?? 'Text'} should contain "${needle}" but got: ${text.slice(0, 200)}`);
  }
}

function getText(result: { content: { type: string; text: string }[] }): string {
  return result.content.map(c => c.text).join('\n');
}

// --- Setup ---

function setup() {
  // Create isolated test directories
  fs.mkdirSync(TEST_DIR, { recursive: true });
  fs.mkdirSync(GLOBAL_DIR, { recursive: true });

  // Override HOME for global vault
  process.env.HOME = TEST_DIR;
  process.chdir(path.join(TEST_DIR));
}

function cleanup() {
  try {
    fs.rmSync(TEST_DIR, { recursive: true, force: true });
  } catch { /* ignore */ }
}

// --- Tests ---

function runTests() {
  console.log('\n========================================');
  console.log('  ContextVault MCP Server - Test Suite');
  console.log('========================================\n');

  const vault = new VaultManager(TEST_DIR);

  // 1. ctx_init
  console.log('[ctx_init]');
  test('initializes project vault', () => {
    const result = handleInit(vault, {});
    const text = getText(result);
    assertContains(text, 'Setup Complete');
    assertContains(text, '.contextvault');
    assert(fs.existsSync(path.join(TEST_DIR, '.contextvault', 'index.md')), 'Project index should exist');
  });

  test('init with force reinitializes', () => {
    const result = handleInit(vault, { force: true });
    const text = getText(result);
    assertContains(text, 'Setup Complete');
  });

  // 2. ctx_status
  console.log('\n[ctx_status]');
  test('shows vault status', () => {
    const result = handleStatus(vault);
    const text = getText(result);
    assertContains(text, 'ContextVault Status');
    assertContains(text, 'Global Vault');
    assertContains(text, 'Project Vault');
  });

  // 3. ctx_doc
  console.log('\n[ctx_doc]');
  test('creates a document', () => {
    const result = handleDoc(vault, { topic: 'Auth System', content: 'Uses JWT tokens with 15min expiry. Refresh tokens in Redis.' });
    const text = getText(result);
    assertContains(text, 'P001');
    assertContains(text, 'Auth System');
    assert(!result.isError, 'Should not be an error');
  });

  test('detects duplicate topic', () => {
    const result = handleDoc(vault, { topic: 'Auth System', content: 'Another auth doc' });
    const text = getText(result);
    assertContains(text, 'existing document');
    assertContains(text, 'ctx_update');
  });

  test('requires topic and content', () => {
    const result = handleDoc(vault, { topic: 'Missing' });
    assert(result.isError === true, 'Should be an error');
  });

  // 4. ctx_error
  console.log('\n[ctx_error]');
  test('creates an error document', () => {
    const result = handleError(vault, {
      error_message: 'CORS policy blocked request',
      root_cause: 'Missing Access-Control-Allow-Origin header',
      solution: 'Added CORS middleware to Express server',
      prevention: 'Always configure CORS before adding routes',
    });
    const text = getText(result);
    assertContains(text, 'P002');
    assertContains(text, 'error');
  });

  // 5. ctx_decision
  console.log('\n[ctx_decision]');
  test('creates a decision document', () => {
    const result = handleDecision(vault, {
      decision: 'Use PostgreSQL over MongoDB',
      options: '1. PostgreSQL (relational)\n2. MongoDB (document)\n3. SQLite (embedded)',
      reasoning: 'Need ACID compliance and complex joins for financial data',
      tradeoffs: 'Harder to scale horizontally than MongoDB',
    });
    const text = getText(result);
    assertContains(text, 'P003');
    assertContains(text, 'Decision');
  });

  // 6. ctx_plan
  console.log('\n[ctx_plan]');
  test('creates a plan document', () => {
    const result = handlePlan(vault, {
      goal: 'Implement user authentication',
      steps: '1. Set up passport.js\n2. Create user model\n3. Add login/register routes\n4. Add JWT middleware',
      status: 'In Progress',
    });
    const text = getText(result);
    assertContains(text, 'P004');
    assertContains(text, 'Plan');
  });

  // 7. ctx_snippet
  console.log('\n[ctx_snippet]');
  test('creates a snippet in global vault', () => {
    const result = handleSnippet(vault, {
      name: 'Express error handler',
      code: 'app.use((err, req, res, next) => { res.status(500).json({ error: err.message }); });',
      language: 'javascript',
      use_case: 'Global error handler for Express apps',
    });
    const text = getText(result);
    assert(text.includes('G0') && text.includes('global vault'), 'Should create in global vault with G### ID');
  });

  // 8. ctx_intel
  console.log('\n[ctx_intel]');
  test('creates an intel document', () => {
    const result = handleIntel(vault, {
      area: 'Database layer',
      findings: 'Uses Prisma ORM. Models defined in schema.prisma. Migrations in prisma/migrations/.',
    });
    const text = getText(result);
    assert(text.includes('P0') && text.includes('Intel'), 'Should create intel doc with P### ID');
  });

  // 9. ctx_search
  console.log('\n[ctx_search]');
  test('finds documents by keyword', () => {
    const result = handleSearch(vault, { query: 'auth' });
    const text = getText(result);
    assertContains(text, 'P001');
    assertContains(text, 'Auth System');
  });

  test('returns no results for unknown query', () => {
    const result = handleSearch(vault, { query: 'xyznonexistent' });
    const text = getText(result);
    assertContains(text, 'No results');
  });

  // 10. ctx_read
  console.log('\n[ctx_read]');
  test('reads a document by ID', () => {
    const result = handleRead(vault, { id: 'P001' });
    const text = getText(result);
    assertContains(text, 'Auth System');
    assertContains(text, 'JWT tokens');
  });

  test('returns error for missing document', () => {
    const result = handleRead(vault, { id: 'P999' });
    const text = getText(result);
    assertContains(text, 'not found');
  });

  // 11. ctx_update
  console.log('\n[ctx_update]');
  test('updates an existing document', () => {
    const result = handleUpdate(vault, {
      id: 'P001',
      section: 'Key Points',
      content: '- Added: Password reset uses email link',
    });
    const text = getText(result);
    assertContains(text, 'Updated');
    assertContains(text, 'P001');

    // Verify content was added
    const doc = handleRead(vault, { id: 'P001' });
    assertContains(getText(doc), 'Password reset');
  });

  // 12. ctx_new
  console.log('\n[ctx_new]');
  test('creates a custom document', () => {
    const result = handleNew(vault, {
      title: 'Deployment Guide',
      content: 'Deploy to AWS ECS using GitHub Actions. Docker image pushed to ECR.',
      vault: 'project',
    });
    const text = getText(result);
    assert(text.includes('P0') && text.includes('Deployment Guide'), 'Should create doc with P### ID');
  });

  // 13. ctx_note
  console.log('\n[ctx_note]');
  test('adds a note to existing document', () => {
    const result = handleNote(vault, { id: 'P001', note: 'Remember to add rate limiting to auth endpoints' });
    const text = getText(result);
    assertContains(text, 'Note added');
    assertContains(text, 'P001');
  });

  // 14. ctx_link
  console.log('\n[ctx_link]');
  test('links two documents', () => {
    const result = handleLink(vault, { from_id: 'P001', to_id: 'P003' });
    const text = getText(result);
    assertContains(text, 'Linked');
    assertContains(text, 'P001');
    assertContains(text, 'P003');
  });

  // 15. ctx_mode
  console.log('\n[ctx_mode]');
  test('shows current mode', () => {
    const result = handleMode(vault, {});
    const text = getText(result);
    assertContains(text, 'local');
    assertContains(text, 'balanced');
  });

  test('changes mode', () => {
    const result = handleMode(vault, { mode: 'full', enforcement: 'strict' });
    const text = getText(result);
    assertContains(text, 'full');
    assertContains(text, 'strict');
  });

  // Reset mode back
  handleMode(vault, { mode: 'local', enforcement: 'balanced' });

  // 16. ctx_help
  console.log('\n[ctx_help]');
  test('shows help', () => {
    const result = handleHelp(vault);
    const text = getText(result);
    assertContains(text, 'ctx_doc');
    assertContains(text, 'ctx_error');
    assertContains(text, 'ctx_search');
    assert(text.includes('ctx_init'), 'Should list all commands');
  });

  // 17. ctx_health
  console.log('\n[ctx_health]');
  test('runs health check', () => {
    const result = handleHealth(vault);
    const text = getText(result);
    assertContains(text, 'Health Check');
    assertContains(text, 'Score');
  });

  // 18. ctx_changelog
  console.log('\n[ctx_changelog]');
  test('shows changelog', () => {
    const result = handleChangelog();
    const text = getText(result);
    assertContains(text, 'Changelog');
    assertContains(text, 'v1.0.0');
    assertContains(text, 'v1.8.4');
  });

  // 19. ctx_bootstrap
  console.log('\n[ctx_bootstrap]');
  test('scans project', () => {
    // Create a fake package.json for scanning
    fs.writeFileSync(path.join(TEST_DIR, 'package.json'), '{"name":"test","dependencies":{"express":"1.0"}}');
    const result = handleBootstrap(vault, {});
    const text = getText(result);
    assertContains(text, 'Bootstrap Scan');
    assertContains(text, 'Detected');
  });

  // 20. ctx_handoff
  console.log('\n[ctx_handoff]');
  test('creates session handoff', () => {
    const result = handleHandoff(vault, {
      completed: 'Set up auth system with JWT',
      in_progress: 'Adding password reset flow',
      next_steps: 'Complete password reset, then add 2FA',
    });
    const text = getText(result);
    assertContains(text, 'handoff');
    assertContains(text, 'Complete password reset');
  });

  // 21. ctx_quiz
  console.log('\n[ctx_quiz]');
  test('generates quiz questions', () => {
    const result = handleQuiz(vault, {});
    const text = getText(result);
    assertContains(text, 'Quiz');
  });

  // 22. ctx_explain
  console.log('\n[ctx_explain]');
  test('explain without save', () => {
    const result = handleExplain(vault, { concept: 'JWT Tokens' });
    const text = getText(result);
    assertContains(text, 'JWT Tokens');
  });

  test('explain with save', () => {
    const result = handleExplain(vault, { concept: 'OAuth2 Flow', save: true });
    const text = getText(result);
    assertContains(text, 'Saved');
  });

  // 23. ctx_upgrade
  console.log('\n[ctx_upgrade]');
  test('runs upgrade check', () => {
    const result = handleUpgrade(vault);
    const text = getText(result);
    assert(text.includes('Upgraded') || text.includes('Up to Date'), 'Should report upgrade status');
  });

  // 24. ctx_share
  console.log('\n[ctx_share]');
  test('exports documents as markdown', () => {
    const result = handleShare(vault, { ids: ['P001', 'P002'] });
    const text = getText(result);
    assertContains(text, 'Exported');
    assertContains(text, 'Auth System');
  });

  test('exports documents as JSON', () => {
    const result = handleShare(vault, { ids: ['P001'], format: 'json' });
    const text = getText(result);
    assert(text.startsWith('['), 'Should be JSON array');
    const parsed = JSON.parse(text);
    assert(parsed[0].id === 'P001', 'Should contain P001');
  });

  // 25. ctx_import
  console.log('\n[ctx_import]');
  test('import from legacy (no legacy vault)', () => {
    const result = handleImport(vault, { source_path: 'legacy' });
    const text = getText(result);
    assertContains(text, 'Legacy Import');
  });

  test('import from directory', () => {
    // Create a test source directory
    const srcDir = path.join(TEST_DIR, 'import-source');
    fs.mkdirSync(srcDir, { recursive: true });
    fs.writeFileSync(path.join(srcDir, 'test_doc.md'), '# Test Import\n\nImported content.');

    const result = handleImport(vault, { source_path: srcDir });
    const text = getText(result);
    assertContains(text, 'Imported');
  });

  // --- Results ---
  console.log('\n========================================');
  console.log(`  Results: ${passed} passed, ${failed} failed`);
  console.log('========================================\n');

  if (failures.length > 0) {
    console.log('Failures:');
    failures.forEach(f => console.log(`  - ${f}`));
    console.log('');
  }

  return failed === 0;
}

// --- Run ---

setup();
try {
  const success = runTests();
  cleanup();
  process.exit(success ? 0 : 1);
} catch (err) {
  console.error('Test runner error:', err);
  cleanup();
  process.exit(1);
}
