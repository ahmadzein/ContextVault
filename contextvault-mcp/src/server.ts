import * as fs from 'node:fs';
import * as path from 'node:path';
import { fileURLToPath } from 'node:url';
import { McpServer, ResourceTemplate } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { z } from 'zod';
import { VaultManager } from './vault/manager.js';
import { ToolResponse } from './vault/types.js';

// Tool handlers
import { handleInit } from './tools/init.js';
import { handleStatus } from './tools/status.js';
import { handleDoc } from './tools/doc.js';
import { handleError } from './tools/error.js';
import { handleDecision } from './tools/decision.js';
import { handleSearch } from './tools/search.js';
import { handleRead } from './tools/read.js';
import { handleHandoff } from './tools/handoff.js';
import { handlePlan } from './tools/plan.js';
import { handleBootstrap } from './tools/bootstrap.js';
import { handleUpdate } from './tools/update.js';
import { handleNew } from './tools/new.js';
import { handleMode } from './tools/mode.js';
import { handleHelp } from './tools/help.js';
import { handleHealth } from './tools/health.js';
import { handleChangelog } from './tools/changelog.js';
import { handleLink } from './tools/link.js';
import { handleQuiz } from './tools/quiz.js';
import { handleUpgrade } from './tools/upgrade.js';
import { handleShare } from './tools/share.js';
import { handleImport } from './tools/import.js';
import { handleArchive } from './tools/archive.js';
import { handleReview } from './tools/review.js';

export class ContextVaultServer {
  private mcpServer: McpServer;
  private vault: VaultManager;

  constructor(version?: string) {
    this.vault = new VaultManager();
    const resolvedVersion = version ?? this.readPackageVersion();
    this.mcpServer = new McpServer({
      name: 'contextvault-mcp',
      version: resolvedVersion,
    });

    this.registerTools();
    this.registerResources();
  }

  private readPackageVersion(): string {
    try {
      const dir = path.dirname(fileURLToPath(import.meta.url));
      const pkgPath = path.resolve(dir, '..', 'package.json');
      return JSON.parse(fs.readFileSync(pkgPath, 'utf-8')).version ?? '0.0.0';
    } catch {
      return '0.0.0';
    }
  }

  /**
   * Wraps a tool handler with enforcement tracking and error handling.
   */
  private withTracking(name: string, result: ToolResponse): ToolResponse {
    // Track research activity on search/read operations
    if (name === 'ctx_search') {
      // query tracked below in individual handler
    } else if (name === 'ctx_read') {
      // id tracked below in individual handler
    }

    // Track edits for non-ctx tools
    if (!name.startsWith('ctx_')) {
      this.vault.trackEdit();
    }

    // Append enforcement reminder if needed (edit-based)
    const reminder = this.vault.getEnforcementReminder();
    if (reminder && !name.startsWith('ctx_')) {
      const lastContent = result.content[result.content.length - 1];
      if (lastContent?.type === 'text') {
        lastContent.text += reminder;
      }
    }

    // Append research reminder if needed (non-blocking nudge)
    const researchReminder = this.vault.getResearchReminder();
    if (researchReminder && (name === 'ctx_search' || name === 'ctx_read')) {
      const lastContent = result.content[result.content.length - 1];
      if (lastContent?.type === 'text') {
        lastContent.text += researchReminder;
      }
    }

    return result;
  }

  private registerTools(): void {
    const vault = this.vault;

    // ── ctx_init ──────────────────────────────────────────────────
    this.mcpServer.registerTool(
      'ctx_init',
      {
        title: 'Initialize Vault',
        description: `Initialize ContextVault in the current project. ContextVault is a persistent documentation system for AI coding assistants — it stores learnings, decisions, bug fixes, and session handoffs in structured markdown documents organized into global (cross-project) and project-specific vaults.

Creates the .contextvault/ directory with index.md, settings.json, and archive folder.

Args:
  - force (boolean): Reinitialize even if vault already exists (default: false)

Returns: Setup confirmation with directory structure created.

Use when starting a new project or onboarding to an existing codebase. Use ctx_upgrade instead if a vault already exists but needs format updates.`,
        inputSchema: {
          force: z.boolean().optional().default(false).describe('Force reinitialize even if vault exists'),
        },
        annotations: {
          readOnlyHint: false,
          destructiveHint: true,
          idempotentHint: true,
          openWorldHint: false,
        },
      },
      async (params) => {
        try {
          return this.withTracking('ctx_init', handleInit(vault, params as Record<string, unknown>));
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err);
          return { content: [{ type: 'text' as const, text: `Error: ${msg}` }], isError: true };
        }
      }
    );

