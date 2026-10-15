---
title: ImpactService boundary and reactions to auth
type: grilling
status: closed
assignee: paul
blocked-by: [04-auth-snapshot-and-events]
---
## Question
Define `ImpactService`: its dependencies (token provider + user id only), the inputs it reacts to (snapshot identity change, login success, app foreground/NTP appear, logout), the cache keyed by user id (incl. the `anonymous_user`/local-seed path from `pq-mob-4236`/`pq-mob-4894-impact-manager`), who owns animation/`@Published` state, how `registerVisit` 401 handling uses the gateway instead of renewing itself, and what the provider/presenter keeps. Decide how much of the earlier `ImpactManager` shape is reused.

## Resolution

Decided with Paul (all recommendations accepted). iOS 15 floor.

1. **Shape.** Keep the `pq-mob-4894-impact-manager` branch's stateless decision/persistence helpers (snapshot building, level/seed rules, keyed cache) and add a thin stateful `ImpactService` on top: not an `ObservableObject`, no UI knowledge. Injected: token gateway, accounts provider, cache, local seeds, `AuthSession`'s identity stream. Publishes a plain `ImpactState` (seeds, level, progress, `lastError`) and an event stream (`balanceIncreased(by:)`, `levelUp(level)`).
2. **Cache keyed by user id.** One store keyed by `sub` with an anonymous slot for guests (branch design). Identity change switches the key, giving instant correct numbers, replacing the single logged-in slot wiped on logout. A user's slot is still cleared on `userInitiated` and `sessionExpired` (ticket 04), so a signed-out device holds no account numbers. Old unkeyed `LoggedInImpactCache.*` keys are dropped without migration; the anonymous slot keeps reading the existing local-seed keys so existing guests lose nothing.
3. **Reactions.** Identity stream: switch to that user's cached snapshot immediately, then signed-in runs `registerVisit`, signed-out runs the daily local-seed collection. Foreground and NTP appear both call `refresh(trigger:)`; concurrent calls for one user coalesce into one request; no time-based throttle (behaviour matches today). While `status` is `unresolved` the service defers refresh; the first frame renders from a persisted `lastKnownUserId`. `hasResolvedAuthState`, `pendingSeedStateRefresh` and `hasHandledCurrentResolution` go away.
4. **Tokens and stale-response guard.** `registerVisit` takes no token parameter; it gets one from the gateway (`accessToken(rejecting:)` on 401) and `AccountsProvider`/`AccountsService` stop renewing themselves. The in-flight guard compares the `userId` captured before the request with the current identity, not access tokens (tokens legitimately change on refresh).
5. **Errors.** The service publishes `lastError` (replacing `hasRegisterVisitError`) and retries on the next trigger. The register-visit error toast moves to the presenter/`BrowserViewController` layer. A gateway `signedOut` is handled by `AuthSession`, not the service.
6. **Animation.** Balance-increment timing (`asyncAfter`, temporary `balanceIncrement`, `withAnimation`) and the level-up sparkle stay in the presenter; the service only emits events. `EcosiaAccountNotificationCenter.postLevelUp` remains presenter-owned until the presenter-layer step. `User.swift`'s read of `EcosiaAuthUIStateProvider.shared.seedCount` moves to the service's state.

### Amendment (compatibility review against v12.6.0)

Item 2 changes: the old unkeyed `LoggedInImpactCache.*` keys are **migrated once** into the signed-in user's keyed slot (then deleted), not dropped; if no `lastKnownUserId` exists yet, the first frame reads the legacy slot directly. The anonymous slot must keep the existing local-seed keys (`TotalSeedsCollected`, `CurrentLevel`, `LastAppOpenDate`); the branch's new guest storage keys are not adopted. See the map's "Compatibility with released versions".
