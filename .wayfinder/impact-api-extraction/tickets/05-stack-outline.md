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
Dependencies: PR 2 needs PR 1. PR 3 is independent (only `AccountsService`) and can start from `main` any time, merging in either order. PR 4 needs PR 1 and should follow PR 2. PR 5 needs PR 1 and is easier after PR 2 and PR 4.

Status on `main`: PR 1 merged (ecosia/ios-browser#1339), PR 2 merged (ecosia/ios-browser#1365). PR 3 onward not started.

1. **Extract** (`-1-extract`): new files only: `AuthSessionProviderProtocol` + `EcosiaAuthSessionProvider` (`Account/Auth/`), `ImpactManager` (`UI/Account/Impact/`). `EcosiaAuthUIStateProvider` becomes a forwarding facade (forwards `objectWillChange`, computed property forwards, `impactManager:` init param defaulting from `accountsProvider:`). NotificationCenter, dedup flags, and both cache-clear sites unchanged. Gate: existing tests (`EcosiaAuthUIStateProviderImpactCacheTests`, `AuthTests`, homepage snapshots) pass with assertions untouched; test edits only mechanical (static hooks now on `ImpactManager`).
2. **Characterization tests** (`-2-tests`): test-only. Fake auth seam + mock `AccountsProviderProtocol` covering register-visit, in-flight account guard, refresh deferral, dedup ordering.
3. **API token seam** (`-3-api-token`): conformance-only (ticket 04). A Core protocol with `accessToken` + `renewCredentials()`, `extension EcosiaAuthenticationService: <protocol> {}`, and `AccountsService` storing the protocol type (default `.shared`). No behavior change. Adds an `AccountsServiceTests` case for 401 → renew → retry with a fake. `AccountsProviderWrapper` is already wired in `AppDelegate` (ecosia/ios-browser#1354) and is not part of this PR. A renew-on-401 no longer interacts with `ImpactManager`: its in-flight guard compares `userID`, not the access token, so the retried response is applied (ecosia/ios-browser#1366). The restructure plan's token gateway (its PR 1) later replaces this seam, so keep PR 3 conformance-only and small.
4. **Reactive channel** (`-4-reactive`): typed auth-event publisher replaces NotificationCenter for impact; `ImpactManager` subscribes directly, and the provider's `isLoggedIn` mirror updates from the same stream so the two copies move together (`levelProgress` combines both). Intended behavior change: one impact reaction per auth transition regardless of window count, including with no window registered. Cache clearing stays in `EcosiaAuthenticationService` (ticket 03), so `AuthTests` cache assertions stay untouched. `EcosiaAuthenticationService` is not `@MainActor` and `dispatchAuthStateChange` runs off main, so delivery hops to main. Event shape decided in ticket 06.
5. **Cleanup** (`-5-cleanup`): repoint `User.seedCount` at `ImpactManager`; mechanically move caches / seed manager / `ImpactSnapshot` out of `UI/`; split `ImpactManager` so its impact logic (register-visit, token guard, dedup flags, snapshot resolution, cache writes) leaves `UI/` while presentation (`withAnimation` timing, `balanceIncrement`, level-up trigger) stays in `UI/`. `hasRegisterVisitError` is the only error surface (no toast since ecosia/ios-browser#1354). Destination folder decided in ticket 07. Can be its own PR before the mechanical moves if the split is large.

Deferred beyond this map (see Out of scope): cache unification, which also moves cache clearing out of `EcosiaAuthenticationService`; migrating consumers from the facade to a `UserManager`.
