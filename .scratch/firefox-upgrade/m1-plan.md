# Milestone 1 execution plan: feature configuration

**Written:** 2026-10-25, against `origin/upgrade/firefox` at `f0bb5fa14a` (PR #1362, M0 sign-off docs, still open).
**Milestone:** M1 of the Firefox 157.x upgrade, Jira epic MOB-5026. Tickets 07 to 10 (MOB-5033 to MOB-5036).
**Goal:** the app exposes exactly the Firefox features in [milestones.md](milestones.md#product-decisions), each decision is locked by a test, and each is confirmed on a device.
**Updated:** 2026-10-26, Q1 reframed, Q2 to Q6 answered (the AI controls hub is replaced by Ecosia's AI-free searching toggle); section 4 and step 4 rewritten.

This file is written so that an agent with no memory of the planning conversation can execute it. Read section 1 before running anything. The M0 plan ([m0-plan.md](m0-plan.md)) is done; its worktree, `verify.sh` and diary format carry over.

---

## 1. Read this first

### 1.1 Rules

1. **Work in the worktree** `/Users/dariocarlomagno/Workspace/ecosia/ios-browser-upgrade`. Do not touch the main checkout (`../ios-browser`) except `git fetch` and reading.
2. **Changes reach `upgrade/firefox` only through reviewed PRs** (spec, working rules), merged with a **merge commit**. Never commit to the local `upgrade/firefox` branch directly; it only fast-forwards to `origin/upgrade/firefox`.
3. **Pushing, opening a PR, Jira, GitHub settings and App Store Connect need Dario's go-ahead** each time. Local branches and commits do not.
4. **No history rewriting** on a branch once it is pushed: no rebase, no amend, no force push. Bring in new `upgrade/firefox` work by merging `origin/upgrade/firefox` into the ticket branch.
5. **Configuration over code** (spec, working rules). Where a Nimbus flag exists, override the channel entry in `firefox-ios/nimbus-features/*.yaml` with a `# Ecosia:` reason, and list `release`, `beta` and `developer` explicitly. Code changes in Firefox files follow [ARCHITECTURE.md](../../firefox-ios/Ecosia/Ecosia.docc/agents/ARCHITECTURE.md) (`// Ecosia:` / `/* Ecosia: */`).
6. **Every ticket ends with a diary entry** in `firefox-ios/EcosiaUpgrade/diary/157.md`, appended under `## Entries after M0` (format: [diary README](../../firefox-ios/EcosiaUpgrade/diary/README.md)). Milestone `M1`.
7. **Long commands run in the background** with a log file (`verify.sh`, `tuist-setup.sh`, builds).
8. **Commit messages** start with `[MOB-XXXX]`. Check after the first commit whether the shared `prepare-commit-msg` hook already adds it on a `dc-mob-*` branch, and do not double it.

### 1.2 Progress file

Keep `.scratch/firefox-upgrade/m1-progress.md` current: the step in progress, ticked steps with commits, the log, and every question under `## Waiting on Dario`. On resume, read this plan and the progress file and continue from the first unticked step.

### 1.3 When to stop and ask

- A question in section 4 is still open and the step needs its answer.
- A build or test failure cannot be traced within two focused attempts.
- What you see contradicts section 3 in a way that changes a step.
- Anything in rule 1.1.3.

Do not stop for what this plan already decides.

### 1.4 PRs and ticket map

Three PRs into `upgrade/firefox`, so the agent-ready work is not held up by the design review in ticket 09 and diary entries do not conflict between parallel branches:

| PR | Branch | Tickets | Steps |
| --- | --- | --- | --- |
| A | `dc-mob-5033-m1-feature-flags` | 07 (MOB-5033), 08 (MOB-5034), plus this plan | 0, 1, 2, 3 |
| B | `dc-mob-5035-ai-free-gates-firefox-ai` | 09 (MOB-5035) | 4 |
| C | `dc-mob-5036-feature-config-tests` | 10 (MOB-5036), M1 close-out | 5, 6 |

B starts from `origin/upgrade/firefox` once A is merged (or from A if A is still in review, then merges `origin/upgrade/firefox` after A lands). C starts after A and B are merged.

**PR #1362** (M0 sign-off) is still open. It only touches `README.md`, `m0-progress.md` and the end of `diary/157.md`. PR A does not touch the first two; if #1362 merges first, PR A's diary append conflicts at the end of `157.md`. Resolve by merging `origin/upgrade/firefox` into the branch and keeping both entries, the #1362 one first.

---

## 2. Prerequisites

Unchanged from M0 and still true on 2026-10-25: Xcode 27.0 (27A266a), iPhone 17 simulator, `tuist`, `swiftlint`, `actionlint`, `Staging.xcconfig` present in the worktree, `verify.sh` green on `f0bb5fa14a` (step 0 re-checks it). Device checks need two physical devices or one device plus the simulator: one with Apple Intelligence enabled (iPhone 15 Pro or later, iOS 26, English) and one without.

---

## 3. Facts as of 2026-10-25

### 3.1 Nimbus channels

- `firefox-ios/bin/nimbus-fml-configuration.sh` maps Xcode configurations to channels: `Debug`, `BetaDebug`, `Testing` → `developer`; `Development_TestFlight`, `Development_Firebase` → `beta`; `Release` → `release`.
- **Unit tests only ever see `developer` values.** The `Testing` configuration generates `Client/Generated/FxNimbus.swift` (gitignored) for `developer`, and `UnitTestAppDelegate` never initializes Nimbus, so `value()` returns the generated defaults.
- **Release and beta values can be generated without building:** the cached binary `firefox-ios/build/nimbus/<AS version>/bin/nimbus-fml` (`156.20260827050222` today; it exists after any build) runs as `nimbus-fml generate --channel <ch> --language swift --cache-dir build/nimbus/fml-cache nimbus.fml.yaml <outdir>` from `firefox-ios/`. Each feature's resolved defaults appear in its `public convenience init(... enabled: Bool = <value> ...)`.

Resolved values on `f0bb5fa14a`, generated that way:

| Feature (`FeatureFlagID`) | release | beta | developer | Decision |
| --- | --- | --- | --- | --- |
| `hostedSummarizer` | false | **true** | **true** | off |
| `summarizerAppAttestAuth` | **true** | **true** | **true** | off |
| `adBlocker` / `adBlockerBadge` | **true** / false | **true** / false | **true** / false | off / off |
| `googleLens` | false | false | false | off |
| `quickAnswers` | false | false | false | off |
| `vpnFeature` | false | false | false | off |
| `novaDesign` | false | false | false | off |
| `translation` | true | true | true | on |
| `aiKillSwitch` (hub row) | true | true | true | on (the hub is kept) |

`release` is listed explicitly only in `adBlockerFeature.yaml`. `vpnFeature.yaml`, `googleLensFeature.yaml` and `novaDesignFeature.yaml` (no `# Ecosia:` reason) rely on upstream's variable default for `release`; `quickAnswersFeature.yaml` and `translationsFeature.yaml` have no `# Ecosia:` reason; `translationsFeature.yaml` has no `defaults:` block at all.

### 3.2 Summaries (ticket 07)

- Every entry point (shake gesture, toolbar button, main-menu item, Settings row, AI controls hub row, tab and toolbar middlewares) goes through `DefaultSummarizerNimbusUtils` in `Client/Frontend/Summarizer/SummarizerNimbusUtils.swift`. The gate is **on-device OR hosted**: `isSummarizeFeatureEnabled = isAppleSummarizerEnabled() || isHostedSummarizerEnabled()`.
- **The hosted path is already off in code:** the 155.1 experiment made `isHostedSummarizerEnabled()` return `false` under a `/* Ecosia: */` block. Every hosted call site (`SummarizeCoordinator`, `SummarizeMiddleware`, `TabManagerMiddleware`, `ToolbarMiddleware`, `SummarizerServiceFactory` in `BrowserKit/Sources/SummarizeKit`) reads that function, so the YAML change is belt and braces, plus what the debug menu and future upstream call sites read.
- `isAppAttestAuthEnabled()` reads the flag directly, but `SummarizerServiceFactory` only uses it when it builds the hosted summarizer, which it never does. No App Attest work runs at launch (only a hidden debug setting deletes the key).
- `isAppleSummarizerEnabled()` = `AppleIntelligenceUtil.isAppleIntelligenceAvailable` (`Client/Application/AppleIntelligenceUtil.swift`, written at launch into `PrefsKeys.appleIntelligenceAvailable` / `cannotRunAppleIntelligence`), and English locale unless `summarizerLanguageExpansion` is on. `SKIP_APPLE_INTELLIGENCE` (`BrowserKit/Sources/Common/Constants/LaunchArguments.swift`) forces unavailable.
- Entry points (the full trigger list is `SummarizerTrigger.swift`): shake (`BrowserViewController.motionEnded`, `isShakeGestureEnabled`); address-bar summarize button (`AddressBarState`, `isToolbarButtonEnabled && canSummarize`); reader-mode-with-summarizer button (`AddressBarState`, `isLanguageExpansionEnabled && canSummarize`); main menu "Summarize page" (`MainMenuConfigurationUtility`, `summaryIsAvailable` from `TabManagerMiddleware`); reader-mode bar button (`SummarizeMiddleware`); the "summarizeToolbarEntry" contextual hint, anchored to the address-bar button. `canSummarize` / `summaryIsAvailable` come from `SummarizeMiddleware.makeConfiguration`, which needs `isSummarizeFeatureToggledOn`. Final guard: `BrowserCoordinator.showSummarizePanel`.
- **Leak if the Summarize settings screen is ever shown:** `SummarizeSettingsViewController` (around line 67) dispatches `canSummarize: isOn` from its toggle with no device check, and its main toggle has no device gate. On an unsupported device this would show the reader-mode-with-summarizer button. Only matters if ticket 09 brings that screen back (Q2).
- Release is English-only: `summarizerLanguageExpansion` is off on `release` (on for `beta` and `developer`), and `isAppleSummarizerEnabled()` then also needs the device language to be `en`.
- No page content goes to Mozilla, but two Mozilla requests remain: `makeConfiguration` fetches the prompt collection `summarizer-models-config` from Mozilla Remote Settings (`ASAIRemoteConfig`), and Nimbus itself fetches from Mozilla. Record both in the diary; neither is in scope.
- **In Ecosia's Settings, neither the Summarize row nor the AI controls row is reachable** (see 3.4).

### 3.3 Lens, Quick Answers, ad blocker (ticket 08)

- **Speech recognition:** `NSSpeechRecognitionUsageDescription` is in `firefox-ios/Client/Info.plist` and in 62 `firefox-ios/Client/*.lproj/InfoPlist.strings`; `origin/main` has none of them. The only Speech framework code is `BrowserKit/Sources/QuickAnswersKit/Backend/SpeechService/*`, used only by Quick Answers. **But `QuickAnswersKit` is linked into the app** (`Tuist/ProjectDescriptionHelpers/Targets+Client.swift:138`, imported by `BrowserCoordinator`, `BrowserViewController`, `HomepageHeaderCell` and others), so the binary references `SFSpeechRecognizer` without the purpose string. See question Q1.
- `NSMicrophoneUsageDescription` stays (on `main` today; WebRTC).
- **The ad-block list is downloaded and compiled even with the flag off.** `ContentBlocker.reloadAdBlockerList()` (`Client/ContentBlocker/ContentBlocker.swift`) has no flag check. It runs (a) on every safelist change and on "clear website data" (`ContentBlocker+Safelist.swift` `updateSafelist`, `Clearables.swift`), and (b) on every Remote Settings sync that reports `tracking-protection-lists-ios`. Each run calls `ASAdBlockerListFetcher.fetchAdBlockerListJSON()`, which creates the Remote Settings client for Mozilla's `tracking-protection-lists-ios` collection (`getRecords(syncIfEmpty: true)`) and then compiles the ~7.7 MB list into WebKit. Once that client exists, the periodic Remote Settings sync keeps it current. Only applying the rules to tabs is gated (`FirefoxTabContentBlocker.swift:71`, flag and `BlockAds` pref).
- The bundled `RemoteSettingsData/attachments/tracking-protection-lists-ios/ad-block.json` (~7.7 MB) still ships in the app with the flag off. Removing it is not required by ticket 08 and is left to ticket 26.
- The "Block Ads" row lives in `BrowsingSettingsViewController`, gated on `.adBlocker`. Ecosia's General settings section does not list the Browsing row at all (3.4), so it is unreachable from Settings either way. The main menu's site-protection header also navigates to `.adBlocker`; it is gated on the badge and the flag.
- Lens: every entry point also needs `defaultEngine.isGoogleEngine`, false for Ecosia.

### 3.4 AI controls hub (ticket 09)

- Hub: `Client/Frontend/Settings/AIControls/AIControlsModel.swift` and `AIControlsSettingsView.swift` (SwiftUI), opened by `SettingsCoordinator.pressedAIControls()`.
- Rows are already gated one by one: Translations on `.translation`, Page Summaries on `isSummarizeFeatureEnabled` (on-device only, given 3.2), Quick Answers on `.quickAnswers` (off). So once ticket 08 is done, the hub shows Translations, plus Page Summaries on supported devices, plus the "Block AI Enhancements" master switch.
- **The hub is not reachable in the Ecosia app.** `AppSettingsTableViewController.getGeneralSettings()` keeps Firefox's whole General list (Browsing, Summarize, Quick Answers, Translation, AI Controls rows, …) inside a `/* Ecosia: */` block and returns Ecosia's own list, which has none of them. The same holds for Firefox's standalone Translation and Summarize settings rows.
- **Two "Learn more" links go to Mozilla:** `AIControlsModel.headerLinkInfo` and `blockAIEnhancementsLinkInfo` both point to `SupportUtils.URLForTopic("ios-ai-controls")` → `https://support.mozilla.org/1/mobile/<version>/iOS/<locale>/ios-ai-controls`.
- **The header card shows Firefox's fox artwork:** `foxWithStars` (`AIControlsSettingsView.swift`, `Client/Assets/Images.xcassets/foxWithStars.imageset`).
- The kill switch (`AIControlsModel.toggleKillSwitch`) also flips Quick Answers' user preference even when its row is hidden. Harmless while the flag is off.
- Upstream slip: the second link checks `headerLinkInfo.url` but shows `blockAIEnhancementsLinkInfo.label`. Both URLs are the same today.
- Strings: the English values do not say Firefox or Mozilla (the app name comes from `AppName.shortName` via `%@`). None of the 61 localized `Settings.strings` with hub keys contains "Firefox" or "Mozilla" today; still run `python3 ecosify-strings.py firefox-ios` after any string change.
- Existing tests: `firefox-ios-tests/Tests/ClientTests/Settings/AI Controls/AIControlsModelTests.swift`.

### 3.5 Tests (ticket 10)

- `EcosiaTests` sources: `EcosiaTests/**/*.swift` minus snapshot tests (`Tuist/ProjectDescriptionHelpers/Targets+Tests.swift`), so a new file there is picked up after `tuist generate`. It does not include `ClientTests/FeatureFlagsProviderTests.swift`'s mocks, and no EcosiaTests file reads Nimbus today.
- Real layer: `NimbusFeatureFlagLayer().checkNimbusConfigFor(_:with:)` (`Client/Nimbus/NimbusFeatureFlagLayer.swift`), or `FeatureFlagsProvider(prefs:backendLayer:)`. Debug-menu overrides are compiled out for Ecosia (`#if MOZ_CHANNEL_beta || MOZ_CHANNEL_developer`), so the prefs argument does not change the result.
- Style reference: `EcosiaTests/FirefoxUpgradeCharacterizationTests.swift` (doc comment per test, `// MARK: -` sections, assert messages).
- Do not use `FxNimbus.shared.features.X.with { }` overrides in these tests: they last for the whole test process and there is no reset helper.

---

## 4. Open questions for Dario

Written into the progress file's `## Waiting on Dario`. Steps that do not need the answer go ahead.

- **Q1: reframed on 2026-10-26, no longer blocks PR A.** Removing `NSSpeechRecognitionUsageDescription` while `QuickAnswersKit` stays compiled in leaves the app linking `Speech.framework` and referencing `SFSpeechRecognizer` with no purpose string (confirmed with `otool -L` / `nm -u` on the built `Client.debug.dylib`). Only App Store Connect's processing of an uploaded build can say whether it flags that (ITMS-90683); no local tool reproduces its scan, and Firebase distribution (ticket 22) does not go through App Store Connect. `upgrade/firefox` ships nowhere, so the answer is not needed to merge PR A. It is needed before the first App Store Connect upload of the upgrade: one internal TestFlight upload, at the latest before release (ticket 24). If it is flagged, either restore the key or stop compiling `QuickAnswersKit`.
- **Q2 to Q5: answered on 2026-10-26.** Dario: the hub does not come to Ecosia's Settings. Ecosia's "AI-free searching" toggle replaces it and switches off **both page summaries and translations**. Where that toggle is not offered, **page summaries get their own Settings row** (Firefox's Summarize row). The hub's links, master switch and artwork are therefore moot. Ticket 09 rewritten accordingly (`issues/09-ai-controls-hub.md`); Jira MOB-5035 updated to match on 2026-10-27.
- **Q6: answered on 2026-10-26.** Firefox treats translations as a switchable AI feature (its own Translation settings row, and the hub's "AI-powered features" list), so Dario: treat it like summaries. Where AI-free searching is not offered, Firefox's Translation row appears next to the Summarize row.

Pre-decided, Dario can veto:

- **D1. Hosted summaries: keep both gates.** The existing code override and the new YAML values. The code override protects against a future upstream call site; the YAML makes the debug menu and the generated config truthful.
- **D2. Ticket 10's release and beta values are checked by a script, not a unit test.** Unit tests can only see `developer` (3.1). `firefox-ios/EcosiaUpgrade/tools/check-feature-config.sh` generates `FxNimbus.swift` for all three channels with the cached `nimbus-fml` binary and asserts the same table; `verify.sh` runs it. The unit tests in `EcosiaTests` assert the `developer` values through `NimbusFeatureFlagLayer`, as the ticket asks.
- **D3. Ad-block list: gate in code.** Add `// Ecosia:` guards so `reloadAdBlockerList()` returns early when `.adBlocker` is off, and the Remote Settings sync handler skips it. Leave the bundled JSON (ticket 26).

---

## 5. Steps

### Step 0: branch and baseline

```bash
cd /Users/dariocarlomagno/Workspace/ecosia/ios-browser-upgrade
git fetch origin --quiet
git status --short                      # must be empty apart from this plan and the progress file
git switch -c dc-mob-5033-m1-feature-flags origin/upgrade/firefox
```

Run `verify.sh` on the branch point in the background if it has not been run on `origin/upgrade/firefox`'s current head. Create `m1-progress.md` (appendix A).

**Done when:** the branch exists, the baseline is green, the progress file exists.

### Step 1 (ticket 07, MOB-5033): summaries on-device only

1. `hostedSummarizerFeature.yaml`: `release`, `beta`, `developer` all `enabled: false`, `toolbarEntrypoint: false`, `shakeGesture: false`, with `# Ecosia:` reason ("on-device summaries only: no page content goes to Mozilla's hosted summarizer; `isHostedSummarizerEnabled()` is also overridden in code").
2. `summarizerAppAttestAuthFeature.yaml`: `enabled: false` on all three, `# Ecosia:` reason (App Attest only exists for the hosted path).
3. Generate all three channels (3.1) and confirm both features resolve to false everywhere. Paste the table into the diary entry.
4. Trace and list every summaries entry point with its gate, file and line (3.2 is the starting point; grep `summarizerNimbusUtils.` and `SummarizerNimbusUtils` across `Client/`). Confirm none bypasses `isSummarizeFeatureEnabled` / `isAppleSummarizerEnabled`.
5. Simulator check with `SKIP_APPLE_INTELLIGENCE`: no toolbar button, no menu item, shake does nothing. (Settings and hub rows are unreachable until step 4.)
6. Commit `[MOB-5033] Turn off hosted summaries and App Attest on every channel`.
7. Diary entry (entry points and gates table, generated values, the device checks still owed).

**Device checks owed to Dario** (progress file): on a supported device, summaries work and a proxy (Proxyman or Charles) shows no request to Mozilla's summarizer or App Attest endpoints; on an unsupported device, no entry point.

### Step 2 (ticket 08, MOB-5034): Lens, Quick Answers and ad blocker off

1. `googleLensFeature.yaml`: add `release: enabled: false` (keep the existing `# Ecosia:` comment, extend it to say `release` is now explicit).
2. `quickAnswersFeature.yaml`: add `release: enabled: false, model: exa` and a `# Ecosia:` reason.
3. `adBlockerFeature.yaml`: `enabled: false`, `badge-enabled: false` on all three; rewrite the `# Ecosia:` reason: the EasyList-based list hides the ads on Ecosia's own search results, which fund tree planting; ticket 26 investigates keeping it.
4. Ad-block list (D3): guard `ContentBlocker.reloadAdBlockerList()` on `.adBlocker`, with a `// Ecosia:` comment. Check whether `ContentBlocker` can reach `FeatureFlaggable`'s provider during `ContentBlocker.shared` init in unit tests (the M0 crash lesson: resolve optionally if not). Add unit tests with the existing `MockAdBlockerListFetcher` that counts fetches, in `ClientTests/ContentBlockerTests.swift` (its flag mocks are not available to `EcosiaTests`).
5. Speech recognition (Q1): check once more that nothing outside `QuickAnswersKit` requests speech authorization; remove `NSSpeechRecognitionUsageDescription` from `Client/Info.plist` and its line (plus comment line) from the 62 `Client/*.lproj/InfoPlist.strings`. Check every file still parses: `plutil -lint`.
6. Generate all three channels and confirm Lens, Quick Answers, ad blocker and badge are false.
7. Commits: `[MOB-5034] Turn off Google Lens, Quick Answers and the ad blocker on every channel`, `[MOB-5034] Skip the ad-block list while the ad blocker is off`, `[MOB-5034] Remove the speech-recognition purpose string`.
8. Diary entry, including what still ships (the bundled 7.7 MB list, `QuickAnswersKit` linked) and Q1's outcome.

**Device checks owed to Dario:** no Lens or Quick Answers entry point on the new tab page, the address bar or the image context menu; no "Block Ads" anywhere; Ecosia search ads show normally on the upgrade build.

### Step 3: PR A

1. Run `verify.sh` (background). Must be green.
2. Commit this plan with the progress file: `[MOB-5033] M1 plan`.
3. Ask Dario to push and open PR A: title `[MOB-5033] [MOB-5034] Summaries on-device only; Lens, Quick Answers and ad blocker off`, base `upgrade/firefox`, merge with a merge commit, description lists the device checks owed and the App Store Connect check from Q1.

### Step 4 (ticket 09, MOB-5035): AI controls hub

Rewritten after Q2 to Q5 (2026-10-26). Branch `dc-mob-5035-ai-free-gates-firefox-ai`, started from PR A's branch because A is not pushed yet.

1. `AIFreeSearchingSelection` (Ecosia module) gets `isAvailable` (the toggle is offered: flag on, and Ecosia is the provider) and `blocksBrowserAI` (`isAvailable` and the user value is on). `isActive` stays as it is for search; it ignores the provider, so it cannot be the browser-AI rule.
2. Summaries: `DefaultSummarizerNimbusUtils.isSummarizeFeatureToggledOn` also requires `!blocksBrowserAI` (`/* Ecosia: */`). Every summaries entry point reads it (3.2).
3. Translations: `FeatureFlagsProvider.isEnabled(.translation)` returns false while `blocksBrowserAI` (`// Ecosia:`). Every translations gate reads that flag, and `FeatureFlagsProvider` is the only production `FeatureFlagProviding`.
4. `AIFreeSearchingSearchSettings` hides on `!isAvailable` and, on change, dispatches `ToolbarAction(.didSummarizeSettingsChange)` and `TranslationsAction(.didTranslationSettingsChange)` for the window, as Firefox's own settings screens do.
5. Ecosia's General settings add Firefox's `SummarizeSetting` when `!isAvailable` and the device can summarize. Its screen's `canSummarize` leak (3.2) cannot trigger, because the row only shows on supported devices.
6. Tests: `AIFreeSearchingSelectionTests` (the rule, including a provider change after AI-free was turned on) and `EcosiaTests/AIFreeSearchingBrowserAITests.swift` (both gates; other flags untouched).
7. Diary entry, `verify.sh`, ask Dario to push PR B. Device checks per the ticket's criteria.

### Step 5 (ticket 10, MOB-5036): lock the configuration

1. `EcosiaTests/FeatureConfigurationTests.swift`: one test per row of ticket 10's table (translations on; hosted summarizer and App Attest off; Lens, Quick Answers, VPN off; ad blocker and badge off; Nova off), each reading `NimbusFeatureFlagLayer().checkNimbusConfigFor(_:with:)`. Add one for D1's code override (`DefaultSummarizerNimbusUtils.isHostedSummarizerEnabled() == false`), using `DependencyHelperMock` for the profile.
2. `firefox-ios/EcosiaUpgrade/tools/check-feature-config.sh` (D2): generates the three channels into a temp dir, asserts the same table for `release` and `beta` (and `developer`, so it also runs without a test build), exits non-zero with the feature and channel that differ. A small `check-feature-config.test.sh` in the style of `sync-main.test.sh` only if the parsing is non-trivial. Hook it into `verify.sh` after linting.
3. Mutation check by hand, once per row: flip the value on one channel, confirm exactly the matching test (developer) or script line (release, beta) fails, and revert. Record the result in the diary.
4. Commits: `[MOB-5036] Lock the M1 feature decisions with tests`, `[MOB-5036] Check the feature decisions on the release and beta channels`.

**Device checks owed to Dario:** VPN off, no "Block Ads" row, Nova off.

### Step 6: M1 close-out

1. `/code-review` on PRs A to C's commits against `origin/upgrade/firefox`.
2. M1 summary in `157.md`: each product decision, how it is enforced (YAML, code, test, script), device checks done, what still ships but is unreachable (`QuickAnswersKit`, the bundled ad-block list), time spent, new traps.
3. Mark the M1 row in `milestones.md` as done. `verify.sh`, ask Dario to push PR C.

**Done when** (milestones.md): each decision is covered by a test and confirmed on a device.

---

## Appendix A: progress file template

```markdown
# M1 progress

Plan: .scratch/firefox-upgrade/m1-plan.md
Base: origin/upgrade/firefox <hash>

## Steps

- [ ] 0 Branch and baseline
- [ ] 1 Summaries on-device only (MOB-5033): <commits>
- [ ] 2 Lens, Quick Answers, ad blocker off (MOB-5034): <commits>
- [ ] 3 PR A: <number>
- [ ] 4 AI controls hub (MOB-5035): <commits>; PR B: <number>
- [ ] 5 Feature configuration tests (MOB-5036): <commits>
- [ ] 6 Close-out; PR C: <number>

In progress: <step or "nothing">

## Device checks owed

<one line per check, ticked when Dario confirms>

## Waiting on Dario

<questions>

## Log

- YYYY-MM-DD HH:MM <what happened>
```
