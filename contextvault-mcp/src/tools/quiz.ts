import { VaultManager } from '../vault/manager.js';
import { ToolResponse } from '../vault/types.js';

export function handleQuiz(vault: VaultManager, params: Record<string, unknown>): ToolResponse {
  const topic = params.topic as string | undefined;

  const settings = vault.settings.load();
  const entries = [];

  if (settings.mode !== 'global' && vault.projectExists()) {
    entries.push(...vault.projectIndex.parseEntries());
  }
  if (settings.mode !== 'local' && vault.globalExists()) {
    entries.push(...vault.globalIndex.parseEntries());
  }

  if (entries.length === 0) {
    return {
      content: [{ type: 'text', text: 'No documents in vault to quiz on. Create some docs first.' }],
    };
  }

  // Filter by topic if provided
  let filtered = entries;
  if (topic) {
    const topicLower = topic.toLowerCase();
    filtered = entries.filter(e =>
      e.topic.toLowerCase().includes(topicLower) ||
      e.summary.toLowerCase().includes(topicLower)
    );
    if (filtered.length === 0) {
      return {
        content: [{ type: 'text', text: `No documents found matching topic "${topic}". Available topics:\n${entries.map(e => `- ${e.id}: ${e.topic}`).join('\n')}` }],
      };
    }
  }

  // Pick random entries for quiz
  const shuffled = filtered.sort(() => Math.random() - 0.5);
  const quizItems = shuffled.slice(0, Math.min(5, shuffled.length));

  let text = `# Knowledge Quiz\n\n`;
  text += topic ? `Topic: **${topic}**\n\n` : `All vault topics\n\n`;
  text += `Answer these questions based on your vault knowledge:\n\n`;

  quizItems.forEach((item, i) => {
    text += `**Q${i + 1}.** What is documented in **${item.id}** about "${item.topic}"?\n`;
    text += `> Hint: ${item.summary}\n\n`;
  });

  text += `\n---\nUse **ctx_read** with each ID to check your answers.`;

  return { content: [{ type: 'text', text }] };
}
