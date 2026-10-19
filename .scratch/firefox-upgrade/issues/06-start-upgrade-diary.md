# 06: Start the upgrade diary

**Jira:** [MOB-5032](https://ecosia.atlassian.net/browse/MOB-5032)
**Milestone:** M0 Upgrade branch established
**Status:** ready-for-agent
**Blocked by:** 01

## What to build

The upgrade diary for this upgrade, in `firefox-ios/EcosiaUpgrade/diary/`, readable by engineers and agents alike.

- `diary/README.md`: the entry format (date, author as engineer or agent, ticket, what was done, what was decided and why, new traps) and the rule that every ticket ends with an entry.
- `diary/157.md`: the diary for this upgrade. Its first section, "155.1 checkpoint", summarizes the experiment from the 19 tickets on `origin/firefox-upgrade-155.1` under `.scratch/firefox-upgrade-155-1/issues/`: what each ticket did, the product decisions taken, and the full trap list from ticket 19 ("For the next upgrade — additions to the trap list").
- Copy the 19 original ticket files into `diary/155.1-experiment/` unchanged, as source material.

Also move the glossary (`firefox-ios/EcosiaUpgrade/GLOSSARY.md`), root `GLOSSARY-MAP.md` and ADR 0007 from the planning session onto `upgrade/firefox` if they are not there yet.

## Acceptance criteria

- [ ] `diary/README.md` defines the entry format
- [ ] `diary/157.md` has a 155.1 checkpoint section with every trap from the experiment
- [ ] The 19 experiment tickets are preserved under `diary/155.1-experiment/`
- [ ] Glossary, glossary map and ADR 0007 are on `upgrade/firefox`
- [ ] Diary entry written (the first one)
