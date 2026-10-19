# Upgrade diary

Past upgrades kept a diary, and it repeatedly helped trace issues found in QA back to the decision that caused them. This folder holds one diary per Firefox upgrade, written by engineers and agents alike.

## Rules

- **One diary file per upgrade**, named after the target release: `<target>.md`. The upgrade to Firefox 157 is [`157.md`](157.md).
- **Every ticket ends with an entry.** A ticket is not done until its entry is written.
- **A milestone is done only when its entry exists.**
- **Engineers and agents write the same way.** The heading names the author: `author: <engineer name>` or `agent: <model name>`.
- **Entries are appended, never rewritten.** To correct an earlier entry, add a new entry that says what was wrong and what is right.
- [`155.1-experiment/`](155.1-experiment/) holds the 155.1 experiment's tickets, copied unchanged. They are the source of the 155.1 checkpoint in `157.md`.

## Entry format

```markdown
### YYYY-MM-DD: <ticket number and title> (<author: engineer name | agent: model name>)

**Milestone:** M0
**Commits:** <short hashes>

**Done:** what changed, in two to five sentences.

**Decided:** each decision with its reason. For conflicts: file, type (removal / substitution / addition), resolution, reason.

**Traps:** new pitfalls worth checking next time, or "none".
```

Conflict resolution types:

- **removal:** Ecosia removed Firefox code.
- **substitution:** Ecosia replaced Firefox code.
- **addition:** Ecosia added code.
