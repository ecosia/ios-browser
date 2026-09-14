# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

## Before exploring, read these

- **`CONTEXT-MAP.md`** at the repo root: this is a multi-context repo. It points at one `CONTEXT.md` per context. Read each one relevant to the topic.
- **`adr/`** at the repo root: system-wide architectural decisions (not `docs/adr/` — this repo's ADRs live at the top-level `adr/` directory). In multi-context repos, also check `<context-dir>/docs/adr/` for context-scoped decisions.

If a context's `CONTEXT.md` or its `docs/adr/` don't exist yet, **proceed silently**. Don't flag their absence; don't suggest creating them upfront. The `/domain-modeling` skill (reached via `/grill-with-docs` and `/improve-codebase-architecture`) creates them lazily when terms or decisions actually get resolved.

## Naming heads-up

`firefox-ios/Ecosia/Ecosia.docc/agents/CONTEXT.md` also exists in this repo. It is **not** a domain-modeling glossary — it's Ecosia's own pre-existing "what to do before changing code" checklist, referenced from `AGENTS.md`. Don't confuse it with the `CONTEXT.md` files this convention creates; they share a filename by coincidence, not by relation.

## File structure (multi-context)

```
/
├── CONTEXT-MAP.md
├── adr/                                        ← system-wide decisions
└── firefox-ios/
    └── Tuist/upgrade/
        └── CONTEXT.md                          ← Firefox Upgrade context
```

Additional contexts (e.g. the app's general domain model) get added to `CONTEXT-MAP.md` lazily, as `/domain-modeling` sessions resolve their first terms — see that entry's own file for its location convention once it exists.

## Use the glossary's vocabulary

When your output names a domain concept (in an issue title, a refactor proposal, a hypothesis, a test name), use the term as defined in the relevant context's `CONTEXT.md`. Don't drift to synonyms the glossary explicitly avoids.

If the concept you need isn't in the glossary yet, that's a signal: either you're inventing language the project doesn't use (reconsider) or there's a real gap (note it for `/domain-modeling`).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than silently overriding:

> _Contradicts ADR-0007 (event-sourced orders), but worth reopening because…_
