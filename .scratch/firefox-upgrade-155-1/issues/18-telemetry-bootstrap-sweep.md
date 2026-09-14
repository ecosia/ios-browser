# 18: Telemetry and bootstrap sweep

**What to build:** Telemetry and app-bootstrap code correctly reflect every new event and symbol introduced by the verticals completed so far, done last so the full picture of what changed is known rather than guessed at.

**Blocked by:** 10, 11, 12, 13, 14, 15, 16, 17

**Status:** done

- [x] Telemetry wrapper code is reconciled per the intent-diff manifest, including the new `UserFeaturePreferenceProvider` conformance and the removed legacy telemetry action cases
- [x] Ecosia's Glean-wrapper mock still satisfies the current telemetry protocol
- [x] App bootstrap files (app delegate, launch utility, window manager, web server, accessibility identifiers) are reconciled per the intent-diff manifest
- [x] Any UI test relying on an accessibility identifier that shifted position/name is confirmed still correct

## Verification standard (applies to every AC in this ticket)

Nothing in the repo compiles until ticket 19 — the rebase is in progress with hundreds of files
still carrying conflict markers inside the same `Client` target, so `xcodebuild` fails on the first
unresolved file and never reaches this vertical. **Do not read "compiles", "passes" or "behaves
correctly" in an AC as requiring a build or a test run.** They are satisfied by the static
substitutes the earlier tickets established:

- `xcrun swiftc -parse <file>` on every file touched, plus a check that no conflict markers remain.
- A symbol-dependency sweep: every non-SDK symbol the reconciled code references still resolves in
  the tree (this is what catches the silent losses a clean auto-merge produces).
- `cd firefox-ios && tuist generate --no-open` when the file set or module imports changed.
- `swiftlint --strict` — run it bare from the repo root, not with explicit paths (see ticket 10's
  tooling notes for why).
- `plutil -lint` for plists/`.strings`; `bin/nimbus-fml.sh` for Nimbus manifest work.

Actual compilation and test execution are ticket 19's job. State plainly in your findings which ACs
were verified statically rather than executed, and hand any runtime risk you could not settle to
ticket 19.

**Every AC below was verified statically, not executed.** What was run: `xcrun swiftc -parse` on all
19 touched Swift files (clean), `node --check` on the one touched `.js`, a conflict-marker scan
(clean), `intent-diff-check.py` and `symcheck.py` over both the conflicted and the auto-merged files
in scope, `cd firefox-ios && tuist generate --no-open` (success), and bare `swiftlint lint --strict
--quiet` from the repo root (no violation in any file this ticket touched).

## Inherited findings

