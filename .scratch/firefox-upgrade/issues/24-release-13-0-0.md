# 24: Release 13.0.0

**Jira:** [MOB-5050](https://ecosia.atlassian.net/browse/MOB-5050)
**Milestone:** M5 Beta, migrate `main`, release 13.0.0
**Status:** ready-for-human
**Blocked by:** 23

## What to build

Ecosia 13.0.0 shipped through the normal release flow: the version-bump PR (`MARKETING_VERSION` in `firefox-ios/Client/Ecosia/BuildSettingsConfigurations/EcosiaCommon.xcconfig`) cuts the release on merge, followed by a staged App Store rollout with crash and user-report monitoring.

## Acceptance criteria

- [ ] Version-bump PR to 13.0.0 merged and the release tag created
- [ ] Staged rollout completed without a halt, or a halt resolved
- [ ] Stable by the team's usual post-release criteria
- [ ] Final diary entry: what went well, what to change next time, and what M6 (the release-watching agent) should take from this upgrade
