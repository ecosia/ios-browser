---
type: wayfinder:grilling
status: closed
blocked-by: []
claimed: Paul
---
## Question
Names and file homes for: the pure Impact API service in `Core` (rename/widen `AccountsProvider`?), the new impact state class, the auth-seam protocol and wrapper, and the retained `EcosiaAuthUIStateProvider` facade. Open from ticket 01: static `ImpactManager` (4236 style) vs an injected instance, judged by review size. Includes isolation (`@MainActor`, `ObservableObject`) and singleton vs injected.

## Resolution

- Core API layer: keep `AccountsProvider` / `AccountsService` and `Core/Accounts`; no rename in the stack unless an endpoint beyond `/accounts/visit` is added.
- Impact class: instance `@MainActor final class ImpactManager: ObservableObject` owning the impact `@Published` state, animations, register-visit and the dedup flags (`hasHandledCurrentResolution`, `pendingSeedStateRefresh`, `hasRegisterVisitError`). `EcosiaAuthUIStateProvider` forwards `objectWillChange` and exposes the same properties as computed forwards.
- Homes in PR 1: new files only. `UI/Account/Impact/ImpactManager.swift`; seam in `Account/Auth/`. Caches, seed manager and `ImpactSnapshot` stay in `UI/Account/SeedProgressManager` (relocating to Core is a later mechanical PR).
- Seam: `AuthSessionProviderProtocol` (`isLoggedIn`, `hasResolvedAuthState`, `accessToken`) with default `EcosiaAuthSessionProvider` reading `EcosiaAuthenticationService.shared`.
- Construction: no `ImpactManager.shared`. `EcosiaAuthUIStateProvider.shared` builds it; the provider keeps its `accountsProvider:` init parameter and `accountsProviderFactory`, forwarding them; a new `impactManager:` parameter defaults to one built from them.
- Fact for later: `AccountsService` (Core) depends directly on `EcosiaAuthenticationService` for renew-on-401. Left untouched in PR 1; a later API-service PR replaces it with an injected token-provider protocol (`accessToken` + `renewCredentialsIfNeeded()`) and wires `AccountsProviderWrapper`.