- **glean-swift jumps three majors, 66 → 69.** Ticket 03 had to bump Ecosia's Tuist pin because `MozillaRustComponents` at 155.1 requires `from: "69.0.0"`. Treat this ticket's AC "Ecosia's Glean-wrapper mock still satisfies the current telemetry protocol" as **likely-to-fail**, not a formality. — **Confirmed: it did fail.** See §2.
- `MockGleanWrapper.swift` is already resolved (ticket 09, took upstream's protocol-conformant version). — Re-verified: it is byte-identical to upstream and already declares `recordText`/`recordStringList`.
- `AppDelegate.swift` … `isNovaDesignOnClosure:` — **already correct** in the merged file (`isNovaDesignOnClosure: { self.featureFlagsProvider.isEnabled(.novaDesign) }`, `AppDelegate.swift:42`); ticket 05's rename had already landed there. No change needed.
- `RemoteSettingsGleanTelemetry.swift` is new upstream; check whether bootstrap needs to register it. — **No.** It is wired exactly as upstream wires it, from `Providers/Profile.swift:681` (`service.setTelemetry(telemetry: RemoteSettingsGleanTelemetry())`), and that line is byte-identical to upstream's. It takes `GleanWrapper` by injection with a `DefaultGleanWrapper()` default, so it is silenced along with everything else.

## Findings

### 1. `TelemetryWrapper.swift` — 2 conflicts

- **Ping registration.** Kept Ecosia's removal, but **corrected the recorded reason**. The original
  comment said `GleanMetrics.Pings doesn't exist in Ecosia's generated metrics`; that is no longer
  true — `firefox-ios/Client/Glean/pings.yaml` is fed to the Glean generator by Tuist's
  `Glean SDK Generator Script` build phase (`Tuist/ProjectDescriptionHelpers/BuildScripts.swift:169`)
  and `GleanMetrics.Pings.shared` does generate into `Client/Generated/Metrics/Metrics.swift`. The
  removal now stands on behavioural grounds, which are the real ones: **Glean *is* initialised and
  uploads for Ecosia**, so registering Firefox's custom pings would start sending them. The comment
  block records both the behavioural reason and the fact that the compile-level reason expired, so
  the next upgrade does not re-litigate it from a false premise.
- **New `.tabCountDiscrepancy` app-error case.** Silenced to match its siblings in that block.
  Handling it explicitly matters: the `default:` branch of that switch *reports uninstrumented
  metrics*, so letting a new upstream case fall through would be a behaviour change, not a no-op.
- `UserFeaturePreferenceProvider` conformance (AC-1) was already present from the auto-merge
  (`TelemetryWrapper.swift:42-44`) and its two uses (`userPreferences.startAtHomeSetting`,
  `userPreferences.getPreferenceFor(.googleLens)`) both resolve.

### 2. `GleanWrapper.swift` + `FakeGleanWrapper.swift` — the AC that was flagged likely-to-fail, and did fail

The 155.1 `GleanWrapper` protocol **removed** `recordLabel`, `recordLabeledQuantity`,
`incrementNumerator`, `incrementDenominator` and **added** `recordText(for:value:)` and
`recordStringList(for:value:)`.

- Both conflicts were Ecosia's four now-orphaned delegating methods against an **empty** upstream
  side. No caller exists for any of the four anywhere in the tree, and they are no longer protocol
  requirements, so they were dropped from `DefaultGleanWrapper` **and** from `FakeGleanWrapper`.
- **The real defect was outside both conflict markers** (trap 2 again). Upstream's two new methods
  auto-merged into `DefaultGleanWrapper` with upstream's *live* bodies:

  ```swift
  func recordText(for metric: TextMetricType, value: String) { metric.set(value) }
  func recordStringList(for metric: StringListMetricType, value: [String]) { metric.set(value) }
  ```

  Every other method in that struct delegates to `fakeWrapper`. These two would have recorded
  straight into Glean — and they have nine live callers in
  `Frontend/Browser/WebCompat/WebCompatReportRecorder.swift`, so this was a working hole in Ecosia's
  telemetry silencing, not dead code. Both now delegate to `fakeWrapper`, and
  `FakeGleanWrapper` gained the two matching no-ops (without which it would not have compiled at
  all: it declares `: GleanWrapper` conformance and was missing two requirements).

`MockGleanWrapper` and `FakeGleanWrapper` are the only two conformers in the tree; both now satisfy
the 155.1 protocol exactly.

### 3. `AppDelegate.swift` — 5 conflicts (AC-3)

1. Imports — pure addition, kept both `TipKit` (upstream) and `Ecosia`.
2. `willFinishLaunching` — kept Ecosia's Snowplow-Micro staging hook, took upstream's
   `shareTelemetry.recordOpenDeeplinkTime()`. Ecosia had no delta on that call; the name change is
   upstream inlining its own helper.
3. `LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)` — the class is
   **confirmed deleted upstream** (`Client/FeatureFlags/` at 155.1 contains only `CoreBuildFlags`,
   `FeatureFlagID`, `FeatureFlagsProvider`, `FlaggableFeatureOptions`, `UserFeaturePreferenceManager`).
   Dropped. Ecosia's `Unleash.loadCachedModelIfNeeded()` hydration, which sat in the same hunk, is kept.
4. **`startRecordingStartupOpenURLTime()` and Ecosia's `ActionTokenPair` are gone.** Upstream moved
   the deeplink-timing observers out of `AppDelegate` and into `SceneDelegate` (`SceneDelegate.swift:247,257`),
   deleting the helper. Ecosia's `ActionTokenPair` existed *only* to make that helper's two mutable
   `var` token captures Swift-6 `@Sendable`-clean; upstream's replacement has no mutable captures, so
   the workaround has nothing left to guard. `SceneDelegate.swift` has **zero** Ecosia delta and
   merged to upstream exactly — trap 5, reason expired.
5. `applicationDidBecomeActive` — pure addition, kept both `prefetchMerinoStories()` (upstream) and
   `ecosiaTrackBecomeActiveLifecycle()` (Ecosia, MOB-4384).

### 4. `WindowManager.swift` — now **byte-identical to upstream** (trap 5)

Ecosia's entire delta on this file was one MOB-4384 workaround: `tabManager(for:)` returned a
non-optional `TabManager`, so a cross-test async race (a background task querying a window whose
`TabManager` had already deallocated) hit `windows.first!.value.tabManager!` and crashed the whole
app-hosted test *process*. The workaround added a non-fatal path, a `lastConfiguredTabManagerForTests`
strong cache, and an `unsafeAnyTabManager()` fallback.

**Upstream 155.1 rewrote the same method to return `TabManager?`**: no force-unwrap anywhere, and the
`assertionFailure` / `.fatal` log is skipped under `AppConstants.isRunningUnitTest`. Every one of the
~60 call sites in the tree already uses `guard let` or optional chaining (they are upstream's, and
they auto-merged), and upstream even added `test_windowManagerTabManager_returnsNilForInvalidWindowUUID`
asserting the nil return. The workaround's reason is fully expired, so the file was taken from
upstream wholesale and the Ecosia cache deleted — the ideal outcome, zero conflict surface next upgrade.

**Runtime risk handed to ticket 19:** upstream returns `nil` where Ecosia's fallback returned *some*
live `TabManager`. That converts the old crash into an early return, which is strictly safer, but any
Ecosia test that implicitly relied on getting a manager back will now take a different path. Watch
`WindowManagerTests` and the app-hosted `ClientTests` suite for behavioural (not crash) failures.

### 5. `SummarizerNimbusUtils.swift` — inherited from ticket 00, plus its test fallout

- Substitution conflict: kept Ecosia's `isHostedSummarizerEnabled() -> false` ("Ecosia uses only
  Apple Intelligence"), **updated the commented-out original** from the deleted
  `featureFlags.isFeatureEnabled(.hostedSummarizer, checking: .buildOnly)` to upstream's current
  `featureFlagsProvider.isEnabled(.hostedSummarizer)`, and added upstream's two new protocol members
  `isAppAttestAuthEnabled()` / `usesPermissiveGuardrails()` (both required by the `SummarizerNimbusUtils`
  protocol; both flags exist in `FeatureFlagID.swift`). Both mocks (`MockSummarizerNimbusUtils`,
  `MockNimbusUtils`) already declare all five methods.
- **`SummarizerNimbusUtilsTests.swift` is new in 155.1** (trap 3b: no conflict, no Ecosia delta,
  nothing for the intent-diff to see) and two of its tests contradict Ecosia's substitution outright:
  `test_isHostedSummarizerEnabled_whenFeatureFlagEnabled` and
  `test_isSummarizeFeatureEnabled_whenAppleSummarizerDisabled`. Both are commented out with a
  `/* Ecosia: … */` block stating why. Every other test in the file was traced by hand and still
  holds, because Apple Intelligence covers them — including `whenHostedShakeEnabled`, which passes
  via the Apple shake path.

### 6. `MozillaRustComponents` — the vendored wrapper package

This package's `GleanMetrics` calls bypass `GleanWrapper` entirely, so Ecosia's silencing strategy
does not reach them automatically. Ecosia's pre-upgrade state was self-consistent: they had replaced
this package's checked-in `Generated/Metrics/Metrics.swift` with a differently-generated 7,965-line
blob (the *app's* metric set — it has `Pings` but no `NimbusEvents`, `AdsClient` or `SyncV2`), and
every call site referencing those was commented out with `// Ecosia: Telemetry silenced - GleanMetrics
not available in separate package`.

155.1 breaks that arrangement from both ends, so the package was made self-consistent again:

- **Both `Generated/Metrics/Metrics.swift` files were taken from upstream** and are now byte-identical
  to it. They are generated artifacts with **zero** `Ecosia:` markers, nothing outside the package can
  see their (internal) symbols, and no build step regenerates them — `bin/sdk_generator.sh` writes to
  `firefox-ios/Client/Generated/Metrics/`, a different target. Upstream's version is the only one
  consistent with the 155.1 wrapper sources: it declares `NimbusEvents` (incl. the new `databaseLoad`
  / `databaseMigration`), `AdsClient`, `SyncV2` and `Pings.nimbusTargetingContext`, all of which live
  155.1 code in this package references. The Focus copy's Ecosia delta was three blank lines.
- `NimbusCreate.swift` (2 conflicts): upstream added `recordDatabaseLoad` / `recordDatabaseMigration`
  to the `MetricsHandler` protocol (confirmed in `Generated/nimbus.swift`), so both are implemented
  with their Glean bodies commented out, matching the four siblings. `class` → `final class` taken
  from upstream. Second conflict: Ecosia's `remoteSettingsService:` / `collectionName:` parameters
  adapted an older binding — the 155.1 `NimbusClient.init` takes `remoteSettingsInfo:
  NimbusServerSettings?`, and no caller passes Ecosia's two, so they and their comment were removed.
- **Three live Glean call sites that auto-merged in un-silenced, all new in 155.1** (trap 3b):
  `NimbusCreate.submitTargetingContext()` (`GleanMetrics.Pings.shared.nimbusTargetingContext.submit()`),
  `NimbusBuilder.swift`'s `GleanMetrics.NimbusEvents.isReady.record()`, and the whole of the new file
  `AdsClient/AdsClientTelemetry.swift` (5 methods). All silenced with `// Ecosia:` markers.
  `Nimbus/Utils/NimbusGleanPings.swift` is also new but only *declares* a `Ping` object, which uploads
  nothing unless registered — and `TelemetryWrapper` deliberately does not register it — so it stays
  as upstream wrote it; `Client/Experiments/RecordedNimbusContext.swift:146` needs it to exist.
- `SyncManagerTelemetry.swift` (1 conflict): substitution. Ecosia's `{ _ in }` ping defaults and empty
  body kept; the commented-out original was **updated to upstream's 155.1 version** (it grew the
  Addresses and Tabs engines and turned the unsupported-engine `throw` into an `assertionFailure`),
  and rewritten to use the file's `/* Ecosia: … */` block convention instead of the ad-hoc
  `// … (all telemetry code removed)` placeholder.
- **The Focus wrapper is left as upstream wrote it.** Ecosia never silenced it (their only deltas
  there are brace formatting), Focus is not an Ecosia product, and the Focus `NimbusBuilder` conflict
  was upstream deleting the `serverSettings` computation in favour of passing `nil` — Ecosia's side
  was v147 code with a reformatted brace, so the upstream side was taken.
- `ASOhttpClient/OhttpManager.swift` (1 conflict, owned by no ticket, resolved here because it blocks
  the same package): upstream renamed `invalidateKey()` → `invalidateKey(for:)`; Ecosia's only delta
  was brace style. Took upstream's call with Ecosia's formatting.

### 7. `TelemetryWrapperTests.swift` — 3 conflicts

All three had an **empty** upstream side: upstream deleted the onboarding wallpaper/engagement-
notification tests and the `viewHistoryPanel` / `viewDownloadsPanel` tests outright. Two Ecosia
`/* Ecosia: removed in v147 … */` markers sat *inside* those deleted blocks — upstream now does the
removal itself, so per the standing rule the markers went with them rather than being left as
phantoms. The third conflict kept `let profile = MockProfile()` (the next line needs it) and dropped
the `LegacyFeatureFlagsManager` call.

### 8. `Summarizer.js` — 1 conflict

Upstream removed `ALLOWED_LANGS` / `isPageLanguageSupported` (superseded by the language-expansion
feature). Ecosia's SERP-suppression block (`ECOSIA_SERP_HOSTS` / `isEcosiaSERP`, still called at
line ~115) was kept; `ALLOWED_LANGS` was dropped. **Ticket 19 must run `npm run build`** — AGENTS.md
requires it whenever a user script changes, and the bundled output is not regenerated by Tuist.

