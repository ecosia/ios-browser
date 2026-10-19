# 17: Launch / Onboarding vertical

**What to build:** App launch and first-run onboarding continue to behave correctly for Ecosia users after upstream fully removed the legacy onboarding stack in favor of its new OnboardingKit module, and dropped the splash-screen animation.

**Blocked by:** 10

**Status:** done

- [x] The launch coordinator and Ecosia's intro-screen manager are reconciled per the intent-diff manifest against the new OnboardingKit-based launch flow (see Findings §2)
- [x] The `Intro` symbol flagged in the symbol-dependency report is resolved in `BrowserViewController+Ecosia.swift` — **it is an Ecosia-owned method name, not a reference to a deleted type; see Findings §3**
- [x] The Ecosia-relevant assertions from the three deleted onboarding test files are ported or confirmed not applicable (see Findings §4)
- [x] `LaunchCoordinatorTests`, `LaunchScreenViewModelTests`, and `LaunchScreenViewControllerTests` are updated alongside the production code (see Findings §5)

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


## Inherited findings

- `MockLaunchScreenManager.swift` and `MockLaunchFinishedLoadingDelegate.swift` are **already resolved** (ticket 09), both by taking upstream's version — upstream had independently adopted Ecosia's MOB-4384 behaviour (`startLoading` no longer bumps `loadNextLaunchTypeCalled`; there is a dedicated `loadNextLaunchType()` override with call-history tracking).
- `LaunchType` at 155.1 has cases `videoIntro`, `termsOfService(manager:)`, `intro(manager:)`, `survey…`, `update`, `defaultBrowser`. Upstream's `verifyLaunchWithCalled` pattern-matches without requiring `Equatable`, which resolves the concern behind Ecosia's old string-comparison workaround.
- `NimbusOnboardingFeatureLayerTests.swift` is conflicted and is this ticket's (one of the three deleted onboarding test files named in the AC).

---

# Findings (session completing ticket 17)

**Outcome:** 13 conflicted files resolved, 8 upstream-deleted onboarding test files removed, 1 file moved
to upstream's path, and 6 auto-merged/clean files corrected. Unmerged count 447 → 425. No commits.
This was the largest structural collision of the upgrade: upstream deleted the entire legacy onboarding
stack and **reused the name of the function Ecosia had replaced**.

## 1. Scope

| State | File | Resolution |
| --- | --- | --- |
| `UU` 2 | `Client/Coordinators/Launch/LaunchCoordinator.swift` | see §2 |
| `UU` 2 | `Client/Coordinators/LaunchView/LaunchScreenViewModel.swift` | Ecosia's intro-before-ToS order kept; upstream's new `.videoIntro` branch kept; the dead `.update` branch dropped |
| `UU` 1 | `Client/Application/AppLaunchUtil.swift` | Ecosia's `EcosiaSearchBarLocationSaver` kept; upstream's new `migrateBottomBarPositionToTopOnIPad` call commented, see §6 |
| `UU` 1 | `Client/IntroScreenManager.swift` | both imports kept (`OnboardingKit` + `Ecosia`); Ecosia's `User.shared.firstTime` gate intact |
| `UU` 1 | `Client/Coordinators/Launch/TermsOfServiceManager.swift` | took upstream and **moved to `Client/TermsOfServiceManager.swift`**, see §7 |
| `UU` 5/2/4/7/2/6/1 | `LaunchCoordinatorTests`, `LaunchTypeTests`, `LaunchScreenViewControllerTests`, `LaunchScreenViewModelTests`, `IntroScreenManagerTests`, `OnboardingTelemetryUtilityTests`, `OnboardingLaunchScreenViewControllerTests` | see §5 |
| `UU` 1 | `…/ClientTests/TermsOfUse/TermsOfUseTelemetryTests.swift` | upstream (0 Ecosia markers) |
| `UU` 1 | `Shared/it.lproj/Intro.strings` | kept Ecosia's "Benvenuto in Ecosia"; `plutil -lint` OK |
| `DU` ×8 | the onboarding test files upstream deleted | removed, see §4 |
| `A `/`M ` | `EcosiaSearchBarLocationSaver.swift`, `XCTestCaseExtensions.swift`, `NimbusOnboardingTestingConfigUtility.swift`, `MockGleanPlumbEvaluationUtility.swift`, `LaunchScreenViewController.swift`, `LaunchArguments.swift` | see §6, §8 |

