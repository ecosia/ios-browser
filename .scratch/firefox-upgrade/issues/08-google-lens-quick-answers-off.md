# 08: Google Lens, Quick Answers and ad blocker off

**Jira:** [MOB-5034](https://ecosia.atlassian.net/browse/MOB-5034)
**Milestone:** M1 Feature configuration
**Status:** ready-for-agent
**Blocked by:** 02

## What to build

Google Lens, Quick Answers and the ad blocker are unreachable on every channel, and the app no longer asks for permissions only Quick Answers needed.

**Google Lens and Quick Answers**

- `googleLensFeature.yaml` and `quickAnswersFeature.yaml` are already `enabled: false` on beta and developer, but `release` relies on upstream's variable default. List `release: enabled: false` explicitly in both, with a `# Ecosia:` reason.
- The 155.1 experiment *added* `NSSpeechRecognitionUsageDescription` to `firefox-ios/Client/Info.plist` for Quick Answers (its ticket 08). Remove it, along with its translations in the `InfoPlist.strings` files. Check first that nothing else uses speech recognition.
- Keep `NSMicrophoneUsageDescription` (production has it today; web pages use the microphone through WebRTC).

**Ad blocker**

Out for now, because its EasyList-based block list hides the ads on Ecosia's own search results page (ticket 26 investigates keeping it long term). The experiment configured `adBlockerFeature.yaml` as `enabled: true`, `badge-enabled: false` on every channel. Set `enabled: false` on release, beta and developer, with a `# Ecosia:` reason pointing at ticket 26.

Check what still runs while the feature is off: whether `ASAdBlockerListFetcher` keeps downloading the `tracking-protection-lists-ios` collection from Mozilla, and whether the bundled list (`RemoteSettingsData/attachments/tracking-protection-lists-ios/ad-block.json`, about 7.7 MB) is still compiled into WebKit content rules at launch. Stop either one if it does.

## Acceptance criteria

- [x] Google Lens, Quick Answers and the ad blocker (and its badge) resolve to off on release, beta and developer in the generated `FxNimbus.swift` (generated release, beta and developer all off, 2026-10-25)
- [x] `NSSpeechRecognitionUsageDescription` is gone from `Info.plist` and every `InfoPlist.strings`, and no code path requests speech-recognition permission (only QuickAnswersKit requests it and Quick Answers is off; the App Store Connect check stays open as Q1)
- [x] No Lens or Quick Answers entry point on the new tab page, address bar or context menus, and no "Block Ads" row in Browsing settings, checked on device (simulator 2026-10-27, EcosiaBeta BetaDebug)
- [x] Ecosia's search ads display normally on the upgrade build (simulator 2026-10-27, EcosiaBeta BetaDebug)
- [x] With the ad blocker off, no ad-block list is downloaded or compiled, or the remaining work is explained in the diary (simulator 2026-10-27, EcosiaBeta BetaDebug: the app log never requests tracking-protection-lists-ios and no ad-block rule list is compiled; the bundled ad-block.json is left to ticket 26 in the diary)
- [x] Diary entry written
