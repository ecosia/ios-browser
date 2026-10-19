# 18: Upgrade test plan in Miro

**Jira:** [MOB-5044](https://ecosia.atlassian.net/browse/MOB-5044)
**Milestone:** M4 Production parity
**Status:** ready-for-human
**Blocked by:** 15

## What to build

The test plan QA follows for this upgrade, created from the team's Miro template (step 6 of the Firefox Upgrades process page) and linked from Confluence.

Cover at least:

- every Firefox feature we keep (Translations, on-device Summaries, the AI controls hub), and confirmation that removed ones (Google Lens, Quick Answers, VPN, ad blocker) are unreachable;
- every feature area with Ecosia customizations: toolbar and address bar, main menu, homepage and impact counter, bookmarks, settings, tracking protection, launch and onboarding, accounts and the invisible auth tab, search engine and search events;
- Firefox files that Ecosia fully overrides, where upstream may have changed keys or behavior we mirror (for example `AppSettingsTableViewController` and its `+Ecosia` extension);
- the update paths from ticket 20;
- intended visual changes found in ticket 11.

It can start once ticket 15 has listed the target's changes, and is updated after ticket 17.

## Acceptance criteria

- [ ] Miro board created from the template, renamed for this upgrade, and linked from Confluence
- [ ] Every item above has at least one flow
- [ ] QA has reviewed the plan
- [ ] Diary entry written
