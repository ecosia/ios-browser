---
type: wayfinder:grilling
status: closed
blocked-by: []
claimed: Paul
---
## Question
What exact protocol does the impact class need from auth (`isLoggedIn`, `accessToken`, `hasResolvedAuthState`, ...), what does the thin wrapper over `EcosiaAuthenticationService.shared` look like, and who owns clearing the logged-in cache on logout/expiry (today `EcosiaAuthenticationService` does) so auth no longer knows about impact?

## Resolution

- Seam protocol (name decided in ticket 04): read-only `isLoggedIn`, `hasResolvedAuthState`, `accessToken`. `userProfile`, avatar and username stay on `EcosiaAuthUIStateProvider`.
- Default wiring: a tiny wrapper type reading `EcosiaAuthenticationService.shared`, used as the default init argument of the impact class, so `.shared` and all call sites are untouched and tests can inject a fake.
- Cache clearing in PR 1: unchanged. `EcosiaAuthenticationService.clearLoggedInImpactCacheIfNeeded` and the provider's `loggedInImpactCacheType.clear()` stay. Ownership flips in the reactive PR (4 in the final stack) (auth emits events; impact clears its own cache, including the `wasLoggedIn` expired-token case), which also closes the "no window registered" gap.
- Event channel in PR 1: the provider keeps observing the `NotificationCenter` auth notifications and calls plain methods on the impact class; dedup flags (`hasHandledCurrentResolution`, `pendingSeedStateRefresh`) move verbatim with their handlers.
- `User.seedCount` (Core reads the UI-layer provider) is left alone in PR 1; repoint it once the impact class exists.
