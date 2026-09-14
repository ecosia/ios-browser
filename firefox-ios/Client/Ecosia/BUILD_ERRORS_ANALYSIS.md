# Build Errors Analysis (Ecosia / firefox-upgrade)

Generated from `xcodebuild -scheme Ecosia -project firefox-ios/Client.xcodeproj` build. Errors are grouped by category with **possible solutions**.

---

## 1. Main actor / concurrency isolation

### 1.1 `debugKey` (main actor–isolated static)

- **Files:** `AccountsProviderWrapper.swift:22`, `EcosiaAuthFlow.swift:145`, `EcosiaAuthFlow.swift:157`
- **Error:** `main actor-isolated static property 'debugKey' cannot be accessed from outside of the actor`
- **Cause:** `SimulateAuthErrorSetting.debugKey` is main-actor isolated; accessed from nonisolated or async context.
- **Solutions:**
  - Make `SimulateAuthErrorSetting` (or `debugKey`) `nonisolated` if it’s only reading `UserDefaults`.
  - Or access it on the main actor: `await MainActor.run { SimulateAuthErrorSetting.debugKey }` / wrap call site in `Task { @MainActor in ... }`.

### 1.2 `Task.sleep(for: .seconds)` / iOS 16

- **Files:** `EcosiaAuthFlow.swift:171`, `DispatchQueueHelper+BuildChannel.swift:22`
- **Error:** `'sleep(for:tolerance:clock:)' is only available in iOS 16.0 or newer` (and `.seconds`).
- **Cause:** Deployment target may be &lt; iOS 16, or availability not declared.
- **Solutions:**
  - Use `Task.sleep(nanoseconds: UInt64(delayedCompletion * 1_000_000_000))` for iOS 15 compatibility.
  - Or add `@available(iOS 16, *)` and use `Task.sleep(for: .seconds(...))` where acceptable.

### 1.3 Session / monitoring (main actor)

- **Files:** `EcosiaAuthFlow.swift:205`, `209`, `243`
- **Error:** `main actor-isolated instance method 'setupSessionCookies()' cannot be called from outside of the actor`; `call to main actor-isolated instance method 'startMonitoring' in a synchronous nonisolated context`.
- **Cause:** `InvisibleTabSession` methods are called from async nonisolated code but are effectively main-actor (UI/tab).
- **Solutions:**
  - Call them from the main actor: `await MainActor.run { session.setupSessionCookies() }` and `await MainActor.run { session.startMonitoring { ... } }`, or make the call site `@MainActor` and use the same calls.
  - Alternatively, mark `setupSessionCookies()` / `startMonitoring` as `@MainActor` and always invoke them with `await` from an async context or from a `Task { @MainActor in ... }`.

### 1.4 InvisibleTabSession ↔ TabAutoCloseManager (actor / main actor)

- **Files:** `InvisibleTabSession.swift:103`, `108`, `138`, `173`; `TabAutoCloseManager.swift:148`, `149`, `184`, `216`, `235`
- **Errors:**
  - Call to actor-isolated `setTabManager` / `setupAutoCloseForTab` / `cancelAutoCloseForTab` from wrong context.
  - Main actor–isolated `tab.url`, `tab.webView` referenced from nonisolated actor.
- **Cause:** `TabManager` is `@MainActor`; `InvisibleTabAutoCloseManager` is an actor; mixing sync/async and main/actor boundaries.
- **Solutions:**
  - Run all tab manager and auto-close calls on the main actor: e.g. `Task { @MainActor in InvisibleTabAutoCloseManager.shared.setTabManager(tabManager) }` and same for `setupAutoCloseForTab` / `cancelAutoCloseForTab`.
  - For `Tab` properties (`url`, `webView`), only read them inside `@MainActor` code (e.g. inside a `Task { @MainActor in ... }` or from a main-actor method).

### 1.5 TabManager+InvisibleTab (main actor)

- **File:** `TabManager+InvisibleTab.swift` (multiple lines)
- **Error:** `main actor-isolated property 'tabs' / 'normalTabs' / 'privateTabs' can not be referenced from a nonisolated context`
- **Cause:** Extension is nonisolated but accesses `TabManager` (which is `@MainActor`) properties.
- **Solutions:**
  - Mark the extension methods as `@MainActor` so they run on the same isolation as `TabManager`.
  - Or wrap usages in `await MainActor.run { ... }` at call sites.

### 1.6 BookmarksExchange (main actor / Sendable)

