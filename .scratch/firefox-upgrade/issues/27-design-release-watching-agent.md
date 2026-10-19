# 27: Design the release-watching agent

**Jira:** [MOB-5053](https://ecosia.atlassian.net/browse/MOB-5053)
**Milestone:** M6 Release-watching agent
**Status:** needs-triage
**Blocked by:** 22

## What to build

An ADR for the agent that watches Firefox releases, assesses how each affects our customizations, and recommends taking it now or waiting to bundle it. Written when M5 is close, so it uses what this upgrade taught us.

The ADR covers:

- **Trigger:** which Firefox releases count (stable tags only, dot releases, security releases) and how they are detected.
- **Inputs:** `UPSTREAM_BASE`, the tooling in `firefox-ios/EcosiaUpgrade/tools/`, the trap list, the upgrade diary and the product decisions.
- **Outputs:** an assessment per release and a recommendation (take now, or wait and bundle) with its reasons.
- **Decision criteria**, agreed with product: security fixes, features product wants, features we would have to switch off, conflict risk, and how many releases behind we are.
- **Human control:** the agent never merges or releases. It writes reports, diary entries and draft PRs; the team decides.
- **Where it runs and what it costs:** CI runner, agent platform, credentials, expected spend per release.

## Acceptance criteria

- [ ] ADR written and accepted by the team
- [ ] Take-now vs bundle criteria agreed with product
- [ ] Success measures defined for the pilot (accuracy against a human assessment, time saved)
- [ ] Tickets 28–32 updated to match the design
- [ ] Diary entry written
