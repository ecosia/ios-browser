---
label: wayfinder:map
title: Restructure native auth, web session sync and impact API
---

## Destination

A reviewed, decision-complete **migration plan**: the target architecture plus an ordered chain of PR-sized steps (stacked PRs / stacked branches; step N depends only on steps 1..N-1; each step ships behaviour-preserving until the last few). Nothing is implemented in this effort.

## Notes

- Repo: Ecosia iOS Browser (Firefox iOS fork). Read `firefox-ios/Ecosia/Ecosia.docc/agents/*.md` (ARCHITECTURE, SWIFT, TESTING, TUIST) before deciding anything touching code conventions.
- **Minimum OS is iOS 15.** No `@Observable`/Observation, no `Task.sleep(for:)`, no iOS 16+/17+ SwiftUI/Foundation APIs without `#available`. Presenters stay `ObservableObject`/`@Published`. Raising the minimum is out of scope.
- **Native is the source of truth for auth.** The webview session (EASC cookie, Auth0 SSO cookies) must be kept in sync *from* native.
- **Auth and Impact API logic are separate.** Impact depends only on "current user id + a token provider".
- **Reactive:** Combine `CurrentValueSubject` snapshot, replayed on subscribe; `NotificationCenter` is only a temporary bridge removed in the last step. Impact refresh reacts to login success, app foreground, credential/identity change.
- **Refresh-token rotation is deferred.** Not designed for or scheduled here (see "If rotation is ever enabled").
- Standing preferences: never add Sentry (`.sentry`) logging or touch Sentry forwarding; comments and PR text describe the final design, not the decision trail; the PR checklist is the full list on every PR.
- Tracker: local-markdown (no tracker doc configured). Tickets are in `tickets/`.

## Settled up front (grilling round 1)

- Plan starts from `main`; the `pq-mob-4236` / `pq-mob-4894-impact-manager` branches are *input* to the impact step, not a prerequisite.
- Layers (each depends only on the one above): `AuthSession` (native truth: Auth0, keychain credentials, claims, token lifecycle) → `WebSessionSync` (session-transfer token, invisible tab, EASC/Auth0 cookie clearing, reconciliation) → `ImpactService` (impact API, cache, local seeds; no Auth0 knowledge) → UI presenters (thin `ObservableObject`s composing auth + impact).
- One app-wide immutable auth snapshot (`status` unresolved/signedOut/signedIn, userId, claims, `credentialsVersion`) published via Combine; replaces `hasResolvedAuthState`/`hasHandledCurrentResolution`-style workarounds.
- Per-window `EcosiaBrowserWindowAuthManager` state goes away; the invisible-tab flow awaits its result directly.
- Single `AccessTokenProvider` actor with single-flight renewal; nobody reads `accessToken` or calls renew directly; SSO exchange goes through it.
- Claims (userId, name, picture, email) come from decoding the ID token locally on every credentials change; `/userinfo` only as fallback (subject to ticket: ID token claims research).

## Compatibility with released versions

Production is **v12.6.0** (tag `v_12.6.0_3386`, 2026-09-24). It already persists: Auth0 credentials in the keychain (default `CredentialsManager` store key `credentials`), `EcosiaAuthenticationService.wasLoggedIn` and the unkeyed `LoggedInImpactCache.*` keys (both shipped in 12.6.0 via MOB-4236), local seeds (`TotalSeedsCollected`, `CurrentLevel`, `LastAppOpenDate`), and the `EASC`/Auth0-domain cookies in the shared `WKWebsiteDataStore` plus an `EASC` copy in `HTTPCookieStorage.shared`. Every step must keep these readable:

