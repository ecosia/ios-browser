# 04: Automatic main sync job

**Jira:** [MOB-5030](https://ecosia.atlassian.net/browse/MOB-5030)
**Milestone:** M0 Upgrade branch established
**Status:** ready-for-human
**Blocked by:** 02, 05

## What to build

A GitHub Actions workflow that runs after every push to `main`, merges `main` into `upgrade/firefox`, and makes the result visible:

- **Clean merge:** open (or update) a PR from a sync branch into `upgrade/firefox`, so the merge goes through the same CI and review as any other change. Auto-merge it once CI passes, if branch rules allow.
- **Conflicts:** open the PR in draft with the list of conflicting files and notify the owner.

The workflow must never push directly to `upgrade/firefox`. Because it is triggered by pushes to `main`, the workflow file has to live on `main`. It is the one piece of upgrade work that lands there, and it does nothing to the app.

## Acceptance criteria

- [ ] A merge to `main` produces a sync PR into `upgrade/firefox` within minutes
- [ ] The sync PR runs the full CI from ticket 05 (build, unit tests, lint)
- [ ] A deliberately conflicting change produces a draft PR listing the files and notifies the owner
- [ ] The workflow stops on its own once `upgrade/firefox` no longer exists (after migrating `main`)
- [ ] Diary entry written
