# 23: Migrate `main`

**Jira:** [MOB-5049](https://ecosia.atlassian.net/browse/MOB-5049)
**Milestone:** M5 Beta, migrate `main`, release 13.0.0
**Status:** ready-for-human
**Blocked by:** 22

## What to build

`upgrade/firefox` becomes `main`, when the team decides, following [ADR 0007](../../../adr/0007-graft-firefox-upgrades-onto-main-via-upgrade-branch.md). See the commands in [spec.md](../spec.md#migrating-main-m5).

1. Announce a short merge freeze on `main`, and run a last main sync so `upgrade/firefox` contains every `main` commit.
2. Create `main-147` from the current `main`. It is the archive, and the base for any patch to 12.x.
3. Move `main` to `upgrade/firefox` as a fast-forward, or through a PR if branch rules require one. No force push.
4. Delete `upgrade/firefox`. Remove the main sync workflow (ticket 04) and the `upgrade/firefox` triggers (ticket 05).
5. Tell the team. Open feature branches need only a normal merge or rebase onto the new `main`, not a history rewrite.
6. Update the "Keep upgrade branch updated" and "Migrate main" sections of the Firefox Upgrades Confluence page to match ADR 0007.

## Acceptance criteria

- [ ] `main-147` exists at the pre-migration `main`
- [ ] `main` contains `upgrade/firefox`, with no force push used
- [ ] `upgrade/firefox`, its sync workflow and its CI triggers are removed
- [ ] The patch recipe from `main-147` is written in the diary
- [ ] Confluence process page updated
- [ ] Diary entry written
