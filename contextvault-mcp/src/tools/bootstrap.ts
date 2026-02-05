import * as fs from 'node:fs';
import * as path from 'node:path';
import { VaultManager } from '../vault/manager.js';
import { ToolResponse } from '../vault/types.js';

export function handleBootstrap(vault: VaultManager, _params: Record<string, unknown>): ToolResponse {
  if (!vault.projectIndex.exists()) vault.initProject();

  const projectRoot = path.resolve(vault.projectPath, '..');
  const scan = scanProject(projectRoot);

  let text = `# Bootstrap Scan Results\n\n`;
  text += `**Project root:** ${projectRoot}\n\n`;
  text += `## Detected\n\n`;
  text += `- **Languages:** ${scan.languages.join(', ') || 'None detected'}\n`;
  text += `- **Frameworks:** ${scan.frameworks.join(', ') || 'None detected'}\n`;
  text += `- **Package managers:** ${scan.packageManagers.join(', ') || 'None detected'}\n`;
  text += `- **Config files:** ${scan.configFiles.length} found\n`;
  text += `- **Source directories:** ${scan.srcDirs.join(', ') || 'None detected'}\n\n`;
  text += `## Recommendation\n\n`;
  text += `Use **ctx_doc** to create documentation for each major component found.\n`;
  text += `Use **ctx_intel** to document the architecture and patterns discovered.\n\n`;
  text += `### Suggested Documents\n\n`;

  if (scan.languages.length > 0) {
    text += `1. Architecture doc: tech stack (${scan.languages.join(', ')}), structure, patterns\n`;
  }
  if (scan.frameworks.length > 0) {
    text += `2. Framework doc: ${scan.frameworks.join(', ')} setup and conventions\n`;
  }
  text += `3. Build/deploy doc: how to build, test, and deploy this project\n`;

  return { content: [{ type: 'text', text }] };
}

interface ScanResult {
  languages: string[];
  frameworks: string[];
  packageManagers: string[];
  configFiles: string[];
  srcDirs: string[];
}

function scanProject(root: string): ScanResult {
  const result: ScanResult = {
    languages: [],
    frameworks: [],
    packageManagers: [],
    configFiles: [],
    srcDirs: [],
  };

  const ignoreDirs = new Set(['.git', 'node_modules', '.contextvault', '.claude', 'dist', 'build', '__pycache__', '.venv', 'venv']);

  try {
    const entries = fs.readdirSync(root);

    // Check for package managers and languages
    for (const entry of entries) {
      const fullPath = path.join(root, entry);
      const stat = fs.statSync(fullPath);

      if (stat.isDirectory() && !ignoreDirs.has(entry)) {
        if (['src', 'lib', 'app', 'pkg', 'cmd'].includes(entry)) {
          result.srcDirs.push(entry);
        }
      }

      if (stat.isFile()) {
        // Package managers
        if (entry === 'package.json') {
          result.packageManagers.push('npm');
          try {
            const pkg = JSON.parse(fs.readFileSync(fullPath, 'utf-8'));
            if (pkg.dependencies) {
              if (pkg.dependencies.react) result.frameworks.push('React');
              if (pkg.dependencies.vue) result.frameworks.push('Vue');
              if (pkg.dependencies.next) result.frameworks.push('Next.js');
              if (pkg.dependencies.express) result.frameworks.push('Express');
              if (pkg.dependencies.fastify) result.frameworks.push('Fastify');
            }
          } catch { /* ignore parse errors */ }
        }
        if (entry === 'Cargo.toml') { result.packageManagers.push('cargo'); result.languages.push('Rust'); }
        if (entry === 'go.mod') { result.packageManagers.push('go modules'); result.languages.push('Go'); }
        if (entry === 'requirements.txt' || entry === 'pyproject.toml') { result.packageManagers.push('pip'); result.languages.push('Python'); }
        if (entry === 'Gemfile') { result.packageManagers.push('bundler'); result.languages.push('Ruby'); }

        // Languages
        if (entry === 'tsconfig.json') result.languages.push('TypeScript');
        if (entry.endsWith('.js') || entry.endsWith('.mjs')) result.languages.push('JavaScript');

        // Config files
        if (entry.startsWith('.') && stat.isFile() && entry !== '.git' && entry !== '.DS_Store') {
          result.configFiles.push(entry);
        }
        if (entry.endsWith('.json') || entry.endsWith('.yaml') || entry.endsWith('.yml') || entry.endsWith('.toml')) {
          result.configFiles.push(entry);
        }
      }
    }
  } catch { /* ignore read errors */ }

  // Deduplicate
  result.languages = [...new Set(result.languages)];
  result.frameworks = [...new Set(result.frameworks)];
  result.packageManagers = [...new Set(result.packageManagers)];

  return result;
}