- **File:** `BookmarksExchange.swift:37`, `172`
- **Errors:** `non-Sendable parameter type '[BookmarkItem]' cannot be sent ... into main actor-isolated implementation`; `call to main actor-isolated instance method 'getCurrentTheme(for:)'`; `main actor-isolated property 'currentWindowUUID'`.
- **Solutions:**
  - Get theme/window on main actor and pass into the export API, or make the protocol method accept a theme/window passed from the caller (already main-actor).
  - For `[BookmarkItem]`: ensure `BookmarkItem` is `Sendable` or pass data in a way that doesn’t cross isolation (e.g. copy on main actor then pass).

### 1.7 Protocol conformances “crossing into main actor”

- **Files:** `BrowserViewController+Ecosia.swift` (HomepageViewControllerDelegate, DefaultBrowserDelegate, WhatsNewViewDelegate, PageActionsShortcutsDelegate); `HomepageViewController+Ecosia.swift` (NTPHeaderDelegate, NTPLibraryDelegate, NTPImpactCellDelegate, NTPNewsCellDelegate, NTPCustomizationCellDelegate, SharedHomepageCellDelegate).
- **Error:** `conformance of 'BrowserViewController' to protocol 'X' crosses into main actor-isolated code and can cause data races`
- **Cause:** `BrowserViewController` is not marked `@MainActor` but the protocol implementations touch main-actor state.
- **Solutions:**
  - Mark `BrowserViewController` as `@MainActor` in the base (if acceptable for the whole app), or
  - Mark only the Ecosia extension that adds these conformances as `@MainActor` (e.g. `extension BrowserViewController: HomepageViewControllerDelegate` in a `@MainActor` context), or
  - Ensure protocol methods that touch UI/tab state are explicitly `@MainActor` and that the type’s isolation is consistent.

---

## 2. Firefox API / type changes (upgrade)

### 2.1 LegacyTabManager removed

- **File:** `InvisibleTabSession.swift:78`
- **Error:** `cannot find type 'LegacyTabManager' in scope`
- **Cause:** Type was removed or renamed in the Firefox upgrade.
- **Solution:** Use the current `TabManager` protocol. Replace `browserViewController.tabManager as? LegacyTabManager` with `browserViewController.tabManager` (type is already `TabManager`). Use the public `TabManager` API only (e.g. `addTab(_:afterTab:zombie:isPrivate:)`); there is no public `configureTab` — that’s internal to `TabManagerImplementation`.

### 2.2 Tab creation (configureTab / addTab)

- **File:** `InvisibleTabSession.swift:84–91`
- **Error:** `'nil' requires a contextual type` (and dependency on LegacyTabManager).
- **Cause:** Old code used `LegacyTabManager.configureTab(newTab, request: ..., afterTab: nil, flushToDisk: true, zombie: false)`.
- **Solution:** Use the public API: create tab with `tabManager.addTab(URLRequest(url: url), afterTab: nil, zombie: false, isPrivate: false)`, then set `newTab.isInvisible = true` (if the property exists) and use `InvisibleTabManager.shared.markTabAsInvisible(newTab)`.

### 2.3 removeTab(Tab) vs removeTab(TabUUID)

- **Files:** `InvisibleTabSession.swift:152`; `TabAutoCloseManager.swift:235`
- **Error:** `cannot convert value of type 'Tab' to expected argument type 'TabUUID' (aka 'String')`; `extra trailing closure passed in call`
- **Cause:** `TabManager` protocol has `removeTab(_ tabUUID: TabUUID)` (no completion) and `removeTabs(_ tabs: [Tab])`. The old `removeTab(tab, completion:)` no longer exists.
- **Solution:** Call `removeTab(tab.tabUUID)`. Run any “completion” logic after that (e.g. `Task { @MainActor in ... }` or dispatch after removal), since the protocol doesn’t expose a completion callback for `removeTab(tabUUID)`.

### 2.4 setupAutoCloseForTab / cancelAutoCloseForTab (Tab vs TabUUID)

- **Files:** `InvisibleTabSession.swift:108`, `138`, `152`; `TabAutoCloseManager.swift`
- **Error:** Actor-isolated method cannot be called from outside; `Tab` vs `TabUUID`; extra trailing closure.
- **Cause:** API likely takes `TabUUID` (and maybe a notification name), not `Tab` and no trailing closure.
- **Solution:** Use `setupAutoCloseForTab(tab.tabUUID, on: .EcosiaAuthStateChanged, timeout: self.timeout)` (or the exact signature of `TabAutoCloseManager`). Use `cancelAutoCloseForTab(tab.tabUUID)`. Remove any trailing closure; if completion is needed, handle it inside the manager or via a different mechanism (e.g. notification or callback registered on the manager).