    // ── ctx_status ────────────────────────────────────────────────
    this.mcpServer.registerTool(
      'ctx_status',
      {
        title: 'Vault Status',
        description: `Show ContextVault vault status for both global (~/.contextvault/) and project (.contextvault/) vaults.

Returns: Mode (local/global/full), enforcement level (light/balanced/strict), document counts, max limits, and vault paths. Also returns structuredContent with machine-readable stats.`,
        annotations: {
          readOnlyHint: true,
          destructiveHint: false,
          idempotentHint: true,
          openWorldHint: false,
        },
      },
      async () => {
        try {
          const result = this.withTracking('ctx_status', handleStatus(vault));
          const stats = vault.getStats();
          return {
            ...result,
            structuredContent: {
              mode: stats.mode,
              enforcement: stats.enforcement,
              global: { docs: stats.globalDocs, maxDocs: stats.globalMaxDocs, path: stats.globalPath, exists: stats.globalExists },
              project: { docs: stats.projectDocs, maxDocs: stats.projectMaxDocs, path: stats.projectPath, exists: stats.projectExists },
            },
          };
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err);
          return { content: [{ type: 'text' as const, text: `Error: ${msg}` }], isError: true };
        }
      }
    );

    // ── ctx_doc ───────────────────────────────────────────────────
    this.mcpServer.registerTool(
      'ctx_doc',
      {
        title: 'Document Learning',
        description: `Save a learning, code snippet, or codebase exploration finding to the ContextVault documentation vault. Automatically checks for existing documents on the same topic to prevent duplicates.

Args:
  - content (string, required): What you learned, explored, or the code snippet
  - topic (string): Topic name, e.g. "Auth System", "Docker Setup"
  - type ('learning' | 'intel' | 'snippet'): Document type — 'learning' for general knowledge, 'intel' for codebase exploration findings, 'snippet' for reusable code patterns (default: 'learning')
  - vault ('global' | 'project'): Where to store — 'global' for cross-project knowledge, 'project' for this codebase only (snippets default to global, others to project)
  - language (string): Programming language (for snippets)
  - area (string): Alias for topic (for intel type)
  - use_case (string): When to use this snippet

Returns: Confirmation with created document ID (e.g. P001, G005) and file path.

For bug fixes use ctx_error, for architectural choices use ctx_decision, for free-form documents use ctx_new.`,
        inputSchema: {
          content: z.string().describe('What you learned, explored, or the code snippet'),
          topic: z.string().optional().describe('Topic name, e.g. "Auth System", "Docker Setup"'),
          type: z.enum(['learning', 'intel', 'snippet']).optional().default('learning').describe('Document type'),
          vault: z.enum(['global', 'project']).optional().describe('Target vault'),
          language: z.string().optional().describe('Programming language (for snippets)'),
          area: z.string().optional().describe('Area explored (alias for topic, for intel type)'),
          use_case: z.string().optional().describe('When to use this snippet'),
        },
        annotations: {
          readOnlyHint: false,
          destructiveHint: false,
          idempotentHint: false,
          openWorldHint: false,
        },
      },
      async (params) => {
        try {
          return this.withTracking('ctx_doc', handleDoc(vault, params as Record<string, unknown>));
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err);
          return { content: [{ type: 'text' as const, text: `Error: ${msg}` }], isError: true };
        }
      }
    );

    // ── ctx_error ─────────────────────────────────────────────────
    this.mcpServer.registerTool(
      'ctx_error',
      {
        title: 'Document Bug Fix',
        description: `Save a bug fix to the ContextVault documentation vault so the same problem never wastes time twice. Creates a structured error document with diagnosis and resolution.

Args:
  - error_message (string, required): The exact error text or symptom encountered
  - root_cause (string, required): What actually caused the error
  - solution (string, required): How the error was fixed
  - prevention (string): How to prevent this in the future

Returns: Confirmation with created document ID (e.g. P005).`,
        inputSchema: {
          error_message: z.string().describe('The error message encountered'),
          root_cause: z.string().describe('What caused the error'),
          solution: z.string().describe('How the error was fixed'),
          prevention: z.string().optional().describe('How to prevent this in the future'),
        },
        annotations: {
          readOnlyHint: false,
          destructiveHint: false,
          idempotentHint: false,
          openWorldHint: false,
        },
      },
      async (params) => {
        try {
          return this.withTracking('ctx_error', handleError(vault, params as Record<string, unknown>));
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err);
          return { content: [{ type: 'text' as const, text: `Error: ${msg}` }], isError: true };
        }
      }
    );

    // ── ctx_decision ──────────────────────────────────────────────
    this.mcpServer.registerTool(
      'ctx_decision',
      {
        title: 'Document Decision',
        description: `Save an architectural or technical decision to the ContextVault documentation vault. Captures the what, why, and trade-offs so future sessions understand the reasoning.

Args:
  - decision (string, required): What was decided
  - reasoning (string, required): Why this option was chosen
  - options (string): Other options that were considered
  - tradeoffs (string): Trade-offs, downsides, or risks of the chosen approach

Returns: Confirmation with created document ID (e.g. P003).`,
        inputSchema: {
          decision: z.string().describe('What was decided'),
          reasoning: z.string().describe('Why this option was chosen'),
          options: z.string().optional().describe('Options that were considered'),
          tradeoffs: z.string().optional().describe('Trade-offs and downsides'),
        },
        annotations: {
          readOnlyHint: false,
          destructiveHint: false,
          idempotentHint: false,
          openWorldHint: false,
        },
      },
      async (params) => {
        try {
          return this.withTracking('ctx_decision', handleDecision(vault, params as Record<string, unknown>));
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err);
          return { content: [{ type: 'text' as const, text: `Error: ${msg}` }], isError: true };
        }
      }
    );

    // ── ctx_plan ──────────────────────────────────────────────────
    this.mcpServer.registerTool(
      'ctx_plan',
      {
        title: 'Document Plan',
        description: `Save an implementation plan to the ContextVault documentation vault. Tracks multi-step tasks with goals and progress so work can resume across sessions.

Args:
  - goal (string, required): What the plan aims to achieve
  - steps (string, required): Implementation steps as a markdown list (use - [ ] for incomplete, - [x] for done)
  - status (string): Current status (default: "In Progress")

Returns: Confirmation with created document ID (e.g. P007).`,
        inputSchema: {
          goal: z.string().describe('What the plan aims to achieve'),
          steps: z.string().describe('Implementation steps (markdown list)'),
          status: z.string().optional().default('In Progress').describe('Current status'),
        },
        annotations: {
          readOnlyHint: false,
          destructiveHint: false,
          idempotentHint: false,
          openWorldHint: false,
        },
      },
      async (params) => {
        try {
          return this.withTracking('ctx_plan', handlePlan(vault, params as Record<string, unknown>));
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err);
          return { content: [{ type: 'text' as const, text: `Error: ${msg}` }], isError: true };
        }
      }
    );

    // ── ctx_bootstrap ─────────────────────────────────────────────
    this.mcpServer.registerTool(
      'ctx_bootstrap',
      {
        title: 'Bootstrap Documentation',
        description: `Auto-scan the current project codebase and generate ContextVault documentation recommendations. Detects languages, frameworks, package managers, config files, and source directories.

Returns: Scan results with detected technologies and suggested documents to create (architecture docs, feature docs, etc.).

Read-only — does not create or modify any files. Use the recommendations to create docs with ctx_doc or ctx_new.`,
        inputSchema: {
          interactive: z.boolean().optional().default(false).describe('Show scan results before creating docs'),
        },
        annotations: {
          readOnlyHint: true,
          destructiveHint: false,
          idempotentHint: true,
          openWorldHint: false,
        },
      },
      async (params) => {
        try {
          return this.withTracking('ctx_bootstrap', handleBootstrap(vault, params as Record<string, unknown>));
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err);
          return { content: [{ type: 'text' as const, text: `Error: ${msg}` }], isError: true };
        }
      }
    );

    // ── ctx_handoff ───────────────────────────────────────────────
    this.mcpServer.registerTool(
      'ctx_handoff',
      {
        title: 'Session Handoff',
        description: `Create a session handoff summary in the ContextVault documentation vault. Captures what was done, what's in progress, and what to do next — so the next AI session (or human developer) can pick up seamlessly without losing context.

Args:
  - completed (string, required): What was completed this session
  - next_steps (string, required): What should be done next
  - in_progress (string): What is still in progress but not finished

Returns: Confirmation with handoff document ID (e.g. P010).

Use at the end of every coding session or when switching tasks.`,
        inputSchema: {
          completed: z.string().describe('What was completed this session'),
          next_steps: z.string().describe('What should be done next'),
          in_progress: z.string().optional().describe('What is still in progress'),
        },
        annotations: {
          readOnlyHint: false,
          destructiveHint: false,
          idempotentHint: false,
          openWorldHint: false,
        },
      },
      async (params) => {
        try {
          return this.withTracking('ctx_handoff', handleHandoff(vault, params as Record<string, unknown>));
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err);
          return { content: [{ type: 'text' as const, text: `Error: ${msg}` }], isError: true };
        }
      }
    );

    // ── ctx_search ────────────────────────────────────────────────
    this.mcpServer.registerTool(
      'ctx_search',
      {
        title: 'Search Documents',
        description: `Search ContextVault documents by keyword. Matches against document topics and summaries across both global (cross-project) and project-specific vaults.

Args:
  - query (string, required): Search keyword (matches topic names, summaries, and related terms)

Returns: Table of matching documents with ID, topic, vault tier (global/project), and summary.

Always search before creating new documents to avoid duplicates.`,
        inputSchema: {
          query: z.string().describe('Search query keyword'),
        },
        annotations: {
          readOnlyHint: true,
          destructiveHint: false,
          idempotentHint: true,
          openWorldHint: false,
        },
      },
      async (params) => {
        try {
          vault.trackResearch(params.query);
          return this.withTracking('ctx_search', handleSearch(vault, params as Record<string, unknown>));
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err);
          return { content: [{ type: 'text' as const, text: `Error: ${msg}` }], isError: true };
        }
      }
    );

    // ── ctx_read ──────────────────────────────────────────────────
    this.mcpServer.registerTool(
      'ctx_read',
      {
        title: 'Read Document',
        description: `Read a ContextVault document by its ID. Documents use prefixed IDs: P### for project-specific docs, G### for global cross-project docs.

Args:
  - id (string, required): Document ID, e.g. "P001", "G003"

Returns: Full document content in markdown format.`,
        inputSchema: {
          id: z.string().describe('Document ID (e.g. "P001", "G003")'),
        },
        annotations: {
          readOnlyHint: true,
          destructiveHint: false,
          idempotentHint: true,
          openWorldHint: false,
        },
      },
      async (params) => {
        try {
          vault.trackResearch(params.id);
          return this.withTracking('ctx_read', handleRead(vault, params as Record<string, unknown>));
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err);
          return { content: [{ type: 'text' as const, text: `Error: ${msg}` }], isError: true };
        }
      }
    );

    // ── ctx_update ────────────────────────────────────────────────
    this.mcpServer.registerTool(
      'ctx_update',
      {
        title: 'Update Document',
        description: `Update an existing ContextVault document by appending new content to a section. Automatically updates the "Last Updated" date and adds a history entry. Preserves existing content — appends rather than replaces.

Args:
  - id (string, required): Document ID to update (e.g. "P001", "G003")
  - content (string, required): New content to append
  - section (string): Section name to update (default: auto-detects "Current Understanding", "Summary", or "Key Points")

Returns: Confirmation of updated document.

Use instead of creating a new document when adding information to an existing topic.`,
        inputSchema: {
          id: z.string().describe('Document ID to update'),
          content: z.string().describe('New content to add/replace in the section'),
          section: z.string().optional().describe('Section name to update (e.g. "Current Understanding", "Key Points")'),
        },
        annotations: {
          readOnlyHint: false,
          destructiveHint: false,
          idempotentHint: false,
          openWorldHint: false,
        },
      },
      async (params) => {
        try {
          return this.withTracking('ctx_update', handleUpdate(vault, params as Record<string, unknown>));
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err);
          return { content: [{ type: 'text' as const, text: `Error: ${msg}` }], isError: true };
        }
      }
    );

    // ── ctx_new ───────────────────────────────────────────────────
    this.mcpServer.registerTool(
      'ctx_new',
      {
        title: 'Create Document',
        description: `Create a new free-form ContextVault document with custom title and content. Auto-generates a sequential ID (P### or G###) and filename from the title.

Args:
  - title (string, required): Document title (used to generate filename)
  - content (string, required): Document content in markdown
  - vault ('global' | 'project'): Where to store — 'global' for cross-project knowledge, 'project' for this codebase only (default: 'project')

Returns: Confirmation with new document ID and file path.

For structured documents, prefer ctx_doc (learnings/snippets/intel), ctx_error (bug fixes), or ctx_decision (architectural choices).`,
        inputSchema: {
          title: z.string().describe('Document title'),
          content: z.string().describe('Document content'),
          vault: z.enum(['global', 'project']).optional().default('project').describe('Which vault to create in'),
        },
        annotations: {
          readOnlyHint: false,
          destructiveHint: false,
          idempotentHint: false,
          openWorldHint: false,
        },
      },
      async (params) => {
        try {
          return this.withTracking('ctx_new', handleNew(vault, params as Record<string, unknown>));
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err);
          return { content: [{ type: 'text' as const, text: `Error: ${msg}` }], isError: true };
        }
      }
    );

    // ── ctx_mode ──────────────────────────────────────────────────
    this.mcpServer.registerTool(
      'ctx_mode',
      {
        title: 'Switch Mode',
        description: `Switch ContextVault mode or enforcement level. Shows current settings if no parameters provided.

Args:
  - mode ('local' | 'global' | 'full'): Which vaults to read/write — 'local' = project vault only, 'global' = global vault only, 'full' = both vaults
  - enforcement ('light' | 'balanced' | 'strict'): Documentation reminder frequency — 'light' = no mid-work reminders, 'balanced' = reminds after 8 edits across 2+ files, 'strict' = reminds after 4 edits

Returns: Confirmation of new settings or current settings if unchanged.`,
        inputSchema: {
          mode: z.enum(['local', 'global', 'full']).optional().describe('Vault mode'),
          enforcement: z.enum(['light', 'balanced', 'strict']).optional().describe('Enforcement level'),
        },
        annotations: {
          readOnlyHint: false,
          destructiveHint: false,
          idempotentHint: true,
          openWorldHint: false,
        },
      },
      async (params) => {
        try {
          return this.withTracking('ctx_mode', handleMode(vault, params as Record<string, unknown>));
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err);
          return { content: [{ type: 'text' as const, text: `Error: ${msg}` }], isError: true };
        }
      }
    );

    // ── ctx_help ──────────────────────────────────────────────────
    this.mcpServer.registerTool(
      'ctx_help',
      {
        title: 'Show Help',
        description: `Show all ContextVault tools organized by category (create, read, maintain, configure) with descriptions and usage guidance.

Returns: Complete tool reference with all available ctx_* tools and their purposes.`,
        annotations: {
          readOnlyHint: true,
          destructiveHint: false,
          idempotentHint: true,
          openWorldHint: false,
        },
      },
      async () => {
        try {
          return this.withTracking('ctx_help', handleHelp(vault));
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err);
          return { content: [{ type: 'text' as const, text: `Error: ${msg}` }], isError: true };
        }
      }
    );

    // ── ctx_health ────────────────────────────────────────────────
    this.mcpServer.registerTool(
      'ctx_health',
      {
        title: 'Health Check',
        description: `Run comprehensive ContextVault health check. Validates index consistency (do index entries match actual files?), file integrity (are documents well-formed?), size compliance (within line/word limits?), and code drift (has the codebase changed since docs were written?).

Returns: Overall health score (0-100), per-category breakdown, and detailed issues list with suggested fixes.`,
        annotations: {
          readOnlyHint: true,
          destructiveHint: false,
          idempotentHint: true,
          openWorldHint: false,
        },
      },
      async () => {
        try {
          return this.withTracking('ctx_health', handleHealth(vault));
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err);
          return { content: [{ type: 'text' as const, text: `Error: ${msg}` }], isError: true };
        }
      }
    );

    // ── ctx_changelog ─────────────────────────────────────────────
    this.mcpServer.registerTool(
      'ctx_changelog',
      {
        title: 'Version Changelog',
        description: `Show ContextVault version history with features, fixes, and improvements per release.

Returns: Formatted changelog from latest to earliest version.`,
        annotations: {
          readOnlyHint: true,
          destructiveHint: false,
          idempotentHint: true,
          openWorldHint: false,
        },
      },
      async () => {
        try {
          return this.withTracking('ctx_changelog', handleChangelog());
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err);
          return { content: [{ type: 'text' as const, text: `Error: ${msg}` }], isError: true };
        }
      }
    );

    // ── ctx_link ──────────────────────────────────────────────────
    this.mcpServer.registerTool(
      'ctx_link',
      {
        title: 'Link Documents',
        description: `Create bidirectional links between two related ContextVault documents. Adds a "Related Documents" section with cross-references to both docs, making it easy to navigate between related knowledge.

Args:
  - from_id (string, required): First document ID (e.g. "P001")
  - to_id (string, required): Second document ID (e.g. "P003")

Returns: Confirmation that both documents were linked.`,
        inputSchema: {
          from_id: z.string().describe('Source document ID'),
          to_id: z.string().describe('Target document ID'),
        },
        annotations: {
          readOnlyHint: false,
          destructiveHint: false,
          idempotentHint: true,
          openWorldHint: false,
        },
      },
      async (params) => {
        try {
          return this.withTracking('ctx_link', handleLink(vault, params as Record<string, unknown>));
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err);
          return { content: [{ type: 'text' as const, text: `Error: ${msg}` }], isError: true };
        }
      }
    );

    // ── ctx_quiz ──────────────────────────────────────────────────
    this.mcpServer.registerTool(
      'ctx_quiz',
      {
        title: 'Knowledge Quiz',
        description: `Generate quiz questions from ContextVault documents to test knowledge retention and verify documentation accuracy.

Args:
  - topic (string): Topic keyword to filter questions. If omitted, generates questions from all documents.

Returns: 5 quiz questions based on stored documentation content.`,
        inputSchema: {
          topic: z.string().optional().describe('Topic to quiz on'),
        },
        annotations: {
          readOnlyHint: true,
          destructiveHint: false,
          idempotentHint: false,
          openWorldHint: false,
        },
      },
      async (params) => {
        try {
          return this.withTracking('ctx_quiz', handleQuiz(vault, params as Record<string, unknown>));
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err);
          return { content: [{ type: 'text' as const, text: `Error: ${msg}` }], isError: true };
        }
      }
    );

    // ── ctx_upgrade ───────────────────────────────────────────────
    this.mcpServer.registerTool(
      'ctx_upgrade',
      {
        title: 'Upgrade Vault',
        description: `Upgrade an existing ContextVault to the latest format version. Creates missing directories (e.g. archive/), adds new settings fields, and fixes structural inconsistencies. Does not modify existing documents.

Returns: Summary of changes made during upgrade.

Use ctx_init for new projects. Use ctx_upgrade when a vault already exists but was created with an older version.`,
        annotations: {
          readOnlyHint: false,
          destructiveHint: false,
          idempotentHint: true,
          openWorldHint: false,
        },
      },
      async () => {
        try {
          return this.withTracking('ctx_upgrade', handleUpgrade(vault));
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err);
          return { content: [{ type: 'text' as const, text: `Error: ${msg}` }], isError: true };
        }
      }
    );

    // ── ctx_share ─────────────────────────────────────────────────
    this.mcpServer.registerTool(
      'ctx_share',
      {
        title: 'Export Documents',
        description: `Export ContextVault documents for sharing with teammates or creating backups.

Args:
  - ids (string[], required): Document IDs to export, e.g. ["P001", "P003", "G001"]
  - format ('md' | 'json'): Export format — 'md' for human-readable markdown, 'json' for machine-parseable (default: 'md')

Returns: Exported document content in the requested format.`,
        inputSchema: {
          ids: z.array(z.string()).describe('Document IDs to export (e.g. ["P001", "P003"])'),
          format: z.enum(['md', 'json']).optional().default('md').describe('Export format'),
        },
        annotations: {
          readOnlyHint: true,
          destructiveHint: false,
          idempotentHint: true,
          openWorldHint: false,
        },
      },
      async (params) => {
        try {
          return this.withTracking('ctx_share', handleShare(vault, params as Record<string, unknown>));
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err);
          return { content: [{ type: 'text' as const, text: `Error: ${msg}` }], isError: true };
        }
      }
    );

    // ── ctx_import ────────────────────────────────────────────────
    this.mcpServer.registerTool(
      'ctx_import',
      {
        title: 'Import Documents',
        description: `Import documents into ContextVault from an external source. Supports importing from a legacy vault directory (.claude/vault/), any directory of markdown files, or a single markdown file.

Args:
  - source_path (string, required): Path to import from. Use "legacy" to auto-detect and import from the old .claude/vault/ format.

Returns: Import summary with counts of imported and skipped documents.`,
        inputSchema: {
          source_path: z.string().describe('Path to import from. Use "legacy" to import from .claude/vault/'),
        },
        annotations: {
          readOnlyHint: false,
          destructiveHint: false,
          idempotentHint: true,
          openWorldHint: false,
        },
      },
      async (params) => {
        try {
          return this.withTracking('ctx_import', handleImport(vault, params as Record<string, unknown>));
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err);
          return { content: [{ type: 'text' as const, text: `Error: ${msg}` }], isError: true };
        }
      }
    );

    // ── ctx_archive ───────────────────────────────────────────────
    this.mcpServer.registerTool(
      'ctx_archive',
      {
        title: 'Archive Document',
        description: `Archive a ContextVault document that is deprecated, replaced, or no longer relevant. Moves the file to the archive/ folder, removes it from the active index, and records the archival reason. The document is preserved for history but no longer appears in searches.

Args:
  - id (string, required): Document ID to archive, e.g. "P001", "G003"
  - reason (string, required): Why this document is being archived, e.g. "Replaced by new auth system"

Returns: Confirmation that document was archived with new location.`,
        inputSchema: {
          id: z.string().describe('Document ID to archive (e.g. "P001", "G003")'),
          reason: z.string().describe('Reason for archiving'),
        },
        annotations: {
          readOnlyHint: false,
          destructiveHint: true,
          idempotentHint: false,
          openWorldHint: false,
        },
      },
      async (params) => {
        try {
          return this.withTracking('ctx_archive', handleArchive(vault, params as Record<string, unknown>));
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err);
          return { content: [{ type: 'text' as const, text: `Error: ${msg}` }], isError: true };
        }
      }
    );

    // ── ctx_review ────────────────────────────────────────────────
    this.mcpServer.registerTool(
      'ctx_review',
      {
        title: 'Curation Review',
        description: `Run a curation review on a ContextVault vault. Identifies stale documents (not updated recently), very short documents (may need expansion or merging), content overlap between documents (merge candidates), and generates prioritized action items.

Args:
  - vault ('global' | 'project'): Which vault to review (default: 'project')
  - stale_days (number): Days without update to consider stale (default: 30)

Returns: Review report with health score, stale docs list, merge suggestions, and prioritized action items. Follow up with ctx_update, ctx_archive, or ctx_link as needed.`,
        inputSchema: {
          vault: z.enum(['global', 'project']).optional().default('project').describe('Which vault to review'),
          stale_days: z.number().optional().default(30).describe('Days without update to consider stale'),
        },
        annotations: {
          readOnlyHint: true,
          destructiveHint: false,
          idempotentHint: true,
          openWorldHint: false,
        },
      },
      async (params) => {
        try {
          return this.withTracking('ctx_review', handleReview(vault, params as Record<string, unknown>));
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err);
          return { content: [{ type: 'text' as const, text: `Error: ${msg}` }], isError: true };
        }
      }
    );
  }

  private registerResources(): void {
    const vault = this.vault;

    // ── Global Vault Index ────────────────────────────────────────
    this.mcpServer.registerResource(
      'global-vault-index',
      'contextvault://global/index',
      {
        description: 'Index of all global vault documents (cross-project knowledge)',
        mimeType: 'text/markdown',
      },
      async (uri) => ({
        contents: [{
          uri: uri.href,
          mimeType: 'text/markdown',
          text: vault.globalExists()
            ? vault.globalIndex.readRaw()
            : 'Global vault not initialized. Use ctx_init to create it.',
        }],
      })
    );

    // ── Project Vault Index ───────────────────────────────────────
    this.mcpServer.registerResource(
      'project-vault-index',
      'contextvault://project/index',
      {
        description: 'Index of all project-specific vault documents',
        mimeType: 'text/markdown',
      },
      async (uri) => ({
        contents: [{
          uri: uri.href,
          mimeType: 'text/markdown',
          text: vault.projectExists()
            ? vault.projectIndex.readRaw()
            : 'Project vault not initialized. Use ctx_init to create it.',
        }],
      })
    );

    // ── Vault Settings ────────────────────────────────────────────
    this.mcpServer.registerResource(
      'vault-settings',
      'contextvault://settings',
      {
        description: 'Current vault mode, enforcement level, and limits',
        mimeType: 'application/json',
      },
      async (uri) => ({
        contents: [{
          uri: uri.href,
          mimeType: 'application/json',
          text: JSON.stringify(vault.settings.load(), null, 2),
        }],
      })
    );

    // ── ContextVault Instructions ─────────────────────────────────
    this.mcpServer.registerResource(
      'vault-instructions',
      'contextvault://instructions',
      {
        description: 'Documentation rules and enforcement instructions for the AI assistant',
        mimeType: 'text/markdown',
      },
      async (uri) => ({
        contents: [{
          uri: uri.href,
          mimeType: 'text/markdown',
          text: this.getInstructions(),
        }],
      })
    );

    // ── Document Template (by ID) ─────────────────────────────────
    this.mcpServer.registerResource(
      'vault-document',
      new ResourceTemplate('contextvault://doc/{id}', { list: undefined }),
      {
        description: 'Read a specific vault document by ID (e.g. P001, G003)',
        mimeType: 'text/markdown',
      },
      async (uri, variables) => {
        const id = variables.id as string;
        const content = vault.readDocument(id);
        return {
          contents: [{
            uri: uri.href,
            mimeType: 'text/markdown',
            text: content ?? `Document ${id} not found.`,
          }],
        };
      }
    );
  }

  private getInstructions(): string {
    return `# ContextVault - Persistent Documentation for AI Coding Assistants

ContextVault stores learnings, decisions, bug fixes, and session handoffs in structured markdown documents. Documents persist across sessions so knowledge is never lost.

## When to document (at meaningful milestones):

- Fixed a bug? → **ctx_error** (error_message, root_cause, solution, prevention)
- Made a decision? → **ctx_decision** (decision, options, reasoning, tradeoffs)
- Learned something? → **ctx_doc** (topic, content, type="learning")
- Found useful code? → **ctx_doc** (content, language, use_case, type="snippet")
- Explored codebase? → **ctx_doc** (area, content, type="intel")
- Ending session? → **ctx_handoff** (completed, in_progress, next_steps)

## Rules:
1. Search before creating — use ctx_search to avoid duplicates
2. Update existing docs — use ctx_update when a topic already has a document
3. Keep documents under 100 lines, index summaries under 15 words
4. Route correctly: global vault = reusable cross-project patterns, project vault = this codebase only
5. Document at milestones, not every trivial edit

## At session start:
- Read vault indexes (contextvault://global/index, contextvault://project/index)
- Use stored knowledge throughout the session
`;
  }

  async run(): Promise<void> {
    const transport = new StdioServerTransport();
    await this.mcpServer.connect(transport);
  }
}
