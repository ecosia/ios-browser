# Concurrency Analysis: firefox-ios/Client/Ecosia

**Date:** February 2, 2026  
**Scope:** `firefox-ios/Client/Ecosia` and subfolders  
**Reference:** `.cursor/skills/swift-concurrency/SKILL.md`  
**Project context:** Swift 6.2, `SWIFT_STRICT_CONCURRENCY=minimal` (see `TODO_SWIFT_CONCURRENCY.md`)

**Status:** All listed fixes have been applied (see diff / git history).

This document analyses concurrency-related patterns in Ecosia Client code so that when strict concurrency is re-enabled (`targeted` or `complete`), issues are understood and can be fixed systematically.

---

## 1. Project settings (relevant to Ecosia)

| Setting | Value | Implication |
|--------|--------|-------------|
| `SWIFT_VERSION` | 6.2 | Full Swift 6 language and concurrency model |
| `SWIFT_STRICT_CONCURRENCY` | minimal | Concurrency checking is relaxed; many issues do not yet emit errors |
| Goal (from TODO) | Re-enable strict concurrency | Ecosia code must be safe under `targeted` / `complete` |

With **minimal**, the compiler does not enforce:
- Sendable on values crossing isolation boundaries
- MainActor isolation for UI types
- Safe use of mutable global/static state

With **targeted** or **complete**, the following patterns in Client/Ecosia will start to produce errors or warnings unless addressed.

---

## 2. Categories of findings

### 2.1 Mutable or nonisolated static state

Static mutable or shared state is problematic under strict concurrency unless it is either immutable, MainActor-isolated, or explicitly opted out with a documented safety invariant.

| Location | Pattern | Risk | Proposed fix |
|----------|---------|------|----------------|
| **MarketsController.swift** (Markets) | `static var current: String?` (computed from `User.shared`) | Read of `User.shared` from arbitrary context; under strict concurrency, static computed properties are nonisolated. | Keep as computed property; ensure `User.shared` is safe from any context, or isolate the type (e.g. `@MainActor enum Markets` / `@MainActor final class Markets`) if it’s UI/config-only. |
| **DefaultBrowser.swift** | `static var minPromoSearches = 50` | Mutable global state; not concurrency-safe. | Make `static let` if never mutated, or move to a config type (e.g. actor or @MainActor) and document. |
| **EcosiaFindInPageBar.swift** | `static var retrieveSavedText: String?` (UserDefaults read) | Nonisolated global read; UserDefaults is thread-safe but the *property* is shared. | Prefer `nonisolated` + doc, or expose via a small helper (e.g. MainActor or actor) if callers are UI-only. |
| **WelcomeTour.Step.swift** | `static var all: [Step]` | Computed, returns new array each time; no mutable state. | Low risk. If type becomes `@MainActor`, this is fine; otherwise leave as-is (value is effectively constant). |
| **FilterController** | `static var current: String?` | Same pattern as Markets: computed from `User.shared`. | Same as Markets: rely on `User.shared` thread-safety or isolate the type. |
| **EcosiaHomepageSectionType** | `static var cellTypes: [ReusableCell.Type]` | Computed, builds array from types. | Low risk (no mutable global). Optional: mark type or property `@MainActor` if only used from UI. |
| **HomepageViewController+EcosiaCells.swift** | `AssociatedKeys`: `static var ecosiaAdapter: UInt8 = 0` | Used as objc association key; value is constant in practice. | Standard pattern for associated keys. Under strict concurrency, consider `nonisolated(unsafe)` with one-line comment that it’s used only as an opaque key. |
| **EcosiaDebugSettings.swift** | `static var isEnabled: Bool` (SimulateAuthError, SimulateImpactAPIError) | Computed from UserDefaults; read from multiple contexts. | UserDefaults is thread-safe. Document that these are simple UserDefaults reads; no code change required unless you want explicit `nonisolated` for clarity. |
| **SnapKit+Ecosia.swift** | `static var veryHigh: ConstraintPriority` | Returns new value each time; no mutable state. | No change. |

