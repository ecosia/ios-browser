# 13: Clear the 155.1 follow-ups

**Jira:** [MOB-5039](https://ecosia.atlassian.net/browse/MOB-5039)
**Milestone:** M2 Verification baseline
**Status:** ready-for-agent
**Blocked by:** 02

## What to build

Clean up the items the 155.1 experiment deliberately left open (ticket 19, "Follow-ups"), so they don't mislead the move to 157.

- `Tuist/ProjectDescriptionHelpers/Schemes+Ecosia.swift` skips six test classes that no longer exist: `AdjustTelemetryHelperTests`, `PrivateBrowsingTelemetryTests`, `OnboardingTelemetryDelegationTests`, `DefaultSearchPrefsTests`, `StoriesFeedTelemetryTests`, `ToastTelemetryTests`. Remove them.
- Three `RustFxA/*.swift` files are picked up by the Client glob, so `RustFirefoxAccounts` exists in two modules. Exclude them from the glob, and drop the `Client.RustFirefoxAccounts` qualification in `MockProfile`.
- `EcosiaSearchBarLocationSaver.saveUserSearchBarLocation(profile:)` reads from its argument but writes through `AppContainer`. Make it use one source.
- The dead "Scan QR Code" quick action (no `ShortcutType.qrCode`, no handler) is a production bug too: file it separately against `main`, don't fix it here.
- `firefox-ios/Client/Info.plist` on `main` still says "Firefox uses your camera…" and "Firefox uses your microphone…". Check whether users actually see that text (or whether `InfoPlist.strings` overrides it in every language). If they do, file it against `main`.

The 62 test files with sync `setUp()`/`tearDown()` where upstream uses `async throws` stay out of scope; they compile and rewriting them would hide real changes.

## Acceptance criteria

- [ ] No skipped test class in the scheme refers to a missing class
- [ ] `RustFirefoxAccounts` exists in one module only
- [ ] `EcosiaSearchBarLocationSaver` reads and writes through the same source, with its tests passing
- [ ] The QR quick-action bug is filed against `main`
- [ ] Diary entry written
