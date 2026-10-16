---
type: wayfinder:grilling
status: closed
blocked-by: []
claimed: Paul
---
## Question
Shape of the typed auth-event stream for PR 4: Combine publisher vs async stream, event cases (logged in / logged out / state loaded with `wasLoggedIn`), delivery when no browser window is registered, and how it replaces the `hasHandledCurrentResolution` / `pendingSeedStateRefresh` ordering rules.

## Resolution

- Emission: once per transition from `EcosiaAuthenticationService.dispatchAuthState`, independent of windows. Per-window notifications remain for their existing consumers; impact stops depending on them (fixes repeated firing and the no-window gap).
- Mechanism: `authEvents: AnyPublisher<AuthEvent, Never>` on the seam protocol (`AuthSessionProviderProtocol`), backed by a `PassthroughSubject`, delivered on the main actor. Not `AsyncStream`, not the custom Core `Publisher`.
- Events: `.loggedIn`, `.loggedOut`, `.stateResolved(isLoggedIn: Bool, previousSessionExpired: Bool)`. `previousSessionExpired` replaces today's `wasLoggedIn` check; `ImpactManager` clears its own cache on `.loggedOut` and on an expired resolution, so auth no longer references impact.
- Dedup: `hasHandledCurrentResolution` and `pendingSeedStateRefresh` stay in `ImpactManager` verbatim in PR 4 (cold launch can still emit `.loggedIn` and `.stateResolved` for one event). Removing them is a separate decision needing proof from PR 2's tests.
- Late subscribers: no replay. `ImpactManager` subscribes first, then reads `isLoggedIn` / `hasResolvedAuthState` synchronously, as the provider does today.
- Stays on NotificationCenter in PR 4: `.EcosiaUserProfileUpdated` (provider / avatar) and the seed-progress notification from `UserDefaultsSeedProgressManager` (revisited in the cache-unification effort).
