# 32: Pilot on the first Firefox release after 13.0.0

**Jira:** [MOB-5058](https://ecosia.atlassian.net/browse/MOB-5058)
**Milestone:** M6 Release-watching agent
**Status:** needs-triage
**Blocked by:** 28, 29, 30, 31

## What to build

A real-release trial that decides whether we keep the agent, change it, or stop.

- The agent runs end to end on the first stable Firefox release after 13.0.0: detection, assessment, diary entry and, if the team takes the release, the draft upgrade PR.
- An engineer assesses the same release by hand, without reading the agent's report first.
- Compare the two using the success measures from ticket 27, and record the cost of the run.

## Acceptance criteria

- [ ] Agent ran end to end on a real release
- [ ] Agent and human assessments compared against the success measures
- [ ] Team decision recorded: keep, change or stop, with follow-up tickets for any changes
- [ ] Confluence Firefox Upgrades page updated with the new process if we keep it
- [ ] Diary entry written; M6 is done when this ticket is
