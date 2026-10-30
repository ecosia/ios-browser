---
type: wayfinder:grilling
status: closed
blocked-by: []
claimed:
---
## Question
Final PR stack: the ordered list, each PR's scope and "done" criteria, the behavior-preservation check for PR 1 (tests that must stay green unchanged), what is deferred to the fog, and how branches stack (base/naming).

## Resolution

Sequence, merged one at a time (not a true stack): each PR branches fresh from `main` once the PRs it depends on have merged, targets `main`, and merges on its own, only with explicit consent. Why: the repo allows squash merges only and deletes branches on merge, so stacked children would need `rebase --onto main` and a force-push after every parent merge. A PR may open early as a draft against its parent's branch, then rebase onto `main` after the parent lands. PR template verbatim.
Branches: `pq-impact-<slug>`, with no ticket (none exists for this work). Avoid `<letters>-<digits>` in the name, or the `prepare-commit-msg` hook prefixes commits with it as a fake ticket. PR 1 is `pq-impact-extract-manager` (ecosia/ios-browser#1339).
Dependencies: PR 2 needs PR 1. PR 3 is independent (only `AccountsService` / `AccountsProviderWrapper`) and can start from `main` any time, merging in either order. PR 4 needs PR 1 and should follow PR 2. PR 5 needs PR 1 and is easier after PR 2 and PR 4.

1. **Extract** (`-1-extract`): new files only: `AuthSessionProviderProtocol` + `EcosiaAuthSessionProvider` (`Account/Auth/`), `ImpactManager` (`UI/Account/Impact/`). `EcosiaAuthUIStateProvider` becomes a forwarding facade (forwards `objectWillChange`, computed property forwards, `impactManager:` init param defaulting from `accountsProvider:`). NotificationCenter, dedup flags, and both cache-clear sites unchanged. Gate: existing tests (`EcosiaAuthUIStateProviderImpactCacheTests`, `AuthTests`, homepage snapshots) pass with assertions untouched; test edits only mechanical (static hooks now on `ImpactManager`).
2. **Characterization tests** (`-2-tests`): test-only. Fake auth seam + mock `AccountsProviderProtocol` covering register-visit, token-changed guard, refresh deferral, dedup ordering.
3. **API token seam** (`-3-api-token`): `AccountsService` replaces direct `EcosiaAuthenticationService` use (renew-on-401) with an injected token-provider protocol (`accessToken` + `renewCredentialsIfNeeded()`); wire `AccountsProviderWrapper` so debug error simulation works.
4. **Reactive channel** (`-4-reactive`): typed auth-event publisher replaces NotificationCenter for impact; cache-clear ownership moves out of `EcosiaAuthenticationService` (including `wasLoggedIn` expired-token case); closes the "no window registered" gap. Event shape decided in ticket 06.
5. **Cleanup** (`-5-cleanup`): repoint `User.seedCount` at `ImpactManager`; mechanically move caches / seed manager / `ImpactSnapshot` out of `UI/`; split `ImpactManager` so its impact logic (register-visit, token guard, dedup flags, snapshot resolution, cache writes) leaves `UI/` while presentation (`withAnimation` timing, `balanceIncrement`, error toast, level-up trigger) stays in `UI/`. Destination folder decided in ticket 07. Can be its own PR before the mechanical moves if the split is large.

Deferred beyond this map (see Out of scope): cache unification; migrating consumers from the facade to a `UserManager`.