**Summary:** The only clearly mutable static in this set is `DefaultBrowser.minPromoSearches`; make it `static let` if it’s never written. The rest are either computed, constant, or used as keys; isolate or document as above.

---

### 2.2 @MainActor and closure-based callbacks

Many types are correctly annotated with `@MainActor`. The remaining issues are callbacks (e.g. subscriptions, completion handlers) that run in a nonisolated or Sendable context and then call MainActor-isolated code.

| Location | Pattern | Risk | Proposed fix |
|----------|---------|------|----------------|
| **NTPImpactCellViewModel** | `referrals.subscribe(self) { … }`; `TreesProjection` / `InvestmentsProjection` subscribe | Subscription closures may be `@Sendable` and run off main actor; they call `refreshCell`, `updateCachedTotalTrees`, etc. (MainActor). | **Already fixed:** closures use `Task { @MainActor in … }` to hop to main actor. Keep this pattern. |
| **NTPImpactCellViewModel** | `deinit` cannot call `referrals.unsubscribe(self)` (unsubscribe is @MainActor). | Unsubscribe is skipped in deinit; no retain cycle because of `[weak self]`. | **Already documented.** Alternative: have a “cancellation” object that is MainActor and holds the subscription, and cancel it from a nonisolated teardown that doesn’t call MainActor. |
| **NTPHeaderViewModel** | `authStateProvider.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }` | Class is `@MainActor`; `sink` may run on Combine’s scheduler. `objectWillChange.send()` should run on main. | Use `.receive(on: DispatchQueue.main)` before `sink`, or ensure the provider’s `objectWillChange` is delivered on main. If the provider is @MainActor, receiving on main is redundant but harmless. |
| **NTPHeaderViewModel** | `NotificationCenter.default.addObserver(..., queue: .main) { [weak self] _ in self?.triggerSeedSparkles() }` | Already on `.main` queue. | No change. |
| **EcosiaAuth** | `Task { await performLogin(flow) }` / `performLogout` | `EcosiaAuth` is not @MainActor; `EcosiaAuthFlow.startLogin` / related are @MainActor. | Task inherits actor context of the caller. If caller is main (e.g. UI), this is fine. If not, use `Task { @MainActor in await performLogin(flow) }` (or equivalent) where the flow must run on main. |
| **InvisibleTabSession** | `startMonitoring(_ completion: @escaping (Bool) -> Void)`; completion called from where? | If completion is invoked from a background queue, UI updates in the handler are unsafe. | Ensure completion is always dispatched to main (e.g. `DispatchQueue.main.async { completion(success) }`), or mark the closure `@MainActor @Sendable` and call from MainActor. |

**Summary:** NTPImpactCellViewModel is already fixed with `Task { @MainActor in … }`. NTPHeaderViewModel and EcosiaAuth/InvisibleTabSession need a quick check that all UI-touching or MainActor-only work runs on main (either by receiver or by explicit hop).

---

### 2.3 Singletons and explicit opt-out

| Location | Pattern | Risk | Proposed fix |
|----------|---------|------|----------------|
| **InvisibleTabManager** | `nonisolated(unsafe) static let shared = InvisibleTabManager()` | Singleton; internal state protected by `DispatchQueue` (concurrent + barrier). | **Already opted out** with a documented pattern. Per skill: document safety invariant (“all mutable state protected by queue”) and consider a follow-up to migrate to an actor later. |
| **TabAutoCloseManager** (InvisibleTabAutoCloseManager) | `actor` with `static let shared` | Actor singleton; no `nonisolated(unsafe)`. | Correct; no change. |

---

### 2.4 DispatchQueue usage (legacy patterns)

The audit lists several files still using `DispatchQueue.main.async` / `asyncAfter`. For strict concurrency, prefer `Task { @MainActor in … }` or `MainActor.assumeIsolated` where appropriate.