### 2.5 OnLocationChange notification

- **File:** `TabAutoCloseManager.swift:152`
- **Error:** `type 'NSNotification.Name?' has no member 'OnLocationChange'`
- **Cause:** `Notification.Name.OnLocationChange` was removed or renamed.
- **Solution:** Use tab events instead. Register as `TabEventHandler` for `.didChangeURL` and in `tab(_ tab: Tab, didChangeURL url: URL)` run the same logic you had in the `OnLocationChange` observer (e.g. call `handlePageLoadCompletion`-equivalent with tab and url). Remove the `NotificationCenter.addObserver(forName: .OnLocationChange, ...)` path.

### 2.6 BrowserViewController member renames / removal

- **File:** `BrowserViewController+Ecosia.swift`
- **Errors:** `cannot find 'urlBar'`, `'toolbar'`, `'tabToolbarDidPressHome'`, `'homePanelDidRequestToOpenSettings'`, `'menuHelper'`, `'whatsNewDataProvider'`, `'referrals'`, `'toolbarContextHintVC'`, `'popToBVC'`, etc.
- **Cause:** Firefox refactor: renames and different structure.
- **Solutions (map old → new where applicable):**
  - `urlBar` → `addressToolbarContainer` (and use its API for “tap location”, e.g. equivalent of `tabLocationViewDidTapLocation(locationView)` if exposed).
  - `toolbar` → likely a toolbar from the new layout (e.g. navigation toolbar); find the correct property on `BrowserViewController` or coordinator.
  - `tabToolbarDidPressHome` → search base for “home” / “toolbar” and use the new action (e.g. on coordinator or a new helper).
  - `homePanelDidRequestToOpenSettings(at: .general)` → same: search for “open settings” / “general” in `BrowserViewController` or navigation handler.
  - `menuHelper` → search for “menu” / “share” / “getSharingAction” in `BrowserViewController`; use the new type if renamed.
  - `whatsNewDataProvider` → search for “whatsNew” / “markPreviousVersionsAsSeen” and use the new property name.
  - `referrals` → likely still on a different object (e.g. `User.shared.referrals` or a service); ensure it’s injected or available where `presentLoadingScreen` runs.
  - `toolbarContextHintVC` → `toolbarUpdateContextHintVC` (rename in Ecosia code).
  - `popToBVC()` → `navigationHandler?.popToBVC()` (method is `fileprivate` on BVC; use the handler).

### 2.7 Tab.metadataManager

- **File:** `BrowserViewController+Ecosia.swift:204`
- **Error:** `value of type 'Tab' has no member 'metadataManager'`
- **Cause:** Property removed or moved (e.g. to another object or renamed).
- **Solution:** Search firefox-ios for “tabGroupData” / “tabAssociatedSearchUrl” / “metadata” on `Tab` or related types; use the new API to get the redirect URL for sign-in.

### 2.8 UserAgentBuilder.ecosiaMobileUserAgent

- **File:** `BrowserViewController+Ecosia.swift:272`
- **Error:** `type 'UserAgentBuilder' has no member 'ecosiaMobileUserAgent'`
- **Solution:** Find the new user-agent API (e.g. different static or instance method / builder) and add an Ecosia-specific UA there, or use the existing mobile UA and override in Ecosia layer if supported.

### 2.9 Presentation / sheet API

- **File:** `BrowserViewController+Ecosia.swift:282`, `285`
- **Error:** `cannot infer contextual base in reference to member 'pageSheet'`; `type 'Any' has no member 'large'`
- **Cause:** Detent or sheet API changed (e.g. `UISheetPresentationController.Detent`, or different type).
- **Solution:** Use the current SDK API for sheet detents (e.g. `UISheetPresentationController.Detent` and the correct identifier or custom detent) and fix the type (avoid `Any`; use the concrete detent type).

### 2.10 Homepage / library / settings

- **File:** `HomepageViewController+Ecosia.swift` (e.g. `homePanelDidRequestToOpenLibrary`, `homePanelDidRequestToOpenSettings`, `referrals`, `bookmarks` / `history` / `readingList` / `downloads`, `homePage`).
- **Cause:** Method or property names changed in base `BrowserViewController` or homepage.
- **Solution:** Search for the new method names (e.g. “open library”, “open settings”, “homepage”) in `BrowserViewController` and `HomepageViewController` and update Ecosia code to use them. Use the correct type for delegate (e.g. `SharedHomepageCellDelegate` if required).