### 9. `LegacyFeatureFlagsManager` cleanup in built test targets (bootstrap, AC-3)

The deleted class still had **13** live call sites. Six of them were in files that are *not*
conflicted — i.e. silent breakage no conflict would ever have surfaced — and all six are in targets
Ecosia actually builds (`EcosiaTests`, `ClientTests`):

`EcosiaTests/Analytics/AnalyticsSpyTests.swift` (×3), `EcosiaTests/EcosiaSearchBarLocationSaverTests.swift`,
`EcosiaTests/EcosiaStartAtHomeMiddlewareTests.swift`,
`EcosiaTests/Settings/AppSettingsTableViewController+EcosiaTests.swift`,
`EcosiaTests/SnapshotTests/SnapshotBaseTests.swift`,
`ClientTests/Helpers/PrivacyNoticeHelperTests.swift`.

Every one is preceded by `DependencyHelperMock().bootstrapDependencies()`, which registers
`FeatureFlagsProvider(prefs:)` as `FeatureFlagProviding` in `AppContainer`
(`DependencyHelperMock.swift:76-77`) — that *is* 155.1's replacement for `initializeDeveloperFeatures`,
so the line is simply deleted, matching what ticket 00 did for `SettingsCoordinatorTests`. In
`PrivacyNoticeHelperTests` the surrounding Ecosia comment went too: `PrivacyNoticeHelper` no longer
gates on any feature flag (there is no `.privacyNotice` `FeatureFlagID`), so the rationale is dead.