| Location | Usage | Proposed direction |
|----------|--------|---------------------|
| **EcosiaDebugSettings** | Many `DispatchQueue.main.asyncAfter(deadline:...) { alert.dismiss(...) }` | Replace with `Task { @MainActor in try? await Task.sleep(...); alert.dismiss(...) }` (or use a small helper) so it’s explicit main-actor work. |
| **SimpleToast+Ecosia** | `DispatchQueue.main.asyncAfter(deadline: dispatchTime) { ... }` for delayed dismiss | Same: `Task { @MainActor in try? await Task.sleep(...); ... }`. |
| **BrowserViewController+Ecosia** | `DispatchQueue.main.async { ... }` | Replace with `Task { @MainActor in ... }` if the block only touches UI/self. |
| **DispatchQueueHelper+BuildChannel** | `DispatchQueue.main.asyncAfter(deadline: .now() + delay)` | Replace with `Task { @MainActor in try? await Task.sleep(for: .seconds(delay)); ... }`. |
| **BookmarksExchange** | `profile.places.getBookmark(...).uponQueue(DispatchQueue.main) { result in ... }` | Already targeting main queue; ensure callback doesn’t capture non-Sendable state. Optional: wrap in `Task { @MainActor in ... }` for consistency. |
| **EcosiaThemeManager** | `mainQueue: DispatchQueueInterface = DispatchQueue.main` | Injected dependency; used for dispatching. Can be kept; ensure callbacks that touch UI are dispatched to main. |

**Summary:** No need to change semantics; gradually replace `DispatchQueue.main.async` / `asyncAfter` with `Task { @MainActor in ... }` and `Task.sleep` so the codebase is clearly main-actor–oriented and easier to check under strict concurrency.

---

### 2.5 Task usage (correct vs unnecessary)

| Location | Pattern | Note |
|----------|---------|------|
| **NTPImpactCellViewModel** | `Task { @MainActor in self.updateCachedTotalTrees(); ... }` inside subscribe closures | Correct: hop to main before calling MainActor-isolated methods. |
| **NTPImpactCellViewModel** | `updateCachedTotalTrees()` uses `Task { @MainActor in self.cachedTotalTrees = await TreesProjection.shared.treesAt(...) }` | Correct: update cached state on main after async work. |
| **MultiplyImpact** | `Task { [weak self] in ... }` (no explicit @MainActor) | If the closure only touches UI/self and the class is @MainActor, the task will run in the same context when launched from main; for clarity, consider `Task { @MainActor [weak self] in ... }`. |
| **LoadingScreen** | `Task { [weak self] in ... }` | Same as above. |
| **EcosiaAuth** | `Task { await performLogin(flow) }` | Ensure flow runs on main when required; add `@MainActor` to the task if the caller is not guaranteed main. |
| **TabAutoCloseManager** | `Task { @MainActor [weak self] in ... }` and internal `Task { [weak self] in ... }` | Already mixes actor and MainActor appropriately. |
| **EcosiaDebugSettings** | `Task { @MainActor in ... }` and `Task { ... }` | Use `@MainActor` in the task when the block touches UI or @MainActor state. |

**Summary:** Most `Task` usage is correct. Where the class is `@MainActor` and the task only updates UI/self, making the task explicitly `Task { @MainActor in ... }` improves clarity and avoids surprises when strict concurrency is on.

---

### 2.6 ObservableObject and Combine

| Location | Pattern | Risk | Proposed fix |
|----------|---------|------|----------------|
| **NTPHeaderViewModel** | `@MainActor final class NTPHeaderViewModel: ObservableObject`; `@Published var showSeedSparkles`; `authStateProvider.objectWillChange.sink(...)` | View model is MainActor; Combine may deliver on a different scheduler. | Use `.receive(on: DispatchQueue.main)` (or RunLoop.main) before `sink` so `objectWillChange.send()` and UI updates happen on main, or ensure provider always sends on main. |

---

### 2.7 nonisolated on TabManager+InvisibleTab / Tab+InvisibleTab

Extensions use `nonisolated var` / `nonisolated func` and document that `InvisibleTabManager` is thread-safe via its queue. This is consistent with the singleton’s `nonisolated(unsafe)` and documented invariant. No change beyond keeping the comment.

---

## 3. File-level summary (Client/Ecosia)

