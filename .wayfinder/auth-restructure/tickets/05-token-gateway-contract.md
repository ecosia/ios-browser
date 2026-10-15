---
title: AccessTokenProvider contract (single-flight, rotation-ready)
type: grilling
status: closed
assignee: paul
blocked-by: [02-rotation-and-sso-exchange, 04-auth-snapshot-and-events]
---
## Question
Define the `AccessTokenProvider` actor: API (`validAccessToken(requiringScopes:)`, SSO exchange), single-flight semantics, who persists rotated credentials, failure semantics (retry vs forced sign-out; what the snapshot shows), scope-refresh handling (`hasConversationScopes`), and what is deliberately left as a no-op today so enabling rotation needs only a config change.

## Resolution

Decided with Paul (recommendations accepted; "continue" taken as acceptance). iOS 15 floor: actor + async/await + Combine only.

1. **API.** One `AccessTokenProvider` actor behind a protocol (fakeable): `accessToken(minimumValidity: = 60s, requiringScopes: = [])` returns a small value (token, expiry, scopes); `sessionTransferToken()` returns the SSO exchange result. Nothing outside the gateway calls Auth0's SSO exchange. `EcosiaAuthenticationService.accessToken/idToken/refreshToken` and the public `renewCredentialsIfNeeded()` are removed. A still-valid cached token returns with no network call.
2. **One refresh-token operation at a time.** Renewal and SSO exchange share one in-flight slot (both consume the refresh token under rotation). Concurrent callers await the same task; an SSO exchange waits for an in-flight renewal and vice versa. This adds the coalescing Auth0.swift's `CredentialsManager` lacks.
3. **Persistence and ordering.** The gateway is the only keychain writer, wrapping a single `CredentialsManager` (the second, unused `DefaultCredentialsManager` is deleted). Credentials from renewal and from SSO exchange (refresh token and ID token, when present) are stored before the call returns; on the non-rotating tenant this is a no-op, so enabling rotation is only a config change. Login, logout and clear also go through the actor with a generation counter: a response arriving after a logout began is discarded, not stored.
4. **Errors.** Typed: `signedOut` (permanent; also tells `AuthSession` to flip to `signedOut(sessionExpired)` and clears the keychain), `temporarilyUnavailable` (network/429/5xx; tokens kept), `insufficientScope`, `storageFailure`. No retry loop in the gateway; callers fail their request and the next `refreshIfNeeded` trigger retries. Leeway for the iOS client (desktop uses 30 s) is a rotation-rollout config item, not a code step.
5. **Scopes.** Missing requested scopes throw `insufficientScope`; no silent upscale (assumption to verify: Auth0 refresh grants can only narrow the original grant, so the user must sign in again). The snapshot's `grantedScopes` lets the UI hide uploads meanwhile.
6. **401 handling.** `accessToken(rejecting: staleToken)` renews only if the gateway's current token is still the rejected one; otherwise it returns the already-renewed token. Simultaneous 401s cause one renewal. `AccountsService` and `FileUploadService` stop calling renew themselves.
7. **Ownership and events.** `AuthSession` owns the gateway. Login: `AuthSession` runs Auth0 web auth and hands the credentials to the gateway. The gateway emits "credentials changed" (new ID token, scopes, version bump) and "permanent failure" to `AuthSession`, which updates the snapshot and never holds tokens. `AuthSession.refreshIfNeeded(trigger:)` delegates to the gateway.

Left for later: the rotation rollout checklist (leeway, one verification pass on dev/staging covering reuse error strings, SSO-exchange ID-token claims, scope-upscale behaviour, cascade revocation effect on the web session).

### Amendment (rotation deferred)

Decided later: rotation is deferred. Drop from this contract the shared in-flight slot between renewal and SSO exchange (a per-operation single-flight is enough) and the persistence of refresh/ID tokens returned by renew and SSO exchange. Everything else stands, including routing the SSO exchange through the gateway, the single `CredentialsManager`, the generation counter, typed errors and `accessToken(rejecting:)`.
