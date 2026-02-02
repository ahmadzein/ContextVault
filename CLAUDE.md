# ContextVault Project Instructions

## 📝 Document at Meaningful Milestones

```
┌─────────────────────────────────────────────────────────────────┐
│  AT NATURAL STOPPING POINTS — ASK YOURSELF:                     │
│                                                                 │
│  ✅ Fixed a bug?        → /ctx-error                            │
│  ✅ Made a decision?    → /ctx-decision                         │
│  ✅ Learned something?  → /ctx-doc                              │
│  ✅ Found useful code?  → /ctx-snippet                          │
│  ✅ Explored codebase?  → /ctx-intel                            │
│                                                                 │
│  WHEN to document:                                              │
│  • Feature complete (not mid-edit)                              │
│  • Bug fix solved and verified                                  │
│  • Architecture decision made                                   │
│  • Session ending                                               │
│                                                                 │
│  WHEN NOT to document:                                          │
│  • Trivial edits (version bumps, typos, config)                 │
│  • Mid-refactor (wait until done)                               │
│  • Nothing meaningful was learned                               │
│                                                                 │
│  ✅ Just DO IT. Then say: "Documented to [file]"                │
└─────────────────────────────────────────────────────────────────┘
```

### 📖 Session Start (AUTOMATIC)
1. Read `./.claude/vault/index.md` immediately
2. Note what docs exist

### 📝 Session End
1. Run `/ctx-handoff` to create handoff summary

### 🏷️ Project Docs
- Location: `./.claude/vault/`
- Prefix: P### (P001, P002, etc.)
- Update index after EVERY change

### Commands
`/ctx-doc` `/ctx-error` `/ctx-snippet` `/ctx-decision` `/ctx-intel` `/ctx-handoff` `/ctx-search` `/ctx-read` `/ctx-bootstrap`
