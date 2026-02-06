// ContextVault MCP Server - Type Definitions

export interface VaultSettings {
  mode: 'local' | 'global' | 'full';
  enforcement: 'light' | 'balanced' | 'strict';
  limits: {
    max_global_docs: number;
    max_project_docs: number;
    max_doc_lines: number;
    max_summary_words: number;
  };
}

export const DEFAULT_SETTINGS: VaultSettings = {
  mode: 'local',
  enforcement: 'balanced',
  limits: {
    max_global_docs: 50,
    max_project_docs: 50,
    max_doc_lines: 100,
    max_summary_words: 15,
  },
};

export interface IndexEntry {
  id: string;
  topic: string;
  status: string;
  summary: string;
}

export interface IndexData {
  entries: IndexEntry[];
  relatedTerms: Map<string, string>;
  archivedEntries: { id: string; topic: string; archived: string; reason: string }[];
  lastUpdated: string;
}

export type VaultTier = 'global' | 'project';
export type DocPrefix = 'G' | 'P';

export interface DocumentMeta {
  id: string;
  title: string;
  status: string;
  created: string;
  lastUpdated: string;
}

export interface VaultStats {
  globalDocs: number;
  projectDocs: number;
  globalMaxDocs: number;
  projectMaxDocs: number;
  globalPath: string;
  projectPath: string;
  globalExists: boolean;
  projectExists: boolean;
  mode: string;
  enforcement: string;
}

export interface SearchResult {
  id: string;
  topic: string;
  summary: string;
  vault: VaultTier;
  relevance: number;
}

export interface EnforcementState {
  editCount: number;
  filesEdited: Set<string>;
  lastDocTime: number;
  sessionStart: number;
  researchCount: number;
  areasExplored: Set<string>;
  lastResearchTime: number;
}

export interface ToolResponse {
  [key: string]: unknown;
  content: { type: 'text'; text: string }[];
  isError?: boolean;
}
