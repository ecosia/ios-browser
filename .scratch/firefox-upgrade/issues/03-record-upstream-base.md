# 03: Record the upstream base

**Jira:** [MOB-5029](https://ecosia.atlassian.net/browse/MOB-5029)
**Milestone:** M0 Upgrade branch established
**Status:** ready-for-agent
**Blocked by:** 01

## What to build

A committed record of which Firefox release `upgrade/firefox` is built on, since `git merge-base` can no longer recover it after the graft.

Create `firefox-ios/EcosiaUpgrade/UPSTREAM_BASE` containing one line: the tag, a tab, and the full commit hash. For this branch: `firefox-v155.1`, `04df3bd66b34441c6b97ee3958535c5bf4633ca4`. Add a short `README.md` in the same folder explaining what the file is, who updates it (whoever completes a move to a new upgrade target), and that it must match the tree.

## Acceptance criteria

- [ ] `UPSTREAM_BASE` exists with the tag and full hash, and `git rev-parse firefox-v155.1^{commit}` equals the recorded hash
- [ ] The README explains the format and when to update it
- [ ] `firefox-ios/EcosiaUpgrade/` is not part of any Tuist target (`rg EcosiaUpgrade firefox-ios/Tuist firefox-ios/Project.swift` finds nothing that globs it)
- [ ] Diary entry written
