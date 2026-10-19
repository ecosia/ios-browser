# 20: Update-path testing

**Jira:** [MOB-5046](https://ecosia.atlassian.net/browse/MOB-5046)
**Milestone:** M4 Production parity
**Status:** ready-for-human
**Blocked by:** 17

## What to build

Proof that users updating from production keep their data and settings. In the Firefox 122 upgrade, migrations that only ran from a specific earlier version and data state were not tested, and broke.

Update paths to test:

- from the current App Store version (12.6.x);
- from the oldest version still used by a meaningful share of active users, if analytics shows one.

For each, install the old version, create realistic state, update to an `upgrade/firefox` build, and check that nothing was lost: signed-in account, tabs including private, bookmarks, history, reading list, search engine, impact counter and seeds, theme, start-at-home and toolbar position settings, and the tracking-protection settings.

Review every migration and preference-key change upstream made between 147 and the target (database schema, `PrefsKeys`, Nimbus-persisted values) and make sure each is covered.

## Acceptance criteria

- [ ] Versions to test agreed, using analytics
- [ ] Each update path passes with all listed state intact
- [ ] Every upstream migration between 147 and the target is listed and covered
- [ ] Diary entry written
