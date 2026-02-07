import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  ListResourcesRequestSchema,
  ReadResourceRequestSchema,
  ListResourceTemplatesRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
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
// Removed: handleSnippet, handleIntel, handleNote, handleExplain, handleAsk (consolidated)

export class ContextVaultServer {
  private server: Server;
  private vault: VaultManager;

  constructor() {
    this.vault = new VaultManager();
    this.server = new Server(
      {
        name: 'contextvault-mcp',
        version: '1.0.5',
      },
      {
        capabilities: {
          tools: {},
          resources: {},
        },
      }
    );

    this.registerTools();
    this.registerResources();
  }

  private registerTools(): void {
    // List all 23 tools
    this.server.setRequestHandler(ListToolsRequestSchema, async () => ({
      tools: [
        {
          name: 'ctx_init',
          description: 'Initialize ContextVault in the current project. Creates .contextvault/ directory with index and settings.',
          inputSchema: {
            type: 'object' as const,
            properties: {
              force: { type: 'boolean', description: 'Force reinitialize even if vault exists', default: false },
            },
          },
        },
        {
          name: 'ctx_status',
          description: 'Show ContextVault status: document counts, paths, mode, enforcement level.',
          inputSchema: { type: 'object' as const, properties: {} },
        },
        {
          name: 'ctx_doc',
          description: 'Document a learning, exploration finding, or code snippet. Use type="intel" for codebase exploration, type="snippet" for reusable code patterns.',
          inputSchema: {
            type: 'object' as const,
            properties: {
              topic: { type: 'string', description: 'Topic name (e.g. "Auth System", "Docker Setup")' },
              content: { type: 'string', description: 'What you learned, explored, or the code snippet' },
              type: { type: 'string', enum: ['learning', 'intel', 'snippet'], description: 'Document type: learning (default), intel (exploration), snippet (code)', default: 'learning' },
              vault: { type: 'string', enum: ['global', 'project'], description: 'Which vault (snippets default to global, others to project)' },
              language: { type: 'string', description: 'Programming language (for snippets)' },
              area: { type: 'string', description: 'Area explored (alias for topic, for intel type)' },
              use_case: { type: 'string', description: 'When to use this snippet (for snippets)' },
            },
            required: ['content'],
          },
        },
        {
          name: 'ctx_error',
          description: 'Document a bug fix: error message, root cause, solution, and prevention.',
          inputSchema: {
            type: 'object' as const,
            properties: {
              error_message: { type: 'string', description: 'The error message encountered' },
              root_cause: { type: 'string', description: 'What caused the error' },
              solution: { type: 'string', description: 'How the error was fixed' },
              prevention: { type: 'string', description: 'How to prevent this in the future' },
            },
            required: ['error_message', 'root_cause', 'solution'],
          },
        },
        {
          name: 'ctx_decision',
          description: 'Document an architectural or technical decision with reasoning.',
          inputSchema: {
            type: 'object' as const,
            properties: {
              decision: { type: 'string', description: 'What was decided' },
              options: { type: 'string', description: 'Options that were considered' },
              reasoning: { type: 'string', description: 'Why this option was chosen' },
              tradeoffs: { type: 'string', description: 'Trade-offs and downsides' },
            },
            required: ['decision', 'reasoning'],
          },
        },
        {
          name: 'ctx_plan',
          description: 'Document an implementation plan for a multi-step task.',
          inputSchema: {
            type: 'object' as const,
            properties: {
              goal: { type: 'string', description: 'What the plan aims to achieve' },
              steps: { type: 'string', description: 'Implementation steps (markdown list)' },
              status: { type: 'string', description: 'Current status', default: 'In Progress' },
            },
            required: ['goal', 'steps'],
          },
        },
        {
          name: 'ctx_bootstrap',
          description: 'Auto-scan the codebase and generate documentation. Creates architecture and feature docs.',
          inputSchema: {
            type: 'object' as const,
            properties: {
              interactive: { type: 'boolean', description: 'Show scan results before creating docs', default: false },
            },
          },
        },
        // ctx_snippet and ctx_intel removed - use ctx_doc with type="snippet" or type="intel"
        {
          name: 'ctx_handoff',
          description: 'Create a session handoff summary for the next session to continue seamlessly.',
          inputSchema: {
            type: 'object' as const,
            properties: {
              completed: { type: 'string', description: 'What was completed this session' },
              in_progress: { type: 'string', description: 'What is still in progress' },
              next_steps: { type: 'string', description: 'What should be done next' },
            },
            required: ['completed', 'next_steps'],
          },
        },
        {
          name: 'ctx_search',
          description: 'Search across vault documents by keyword.',
          inputSchema: {
            type: 'object' as const,
            properties: {
              query: { type: 'string', description: 'Search query' },
            },
            required: ['query'],
          },
        },
        {
          name: 'ctx_read',
          description: 'Read a vault document by ID (e.g. "P001", "G003").',
          inputSchema: {
            type: 'object' as const,
            properties: {
              id: { type: 'string', description: 'Document ID (e.g. "P001", "G003")' },
            },
            required: ['id'],
          },
        },
        {
          name: 'ctx_update',
          description: 'Update an existing vault document by appending or modifying a section.',
          inputSchema: {
            type: 'object' as const,
            properties: {
              id: { type: 'string', description: 'Document ID to update' },
              section: { type: 'string', description: 'Section name to update (e.g. "Current Understanding", "Key Points")' },
              content: { type: 'string', description: 'New content to add/replace in the section' },
            },
            required: ['id', 'content'],
          },
        },
        {
          name: 'ctx_new',
          description: 'Create a new vault document with custom title and content.',
          inputSchema: {
            type: 'object' as const,
            properties: {
              title: { type: 'string', description: 'Document title' },
              content: { type: 'string', description: 'Document content' },
              vault: { type: 'string', enum: ['global', 'project'], description: 'Which vault', default: 'project' },
            },
            required: ['title', 'content'],
          },
        },
        {
          name: 'ctx_mode',
          description: 'Switch vault mode or enforcement level.',
          inputSchema: {
            type: 'object' as const,
            properties: {
              mode: { type: 'string', enum: ['local', 'global', 'full'], description: 'Vault mode' },
              enforcement: { type: 'string', enum: ['light', 'balanced', 'strict'], description: 'Enforcement level' },
            },
          },
        },
        {
          name: 'ctx_help',
          description: 'Show all ContextVault commands and their descriptions.',
          inputSchema: { type: 'object' as const, properties: {} },
        },
        {
          name: 'ctx_health',
          description: 'Check vault health: orphaned docs, index mismatches, size limits.',
          inputSchema: { type: 'object' as const, properties: {} },
        },
        // ctx_note removed - use ctx_update with section="Notes"
        {
          name: 'ctx_changelog',
          description: 'Show ContextVault version history and changelog.',
          inputSchema: { type: 'object' as const, properties: {} },
        },
        {
          name: 'ctx_link',
          description: 'Link two related documents together.',
          inputSchema: {
            type: 'object' as const,
            properties: {
              from_id: { type: 'string', description: 'Source document ID' },
              to_id: { type: 'string', description: 'Target document ID' },
            },
            required: ['from_id', 'to_id'],
          },
        },
        {
          name: 'ctx_quiz',
          description: 'Test knowledge retention from vault documents. Generates questions based on stored docs.',
          inputSchema: {
            type: 'object' as const,
            properties: {
              topic: { type: 'string', description: 'Optional topic to quiz on' },
            },
          },
        },
        // ctx_explain removed - use ctx_doc instead
        {
          name: 'ctx_upgrade',
          description: 'Upgrade vault format to latest version. Fixes structure issues.',
          inputSchema: { type: 'object' as const, properties: {} },
        },
        {
          name: 'ctx_share',
          description: 'Export vault documents for sharing.',
          inputSchema: {
            type: 'object' as const,
            properties: {
              ids: {
                type: 'array',
                items: { type: 'string' },
                description: 'Document IDs to export (e.g. ["P001", "P003"])',
              },
              format: { type: 'string', enum: ['md', 'json'], description: 'Export format', default: 'md' },
            },
            required: ['ids'],
          },
        },
        {
          name: 'ctx_import',
          description: 'Import documents from external source or legacy .claude/vault/ location.',
          inputSchema: {
            type: 'object' as const,
            properties: {
              source_path: { type: 'string', description: 'Path to import from. Use "legacy" to import from .claude/vault/' },
            },
            required: ['source_path'],
          },
        },
        {
          name: 'ctx_archive',
          description: 'Archive a vault document. Moves doc to archive folder, removes from active index, adds to archived table.',
          inputSchema: {
            type: 'object' as const,
            properties: {
              id: { type: 'string', description: 'Document ID to archive (e.g. "P001", "G003")' },
              reason: { type: 'string', description: 'Reason for archiving (e.g. "Replaced by new auth system", "Feature deprecated")' },
            },
            required: ['id', 'reason'],
          },
        },
        {
          name: 'ctx_review',
          description: 'Run curation review on vault. Finds stale docs, suggests merges, identifies cleanup opportunities.',
          inputSchema: {
            type: 'object' as const,
            properties: {
              vault: { type: 'string', enum: ['global', 'project'], description: 'Which vault to review', default: 'project' },
              stale_days: { type: 'number', description: 'Days without update to consider stale', default: 30 },
            },
          },
        },
        // ctx_ask removed - use ctx_search + ctx_read instead
      ],
    }));

    // Handle tool calls
    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;
      const params = (args ?? {}) as Record<string, unknown>;

      let result: ToolResponse;

      try {
        switch (name) {
          case 'ctx_init': result = handleInit(this.vault, params); break;
          case 'ctx_status': result = handleStatus(this.vault); break;
          case 'ctx_doc': result = handleDoc(this.vault, params); break;
          case 'ctx_error': result = handleError(this.vault, params); break;
          case 'ctx_decision': result = handleDecision(this.vault, params); break;
          case 'ctx_search': result = handleSearch(this.vault, params); break;
          case 'ctx_read': result = handleRead(this.vault, params); break;
          case 'ctx_handoff': result = handleHandoff(this.vault, params); break;
          case 'ctx_plan': result = handlePlan(this.vault, params); break;
          case 'ctx_bootstrap': result = handleBootstrap(this.vault, params); break;
          case 'ctx_update': result = handleUpdate(this.vault, params); break;
          case 'ctx_new': result = handleNew(this.vault, params); break;
          case 'ctx_mode': result = handleMode(this.vault, params); break;
          case 'ctx_help': result = handleHelp(this.vault); break;
          case 'ctx_health': result = handleHealth(this.vault); break;
          case 'ctx_changelog': result = handleChangelog(); break;
          case 'ctx_link': result = handleLink(this.vault, params); break;
          case 'ctx_quiz': result = handleQuiz(this.vault, params); break;
          case 'ctx_upgrade': result = handleUpgrade(this.vault); break;
          case 'ctx_share': result = handleShare(this.vault, params); break;
          case 'ctx_import': result = handleImport(this.vault, params); break;
          case 'ctx_archive': result = handleArchive(this.vault, params); break;
          case 'ctx_review': result = handleReview(this.vault, params); break;
          default:
            result = { content: [{ type: 'text', text: `Unknown tool: ${name}` }], isError: true };
        }
      } catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        result = { content: [{ type: 'text', text: `Error: ${msg}` }], isError: true };
      }

