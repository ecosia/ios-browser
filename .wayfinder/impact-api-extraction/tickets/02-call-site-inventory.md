---
type: wayfinder:research
status: closed
blocked-by: []
claimed: Paul
---
## Question
Inventory (facts only) every dependency touching the impact/auth seam on current `main`-based code: consumers of `EcosiaAuthUIStateProvider` impact properties and `.shared`, all reads of `EcosiaAuthenticationService.shared` from it, who clears/writes `LoggedInImpactCache` and `UserDefaultsSeedProgressManager`, `accountsProviderFactory` / `AccountsProviderWrapper` injection, notifications posted/observed, and the tests that rely on static type swaps. Findings go in this file's Resolution section.

## Resolution

Code references are to the code before PR 1 (ecosia/ios-browser#1339); line numbers will drift.

Paths relative to `firefox-ios/`. Provider = `Ecosia/UI/Account/EcosiaAuthUIStateProvider.swift` (P). Working tree on `pq-mob-4799-braze-core-markets`.

### 1. Consumers of `EcosiaAuthUIStateProvider`
All production consumers use `.shared`; none uses `accountsProviderFactory` except P itself (P:82-89).
| Consumer | Provider members used |
| --- | --- |
| `Ecosia/UI/NTP/Header/EcosiaAccountNavButton.swift:22` (`@ObservedObject`) | `isLoggedIn` (:17), `hasRegisterVisitError` (:48,67,70) |
| `Ecosia/UI/Account/EcosiaAvatar.swift:14` | `isLoggedIn` (:33) |
| `Ecosia/UI/Account/EcosiaAccountImpactView.swift:13` | `hasRegisterVisitError` (:50), `currentLevelNumber` (:119 onChange, :194 via `.shared` directly) |
| `Ecosia/UI/Account/EcosiaAccountImpactViewModel.swift:29` (forwards `objectWillChange`, :33) | `isLoggedIn`, `username`, `avatarURL`, `seedCount` (:59), `userDisplayText`, `levelDisplayText` (:121), `levelProgress` (:126) |
| `Ecosia/UI/Account/EcosiaAccountAvatarViewModel.swift:36` (injectable param, default `.shared`) | `$avatarURL` (:142), `$isLoggedIn` (:150) only (no impact props) |
| `Client/Ecosia/UI/NTP/Header/NTPHeaderViewModel.swift:25` (forwards `objectWillChange`, :54) | `seedCount` (:28), `isLoggedIn`, `avatarURL`, `balanceIncrement` (:31), `refreshSeedState()` (:118) |
| `Ecosia/Core/User.swift:80` (`User.seedCount`, @MainActor) | `seedCount`; Core model reaching into UI layer. Read by Analytics (`AnalyticsSpyTests` :861,889,1259 compare to `User.shared.seedCount`) |
| `Client/Ecosia/Settings/EcosiaDebugSettings.swift` :807, :890 | `seedCount`; :837, :955 `debugAddSeeds`; :878 `debugTriggerLevelUpAnimation` |
Not used by any consumer outside tests: `debugUpdateBalance` (P:467), `currentProgress` direct read (only via `levelProgress`). `balanceIncrement` only NTPHeaderViewModel. Non-provider impact reads: `EcosiaAccountNavButton.swift:18` and `EcosiaDebugSettings.swift:746-794` use `UserDefaultsSeedProgressManager` statics directly (maxSeeds, loadTotal, addSeeds(1) at :794).

### 2. Reads of `EcosiaAuthenticationService.shared` from P and notifications
Reads: `isLoggedIn` (P:101, 213, 257, 438), `hasResolvedAuthState` (P:102, 439), `userProfile` (P:103, 259), `accessToken` (P:291, and again P:302 as in-flight session check). No writes.
Observed (all `NotificationCenter.default`, queue .main, hop to Task): 
- `.EcosiaAuthStateChanged` (P:175). Posted by `EcosiaBrowserWindowAuthManager.dispatch` (`Ecosia/Account/Auth/EcosiaBrowserWindowAuthManager.swift:58`, `object: self`, userInfo `windowUUID`, `authState`, `actionType: EcosiaAuthActionType`). Entry: `EcosiaAuthenticationService.dispatchAuthStateChange` (`Ecosia/Account/Auth/EcosiaAuthenticationService.swift:464-482`) via `dispatchAuthState` (:75), which fans out per registered window, so P receives one notification PER window (see surprises). P reads only `userInfo["actionType"]`, then re-reads service `isLoggedIn`. Other observers: `BrowserViewController+Omnibox.swift:654`, `InvisibleTabSession.swift:122`, `TabAutoCloseManager.swift:58-87`.
- `.EcosiaUserProfileUpdated` (P:186). Posted by service `userProfile.didSet` (`EcosiaAuthenticationService.swift:77`), no userInfo.
- `UserDefaultsSeedProgressManager.progressUpdatedNotification` (P:198). Posted by `UserDefaultsSeedProgressManager.swift:88,159,170` (save, addSeeds, reset). Name derives from class name string.
Posted by P: `.EcosiaAccountLevelUp` via `EcosiaAccountNotificationCenter.postLevelUp(newLevel:newProgress:)` (P:373; async main-queue; keys in `Ecosia/UI/Account/EcosiaAccountNotifications.swift`). Observers: `EcosiaAccountAvatarViewModel.swift:170`, `EcosiaAccountImpactView.swift:123`, `NTPHeaderViewModel.swift:76`. `EcosiaAccountProgressUpdated` is observed by `EcosiaAccountAvatarViewModel.swift:162`, but P never posts it; only tests call `postProgressUpdated` (no production poster).
Auth-driven impact logic in P: `.userLoggedIn` -> `registerVisitIfNeeded`; `.userLoggedOut` -> `resetToLocalSeedCollection` + `handleLocalSeedCollection`; `.authStateLoaded` -> re-resolve local snapshot if logged out, replay deferred `refreshSeedState` (P:210-252). `EcosiaAuthActionType` has exactly these 3 cases (the switch is exhaustive).

### 3. `LoggedInImpactCache` / `UserDefaultsSeedProgressManager`
LoggedInImpactCache (`Ecosia/UI/Account/SeedProgressManager/LoggedInImpactCache.swift`, UserDefaults keys `LoggedInImpactCache.*`):
- load: P:120 (`resolveInitialImpactSnapshot`, called P:109 init and P:232 authStateLoaded).
- save: P:384 (`persistLoggedInImpactSnapshot`, only when `isLoggedIn`, from `updateBalance` P:337).
- clear: P:400 (`resetToLocalSeedCollection` on `.userLoggedOut`) AND `EcosiaAuthenticationService.swift:494 (.userLoggedOut), :499 (.authStateLoaded where wasLoggedIn)` via `clearLoggedInImpactCacheIfNeeded` (:490), invoked from `dispatchAuthStateChange` :477-479 when `!isLoggedIn`. Service uses `LoggedInImpactCache` concrete type (not the swappable `loggedInImpactCacheType`). Service also owns `wasLoggedIn` flag (:68, set :304, :500), consumed only for this clear.
- Double clear on logout: service clears, then P clears again (test asserts `clearCallCount == 1` on the mock because the service writes the real type).
UserDefaultsSeedProgressManager (via `seedProgressManagerType`, `private`, so NOT swappable from tests): P:125-127 (loadTotal, loadCurrentLevel, calculateInnerProgress in init snapshot), P:198 (notification name, concrete type not the swapped one), P:269 (loadTotal), P:399 (`resetLocalSeedProgress`), P:402, P:413-414 (`collectDailySeed`, loadTotal). Elsewhere: `EcosiaAccountNavButton.swift:18`, `EcosiaDebugSettings.swift:746,747,765,766,794`, and tests/snapshots (see 5).
Type-swap hooks: `loggedInImpactCacheType` (P:77, internal; swapped in `EcosiaAuthUIStateProviderImpactCacheTests.swift:39,44`); `seedProgressManagerType` (P:75, private; never swapped anywhere).

### 4. AccountsProvider injection and debug error simulation
- Chain: `AccountsProviderProtocol` (`Ecosia/Core/Accounts/AccountsProvider.swift:7`, only `registerVisit(accessToken:)`) -> `AccountsProvider` struct (:11, wraps `AccountsServiceProtocol`, `Ecosia/Core/Accounts/Service/AccountsService.swift:7`) -> optional `AccountsProviderWrapper` (`Client/Ecosia/Account/AccountsProviderWrapper.swift:12`), which throws a fake `NSError` when `UserDefaults.standard.bool(forKey: SimulateImpactAPIErrorSetting.debugKey)` (`EcosiaDebugSettings.swift:549-553`; setting surfaced at `AppSettingsTableViewController+Ecosia.swift:134`).
- Factory: `EcosiaAuthUIStateProvider.accountsProviderFactory` (P:82, default `AccountsProvider()`), read lazily once in `.shared` initialiser (P:87).
- **Wiring is missing in the current tree**: no reference to `accountsProviderFactory` or `AccountsProviderWrapper` anywhere in `Client/` Swift (AppDelegate has none). The only trace is the upgrade-patch manifest `Tuist/upgrade/ecosia-customizations-sample.json:~330-337` ("AppDelegate.swift line 93 ... `EcosiaAuthUIStateProvider.accountsProviderFactory = { AccountsProviderWrapper() }`"; must precede first `.shared` access). So `SimulateImpactAPIErrorSetting` currently has no effect on `registerVisit` (verify on a device/branch before relying on it). `Client/Ecosia/BUILD_ERRORS_ANALYSIS.md:11` mentions the wrapper too.
- Errors: P:313-322 sets `hasRegisterVisitError` and shows `EcosiaErrorToastPresenter.shared.presentRegisterVisitError()` (iOS16+); success clears it (P:310). Consumed by NavButton and ImpactView (`showProgress`).

### 5. Tests
- `EcosiaTests/UI/Account/EcosiaAuthUIStateProviderImpactCacheTests.swift` (only direct provider tests): private `MockLoggedInImpactCache`; swaps `EcosiaAuthUIStateProvider.loggedInImpactCacheType` (:39/:44); calls static `resolveInitialImpactSnapshot(isLoggedIn:)` (:56-85); builds `EcosiaAuthUIStateProvider(accountsProvider: AccountsProvider())` (:95,114,138, real provider, real network type, never invoked) and calls internal `handleAuthStateChange(_:)` with hand-built `Notification` (userInfo `actionType`) for `.userLoggedOut` / `.authStateLoaded`; uses real `UserDefaultsSeedProgressManager` (reset/addSeeds) and sets `EcosiaAuthenticationService.wasLoggedIn`; relies on real `EcosiaAuthenticationService.shared` (isLoggedIn false). Would break if: the static type name/hook moves (`loggedInImpactCacheType`), `resolveInitialImpactSnapshot` or `handleAuthStateChange` signatures/visibility change, init signature changes, or `seedCount`/`currentLevelNumber` leave the provider.
- `EcosiaTests/Account/Auth/AuthTests.swift:379-483`: asserts the SERVICE clears the REAL `LoggedInImpactCache` on logout and on failed retrieval after `wasLoggedIn` (and not otherwise). Breaks if `clearLoggedInImpactCacheIfNeeded` moves out of the service.
- `EcosiaTests/ClimateImpactCounter/LoggedInImpactCacheTests.swift`, `UserDefaultsSeedProgressManagerTests.swift`, `UnleashUserDefaultsSeedProgressManagerTests.swift`: concrete-type tests (seedCounterConfig static); unaffected unless those types change.
- `EcosiaTests/SnapshotTests/Homepage/HomepageComponentTests.swift:98,181-183`: seeds `UserDefaultsSeedProgressManager` to max for logged-out NTP snapshot (relies on `.shared` provider reading local state at init/progress notification).
- `EcosiaTests/Analytics/AnalyticsSpyTests.swift:858-889,1256`: compare to `User.shared.seedCount` (i.e. `.shared` provider's seedCount).
- `EcosiaTests/UI/Account/EcosiaAccountAvatarViewModelTests.swift`, `EcosiaAccountAvatarPerformanceTests.swift`: post `EcosiaAccountNotificationCenter.postProgressUpdated/postLevelUp` (EcosiaAccountNotificationCenterTests :181-230); avatar VM defaults to `.shared`. `AuthNotificationSystemTests`, `AuthStateManagerTests`, `TabAutoCloseManagerTests`: `.EcosiaAuthStateChanged` shape (any rename/userInfo change breaks them and P).
- No tests exist for: `registerVisitIfNeeded`/`updateBalance`, `refreshSeedState` deferral, `hasHandledCurrentResolution` ordering, `AccountsProviderWrapper`, `accountsProviderFactory`, `handleSeedProgressUpdate`, NTPHeaderViewModel/ImpactViewModel provider forwarding. No mock `AccountsProviderProtocol` exists (grep). `Tuist/ProjectDescriptionHelpers/Schemes+Ecosia.swift:259` notes AccountsServiceTests transitively constructs the auth service.

### Surprises / hidden coupling
1. `AccountsProviderWrapper` is compiled but not wired (see 4); debug error simulation likely dead on this branch.
2. Cache cleared in two places (service + P) with different mechanisms; service uses concrete `LoggedInImpactCache`, P uses the swappable type, so tests of P cannot observe the service's clear. P's `.authStateLoaded` re-resolve (P:232) depends on the service having already cleared (ordering: service clears BEFORE dispatching, `EcosiaAuthenticationService.swift:477-482`).
3. Auth notification is per-window (`dispatchAuthState` fans out), so P's handler can run N times per transition; correctness leans on `hasHandledCurrentResolution` (reset only on logout) and `pendingSeedStateRefresh`. A fresh login after a prior logged-in resolution without logout in between would be suppressed.
4. If no windows are registered when auth resolves, P never hears it; `refreshSeedState` has a fallback re-sync from the service (P:433-440), but `.userLoggedIn` registration is not retried (P:288 only runs on notification or refresh).
5. `init` registers observers before reading service state deliberately (P:94-98); `.shared` is created via `MainActor.assumeIsolated` lazily, so the factory must be set before first `.shared` touch (including `User.seedCount` from Core/analytics, which can happen early).
6. `registerVisitIfNeeded` mixes auth (accessToken read twice, session-change guard), network, cache write, error toast, level-up notification and UI animation in one Task; `persistLoggedInImpactSnapshot` guards on `isLoggedIn` mirror, which can lag the service.
7. `isLoggedIn` is mirrored in P and updated in three places (:101, :213, :257 inside an extra nested Task), so UI-visible ordering between `isLoggedIn`, `userProfile` and impact values is not atomic.
8. `levelProgress` (P:164) returns 0.25 when `!isLoggedIn` regardless of local `currentProgress`; `levelDisplayText` has no logged-out special-casing despite its doc comment.
9. `seedProgressManagerType` is private so the logged-out path cannot be mocked; tests mutate real `UserDefaults.standard`.
10. Core `User.seedCount` depends on UI-layer `EcosiaAuthUIStateProvider.shared` (inverted layering, @MainActor).
