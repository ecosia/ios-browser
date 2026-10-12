---
title: The stacked PR chain, test strategy and bridge removal
type: grilling
status: closed
assignee: paul
blocked-by: []
---
## Question
Turn the decisions in tickets 01-08 into the ordered, stack-ready chain of PR-sized steps (step N depends only on 1..N-1; behaviour-preserving until the last few; each compiles and passes on iOS 15). For each step: scope, files touched, tests added/migrated (`AuthTests`, `AuthWorkflowTests`, `EcosiaAuthUIStateProviderImpactCacheTests`, `FileUploadServiceTests`, snapshot tests; fakes for `AuthSession`/`AccessTokenProvider`/`ImpactService`), and rollback story. Cover: introducing the gateway and single `CredentialsManager`, `AuthSession` snapshot with a `NotificationCenter` bridge, `WebSessionSync` extraction, `ImpactService` extraction, presenter migration, then bridge removal (`.EcosiaAuthStateChanged`, `.EcosiaUserProfileUpdated`, `EcosiaBrowserWindowAuthManager`, `TabAutoCloseManager` notification dependency) and deletion of `DataClearingIntegration`. Also decide where the rotation rollout checklist (leeway, dev/staging verification pass) sits relative to the chain.

Also: every step must satisfy the map's "Compatibility with released versions" section (persisted keychain/UserDefaults/cookie state from v12.6.0 stays readable; legacy `wasLoggedIn` and `LoggedInImpactCache.*` are read-and-migrated once). Each migration needs a test that seeds the v12.6.0 persisted shape.

## Resolution

Decided with Paul (all recommendations accepted).

| # | PR | Behaviour change |
|---|---|---|
| 1 | **Token gateway**: `AccessTokenProvider` actor over a single `CredentialsManager` (default store key); single-flight renew + SSO exchange; persists rotated tokens (no-op now); typed errors; `AccountsService`/`FileUploadService` use it; second `DefaultCredentialsManager` removed. | Renewal only when needed (was forced on every launch, 401 and upload) |
| 2 | **`AuthSession`**: snapshot, identity + credentials streams, claims from the ID token, sign-out reasons, persisted `lastKnownUserId`, one-time read of legacy `wasLoggedIn`. `EcosiaAuthenticationService` becomes a thin facade and still posts legacy notifications derived from the snapshot. | Offline launch stays signed in; no `/userinfo` |
| 3 | **Foreground refresh**: lifecycle observer feeds `refreshIfNeeded(trigger: .foreground)`. | Foreground refresh |
| 4 | **Impact storage**: cache keyed by `sub`, anonymous slot on the existing seed keys, one-time migration of the legacy unkeyed `LoggedInImpactCache.*` slot. Provider uses it. | None (migration only) |
| 5 | **`ImpactService`**: stateless helpers + stateful service reacting to identity stream, foreground, NTP appear; userId stale-response guard; `AccountsService` drops its token parameter; `EcosiaAuthUIStateProvider` slims down; `hasResolved...` machinery removed. | None intended |
| 6 | **`WebSessionSync` extraction**: invisible-tab handoff, cookie install/clear and the `EASC` upload bridge move over; tab completes by its own landing detection (no per-window notification). | None intended |
| 7 | **Reactive web sync** (behind one Unleash flag): foreground/identity reconcile, silent re-transfer replacing forced logout + re-login (loop-guarded), one 403 retry on uploads. | New web behaviours |
| 8 | **`UserManager` binding**: presenter binds snapshot + `ImpactService` state/events; views migrate; animation moves in unchanged; `refreshFailed` toast. | None |
| 9 | **Bridge and dead-code removal**: `EcosiaBrowserWindowAuthManager`, `EcosiaAuthWindowRegistry`, `.EcosiaAuthStateChanged`, `.EcosiaUserProfileUpdated`, `DataClearingIntegration`, the `EcosiaAuthenticationService` facade. | None |
| 10 | **Mechanical rename** to `UserManager`, singleton accessor tidy-up. | None |

- **Granularity:** ten steps; the migration-only step 4 ships alone so the riskiest persisted-state change gets its own review.
- **Kill switch:** one Unleash flag (pattern of `FileUploadFeatureFlag`) for step 7's new web behaviours only. Steps 1 and 2 change launch/renewal behaviour but are not flagged.
- **Migration code lifetime:** the one-time readers of legacy `wasLoggedIn` and the legacy impact slot stay at least two releases after steps 2/4 ship; removal is a follow-up outside the chain.
- **Rotation track:** separate, non-blocking. The dev/staging verification pass can start once step 1 merges; enabling rotation in production needs steps 1-3 released plus the gating decision (adoption threshold or forced update; a new Auth0 client id is ruled out). Checklist: set `leeway`, reuse error strings, SSO-exchange claims, scope-upscale behaviour, cascade revocation vs the web session.
- **Stack mechanics:** one PR per step, each targeting the previous, merged in order; works with native stacked PRs (availability unconfirmed) or plain stacked branches. Each PR carries the full 7-item checklist, with irrelevant items struck through.
- **Tests:** new fakes (credentials manager incl. SSO exchange, `AccessTokenProvider`, `AuthSession` on `CurrentValueSubject`, existing `CookieStoreProtocol` fake); seeded v12.6.0 persisted-state fixtures (keychain credentials, `wasLoggedIn`, unkeyed impact keys, local seed keys) for every migration test. `AuthTests`/`AuthWorkflowTests` move to step 2; `EcosiaAuthUIStateProviderImpactCacheTests` splits across 4, 5 and 8; `FileUploadServiceTests` to 1 and 7; `AuthStateManagerTests`, `AuthNotificationSystemTests`, `EcosiaAuthWindowRegistryTests` are deleted in 9; NTP snapshot tests change in 8 with no visual diff expected.

### Amendment (rotation deferred)

Rotation is deferred: step 1 no longer includes a shared slot or rotated-token persistence, and there is no separate rotation track in the plan. The "If rotation is ever enabled" note in `map.md`/`plan.md` replaces the rollout checklist and gating decision. Everything else in the chain is unchanged.
