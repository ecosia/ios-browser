# 01: Graft 155.1 onto `main` as `upgrade/firefox`

**Jira:** [MOB-5027](https://ecosia.atlassian.net/browse/MOB-5027)
**Milestone:** M0 Upgrade branch established
**Status:** ready-for-human
**Blocked by:** None

## What to build

The long-lived `upgrade/firefox` branch, created from `main`'s history, carrying the 155.1 upgrade as a single commit (see [ADR 0007](../../../adr/0007-graft-firefox-upgrades-onto-main-via-upgrade-branch.md) and the graft recipe in [spec.md](../spec.md#the-graft-m0)).

Start from the squash commit's tree (`c162a7c953` on `origin/firefox-upgrade-155.1`), not the branch tip: the tip also carries 7 CI experiment commits (`.circleci/config.yml`, `Gemfile.lock`, `fastlane/Fastfile`) and a docs commit (`a9bd75f175`) that also touched `version.xcconfig`, `swiftlint_baseline.json`, `webpack.config.js`, `tuist-commands.sh` and `tuist-setup.sh`. Review each of those changes and carry over only what the upgrade needs.

Parent the graft commit on `89e13a568d`, the `main` commit the squash was taken from.

## Acceptance criteria

- [ ] The graft commit's parent is `89e13a568d`, and its tree matches the 155.1 squash tree plus only reviewed extras
- [ ] `upgrade/firefox` exists on `origin`, created from the graft commit
- [ ] Every change from `a9bd75f175` and the CI experiment commits is either carried over with a reason or deliberately dropped, and the choice is listed in the diary
- [ ] The experiment's manifest, scripts and 19 tickets are preserved for ticket 06 and ticket 14 (not lost with the dropped commits)
- [ ] `main` and `firefox-upgrade-155.1` are untouched
- [ ] Diary entry written

## Notes

`main`'s Ecosia module was verified identical at `89e13a568d` and in the squash commit, which is what makes `89e13a568d` the correct parent.