### 2.11 HomepageViewController+EcosiaCells (dequeueReusableCell / navigateToHomepageSettings)

- **File:** `HomepageViewController+EcosiaCells.swift` (multiple lines)
- **Error:** `value of type '@MainActor @Sendable (UICollectionView, IndexPath) -> ()' has no member 'dequeueReusableCell'`; `'navigateToHomepageSettings' is inaccessible due to 'private' protection level`
- **Cause:** Cell registration/closure type changed (closure is not the view controller); or method was made private.
- **Solution:** Use the view controller (e.g. `self`) to call `dequeueReusableCell` inside the closure, or change the closure to a method on the view controller and use that for registration. For settings, use a public method that wraps `navigateToHomepageSettings` or call the public API that opens homepage settings.

### 2.12 SimpleToast+Ecosia

- **File:** `SimpleToast+Ecosia.swift:32`, `54`
- **Error:** `type 'Toast.UX' has no member 'toastHeight'`; `'heightConstraint' is inaccessible due to 'private' protection level`
- **Solution:** Replace `Toast.UX.toastHeight` with the constant or API that the current `Toast` uses for height. For layout, use public API of the toast view (e.g. a public constraint or a method that sets height) instead of touching a private `heightConstraint`.

### 2.13 AppSettingsTableViewController+Ecosia (optional Profile, Nimbus, TabsSetting, FasterInactiveTabs)

- **File:** `AppSettingsTableViewController+Ecosia.swift` (many lines)
- **Errors:** Optional `Profile` unwrap; `NimbusFeatureFlagID.inactiveTabs` / `TabsSetting` / `FasterInactiveTabs` not found; wrong initializer labels (`prefs:` / `profile:`); `AppSettingsTableViewController` does not conform to `Prefs` / `Profile`; `BrowsingSettingsDelegate` vs `SettingsFlowDelegate`.
- **Cause:** Firefox settings and Nimbus API changed; optional `profile`; different initializers for settings rows.
- **Solutions:**
  - Unwrap `profile` safely (e.g. `guard let profile = profile else { return }`) before using `profile.prefs` or passing `profile`.
  - Replace `NimbusFeatureFlagID.inactiveTabs` / `TabsSetting` / `FasterInactiveTabs` with the new feature IDs and types (search project for “inactive tabs” / “tabs setting”).
  - Use the initializers that the new settings table expects (correct `prefs` / `profile` and delegate types). Don’t make `AppSettingsTableViewController` conform to `Prefs`/`Profile`; pass the real `profile` and `prefs` into the row types that require them.

---

## 3. Optional unwrapping (Profile)

- **File:** `AppSettingsTableViewController+Ecosia.swift` (multiple lines)
- **Error:** `value of optional type '(any Profile)?' must be unwrapped to refer to member 'prefs'`
- **Solution:** Use `guard let profile = profile else { return }` (or early return) and then use `profile.prefs`; or optional chaining / default behavior where appropriate.

---

## 4. InvisibleTabSession.cleanup() in deinit

- **File:** `InvisibleTabSession.swift:173` (and deinit)
- **Error:** `call to main actor-isolated instance method 'cleanup()' in a synchronous nonisolated context`
- **Cause:** `cleanup()` is main-actor isolated but called from deinit (nonisolated).
- **Solution:** Don’t call `cleanup()` from deinit. Rely on explicit cleanup when the session ends (e.g. when tab closes or flow completes). If needed, document that callers must call `cleanup()` before releasing the session.

---

## Summary table

| Category              | Count (approx) | Approach                                              |
|-----------------------|----------------|--------------------------------------------------------|
| Main actor / Sendable | ~25            | Add `@MainActor`, `Task { @MainActor in }`, or unwrap |
| iOS 16 API            | 2              | Use nanoseconds sleep or `@available(iOS 16, *)`       |
| Firefox API/rename    | ~40            | Align with current types and names (see sections 2.x) |
| Optional unwrap       | ~10            | `guard let profile` / optional chaining               |

Recommended order of work: (1) Fix Firebase/API renames and types (section 2) so the project compiles; (2) fix optional unwrapping (section 3); (3) fix main-actor and concurrency (section 1) so tests and runtime are stable; (4) adjust iOS 16 usage (section 1.2) as needed for deployment target.
