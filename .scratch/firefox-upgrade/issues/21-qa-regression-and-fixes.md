# 21: QA regression and fix loop

**Jira:** [MOB-5047](https://ecosia.atlassian.net/browse/MOB-5047)
**Milestone:** M4 Production parity
**Status:** ready-for-human
**Blocked by:** 18, 19, 20

## What to build

QA runs the Miro test plan and the standard regression checklist on device against an `upgrade/firefox` build, and every regression found here, in ticket 11 or ticket 19 is fixed or explicitly accepted.

Fixes land on `upgrade/firefox` through reviewed PRs. A fix for a bug that also exists in production goes to `main` instead, and reaches the upgrade branch through the main sync.

## Acceptance criteria

- [ ] Test plan and regression checklist pass on device
- [ ] No open regression without a decision
- [ ] The team agrees the branch has reached production parity, and the decision is recorded in the diary
- [ ] M4 is done when this ticket is
