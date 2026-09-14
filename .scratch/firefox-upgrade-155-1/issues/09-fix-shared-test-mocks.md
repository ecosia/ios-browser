# 09: Fix shared test mocks and infrastructure

**What to build:** The shared test doubles and infrastructure that many test files across many verticals depend on compile and behave correctly against the upgraded code, resolved once here rather than rediscovered independently by every vertical that happens to use them.

**Blocked by:** 02, 04, 05

**Status:** done

- [x] Every shared mock/test-utility file flagged in the test-suite scan (profile, tab manager, browser view controller, web-kit, and settings-delegate mocks, plus shared test-case extensions) compiles against the upgraded Redux and theming shapes from tickets 04 and 05
- [x] No mock's behavior silently changed in a way that would mask a real regression in the tests that consume it
- [~] A quick smoke build of the test target (even with other tests still broken) confirms these shared files compile cleanly in isolation — *impossible with 528 unmerged files; substituted `swiftc -parse` on every file plus `tuist generate`, see below*

## Comments

### The "test-suite scan" list was reconstructed from Tuist, not guessed

Like ticket 04's nine, the planning list was lost. But there is an authoritative definition: the `ecosiaTests` Tuist target explicitly enumerates the ClientTests files it shares into the Ecosia test target. Those *are* Ecosia's shared mocks. Intersecting that source list with the conflicted files gave **17 files**, mapping exactly onto the AC's own wording:

| AC phrase | File |
| --- | --- |
| profile | `MockProfile.swift` |
| tab manager | `MockTabManager.swift` |
| browser view controller | `MockBrowserViewController.swift` |
| web-kit | `MockWebKit.swift` |
| settings-delegate | `MockSettingsFlowDelegate.swift` |
| shared test-case extensions | `XCTestCaseExtensions.swift`, `DependencyHelperMock.swift`, `StoreTestUtility.swift` |

Plus `MockAppAuthenticator`, `MockBrowserCoordinator`, `MockGleanWrapper`, `MockLaunchFinishedLoadingDelegate`, `MockLaunchScreenManager`, `MockLogger`, `MockNavigationController`, `MockNotificationManager`, `MockUserNotificationCenter`, `MockWindowManager`.

### The headline finding: upstream had already adopted most of Ecosia's MOB-4384 fixes

Ecosia's mock customizations were largely test-infrastructure hardening (MOB-4384). Checked each against upstream 155.1 rather than assuming, and **upstream has since converged on almost all of them**, so taking upstream's file *preserves* the Ecosia intent instead of discarding it:

| Ecosia fix | Status at 155.1 |
| --- | --- |
| `MockProfile` unique DB prefix (prevents "connection already open" crash cascades) | **upstream has it** (`"mock_\(UUID()...prefix(8))"`) |
| `MockProfile` `deinit { shutdown() }` | **upstream has it** |
| `MockProfile.storeAndSyncTabsCalled` spy | **upstream has it** |
| `DependencyHelperMock` protocol-typed registration (`x as Profile`, …) — the Swift 6 key-mismatch fix | **upstream has it throughout** |
| `DependencyHelperMock` unconditional window registration | **upstream has it** |
| `MockLaunchScreenManager`: `startLoading` must not bump `loadNextLaunchTypeCalled` | **upstream has it**, via a dedicated `loadNextLaunchType()` override |
| `MockSettingsFlowDelegate`: `BrowsingSettingsDelegate` conformance + `pressedAutoPlay` (MOB-4892) | **upstream has it** |

That made "take upstream's version" the correct resolution for most of the set — these are protocol-conformance doubles, and the protocols are upstream's.

### Ecosia customizations that were still needed, and kept

- **`DependencyHelperMock`: injectable `themeManager`.** Upstream hardcodes `MockThemeManager()`. Kept Ecosia's `themeManager: ThemeManager = MockThemeManager()` parameter because `AnalyticsSpyTests` and `SnapshotBaseTests` both pass their own (`EcosiaMockThemeManager`, `mockThemeManager`) — dropping it would have broken two Ecosia suites.
- **`MockWebKit`: three mocks upstream does not have at all** — `WKNavigationActionMock`, `WKFrameInfoMock`, `WKSecurityOriginMock`. `WKFrameInfoMock` alone has **5 consumers**, and its `class func new` allocates via the objc runtime because `WKFrameInfo`'s initializer *crashes the process on the iOS 26.5 SDK*. Resolved as a superset: Ecosia's three mocks + upstream's `MockWKWebView`/`MockWKScriptMessage`/`MockWKURLSchemeTask` + Ecosia's `decodeBody`. Added `typealias WKWebViewMock = MockWKWebView` because **both names are in use** — `FormAutofillHelperTests` uses both — so neither could simply win.
- **`XCTestCaseExtensions`: Ecosia's `trackForMemoryLeaks` bounded poll.** Kept (upstream's version asserts immediately, which was a load-induced flake), along with `waitForCondition` and `unwrapAsync`.
- **`MockBrowserViewController`: `MockContentContainer` / `MockScreenshotView`.** Ecosia restored these so `ScreenshotHelperTests` can exercise the homepage / native-error-page branches; they sat outside the conflict and are preserved.

