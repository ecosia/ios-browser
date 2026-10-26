---
type: wayfinder:grilling
status: closed
blocked-by: []
claimed: Paul
---
## Question
Names and file homes for: the pure Impact API service in `Core` (rename/widen `AccountsProvider`?), the new impact state class, the auth-seam protocol and wrapper, and the retained `EcosiaAuthUIStateProvider` facade. Open from ticket 01: static `ImpactManager` (4236 style) vs an injected instance, judged by review size. Includes isolation (`@MainActor`, `ObservableObject`) and singleton vs injected.

## Resolution

Status on `main`: the names, homes and construction below shipped as decided in ecosia/ios-browser#1339. Open items: the conformance-only `AccountsService` token seam (PR 3) and relocating caches / seed manager / `ImpactSnapshot` out of `UI/` (PR 5, ticket 07).

- Core API layer: keep `AccountsProvider` / `AccountsService` and `Core/Accounts`; no rename in the stack unless an endpoint beyond `/accounts/visit` is added.
- Impact class: instance `@MainActor final class ImpactManager: ObservableObject` owning the impact `@Published` state, animations, register-visit and the dedup flags (`hasHandledCurrentResolution`, `pendingSeedStateRefresh`, `hasRegisterVisitError`). `EcosiaAuthUIStateProvider` forwards `objectWillChange` and exposes the same properties as computed forwards.
- Homes in PR 1: new files only. `UI/Account/Impact/ImpactManager.swift`; seam in `Account/Auth/`. Caches, seed manager and `ImpactSnapshot` stay in `UI/Account/SeedProgressManager` (relocating to Core is a later mechanical PR).
- Seam: `AuthSessionProviderProtocol` (`isLoggedIn`, `hasResolvedAuthState`, `accessToken`) with default `EcosiaAuthSessionProvider` reading `EcosiaAuthenticationService.shared`.
- Construction: no `ImpactManager.shared`. `EcosiaAuthUIStateProvider.shared` builds it; the provider keeps its `accountsProvider:` init parameter and `accountsProviderFactory`, forwarding them; a new `impactManager:` parameter defaults to one built from them.
- Construction on `main`: `AppDelegate` sets `accountsProviderFactory = { AccountsProviderWrapper() }` before first `.shared` access (ecosia/ios-browser#1354), so `ImpactManager` receives the debug-aware wrapper.
- `AccountsService` token seam (PR 3): `AccountsService` (Core) depends directly on `EcosiaAuthenticationService` for renew-on-401 (`renewCredentials()` then re-read `accessToken`). PR 3 is conformance-only: a small Core protocol with `accessToken` and `renewCredentials()`, `extension EcosiaAuthenticationService: <protocol> {}`, and `AccountsService` storing the protocol type with `EcosiaAuthenticationService.shared` as the default argument. No wrapper type, no call-site or behavior change; the payoff is that `AccountsServiceTests` can fake the 401 → renew → retry path.