- **Keychain credentials: compatible, by constraint.** The gateway wraps a single `CredentialsManager` with the default store key/service and no new access group. Stored ID-token claims are decoded without validating `exp`, since a launch may hold an expired token.
- **`wasLoggedIn`: read once, then removed.** On first run, empty keychain plus legacy `wasLoggedIn == true` resolves to `signedOut(sessionExpired)`.
- **Unkeyed `LoggedInImpactCache.*`: migrate, don't drop** (amends ticket 07 item 2). The slot belongs to whoever is currently signed in, because old code cleared it on logout and expiry. On first run, copy it into the signed-in user's keyed slot, then delete it. If the user id isn't known yet (no persisted `lastKnownUserId`), the first frame reads the legacy slot directly. Dropping it would regress the flicker fix 12.6.0 just shipped, once, for every signed-in user.
- **Local seed keys: stay as the anonymous slot.** Do not adopt the `pq-mob-4894-impact-manager` branch's new storage keys for guests, or guests would lose their seeds. If keys must change, migrate them once.
- **Cookies: compatible.** The new foreground reconcile is a no-op for users with an `EASC`. Users whose native session is live but `EASC` is gone get one silent re-transfer on first foreground. That is new behaviour: the plan must cover it with a test.
- **Downgrade:** the keyed cache is unknown to older builds, and the legacy slot is deleted on migration, so a downgraded build shows the one-off flicker. Accepted.
- **Refresh behaviour:** old builds renew on every launch, which also resets the refresh token's 14-day idle window. The new behaviour renews only when the access token is near expiry. Any app open after the access token expires still renews, so the idle window effectively still slides.
- **No server/API contract changes** in any step (`registerVisit`, presign, session transfer unchanged).

## If rotation is ever enabled (not part of this plan)

Deferred by Paul: this effort neither designs for nor schedules refresh-token rotation. Enabling it later is its own piece of work, with these facts to start from:
- It is a per-client Auth0 setting, so it affects every installed version at once. Builds up to 12.6.0 call `ssoExchange` at sign-in and discard the rotated refresh token it returns; the next renewal after the `leeway` would then look like reuse and revoke the token family (inferred, never run against a rotating tenant; verify with a 12.6.0 build on dev first).
- On the new gateway the change is one focused PR: share one in-flight slot between renewal and SSO exchange, persist the refresh and ID tokens those calls return, and set a `leeway` (the desktop client uses 30 s). The gateway being the only user of the refresh token is what keeps that small.
- A new Auth0 client id for new builds is ruled out. Gating options left: an adoption threshold or a forced update.
- Research detail: `tickets/02-rotation-and-sso-exchange.md`.

## Decisions so far

