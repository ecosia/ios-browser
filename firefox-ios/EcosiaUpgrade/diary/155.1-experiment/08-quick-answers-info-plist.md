# 08: Add Quick Answers Info.plist entries

**What to build:** The newly-shipped Quick Answers voice feature has the runtime permission declarations it needs to actually run, with copy that reflects Ecosia's own branding rather than upstream's default text.

**Blocked by:** 02

**Status:** done

- [x] A speech-recognition usage-description entry is present (missing today — without it, on-device voice input crashes or is rejected at review)
- [x] The existing microphone usage-description string is reworded from generic upstream branding to Ecosia's own copy

## Comments

### AC 1 — the key arrived from upstream; the copy was the actual work

The ticket assumed Ecosia would have to add `NSSpeechRecognitionUsageDescription`. It was already there: **upstream added it in 155.1**, and the merge brought it in. What upstream also brought was its own branding — `"Firefox uses speech recognition to convert your voice to text for voice search."`

That string is user-visible in **every** locale, not just English: no `.lproj/InfoPlist.strings` file in the repo carries `NSSpeechRecognitionUsageDescription`, so `Info.plist` is the only source for it and there is no localized override to fall back on. Rebranded to Ecosia, and added to `en.lproj/InfoPlist.strings` as well so the English path is explicit rather than relying on the plist fallback.

Requirement confirmed rather than assumed: `QuickAnswersKit` uses `SFSpeechRecognizer` (`Backend/SpeechService/Abstractions.swift`, `DefaultQuickAnswersService.swift`) **and** `AVAudioSession`/`AVAudioEngine` with `recordPermission`. Both declarations are genuinely needed, and `SFSpeechRecognizer.requestAuthorization` traps without the first — exactly the crash the ticket describes.

### AC 2 — microphone copy

`Info.plist` still carried upstream's `"Firefox uses your microphone to record and upload audio."`; Ecosia's rebrand had only ever lived in the `.lproj` files. Rebranded the plist fallback too, and resolved the `en.lproj` conflict in favour of Ecosia's copy (which also preserves Ecosia's `NSCameraUsageDescription` wording).

### Two unrelated `Info.plist` conflicts, resolved to stage the file

- **Key additions** — upstream added `AttributionCopyEndpoint`, `NSAdvertisingAttributionReportEndpoint`, `LiteLLMAPIKey`/`Endpoint`/`Model` and `SKAdNetworkItems`; Ecosia has `AUTH0_CLIENT_ID` and `AdjustAppToken`. Verified the two key sets are **disjoint** (no duplicates introduced), so both were kept.
- **Home-screen quick action** — upstream's third shortcut is its App Icon picker (icon `logoFirefoxLarge`, the Firefox logo); Ecosia substitutes Scan QR Code (`menu-ScanQRCode`, which exists in Ecosia's own asset catalog). Preserved Ecosia's substitution and kept upstream's original in an XML comment, matching the `<!-- Ecosia: … -->` convention already used elsewhere in this file.

`plutil -lint` passes on both `Info.plist` and `en.lproj/InfoPlist.strings`.

### ⚠ Pre-existing bug found, deliberately not fixed

Ecosia's `Scan QR Code` quick action is **dead, and was dead before this upgrade**. `ShortcutType` in `QuickActions.swift` declares only `newTab`, `newPrivateTab`, `openLastBookmark`, `appIcon` — there is no `qrCode` case, no handler for `$(PRODUCT_BUNDLE_IDENTIFIER).QRCode` anywhere in Swift, and Ecosia made **no changes** to `QuickActions.swift` (verified against the fork point). So the shortcut appears on long-press and does nothing.

Preserved as-is because that is the pre-upgrade behaviour and changing it is a product decision, not a rebase one. Needs either a `ShortcutType.qrCode` case plus handler, or removal from `Info.plist`. If instead Ecosia wants upstream's App Icon action, its icon must change off `logoFirefoxLarge`.

### ⚠ Gap in ticket 03 found and closed here

Tracing whether Quick Answers is actually built revealed that **`Client` imports `QuickAnswersKit` in 9 files but the Tuist `Client` target never declared it** — so the target could not have compiled. A systematic sweep (every module imported under `firefox-ios/Client/` vs. everything the target declares) found **four** such BrowserKit products, all new at 155.1 and all absent from Ecosia's manifest:

| Product | Client files importing it |
| --- | --- |
| `QuickAnswersKit` | 9 (incl. `BrowserCoordinator`, `QuickAnswersCoordinator`, `ASAIRemoteConfig`) |
| `WebCompatReporterKit` | 3 |
| `AppAttestKit` | 1 (`DeleteAppAttestKeySetting`) |
| `MLPAKit` | 1 (`ChangeMLPAEndpointSetting`) |

All four added to `Targets+Client.swift`; `tuist generate` succeeds and each now appears in the generated project's Frameworks phase. **This belonged to ticket 03** — that ticket caught `ModifiedCopy` (an SPM package) but did not sweep BrowserKit's local products. Ticket 03's record has been amended.

The sweep is now closed: every other module `Client` imports either is an Apple framework or was already imported at the Ecosia baseline (so it already resolved) — `MozillaAppServices`, `MozillaRustComponents`, `SwiftASN1`, `SwiftDraw`, `XCGLogger`, `Accounts`, `AppIntents`, `FoundationModels`. `AppAttestKit`/`MLPAKit`/`WebCompatReporterKit`/`QuickAnswersKit` are also imported inside BrowserKit itself, which its own `Package.swift` handles.

### Out of scope, and a genuine gap in the 19-ticket plan

**67 localized `InfoPlist.strings` files remain conflicted** — see the unassigned list. No ticket in the breakdown covers the localization rebrand sweep, and it needs a product decision rather than mechanical resolution.
