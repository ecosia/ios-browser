# 30: Agent diary

**Jira:** [MOB-5056](https://ecosia.atlassian.net/browse/MOB-5056)
**Milestone:** M6 Release-watching agent
**Status:** needs-triage
**Blocked by:** 06, 27

## What to build

An agent section in the upgrade diary (`firefox-ios/EcosiaUpgrade/diary/`), in the same entry format with the author set to the agent. It gives the team an audit trail for each recommendation and gives the agent a memory across releases.

- One entry per assessed release: what changed, how it affects our customizations, the recommendation and why, and the team's final decision once made.
- Before assessing a release, the agent reads its earlier entries and the latest human diary, including any release it said to wait on.
- Entries reach the repo through a reviewed PR, like any other diary entry.

## Acceptance criteria

- [ ] Every assessment produces a diary entry through a PR
- [ ] The team's decision is recorded against each entry
- [ ] An assessment after a "wait" release covers both releases
- [ ] Diary README updated with the agent rules
