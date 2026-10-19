# 09: AI controls hub shows only kept features

**Jira:** [MOB-5035](https://ecosia.atlassian.net/browse/MOB-5035)
**Milestone:** M1 Feature configuration
**Status:** ready-for-human
**Blocked by:** 02

## What to build

The AI controls settings hub (added upstream in Firefox 151) shows exactly two features: Translations, and Summaries when the device supports on-device summaries. No row, description or link refers to Quick Answers, Google Lens, hosted summaries or Mozilla's AI services, and the copy is Ecosia-branded.

This may need code where the hub's rows are not individually gated by Nimbus flags. Follow the `// Ecosia:` / `/* Ecosia: */` convention in [ARCHITECTURE.md](../../../firefox-ios/Ecosia/Ecosia.docc/agents/ARCHITECTURE.md).

## Acceptance criteria

- [ ] On a supported device the hub shows Translations and Summaries; on an unsupported device, Translations only
- [ ] No "Firefox" or "Mozilla" wording in the hub, in any shipped language (run `python3 ecosify-strings.py firefox-ios` after any string change)
- [ ] Design or product has seen the hub and accepted it
- [ ] Diary entry written
