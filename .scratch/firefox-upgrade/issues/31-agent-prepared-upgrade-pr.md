# 31: Agent-prepared upgrade PR

**Jira:** [MOB-5057](https://ecosia.atlassian.net/browse/MOB-5057)
**Milestone:** M6 Release-watching agent
**Status:** needs-triage
**Blocked by:** 27, 29

## What to build

When the team accepts "take now", the agent prepares the upgrade so engineers review instead of starting from scratch:

- Create an upgrade branch from `main` and apply the release against the recorded base (`git merge-tree --write-tree --merge-base=<UPSTREAM_BASE tag> HEAD <new tag>`).
- Resolve conflicts by type (removal, substitution, addition), check every customized file against its intent diff, and avoid every known trap.
- Build, run unit, feature configuration and snapshot tests and the symbol, missing-file and build-system checks, and update `UPSTREAM_BASE`.
- Open a draft PR listing each conflict, how it was resolved, anything it could not resolve, and the test results.

## Acceptance criteria

- [ ] Only runs when the team asks for it; never merges
- [ ] Draft PR lists every conflict and its resolution, and flags anything left for a human
- [ ] CI runs in full on the draft PR
- [ ] Backtest: replaying the 155.1 to 157 hop reaches a build the team judges comparable to the human one
- [ ] Diary entry written