<!-- one line per closed ticket -->
- [Refresh-token rotation, SSO exchange and concurrent renewal behaviour](tickets/02-rotation-and-sso-exchange.md): `ssoExchange` consumes and rotates the refresh token but `getSSOCredentials()` discards the new one, which would trip reuse detection and revoke the family (rotation blocker); `CredentialsManager` serializes per instance but doesn't coalesce, and the app has two instances; `renewCredentialsIfNeeded()` forces a renew on every call; failures split into force-sign-out vs retry; unverified until tried on dev/staging.
- [Web session (EASC) lifetime and how native can detect it is gone](tickets/03-web-session-lifetime.md): web refresh only happens when a web request hits accounts/nxt (no background refresh), so EASC can hold an expired access token; native refresh tokens (14d idle/30d abs) die sooner than web's (30d/90d); no whoami endpoint, EASC presence is a one-sided signal; recommend native-driven reconcile on foreground/credentials change and a silent re-transfer instead of logout+relogin on web sign-in interception; AI worker auths from the access token inside EASC (stale EASC → 403, no Bearer support yet, so the EASC dependency stays unresolved); `DataClearingIntegration.handleEcosiaAuthCookieClearing()` has no callers; cascade-revocation is off in prod (core doc stale).
- [Which claims does the Auth0 ID token carry?](tickets/01-id-token-claims.md): `sub` is always present and is the Ecosia user id (treat only it as required; `name`, `nickname`, `picture`, `email` optional, `/userinfo` or the access token's `sub` as fallback); claims are refreshed on renewal but an empty/undecodable ID token must keep the last good claims; `ssoExchange` also overwrites the stored ID token; gotchas: `is_sign_up` sticks until next login, `name` is often the email, email/password users get a Gravatar picture iOS shows but web filters, web name changes lag native until renewal; per-provider presence and `ssoExchange` claims unverified (needs a real-token check).
- [Shape of the AuthSession snapshot and its change events](tickets/04-auth-snapshot-and-events.md): `@MainActor` `AuthSession` publishes an immutable snapshot (status `unresolved|signedOut(reason)|signedIn`, `userId`, raw claims, `grantedScopes`, `credentialsVersion`, never tokens) plus identity and credentials streams; status follows keychain presence so offline launch stays signed in, only permanent failures sign out; sign-out reasons replace `wasLoggedIn`; refresh only when expired/near expiry via `refreshIfNeeded(trigger:)` fed by one lifecycle observer; `/userinfo` and `EcosiaUserProfileUpdated` dropped; `DataClearingIntegration` deleted.
- [AccessTokenProvider contract (single-flight)](tickets/05-token-gateway-contract.md): one actor owns all refresh-token use (renewal and SSO exchange both go through it), is the only keychain writer over a single `CredentialsManager` with a generation counter, takes `accessToken(minimumValidity:requiringScopes:)` and `accessToken(rejecting:)` so concurrent 401s cause one renewal, throws typed errors (`signedOut`, `temporarilyUnavailable`, `insufficientScope`, `storageFailure`) with no internal retries (amended: no shared slot and no rotated-token persistence, since rotation is deferred), and emits credentials-changed / permanent-failure events to `AuthSession`, which owns it.
- [WebSessionSync triggers and reconciliation policy](tickets/06-web-session-sync-policy.md): invisible tab stays; one app-wide single-flight reconcile, awaited on login and run in the background on identity change/foreground; native signed in + no `EASC` re-transfers silently, native signed out clears web cookies; web sign-in interception becomes a loop-guarded silent re-transfer (no forced logout/re-login); user logout loads the logout URL, web-initiated sign-out skips it; login transfer failure signs native out, background failure only marks out-of-sync; `EASC`-for-uploads bridge moves into `WebSessionSync` with one 403 re-transfer retry; hosted by the triggering/foreground window.
- [ImpactService boundary and reactions to auth](tickets/07-impact-service-boundary.md): keep the `ImpactManager` branch's stateless helpers under a thin stateful `ImpactService` (no UI; publishes `ImpactState` + events); cache keyed by `sub` with an anonymous slot (existing local-seed keys), cleared per user on `userInitiated`/`sessionExpired`, legacy unkeyed slot migrated once (see Compatibility); reacts to the identity stream, foreground and NTP appear via a coalescing `refresh(trigger:)`; token from the gateway and a userId-captured stale-response guard instead of token comparison; errors published, toast and animation stay in the presenter.
- [Presenter layer: UserManager vs slimmed EcosiaAuthUIStateProvider](tickets/08-presenter-layer.md): `UserManager` (`@MainActor` `ObservableObject`) is a pure presenter binding the snapshot, `ImpactService` state and events via Combine, with synchronous first-frame init; views keep today's property names (rename only, final mechanical step); display behaviour unchanged; animation and debug hooks move over verbatim; one composition function with `.shared` kept as a thin accessor; a `refreshFailed` event drives the toast once per failed refresh.
- [The stacked PR chain, test strategy and bridge removal](tickets/09-pr-chain-and-tests.md): ten linear PR steps (token gateway, `AuthSession`, foreground refresh, impact storage migration, `ImpactService`, `WebSessionSync` extraction, reactive web sync behind one Unleash flag, `UserManager` binding, bridge/dead-code removal, rename); migration readers kept 2+ releases; rotation is deferred and not part of the chain; one PR per step, full checklist, fakes plus seeded v12.6.0 fixtures.

## Not yet specified

## Out of scope

- Implementing any step (plan only).
- Refresh-token rotation: neither enabled nor designed for in this effort (deferred; see "If rotation is ever enabled").
- Raising the minimum iOS version (plan targets iOS 15; tracked separately).
- Any Sentry logging changes.
- A new Auth0 client id for new builds (ruled out by Paul: too costly; it would also force re-login or dual-client support). 