## 2. LaunchCoordinator — upstream reused the name of the function Ecosia had replaced

Upstream 155.1 deleted the legacy onboarding path (`IntroViewModel`, `IntroViewController`,
`UpdateViewModel`, `UpdateViewController`, `NimbusOnboardingFeatureLayer`, `presentUpdateOnboarding`,
`LaunchType.update`) **and renamed `presentModernIntroOnboarding` → `presentIntroOnboarding`** — the
exact name Ecosia had hijacked for its `WelcomeNavigation` flow.

The merge therefore produced **two** `presentIntroOnboarding(with:isFullScreen:)` in one file (upstream's
OnboardingKit implementation at line 189, Ecosia's Welcome flow at line 315): a duplicate declaration
and an ambiguous call site.

Resolved by moving the substitution from the *function body* to the *call site*, which is the smallest
faithful expression of Ecosia's intent:

- Ecosia's Welcome flow is re-homed as **`presentEcosiaWelcomeOnboarding(with:)`** next to its existing
  `WelcomeDelegate` conformance (the `isFullScreen` parameter is dropped — it was never used; the flow
  is always full screen).
- `start(with:)`'s `.intro` case now comments out upstream's `presentIntroOnboarding(...)` call and calls
  Ecosia's, with a marker explaining the rename.
- Upstream's `presentIntroOnboarding` is **left intact and live** rather than commented out. That is the
  Google Lens precedent ("keep upstream's code and its gates as-is — reconcile, don't remove") and it
  matters here for a concrete reason: upstream's body is the only caller of
  `onboardingResumeCardIndex(in:reason:)`, which **upstream's `LaunchCoordinatorTests` exercises with
  four assertions**. Commenting out 112 lines would also re-conflict on every future upgrade.
- Ecosia's own commented-out "original" — the *legacy* body, referencing five deleted types — was
  removed; it is no longer "Firefox's version" of anything.
- `presentUpdateOnboarding` and the `.update` case were deleted with upstream.

**Correction to the inherited findings:** they list `LaunchType`'s 155.1 cases as including `update`.
It does not — 155.1 has `videoIntro`, `termsOfService`, `intro`, `survey`, `defaultBrowser`. `update`
was deleted, which is why the merged switch and view model both had dead branches.

`didRequestSignIn(from:)`, Ecosia's addition to `LaunchCoordinatorDelegate`, is implemented by both
`BrowserCoordinator` and `SceneCoordinator` and by `MockLaunchCoordinatorDelegate`. Upstream's new
`.videoIntro` branch is kept and reconciled: `enable-video-intro` is `false` on developer, beta and
release in `onboardingFrameworkFeature.yaml`, so it never fires for Ecosia.

## 3. AC-2: the `Intro` flag was a third false positive

`BrowserViewController+Ecosia.swift` mentions `Intro` only in **its own method name**
(`presentIntroViewController(_:)`) and one comment. The body uses `LoadingScreen`, `User.shared` and
Ecosia's referral flow — nothing from Firefox's deleted onboarding stack. No successor to find, no edit
needed. (Tickets 14, 15 and 17 have now each had a flagged symbol turn out inert; the report flags
*names*, not references.)

A tree-wide sweep for the deleted types confirms the real state: after this ticket **no live reference
remains** to `IntroViewModel`, `IntroViewController`, `UpdateViewModel`, `UpdateViewController`,
`OnboardingCardDelegate`, `OnboardingViewControllerProtocol`, `OnboardingBasicCardViewController`,
`NimbusOnboardingFeatureLayer` or `SplashScreenAnimation`. The two surviving textual hits are benign:
`ViewControllerConsts.PreferredSize.IntroViewController` (a size constant, clean upstream) and an
accessibility-identifier string in `XCUITests/BaseTestCase.swift`.

## 4. AC-3: the three deleted test files

- **`NimbusOnboardingFeatureLayerTests`** — its single Ecosia assertion (the `%@` app-name placeholder
  renders "Ecosia", not "Firefox") is **already ported**: the successor
  `NimbusOnboardingKitFeatureLayerTests.swift` carries four equivalent Ecosia-marked assertions
  (title, body, button title, popup instructions). Nothing to do; old file deleted.
- **`ModernLaunchScreenViewControllerTests`** — upstream **renamed** it to
  `OnboardingLaunchScreenViewControllerTests.swift`, which is why its Ecosia delta reads as 0 lines
  (trap 7's rename bullet). Its Ecosia content was a `@testable` extension exposing
  `testUpdateViewModel` / `testSurveySurfaceManager` because those properties were private in v147.
  **Both halves are obsolete:** `UpdateViewModel` is deleted, and upstream now exposes
  `introScreenManager` and `surveySurfaceManager` directly on `MockLaunchScreenManager`. Took upstream's
  renamed file; its four `.update` tests (all Ecosia's) went with the deleted launch type.
- **`UpdateViewModelTests`** — `UpdateViewModel` is deleted upstream and has no successor. Its one Ecosia
  marker was a stale-API note (`PrefsKeys.NimbusFeatureTestsOverride removed in v147`). Not applicable;
  file deleted.

Also deleted (all `DU`, all referencing deleted types): `IntroViewModelTests`,
`Mocks/MockOnboardingCardDelegate`, `OnboardingButtonActionTests`, `OnboardingTelemetryDelegationTests`,
`OnboardingViewControllerProtocolTests`, and `XCUITests/OnboardingTests`.

## 5. Test files — two genuine merges, four expired reasons

Two files needed **real merging**, not a choice of side:

- **`LaunchScreenViewModelTests`** — upstream's `testLaunchType_termsOfServiceAndIntro_sequence` asserts
  **ToS first, then intro**. Ecosia deliberately inverted that order in production
  (`LaunchScreenViewModel.loadLaunchType`), so upstream's version would fail. Took upstream's file and
  substituted that one sequence block for Ecosia's order, with a marker. Ecosia's other content here was
  stale-API noise: `MockGleanPlumbMessageManagerProtocol` **still exists** (reason expired) and
  `PrefsKeys.NimbusUserEnabledFeatureTestsOverride` is gone from both sides (upstream replaced it with
  `setTermsOfServiceFeatureEnabled`). Its two commented-out tests had no behavioural justification.
- **`IntroScreenManagerTests`** — Ecosia's four `shouldShowIntroScreen` tests cover the
  `User.shared.firstTime` gate they added to production, and are load-bearing. But Ecosia had deleted
  upstream's `isModernOnboardingEnabled` / `shouldUseJapanConfiguration` / `onboardingVariant` tests for
  properties that still exist. Merged: upstream's file as the base, plus `@testable import Ecosia`,
  plus `User.shared.firstTime = true` in `setUp`/`tearDown` (needed to make upstream's assertions
  deterministic under Ecosia's extra condition), plus Ecosia's two *unique* cases
  (`testUpgradeFromMain_…`, `testIntroSeenWithFirstTimeFalse_…`). Ecosia's other two duplicated
  upstream's and were dropped.

**`LaunchCoordinatorTests`** kept Ecosia's load-bearing assertion — `.intro` presents `WelcomeNavigation`,
not Firefox's OnboardingKit host — applied to all four of upstream's intro tests. Its other Ecosia
content was expired: the `MockGleanPlumbMessageManagerProtocol` removals (mock still exists) and the
`.update` tests (launch type deleted).

**`LaunchScreenViewControllerTests`** took upstream: its one Ecosia marker said "introScreenManager is
private in v147", and upstream now exposes it on the mock. **`LaunchTypeTests`**,
**`OnboardingTelemetryUtilityTests`** and **`TermsOfUseTelemetryTests`** took upstream (0 Ecosia markers
each).

## 6. Two defects in clean/auto-merged files (trap 2)

**(a) `EcosiaSearchBarLocationSaver.swift` — Ecosia-owned, `A `, no conflict, two independent breaks.**
1. It conforms to `SearchBarLocationSaverProtocol`, which **gained a member** in 155.1
   (`migrateBottomBarPositionToTopOnIPad(profile:userInterfaceIdiom:)`) → conformance failure.
2. Both its writes used `featureFlags.set(feature: .searchBarPosition, to:)` — part of the
   `featureFlags` API that **no longer exists** (ticket 15 established the accessor is gone; these were
   the last two live `featureFlags.set` call sites in the tree). Replaced with upstream's successor,
   `userPreferences.setSearchBarPosition(.bottom)`, and swapped the `FeatureFlaggable` conformance for
   `UserFeaturePreferenceProvider`.
   The new protocol member is implemented by delegating to `SearchBarLocationSaver()`'s, so upstream's
   semantics apply to any caller — but **Ecosia does not call it** from `AppLaunchUtil`, because
   Ecosia's own MOB-4304 migration deliberately puts every device on the bottom Omnibox. Upstream's new
   two-line call is commented in `AppLaunchUtil` with that reason. Behaviour is unchanged from
   pre-upgrade Ecosia.

**(b) `XCTestCaseExtensions.swift` — Ecosia's copy dropped `setupTelemetry(with:)` / `tearDownTelemetry()`.**
Upstream has seven call sites of these static helpers; `OnboardingTelemetryUtilityTests.swift`, which
this ticket took from upstream, is one of them. Merged both sides: Ecosia's `waitForCondition`, its
MOB-4384 memory-leak polling `trackForMemoryLeaks`, and `unwrapAsync` all stay; upstream's two telemetry
helpers plus `@testable import Client` and `import Glean` are restored. `TelemetryWrapper.hasTelemetryOverride`
confirmed present. Shared test infrastructure rather than launch code, so noted here explicitly.

Worth knowing for later tickets: upstream moved `trackForMemoryLeaks`/`unwrapAsync` into the new
**`BrowserKit/Sources/TestKit`** module. Ecosia's same-signature copies in `XCTestCaseExtensions.swift`
are not duplicate-declaration errors — a same-module extension member shadows an imported one — and
Ecosia's polling variant is the one that wins in `ClientTests`, which is what MOB-4384 wants.

## 7. `TermsOfServiceManager.swift` was moved by upstream

Its Ecosia delta reads as `new file` because **upstream relocated it** from
`Client/Coordinators/Launch/` to `Client/TermsOfServiceManager.swift` — the rename trap again. The
conflict was Ecosia's retained `isAffectedUser` / `isInControlBranch` block (upstream's own FXIOS-12249
experiment code, commented "will be removed in 141.0"), which upstream has now deleted and which nothing
references. Took upstream, then `git mv`'d the file to upstream's path: the content is **byte-identical**
to `firefox-v155.1:firefox-ios/Client/TermsOfServiceManager.swift`, so both path and content now match
upstream and the file will not re-conflict.

## 8. Two shared test helpers that would have broken upstream's tests

- **`NimbusOnboardingTestingConfigUtility.swift`** — Ecosia's copy drops the `uiVariant:` parameter from
  `setupNimbus(withOrder:)`, but `OnboardingTelemetryUtilityTests.swift:380` (upstream's, taken here)
  calls `setupNimbus(withOrder:uiVariant:)`. Took upstream (0 Ecosia markers).
- **`MockGleanPlumbEvaluationUtility.swift`** — Ecosia's copy returns `"{}"` where upstream returns real
  JEXL results. It now has no callers (its consumers were the deleted onboarding tests), but took
  upstream anyway (0 Ecosia markers).

`LaunchScreenViewController.swift` (Ecosia's `EcosiaLaunchScreenView.fromNib()`) and
`LaunchArguments.swift` (Ecosia's `USE_SNOWPLOW_MICRO_INSTANCE`) are intact and correct.

## 9. `Intro.strings` — the rebrand survived, with one pre-existing gap

`it.lproj` was the only conflict; Ecosia's "Benvenuto in Ecosia" was kept over upstream's reworded
"Ti diamo il benvenuto in Firefox", consistent with ticket 15's `Settings.strings` decision.

Swept all 101 `Intro.strings`: 95 still contain the word "Firefox", but in **every case bar one** it is
inside a translator comment (`/* Sign in to Firefox account button… */`), not a user-facing value — the
auto-merge preserved Ecosia's rebranded values. The exception is **`sr.lproj`**, whose
`Intro.Slides.Welcome.Title.v2` still reads "Добро дошли у Firefox". That file is **clean upstream with a
zero-line Ecosia delta** — Serbian was never rebranded, so this is a pre-existing Ecosia l10n gap, not
rebase damage. Added to ticket 00's l10n batch.

## 10. Verification — all static, nothing executed

- `xcrun swiftc -parse` on all 22 touched files — clean; zero conflict markers in the group.
  `plutil -lint` OK on `it.lproj/Intro.strings`.
- A tree-wide stale-symbol sweep for the nine deleted onboarding types plus
  `isSearchBarLocationFeatureEnabled` — the only remaining hit is ticket 15's explanatory comment.
- `intent-diff-check.py` over the group. Every `missing` entry maps to a decision above; the largest
  lists are `LaunchCoordinator`'s dead legacy body (§2) and the test files' expired reasons (§5).
- `symcheck.py` over the same set — unresolved names are UIKit/Foundation noise plus four hand-verified
  as real: `Analytics.accountProfile`, `HistoryMigrationResult.totalDuration` (generated rust wrapper),
  and `setupTelemetry`/`tearDownTelemetry` — **which is how §6(b) was found**, since symcheck reported
  them unresolved before the helpers were restored.
- `cd firefox-ios && tuist generate --no-open` — **Success** (after 8 deletions and 1 move).
- `swiftlint lint --strict --quiet`, bare from the repo root — **no violation in any ticket-17 file**.
  Non-vendor count 82 → 71.

## 11. Handed to ticket 19

1. **§2's call-site substitution deviates from the usual convention** of commenting out Firefox's new
   body inside the Ecosia block. The reasons are in §2 (a 112-line dead comment, and upstream's body is
   the only caller of a tested helper), but it is the one structural judgement in this ticket a human
   may want to overrule. Upstream's `presentIntroOnboarding` is unused live code as a result — Swift does
   not warn, and `swiftlint --strict` is clean.
2. **The launch order is Ecosia's: intro → terms of service.** Ecosia's Welcome flow therefore runs
   *before* ToS acceptance. That is pre-existing, and `LaunchScreenViewModelTests` now asserts it, but it
   is worth one look on a fresh install given upstream's ToS work in this release.
3. **`IntroScreenManagerTests` now pins `User.shared.firstTime` in `setUp`/`tearDown`.** If any other
   test class depends on that singleton's value, this class no longer leaks its own state — but the
   singleton is shared, so ordering effects are only observable in a real run.
4. **`ContentBlocker`-style new upstream behaviour also applies here:** `presentVideoIntro` exists and is
   reachable the moment `enable-video-intro` is flipped on any channel, and it would show Firefox's video
   before Ecosia's Welcome.