| File / area | Category | Action |
|-------------|----------|--------|
| MarketsController (Markets) | Static | Consider `@MainActor` for `Markets` or document `User.shared` usage; `static let all` already done. |
| DefaultBrowser | Static | Change `minPromoSearches` to `static let` if never mutated. |
| EcosiaFindInPageBar | Static | Document or wrap `retrieveSavedText`; low priority. |
| FilterController | Static | Same as Markets for `current`. |
| EcosiaHomepageSectionType | Static | Optional `@MainActor` if UI-only. |
| HomepageViewController+EcosiaCells (AssociatedKeys) | Static | Consider `nonisolated(unsafe)` + one-line comment if compiler complains. |
| NTPImpactCellViewModel | MainActor + closures | Already fixed with `Task { @MainActor in … }`; deinit note kept. |
| NTPHeaderViewModel | Combine | Add `.receive(on: DispatchQueue.main)` to the `objectWillChange` sink (or verify provider is main). |
| EcosiaAuth | Task + MainActor | Ensure login/logout flow runs on main when needed; add `Task { @MainActor in … }` if callers are not always main. |
| InvisibleTabSession | Completion | Ensure completion is called on main or is @MainActor. |
| InvisibleTabManager | Singleton | Already documented; keep. |
| EcosiaDebugSettings | DispatchQueue | Replace `DispatchQueue.main.asyncAfter` with `Task { @MainActor in try? await Task.sleep(...); ... }` where it’s just delayed UI. |
| SimpleToast+Ecosia | DispatchQueue | Same as above. |
| BrowserViewController+Ecosia | DispatchQueue | Replace `DispatchQueue.main.async` with `Task { @MainActor in ... }`. |
| DispatchQueueHelper+BuildChannel | DispatchQueue | Replace with Task + sleep. |
| MultiplyImpact / LoadingScreen | Task | Optionally add explicit `@MainActor` in task closure for clarity. |

---

## 4. Recommended fix order (minimal blast radius)

1. **Low-risk, single-line**
   - `DefaultBrowser.minPromoSearches`: if never mutated → `static let minPromoSearches = 50`.

2. **Closure / callback isolation**
   - NTPHeaderViewModel: add `.receive(on: DispatchQueue.main)` to the `objectWillChange` sink (or equivalent).
   - EcosiaAuth: add `Task { @MainActor in await performLogin(flow) }` (and same for logout) if the entry point is not guaranteed main.
   - InvisibleTabSession: ensure completion is dispatched to main (or mark and call from MainActor).

3. **DispatchQueue → Task**
   - EcosiaDebugSettings: replace each `DispatchQueue.main.asyncAfter` used for delayed dismiss with `Task { @MainActor in try? await Task.sleep(...); ... }`.
   - SimpleToast+Ecosia: same for the delayed dismiss.
   - BrowserViewController+Ecosia: replace `DispatchQueue.main.async` with `Task { @MainActor in ... }`.
   - DispatchQueueHelper+BuildChannel: replace with Task + sleep.

4. **Optional clarity**
   - MultiplyImpact, LoadingScreen: add `@MainActor` to existing `Task { [weak self] in ... }` where the body is main-only.
   - Markets / FilterController: add `@MainActor` to the small types that only expose `current` from `User.shared`, or document thread-safety.

5. **Re-enable strict concurrency**
   - In Project.swift, remove or change `SWIFT_STRICT_CONCURRENCY` to `targeted` (then later `complete`).
   - Fix any new compiler errors; the list above should cover most of Client/Ecosia.

---

## 5. Verification

- Build with `SWIFT_STRICT_CONCURRENCY = targeted` (then `complete`) and fix remaining diagnostics.
- Run Ecosia-related tests (unit + UI).
- Manually test: NTP (impact, referrals, projections), default browser promo, auth flow, find in page, bookmarks exchange, theme, debug settings toggles.

---

## 6. References

- `.cursor/skills/swift-concurrency/SKILL.md` – patterns, decision tree, and migration guidance.
- `TODO_SWIFT_CONCURRENCY.md` – project status and re-enable steps.
- `SWIFT_CONCURRENCY_AUDIT.md` – project-wide audit; Client/Ecosia items overlap with this file.