**Seven call sites remain, all inside files that are still conflicted** and owned by other tickets /
19 — recorded in ticket 00 so they are not lost:
`SceneCoordinatorTests`, `LibraryCoordinatorTests`, `ContentContainerTests`,
`ContextualHintViewProviderTests`, `DownloadsPanelTests`, `HistoryPanelTests`, `ReadingListPanelTests`.

### 10. Accessibility identifiers (AC-4)

`AccessibilityIdentifiers.swift` auto-merged correctly: all 22 Ecosia additions survive
(`TabToolbar.historyButton`, the three `MainMenu` entries, and the whole `Ecosia` struct), and every
one is a *pure addition* — upstream renamed or moved nothing Ecosia had replaced. A scripted check
resolved all **47** distinct `AccessibilityIdentifiers.…` paths used across `Ecosia/`, `EcosiaTests/`
and `Client/Ecosia/` against the two identifier files: zero unresolved. Per trap 6, `XCUITests` is
not a target in Ecosia's Tuist project, so the only a11y-dependent tests that matter are
`EcosiaAccessibilityIdentifiersTests` and the snapshot tests, both covered by that check.

### 11. Two stale lint failures cleaned up (from ticket 05)

`EcosiaTests/Mocks/EcosiaMockThemeManager.swift` and `EcosiaTests/UI/Themable/ThemableMockThemeManager.swift`
each had a doubled blank line left where ticket 05 removed `var isNewAppearanceMenuOn`. Both are
Ecosia-owned `A ` files with no merge involvement, and both were failing bare
`swiftlint --strict` (`vertical_whitespace`). Fixed.

