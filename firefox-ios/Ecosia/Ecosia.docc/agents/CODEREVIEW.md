# Code Review & PR Conventions

## PR & Branch Naming

- PR title: `[MOB-XXXX] {name of the feature}` (Jira ticket reference)
- Branch name usually starts with engineer initials (e.g. Jane Doe, `jd-`)
- Branch name usually includes ticket reference `MOB-XXXX` (e.g., `jd-mob-1234-feature-name`)
- No ticket? No ticket reference needed

## Commit Standards

- Split file changes into separate, logical commits
- Commit messages are auto-prefixed with the Jira ticket from your branch name (`hooks/prepare-commit-msg`) — **do not add `[MOB-XXXX]` manually**; the hook skips or dedupes an existing prefix
- Maintain clean commit history — avoid numerous small commits
- Skip `.gitignore` changes by default unless specifically requested

## Review Rules

- Don't explain what the PR does — only include points that require change
- Only focus on changes made in this PR and intended changes described in the PR description
- Verify the project builds successfully before committing
- Address linter errors (max 3 iterations per file)
- Ensure CI/CD checks pass before requesting review
- If the PR touches UI listed in `snapshot_coverage.json` (see the [snapshot coverage map](Ecosia/Ecosia.docc/SNAPSHOT_TESTING_WIKI.md#snapshot-coverage-map)), confirm snapshot tests and `SnapshotArtifacts` references were updated (or that the author documented why not)

## Branch Management

- Production code is on the `main` branch
- New features branch off `main`
- Use descriptive branch names that reflect the feature or fix
