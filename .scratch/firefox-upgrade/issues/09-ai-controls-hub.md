# 09: AI-free searching replaces the AI controls hub

**Jira:** [MOB-5035](https://ecosia.atlassian.net/browse/MOB-5035)
**Milestone:** M1 Feature configuration
**Status:** ready-for-agent
**Blocked by:** 02

> **Changed on 2026-10-26 (Dario).** This ticket first asked for Firefox's AI controls hub to be shown with only Translations and Summaries. The hub is not shown at all: Ecosia's own "AI-free searching" setting takes its place. The Jira ticket still has the old text.

## What to build

Firefox's AI controls settings hub (added upstream in Firefox 151) is not part of Ecosia's Settings, which already leave it out. Ecosia's "AI-free searching" toggle (Settings > Search) takes its place for the AI features Firefox serves:

- While AI-free searching is on, page summaries and translations are off: no summaries entry point (shake, toolbar button, menu item, reader-mode buttons) and no translations entry point (toolbar icon, menu item, contextual hint), and translation models are not downloaded at launch.
- The rule only applies while the toggle is offered (its Unleash flag is on and Ecosia is the search provider). A value the user set before switching to another provider must not keep the features hidden.
- Where the toggle is not offered, Firefox's Summarize settings row appears in General settings, on devices that can summarize on-device.
- Turning the toggle on or off updates the open window's toolbar right away, as Firefox's own settings screens do.

Follow the `// Ecosia:` / `/* Ecosia: */` convention in [ARCHITECTURE.md](../../../firefox-ios/Ecosia/Ecosia.docc/agents/ARCHITECTURE.md).

## Acceptance criteria

- [ ] With AI-free searching on, no summaries or translations entry point anywhere, checked on a supported device
- [ ] With AI-free searching off, summaries (on supported devices) and translations work
- [ ] With a non-Ecosia search provider (or the AI-free flag off), the Summarize row is in General settings on a supported device, and neither feature is hidden by an earlier AI-free value
- [ ] Unit tests for the rule and for both gates
- [ ] Diary entry written