## Process incident — index damage, detected and fully repaired

Near the end of this ticket I ran `git add -A` over four *directories* to stage the files I had
edited. That staged **207 still-conflicted paths as resolved with their conflict markers intact**,
silently dropping their unmerged index stages (the unmerged count fell 418 → 196).

Repaired: the affected set was identified by re-deriving the conflict list with
`git merge-tree --write-tree --name-only --merge-base=firefox-v147.2 04df3bd66b c5afa25d3b`,
intersecting with "currently staged but not unmerged, under those four directories", and then
classifying each candidate three ways — staged blob still contains `>>>>>>> c5afa25d3b` (99), staged
blob is byte-identical to a fresh `git merge-file` of the three versions (8), or add/delete conflict
(112, mostly `AppIcons.xcassets` PNGs). Twelve add/delete paths that earlier tickets are on record as
having resolved (`ASAIRemoteConfig.swift`, `BrowserViewControllerStateTests.swift`, `TabManagerTests.swift`,
`AddressBarStateTests.swift`, `SponsoredTileTelemetryTests.swift`, …) were excluded by cross-checking
the ticket records and the conflicted-file list captured earlier in the session.

The remaining 207 had their three index stages rewritten from `firefox-v147.2` / `04df3bd66b` /
`c5afa25d3b` via `git update-index --index-info`. Working-tree content was never touched, so the
original `HEAD` / `c5afa25d3b (Squash: …)` marker labels are preserved. Verified afterwards:
**404 unmerged paths** (= 418 minus this ticket's 14 legitimate resolutions), **zero** resolved-and-
staged files anywhere in the tree still contain a rebase conflict marker, and all of this ticket's
own resolutions are intact.

Lesson for the remaining tickets, now also in HANDOVER: **never `git add` a directory or use
`git add -A` during this rebase — stage explicit file paths only.** If it happens anyway, `git checkout -m -- <path>`
restores a text conflict but rewrites the marker labels to `ours`/`theirs`, and it refuses
add/delete conflicts outright; rewriting the stages with `git update-index --index-info` is the
lossless repair.

## Verification

| Check | Result |
| --- | --- |
| Conflict markers in the 22 files in scope | none |
| `xcrun swiftc -parse` on all 19 touched Swift files | clean |
| `node --check` on `Summarizer.js` | clean |
| `intent-diff-check.py` over all files in scope | every "missing" line accounted for in §1–§9 above |
| `symcheck.py` over the same set + the 13 bootstrap files | only SDK/Glean/ViewInspector names and package-local symbols the script cannot see (its roots are `firefox-ios` and `BrowserKit/Sources` only) |
| `cd firefox-ios && tuist generate --no-open` | success |
| bare `swiftlint lint --strict --quiet` from repo root | no violation in any file this ticket touched (all remaining violations are in still-conflicted files, plus a pre-existing `function_body_length` in `Search/SearchViewController.swift` — logged in ticket 00) |
| Unmerged files | 418 → **404** |

## Handed to ticket 19

- `npm run build` after the `Summarizer.js` change (AGENTS.md requires it for user-script edits).
- Watch the app-hosted `ClientTests` for behavioural fallout from `WindowManager.tabManager(for:)`
  now returning `nil` instead of an arbitrary live `TabManager` (§4).
- Confirm at build time that the vendored `MozillaRustComponents` package compiles with upstream's
  `Generated/Metrics/Metrics.swift` restored (§6); if anything in the app turns out to have depended
  on Ecosia's larger blob, that is where it will show.
- The 7 remaining `LegacyFeatureFlagsManager` call sites in still-conflicted test files (§9).
