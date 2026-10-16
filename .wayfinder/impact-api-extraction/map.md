---
label: wayfinder:map
---
# Map: Extract Impact API logic from Auth

## Destination

An ordered plan of PRs, each merged on its own, for separating impact (seeds / level / progress, impact API access, impact caches) from auth in `firefox-ios/Ecosia`. Each PR is specified well enough (scope, seams, behavior-preservation guarantee) to hand to an implementer. The map plans only; it implements nothing.

## Notes

- Tracker: local markdown in `.wayfinder/impact-api-extraction/`. Tickets live in `tickets/`; blocking via `blocked-by:` frontmatter; claim via `claimed:` frontmatter.
- "core" = `firefox-ios/Ecosia/Core/` (same Ecosia framework), not a separate package. `Core/Accounts/AccountsProvider` + `AccountsService` already hold the pure `registerVisit(accessToken:)` call.
- Coupling today lives in `EcosiaAuthUIStateProvider` (UI/Account): impact `@Published` state, animations, register-visit, token-changed guard, cache writes, and direct reads of `EcosiaAuthenticationService.shared`. `EcosiaAuthenticationService` also clears `LoggedInImpactCache`.
- Two caches: `LoggedInImpactCache` (server snapshot, UserDefaults) and `UserDefaultsSeedProgressManager` (local, logged-out).
- Agreed direction: PR 1 is a behavior-preserving extraction (new impact class, auth injected via protocol backed by a thin wrapper around `EcosiaAuthenticationService.shared`, `EcosiaAuthUIStateProvider` stays as a forwarding facade, NotificationCenter stays). the reactive PR (PR 4 in the final stack) swaps NotificationCenter for a typed reactive stream. Cache unification comes after, only once ownership is clear.
- Prior art: branch `pq-mob-4236-logged-in-seed-cache` (PR 1281, closed, not on main) introduced a static `ImpactManager` and a single user-id-keyed cache. It is a candidate to mine, not a given base.
- Sizing principle: PRs must be small and digestible for review, especially the first few. This outranks architectural purity (e.g. DI everywhere).
- Repo rules: read `firefox-ios/Ecosia/Ecosia.docc/agents/*.md`; no Sentry logging; Ecosia-owned files vs Firefox core commenting conventions.

## Decisions so far

- [01-stack-base](tickets/01-stack-base.md): fresh stack off `origin/main`; 4236 is reference only; statics are fine, DI only where it pays; small reviewable PRs, merge only with consent.
- [02-call-site-inventory](tickets/02-call-site-inventory.md): seven `.shared` consumers; `User.seedCount` in Core reads the UI-layer provider; the cache is cleared in two places (service + provider); `AccountsProviderWrapper` is not wired in on this branch; only one test covers the provider directly.

- [03-auth-seam](tickets/03-auth-seam.md): 3-member read-only auth protocol + default wrapper over the shared service; cache clearing and notifications stay as-is in PR 1; ownership flips in the reactive PR (4); `User.seedCount` left for a follow-up.
- [04-names-and-homes](tickets/04-names-and-homes.md): keep Accounts* in Core; instance `ImpactManager` (ObservableObject, forwarded by the provider); new files only in PR 1; `AuthSessionProviderProtocol` + `EcosiaAuthSessionProvider`; no new singleton; `AccountsService` auth decoupling is its own later PR.
- [05-stack-outline](tickets/05-stack-outline.md): five-PR stack: extract, characterization tests, API token seam, reactive channel, cleanup (incl. splitting `ImpactManager` into logic outside `UI/` and presentation in `UI/`); PR 1 gate is existing tests green with mechanical edits only; PRs merge one at a time off `main` (squash-only repo), PR 3 is independent; branches `pq-impact-<slug>`, no ticket.
- [06-reactive-event-shape](tickets/06-reactive-event-shape.md): one emission per transition from the auth service; Combine `authEvents` on the seam; `.loggedIn` / `.loggedOut` / `.stateResolved(isLoggedIn:previousSessionExpired:)`; impact clears its own cache; dedup flags kept verbatim; no replay; profile and seed-progress notifications unchanged.

## Not yet specified

- Whether the Core API layer should widen beyond `registerVisit` (e.g. balance endpoint); only matters if it happens.

## Out of scope

- Implementing any of the PRs.
- Changing impact behavior, backend contracts, or UI.
- Cache unification (logged-out local progress + logged-in server snapshot into one store; reference: 4236 user-id-keyed cache). Own effort after PR 5, since it needs the extraction in place.
- Migrating consumers off the facade to a `UserManager` composing auth + impact. Own effort after PR 5.