      // Track research activity on search/read operations
      if (name === 'ctx_search') {
        this.vault.trackResearch(params['query'] as string);
      } else if (name === 'ctx_read') {
        this.vault.trackResearch(params['id'] as string);
      }

      // Track edits for non-ctx tools (before checking reminder)
      if (!name.startsWith('ctx_')) {
        this.vault.trackEdit();
      }

      // Append enforcement reminder if needed (edit-based)
      const reminder = this.vault.getEnforcementReminder();
      if (reminder && !name.startsWith('ctx_')) {
        const lastContent = result.content[result.content.length - 1];
        if (lastContent && lastContent.type === 'text') {
          lastContent.text += reminder;
        }
      }

      // Append research reminder if needed (non-blocking nudge)
      const researchReminder = this.vault.getResearchReminder();
      if (researchReminder && (name === 'ctx_search' || name === 'ctx_read')) {
        const lastContent = result.content[result.content.length - 1];
        if (lastContent && lastContent.type === 'text') {
          lastContent.text += researchReminder;
        }
      }

      return result;
    });
  }

  private registerResources(): void {
    // List available resources
    this.server.setRequestHandler(ListResourcesRequestSchema, async () => ({
      resources: [
        {
          uri: 'contextvault://global/index',
          name: 'Global Vault Index',
          description: 'Index of all global vault documents (cross-project knowledge)',
          mimeType: 'text/markdown',
        },
        {
          uri: 'contextvault://project/index',
          name: 'Project Vault Index',
          description: 'Index of all project-specific vault documents',
          mimeType: 'text/markdown',
        },
        {
          uri: 'contextvault://settings',
          name: 'Vault Settings',
          description: 'Current vault mode, enforcement level, and limits',
          mimeType: 'application/json',
        },
        {
          uri: 'contextvault://instructions',
          name: 'ContextVault Instructions',
          description: 'Documentation rules and enforcement instructions for the AI assistant',
          mimeType: 'text/markdown',
        },
      ],
    }));

    // Resource templates for individual docs
    this.server.setRequestHandler(ListResourceTemplatesRequestSchema, async () => ({
      resourceTemplates: [
        {
          uriTemplate: 'contextvault://doc/{id}',
          name: 'Vault Document',
          description: 'Read a specific vault document by ID (e.g. P001, G003)',
          mimeType: 'text/markdown',
        },
      ],
    }));

    // Read resource content
    this.server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
      const uri = request.params.uri;

      if (uri === 'contextvault://global/index') {
        const content = this.vault.globalExists()
          ? this.vault.globalIndex.readRaw()
          : 'Global vault not initialized. Use ctx_init to create it.';
        return { contents: [{ uri, mimeType: 'text/markdown', text: content }] };
      }

      if (uri === 'contextvault://project/index') {
        const content = this.vault.projectExists()
          ? this.vault.projectIndex.readRaw()
          : 'Project vault not initialized. Use ctx_init to create it.';
        return { contents: [{ uri, mimeType: 'text/markdown', text: content }] };
      }

      if (uri === 'contextvault://settings') {
        const settings = this.vault.settings.load();
        return { contents: [{ uri, mimeType: 'application/json', text: JSON.stringify(settings, null, 2) }] };
      }

      if (uri === 'contextvault://instructions') {
        const instructions = this.getInstructions();
        return { contents: [{ uri, mimeType: 'text/markdown', text: instructions }] };
      }

      // Handle doc/{id} template
      const docMatch = uri.match(/^contextvault:\/\/doc\/([GP]\d{3})$/);
      if (docMatch) {
        const id = docMatch[1];
        const content = this.vault.readDocument(id);
        if (!content) {
          return { contents: [{ uri, mimeType: 'text/markdown', text: `Document ${id} not found.` }] };
        }
        return { contents: [{ uri, mimeType: 'text/markdown', text: content }] };
      }

      return { contents: [{ uri, mimeType: 'text/plain', text: `Unknown resource: ${uri}` }] };
    });
  }

  private getInstructions(): string {
    return `# ContextVault - Documentation Rules

## After EVERY task, document what you learned:

- Fixed a bug? → Use **ctx_error** (error_message, root_cause, solution, prevention)
- Made a decision? → Use **ctx_decision** (decision, options, reasoning, tradeoffs)
- Learned something? → Use **ctx_doc** (topic, content)
- Found useful code? → Use **ctx_snippet** (name, code, language, use_case)
- Explored codebase? → Use **ctx_intel** (area, findings)
- Ending session? → Use **ctx_handoff** (completed, in_progress, next_steps)

## Rules:
1. ALWAYS search before creating (use ctx_search)
2. NEVER create duplicates - update existing docs instead (use ctx_update)
3. Keep documents under 100 lines
4. Keep index summaries under 15 words
5. Route correctly: global = reusable patterns, project = this codebase only
6. Document at meaningful milestones, not every trivial edit

## At session start:
- Read the vault indexes (available as resources)
- Use that knowledge throughout the session
`;
  }

  async run(): Promise<void> {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
  }
}
