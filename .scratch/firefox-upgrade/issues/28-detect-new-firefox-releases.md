# 28: Detect new Firefox releases

**Jira:** [MOB-5054](https://ecosia.atlassian.net/browse/MOB-5054)
**Milestone:** M6 Release-watching agent
**Status:** needs-triage
**Blocked by:** 24, 27

## What to build

A scheduled CI job that lists the release tags in `mozilla-mobile/firefox-ios`, compares the newest stable one with the tag in `UPSTREAM_BASE`, and starts an assessment run (ticket 29) for each stable release newer than our base that has not been assessed yet. Beta and release-candidate tags are ignored, and a release is never assessed twice.

It only goes live after 13.0.0, once we are at production parity on the latest Firefox.

## Acceptance criteria

- [ ] A new stable Firefox release starts an assessment within a day
- [ ] Beta and release-candidate tags are ignored
- [ ] Re-running the job for an assessed release does nothing
- [ ] When we are on the latest release the job finishes quietly
- [ ] Diary entry written
