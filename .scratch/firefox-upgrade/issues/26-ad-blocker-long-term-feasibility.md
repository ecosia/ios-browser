# 26: Investigate keeping the ad blocker long term

**Jira:** [MOB-5052](https://ecosia.atlassian.net/browse/MOB-5052)
**Milestone:** Follow-up (blocks nothing in this upgrade)
**Status:** needs-triage
**Blocked by:** 08

## What to build

An answer to whether Ecosia can offer Firefox's built-in ad blocker (Firefox 154+) without it working against Ecosia, and what that would take. The ad blocker ships switched off in this upgrade (ticket 08).

The problem found during planning: the bundled EasyList-based list (`RemoteSettingsData/attachments/tracking-protection-lists-ios/ad-block.json`, about 7.7 MB) contains a rule scoped to `*ecosia.org` that hides Ecosia's ad elements (for example `.product-ads-carousel` and `div[data-test-id="mainline-result-ad"]`). `ecosia.org` also appears in a broader multi-site hiding rule, and the list covers some Bing ad endpoints. Those ads fund tree planting. Editing the bundled file is not enough, because `ASAdBlockerListFetcher` downloads list updates from Mozilla's Remote Settings (`tracking-protection-lists-ios`) and would bring the rules back.

Questions to answer:

- Can Ecosia's domains, and the ad endpoints its search results depend on, be exempted reliably and permanently, for example through an always-on allow list applied after every list update?
- Should Ecosia host its own filtered list instead of consuming Mozilla's collection?
- What does the feature cost in app size, launch time and memory (content-rule compilation)?
- How does it fit next to Ecosia's own tracking protection and its positioning?
- Product: do we want it at all?

## Acceptance criteria

- [ ] A written recommendation (keep with exemption, keep with an Ecosia-hosted list, or drop), with effort and risk for each option
- [ ] If an exemption is proposed, a prototype shows Ecosia's search ads still display with the blocker on, including after a list update
- [ ] Product decision recorded