### One upstream addition deliberately dropped

`XCTestCaseExtensions` gained `setupTelemetry(with:)` / `tearDownTelemetry()` upstream. Dropped them, and kept `asAnyHashable` (which *is* used, by `SponsoredTileTelemetryTests`).

Reason: they have **zero consumers** anywhere, and they are the only thing that would require `import Glean` in a file compiled into `EcosiaTests` — where **Glean is not an available dependency** (it is declared on `SyncTelemetryTests`, not here). That is exactly why Ecosia had removed those imports. Adding a dependency to satisfy dead code would be the wrong trade. If upstream later uses them, `Glean` must be added to the `ecosiaTests` target at the same time.

### ⚠ Silent structural loss caught — `MockThemeManager` had vanished entirely

At the fork point `MockThemeManager` existed at **two** paths. Upstream deleted `ClientTests/Frontend/Theme/MockThemeManager.swift`; Ecosia had deleted `ClientTests/Mocks/MockThemeManager.swift`. The merge applied **both deletions**, so the class disappeared from ClientTests with **no conflict anywhere to flag it** — and `DependencyHelperMock` calls `MockThemeManager()`, so every test that bootstraps dependencies would have failed to compile.

Found only because `swiftc -parse` was run over the Tuist source list and reported the file missing. Restored upstream's `Mocks/MockThemeManager.swift` (inside the shared `Mocks/*.swift` glob, so both Ecosia test targets pick it up automatically) and removed the two now-dangling explicit references to the dead `Frontend/Theme/` path from `Targets+Tests.swift`.

This is the exact failure mode the intent-diff manifest exists to catch, and the manifest did not catch it — two independent deletions of *different* paths for the same symbol produce no conflict and no diff signal.

### `MockLogger` moved into a new BrowserKit module

Upstream deleted `ClientTests/Mocks/MockLogger.swift` and moved it to **`BrowserKit/Sources/TestKit/MockLogger.swift`**, a new `TestKit` library product. The merged tree briefly had *both*, i.e. a duplicate definition.

Accepted the deletion, and — a third instance of the ticket 03 pattern — **`TestKit` was declared in no Tuist target**, so `import TestKit` (used by upstream's `DependencyHelperMock` and `DocumentLoggerTests`) could not resolve. Added `.package(product: "TestKit")` to both `clientTests` and `ecosiaTests`; verified linked in the regenerated project.

### Also resolved: the file deferred from ticket 06

`SearchEngineSelectionMiddlewareTests.swift` — took upstream's version.

**Correcting my ticket 06 note:** I flagged a risk that upstream's `setupStore()`/`resetStore()` would silently no-op through Ecosia's renamed `setupTestingStore()`/`resetTestingStore()` protocol members. That was wrong — upstream's file *calls those methods by name* from `setUp`/`tearDown`, so they run. The class satisfies `StoreTestUtility` via the protocol extension's defaults, and `StoreTestUtilityHelper.setupStore(with:)`/`resetStore()` both still exist as statics. Verified every symbol it needs is present (`MockSearchEnginesManager`, `SearchEnginesManagerProvider`, `PresentedComponentsState`, `MockStoreForMiddleware`).

### AC 3 — what was actually verified

A real smoke build needs the whole `Client` module, which cannot compile with 528 unmerged files. Substituted two checks that are meaningful on their own:

- **`swiftc -parse` on every file in the shared set** — passes. This is not type checking, but it is what catches the structural damage this kind of merge produces, and it is what surfaced the missing `MockThemeManager`.
- **`tuist generate`** — succeeds; `MockThemeManager.swift` and `TestKit` both appear in the regenerated project.
- **`swiftlint --strict`** — clean on all 17 files.

Type-level confirmation still has to wait for ticket 19.
