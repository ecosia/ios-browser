# 01: Write characterization tests for critical Ecosia behaviors

**What to build:** Before any upstream conflict resolution starts, capture the current, correct behavior of Ecosia's highest-business-risk customizations as executable tests, run against today's code (pre-upgrade). These become the objective pass/fail oracle for the whole upgrade — re-run unchanged after the rebase to prove nothing regressed, rather than relying on code review alone.

Cover: default search-engine identity resolution, the invisible-tab/auth session flow, NTP impact-counter rendering, and the start-at-home override behavior. Where a behavior genuinely resists unit testing (e.g. it's fundamentally a rendering/UI concern), note that explicitly and defer it to the Simulator verification step (ticket 19) instead of forcing a brittle test.

**Blocked by:** None (can start immediately).

**Status:** done

- [x] A unit test asserts Ecosia's default search engine is correctly resolved and identified as non-Google (this also documents the exact identity check that Google Lens's upstream gating depends on)
- [x] A test covers the invisible-tab/auth session flow's key invariant(s)
- [x] A test (or documented reason it's simulator-only) covers the NTP impact-counter's correctness
- [x] A test covers the start-at-home override always resolving to `false` as Ecosia intends
- [x] All new tests pass against current `main`
- [x] Each test that can't be feasibly written as a unit test is explicitly listed with the reason, for tracking in ticket 19's Simulator pass

## Comments

### Deliverable

`firefox-ios/EcosiaTests/FirefoxUpgradeCharacterizationTests.swift` — 8 tests, staged into the in-progress rebase (not committed). Picked up automatically by the `EcosiaTests` target's `EcosiaTests/**/*.swift` glob; no Tuist manifest edit needed, but `tuist generate` must run before the target sees it.

| Behavior | Tests |
| --- | --- |
| Search-engine identity | `testDefaultEngineIsEcosiaAndFailsUpstreamGoogleIdentityCheck`, `testCuratedProviderDefaultEngineAlsoFailsUpstreamGoogleIdentityCheck` |
| Invisible-tab / auth | `testInvisibleTabsAreExcludedFromEveryVisibleTabCollection`, `testTabInvisibleFlagRoundTripsThroughTheRegistry`, `testClosingAnInvisibleTabPrunesItFromTheRegistry` |
| NTP impact counter | `testImpactCounterFormatsValuesWithStableGroupingAndCurrencySymbol`, `testImpactCounterIdentifiersAndDeepLinksAreStable`, `testImpactCounterRowOrderingIsStable` |

### Verification

Verified in a throwaway `git worktree` at tag `pre-155.1-rebase` (`89e13a568d`), because the primary working tree is mid-rebase and unbuildable. That tag is `main` minus only the docs/manifest commit, so it is the pre-upgrade production code the ticket asks for.

- `EcosiaBeta` scheme, iPhone 17 Pro Max simulator: **8 tests, 0 failures**.
- Pre-existing related suites re-run green in the same build: `EcosiaStartAtHomeMiddlewareTests` (5), `EcosiaSearchEngineProviderTests` (4), `InvisibleTabManagerTests` (12) — **21 tests, 0 failures**.
- `swiftlint --strict` clean on the new file.

### Start-at-home: satisfied by existing coverage

No new test written. `EcosiaTests/EcosiaStartAtHomeMiddlewareTests.swift` already asserts `shouldStartAtHome == false` across all five cases (`afterFourHours`, `always`, `disabled`, no setting, private tab). It *is* the characterization test; ticket 04 should treat that file as the oracle it must keep green.

### Deliberate compile-compatibility constraint

The file avoids symbols new in 155.1 so the same source compiles on both sides of the upgrade. Specifically, upstream's `OpenSearchEngine.isGoogleEngine` (new in 155.1, at `Client/Frontend/Browser/SearchEngines/OpenSearchEngine.swift`) is **replicated** as a private helper rather than called:

```swift
engine.engineID == "google" || engine.engineID.hasPrefix("google-")
```

That predicate is what `BrowserViewController+WebViewDelegates.isGoogleLensActionAvailable()` gates the Google Lens context-menu entry on. After ticket 10, the helper should be replaced with a direct `defaultEngine.isGoogleEngine` call so the test asserts against upstream's real implementation rather than a copy — noted for ticket 10 / 19.

Also note `Client.Tab` must be written qualified: `Ecosia` exports its own `Tab`, so a bare `Tab` is ambiguous in any file importing both modules.

### Infeasible as unit tests — for ticket 19's simulator pass

1. **NTP impact-counter rendering.** `NTPImpactCell` / `NTPImpactRowView` / `ProgressView` / `NTPImpactGlassBackgroundView` layout and the counter's count-up animation. The counter's *values, identifiers and deep links* are unit-tested above; the visual result is not. Covered by `EcosiaSnapshotTests` plus a simulator look at the NTP.
2. **End-to-end invisible-tab auth handoff.** `InvisibleTabSession` needs a live `BrowserViewController` and a real `WKWebView` navigation; `isSessionTransferSuccessful()` and the `\.url` KVO redirect tracking are private with no injection seam. The *registry* invariants are unit-tested; the handoff itself needs a simulator sign-in.
3. **Start-at-home launch effect.** The middleware's decision is unit-tested; that the app actually opens on the last tab rather than the homepage after a 4h+ background is a launch-lifecycle behavior.
4. **Search-engine picker presentation.** Identity resolution is unit-tested; that Ecosia appears first and selected in the picker UI is snapshot/simulator.

### Out-of-scope observation

`.swiftlint.yml` is conflicted (`UU`) in the rebase tree — a two-line `excluded:` conflict (`HEAD` adds `.claude/worktrees`, Ecosia adds `firefox-ios/SourcePackages`; both should be kept). It broke YAML parsing, so `swiftlint` silently fell back to its default config. No ticket owns this file; flagging for whoever takes it.
