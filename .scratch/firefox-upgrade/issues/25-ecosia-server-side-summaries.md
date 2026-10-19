# 25: Ecosia-owned server-side summaries

**Jira:** [MOB-5051](https://ecosia.atlassian.net/browse/MOB-5051)
**Milestone:** Follow-up (blocks nothing in this upgrade)
**Status:** needs-triage
**Blocked by:** None

## What to build

Page summaries for devices that cannot summarize on-device, served by an Ecosia-owned backend instead of Mozilla's hosted summarizer. Firefox's hosted path (`hostedSummarizerFeature`, authenticated through `MLPAKit` and `AppAttestKit`, backed by a server-side model) is the reference design, and is switched off for Ecosia in ticket 07.

Needs product, privacy and backend input before it can be specified: which model and host, what page content leaves the device, how requests are authenticated, and how it fits Ecosia's privacy positioning.

## Acceptance criteria

- [ ] Triaged with product, privacy and backend, and either specified or closed
