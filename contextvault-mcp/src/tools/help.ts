import { VaultManager } from '../vault/manager.js';
import { ToolResponse } from '../vault/types.js';

export function handleHelp(_vault: VaultManager): ToolResponse {
  const text = `# ContextVault MCP Commands

## Document Your Work
| Command | Description |
|---------|-------------|
| **ctx_doc** | Quick document a learning, feature, or finding |
| **ctx_error** | Document a bug fix (error, cause, solution) |
| **ctx_decision** | Document a decision with reasoning |
| **ctx_plan** | Document an implementation plan |
| **ctx_snippet** | Save a reusable code snippet |
| **ctx_intel** | Document codebase exploration findings |
| **ctx_handoff** | Create session handoff summary |
| **ctx_explain** | Explain a concept and save to vault |

## Manage Documents
| Command | Description |
|---------|-------------|
| **ctx_search** | Search vault documents by keyword |
| **ctx_read** | Read a document by ID (P001, G003) |
| **ctx_ask** | Ask a question, get targeted answers with excerpts |
| **ctx_update** | Update an existing document |
| **ctx_new** | Create a new document with custom content |
| **ctx_note** | Add a quick note to existing doc |
| **ctx_link** | Link two related documents |
| **ctx_archive** | Archive a deprecated document |
| **ctx_review** | Run weekly curation review |

## Vault Management
| Command | Description |
|---------|-------------|
| **ctx_init** | Initialize vault in current project |
| **ctx_status** | Show vault status and stats |
| **ctx_mode** | Switch mode (local/global/full) or enforcement |
| **ctx_health** | Check vault health and fix issues |
| **ctx_bootstrap** | Auto-scan codebase for documentation |
| **ctx_upgrade** | Upgrade vault format |
| **ctx_changelog** | Show version history |

## Share & Import
| Command | Description |
|---------|-------------|
| **ctx_share** | Export documents for sharing |
| **ctx_import** | Import from external source or legacy vault |
| **ctx_quiz** | Test knowledge retention |

## Resources (Auto-loaded)
- \`contextvault://global/index\` — Global vault index
- \`contextvault://project/index\` — Project vault index
- \`contextvault://settings\` — Current settings
- \`contextvault://instructions\` — Documentation rules
- \`contextvault://doc/{id}\` — Individual document
`;

  return { content: [{ type: 'text', text }] };
}
