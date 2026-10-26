---
type: wayfinder:grilling
status: closed
blocked-by: []
claimed: Paul
---
## Question
Shape of the typed auth-event stream for PR 4: Combine publisher vs async stream, event cases (logged in / logged out / state loaded with `wasLoggedIn`), delivery when no browser window is registered, and how it replaces the `hasHandledCurrentResolution` / `pendingSeedStateRefresh` ordering rules.

## Resolution

- Emission: once per transition from `EcosiaAuthenticationService.dispatchAuthStateChange`, after `clearLoggedInImpactCacheIfNeeded` (same order as today's notification), independent of windows. Per-window notifications remain for their existing consumers; impact stops depending on them (fixes repeated firing and the no-window gap).
- Mechanism: `authEvents: AnyPublisher<AuthEvent, Never>` on the seam protocol (`AuthSessionProviderProtocol`), backed by a `PassthroughSubject`, delivered on the main actor. Not `AsyncStream`, not the custom Core `Publisher`.
- Events: `.loggedIn`, `.loggedOut`, `.stateResolved(isLoggedIn: Bool)`. No expired-session flag: the service keeps clearing the logged-in cache itself, including the `wasLoggedIn` case (ticket 03), so `ImpactManager` has no use for it. Cache unification adds whatever it needs.
- Dedup: `hasHandledCurrentResolution` and `pendingSeedStateRefresh` stay in `ImpactManager` verbatim in PR 4 (cold launch can still emit `.loggedIn` and `.stateResolved` for one event). Removing them is a separate decision needing proof from PR 2's tests.
- Late subscribers: no replay. `ImpactManager` subscribes first, then reads `isLoggedIn` / `hasResolvedAuthState` synchronously, as the provider does today. `ImpactManager` is built lazily with `EcosiaAuthUIStateProvider.shared`, so auth can resolve before it subscribes; that is safe because the service has already cleared a stale logged-in cache by then, and `loadInitialSnapshot` falls through to the local snapshot.
- Stays on NotificationCenter in PR 4: `.EcosiaUserProfileUpdated` (provider / avatar) and the seed-progress notification from `UserDefaultsSeedProgressManager` (revisited in the cache-unification effort).
- Seed-progress observer: `ImpactManager` observes the seed-progress notification itself, so `EcosiaAuthUIStateProvider` no longer handles any impact event.
