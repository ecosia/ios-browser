---
type: wayfinder:grilling
status: closed
blocked-by: []
claimed: Paul
---
## Question
What exact protocol does the impact class need from auth (`isLoggedIn`, `accessToken`, `hasResolvedAuthState`, ...), what does the thin wrapper over `EcosiaAuthenticationService.shared` look like, and who owns clearing the logged-in cache on logout/expiry (today `EcosiaAuthenticationService` does) so auth no longer knows about impact?

## Resolution

Status on `main`: everything below marked PR 1 shipped in ecosia/ios-browser#1339, covered by `ImpactManagerTests` (ecosia/ios-browser#1365). Nothing in this ticket is open; the event channel swap is PR 4 (ticket 06), and cache-clear ownership belongs to the cache-unification effort.

- Seam protocol (name decided in ticket 04): read-only `isLoggedIn`, `hasResolvedAuthState`, `accessToken`, plus `userID` (the ID token's `sub`, stable across renewals; added in ecosia/ios-browser#1366 for the in-flight account guard) (`Account/Auth/AuthSessionProviderProtocol.swift`, `Sendable`). PR 4 adds `authEvents` (ticket 06). `userProfile`, avatar and username stay on `EcosiaAuthUIStateProvider`.
- Default wiring: `EcosiaAuthSessionProvider`, a struct reading `EcosiaAuthenticationService.shared`, is the default `auth:` argument of `ImpactManager.init`, so `.shared` and all call sites are untouched and tests inject `MockAuthSessionProvider`.
- `ImpactManager` mirrors `isLoggedIn` / `hasResolvedAuthState` in private properties, refreshed on auth events, `refreshLoggedInState()` (profile update) and the `refreshSeedState()` catch-up, rather than reading the seam live. `EcosiaAuthUIStateProvider` keeps its own `@Published isLoggedIn` mirror, updated from the same notifications; the two copies are kept in step by hand.
- Cache clearing: unchanged throughout this map. `EcosiaAuthenticationService.clearLoggedInImpactCacheIfNeeded` (logout, and the `wasLoggedIn` expired-session case) and `ImpactManager.resetToLocalSeedCollection` (`loggedInImpactCacheType.clear()`) both keep clearing. The service clears directly because no window, and so no `ImpactManager`, may exist yet when auth resolves; an event-driven clear in `ImpactManager` would miss an expired session that resolves before it subscribes and show the previous account's seeds. Moving the clear out of auth is deferred to the cache-unification effort: a user-id-keyed cache never loads another account's snapshot, so clearing stops being needed for correctness. Until then auth keeps this one reference to `LoggedInImpactCache`.
- Event channel in PR 1: the provider keeps observing the `NotificationCenter` auth notifications and calls plain methods on `ImpactManager`; dedup flags (`hasHandledCurrentResolution`, `pendingSeedStateRefresh`) moved verbatim with their handlers.
- `User.seedCount` (Core reads the UI-layer provider) is left alone in PR 1; repointed in PR 5.
