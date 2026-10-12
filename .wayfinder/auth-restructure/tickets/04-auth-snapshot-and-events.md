---
title: Shape of the AuthSession snapshot and its change events
type: grilling
status: closed
assignee: paul
blocked-by: [01-id-token-claims]
---
## Question
Pin down the `AuthSession` public contract: the snapshot fields (status incl. unresolved, userId, claims, `credentialsVersion`, scopes), what counts as an *identity* change (different userId) vs a *credentials* change (token refresh), the error/degraded states (renewal failed but keychain creds exist, offline at launch), the triggers that re-resolve (launch, foreground, login/logout success, web-detected sign-out), and the exact public API (login/signUp/logout, token access via gateway, snapshot publisher) at iOS 15. Decide how logout and DataClearing-initiated logout appear in the snapshot.

## Resolution

Decided with Paul (grilling, all recommendations accepted). Minimum OS iOS 15: `ObservableObject` + Combine only.

1. **Status model.** `AuthSession.snapshot.status` is `unresolved | signedOut(reason) | signedIn`. It is decided by whether keychain credentials exist and aren't permanently invalid, not by whether a renewal just succeeded. Offline launch resolves to `signedIn` using the stored ID token's claims (today it resolves to logged out). Retryable renewal failures (network, 429, 5xx) never change `status`. Only permanent failures flip it to signed out: `invalid_grant` (incl. reuse), `access_denied`, `login_required`, `noCredentials`, `noRefreshToken`. The impact cache is cleared on `sessionExpired` and `userInitiated`; the reason replaces the persisted `wasLoggedIn` hack.
2. **Sign-out reasons.** `neverSignedIn`, `userInitiated`, `sessionExpired`, `webSignedOut`, `sessionTransferFailed`. No `dataCleared`: `DataClearingIntegration.handleEcosiaAuthCookieClearing()` has no callers, so the plan deletes it in the cleanup step.
3. **Snapshot contents.** `status`, `userId` (= `sub`), `claims` (`sub` required; `name`, `nickname`, `picture`, `email` optional, raw), `grantedScopes`, `credentialsVersion` (increments on every credentials change). Never tokens: those are only reachable via the gateway (ticket 05), so the snapshot is safe to log and publish. An empty/undecodable ID token keeps the last good claims. Email-as-name and Gravatar normalisation live in the presenter layer. `grantedScopes` keeps `hasConversationScopes` a synchronous read.
4. **Derived streams.** Besides the full snapshot (replays current value): an *identity stream* (emits on `userId`/sign-in change, de-duplicated; used by impact cache switching and web sync's "who is the web session for") and a *credentials stream* (emits on `credentialsVersion`; used by presenter name/avatar). An ordinary token refresh never retriggers `registerVisit`; the `previousIsLoggedIn != newIsLoggedIn` guard in `setupTokensWithCredentials` goes away.
5. **Resolve triggers.** `AuthSession` resolves from the keychain at init with no network call and exposes `refreshIfNeeded(trigger:)` with triggers `launch | foreground | loginSuccess | permanentFailure`. It refreshes only if the access token is expired or near expiry (replacing today's forced renewal on every launch, 401 and upload). One small lifecycle observer in the app target feeds `foreground`, so consumers don't each observe `UIApplication`/`UIScene`.
6. **Profile source.** `EcosiaUserProfileUpdated` and the `/userinfo` call go away; `userProfile` is derived from claims, which refresh whenever credentials renew. A web-side name change shows up within about an hour of the next app open (1 h access token). If that proves too slow, keep `/userinfo` as a foreground-only fetch.
7. **Isolation.** `AuthSession` is `@MainActor` with a synchronous `snapshot` property and `CurrentValueSubject` publishers. Non-main code (`FileUploadService`, `AccountsService`) never touches `AuthSession`; it goes through the `AccessTokenProvider` actor (ticket 05).

Not decided here (left to later tickets): the login/logout API's web-handoff orchestration (ticket 06), the gateway's failure semantics and persistence (ticket 05), how impact consumes the identity stream (ticket 07).
