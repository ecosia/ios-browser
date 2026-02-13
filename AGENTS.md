# AI Agent Guidelines for Ecosia iOS Browser

This document contains guidelines and best practices for AI agents (Claude, Copilot, etc.) working on this repository.

## Git and Pull Request Guidelines

### PR Base Branch Selection

**IMPORTANT:** When creating pull requests, always match the base branch to the source branch:

- If the branch was created from `develop`, the PR should target `develop` as the base branch
- If the branch was created from `main`, the PR should target `main` as the base branch
- If the branch was created from another feature branch, target that feature branch

**Example:**
```bash
# If you created the branch like this:
git checkout develop
git checkout -b feature/my-feature

# Then create the PR like this:
gh pr create --base develop ...

# NOT like this:
gh pr create --base main ...  # ❌ Wrong!
```

**Why this matters:** PRs targeting the wrong base branch can cause merge conflicts, incorrect diff views, and confusion during code review.

### How to determine the correct base branch

Before creating a PR, check which branch your feature branch was created from:

```bash
# Show the branch point
git merge-base --fork-point develop
git merge-base --fork-point main

# Or check the branch tracking
git branch -vv
```

## Project-Specific Notes

- Main development branch: `develop`
- Production branch: `main`
- Most feature branches should be created from and target `develop`
