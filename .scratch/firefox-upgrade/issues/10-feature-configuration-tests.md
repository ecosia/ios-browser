# 10: Lock the feature configuration with tests

**Jira:** [MOB-5036](https://ecosia.atlassian.net/browse/MOB-5036)
**Milestone:** M1 Feature configuration
**Status:** ready-for-agent
**Blocked by:** 07, 08, 09

## What to build

Unit tests that fail if a future upgrade or main sync silently changes a product decision. Each test asserts the resolved Nimbus value through the app's feature-flag layer, not the YAML.

| Decision | Assert |
| --- | --- |
| Translations kept | translations feature on |
| Summaries on-device only | hosted summarizer off, App Attest auth off |
| Google Lens out | Google Lens off |
| Quick Answers out | Quick Answers off |
| VPN out | VPN off |
| Ad blocker out | ad blocker off, badge off |
| Nova off | Nova design off |

Add them to `EcosiaTests`, next to the 155.1 characterization tests.

## Acceptance criteria

- [ ] One test per row above, passing on `upgrade/firefox`
- [ ] Flipping any one YAML value makes exactly the matching test fail (checked once by hand)
- [ ] VPN off, ad blocker off (no "Block Ads" row in Browsing settings), and Nova off are also confirmed on a device
- [ ] Diary entry written; M1 is done when this ticket is
