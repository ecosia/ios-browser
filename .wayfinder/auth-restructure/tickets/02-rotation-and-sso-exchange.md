---
title: Refresh-token rotation, SSO exchange and concurrent renewal behaviour
type: research
status: closed
blocked-by: []
---
## Question
When refresh-token rotation is enabled on the Auth0 tenant for the iOS client: (a) does `ssoExchange(withRefreshToken:)` (native-to-web SSO) consume/rotate the refresh token or return a new one, and does Auth0.swift surface it? (b) What are the reuse-detection and leeway/overlap semantics, and what happens when two renewals race with the same refresh token? (c) Does Auth0.swift's `CredentialsManager` (the version in `firefox-ios/SourcePackages/checkouts/Auth0.swift`) serialize concurrent `credentials()`/`renew()` calls and persist the rotated token atomically, or must we do it ourselves? (d) Which failure modes require a forced sign-out vs a retry? Sources: Auth0 docs, the SDK source in the checkout, the platform repo's `clients.tf` for the current iOS client config, and current iOS callers (`EcosiaAuthenticationService`, `AccountsService`, `FileUploadService`, `NativeToWebSSOAuth0Provider`, `DefaultCredentialsManager`).

## Resolution

Versions: Auth0.swift **2.15.1** (checkout; `Package.resolved` rev 259b5d5). Platform repo read at `origin/main`. Rotation is currently **off** for the iOS client in all three environments, so everything below about tenant behaviour comes from Auth0 docs and the SDK source, not from observed behaviour (see Uncertainties).

### Answers

**(a) SSO exchange under rotation.** Yes: `ssoExchange(withRefreshToken:)` is a `grant_type=refresh_token` call to `/oauth/token` with `audience=urn:<auth0-host>:session_transfer`, so with rotation on it consumes the presented refresh token and returns a new one. Auth0.swift surfaces it as `SSOCredentials.refreshToken` (optional; non-nil only when rotation is enabled). The caller must persist it replacing the old one. `CredentialsManager.ssoCredentials()` does this automatically; the raw Authentication API call does not.
**Current app gap:** `NativeToWebSSOAuth0Provider.getSSOCredentials()` calls the raw Authentication API and returns the `SSOCredentials` without storing `refreshToken`. Under rotation that silently orphans the stored token (the keychain still holds the now-invalidated old one) and the next `credentials()`/`renew()` presents a used token, which is reuse. This is the single change that makes rotation unsafe today.

**(b) Reuse detection, leeway, races.**
- Each exchange returns a new RT and invalidates the presented one. Presenting an already-invalidated RT (after leeway) is "reuse": Auth0 revokes the newest RT too and every RT in the same family/grant; all further exchanges are denied until the user re-authenticates (no recovery by retrying).
- Leeway (Dashboard: "Rotation Overlap Period"; API/Terraform: `refresh_token.leeway`, seconds, off by default) lets the *immediately previous* RT be presented again within N seconds without triggering reuse; only the previous token qualifies, the second-to-last triggers reuse. Intended for lost responses and racing requests.
- Two renewals racing with the same RT: within leeway both succeed, each returning its own new RT, so whichever response the app persists last wins and the other new RT is orphaned (an unpredictable outcome the app should avoid by never racing); beyond leeway (or leeway 0, the iOS client's current effective value as nothing is set in `clients.tf`) the second is treated as reuse and the family is revoked, so the user is signed out. Absolute lifetime does not extend on rotation (30 days for iOS client).
- Precedent in this org: `ecosia_browser` (desktop) is `rotating` with `leeway = 30`; `conversation_store_admin_cli` rotating, leeway 0.

**(c) Does `CredentialsManager` serialize and persist atomically?** Partly. In 2.15.1 `credentials()`, `renew()`, `apiCredentials()`, `ssoCredentials()` each run through one private serial `DispatchQueue` per manager (`CredentialsManager.swift:32`, `retrieveCredentials` at ~632, SSO at ~692) and hold the queue until the network call and keychain `store` finish (via `DispatchGroup.wait`), so concurrent calls on the *same instance* run strictly one after another and each reads the latest stored RT. On success it stores `credentials.refreshToken ?? oldRefreshToken`, so a rotated RT is persisted by the SDK. Limits we must handle ourselves:
 1. Serialization is per instance (SDK doc: "cannot synchronize requests across instances"). Not single-flight: N queued callers = N sequential exchanges (N rotations), not one shared result.
 2. `store(credentials:)`/`clear()` are not on the queue ("not thread-safe"). A `clear()` (logout) during an in-flight renew gets overwritten when the renew stores its result, resurrecting the session; likewise `store` after login can race a renew.
 3. Not crash-atomic across the server rotation and keychain write: lost response, process kill, or `.storeFailed` after the server rotated leaves us holding the old RT. Only leeway covers this. The SDK does no retry.
 4. `ssoCredentials()` exists on the SDK manager but is not exposed by our `CredentialsManagerProtocol`/`DefaultCredentialsManager`.
 5. Keychain accessibility is `.afterFirstUnlock` (SimpleKeychain default), fine for background renewals.

**(d) Sign-out vs retry (derived from SDK error model + Auth0 docs).** `CredentialsManagerError` wraps the cause; inspect `cause as? AuthenticationError`.
- **Force sign-out (clear credentials + web session):** `noCredentials`; `noRefreshToken`; `renewFailed`/`ssoExchangeFailed` whose cause is `AuthenticationError` with `code == "invalid_grant"` (covers `isInvalidRefreshToken` "Unknown or invalid refresh token.", `isRefreshTokenDeleted`, and rotation reuse "Unsuccessful Refresh Token exchange, reused refresh token detected" which has no dedicated SDK flag); `access_denied` (`isAccessDenied`); `login_required`. Under reuse the whole family is dead, so a retry can never succeed.
- **Retry / keep signed in:** `AuthenticationError.isNetworkError` (URLError offline/timeout/connection lost, etc.), HTTP 429 / `too_many_attempts`, 5xx, cancellation. Retry with the *same stored* RT (valid within leeway after a lost response); back off.
- **Retry, then escalate:** `storeFailed` (server may already have rotated; rely on leeway, re-read keychain, do not sign out on first occurrence).
- **Not expected for this client:** `largeMinTTL` (we pass no `minTTL`), `biometricsFailed`, MFA codes; treat as non-terminal errors.
- **Current behaviour differs:** `EcosiaAuthenticationService.retrieveStoredCredentials()` treats *any* `credentials()` failure (including offline) as logged out and does not clear keychain; `renewCredentialsIfNeeded()` throws `credentialsRenewalFailed` for all causes, and callers (`AccountsService`, `FileUploadService`) map every failure to `authenticationRequired` without classification.

### Evidence

Auth0 docs (fetched pages, content summarised by the fetch tool; re-verify exact wording before quoting externally):
- Rotation and reuse detection: https://auth0.com/docs/secure/tokens/refresh-tokens/refresh-token-rotation
- Configure rotation, overlap/leeway, effect of enabling, 30d default / 1y max absolute lifetime not extended by rotation: https://auth0.com/docs/secure/tokens/refresh-tokens/configure-refresh-token-rotation
- Session transfer exchange (`/oauth/token`, audience `urn:TENANT:session_transfer`, `access_token` = session transfer token, token single-use, 60 s; "Rotation enabled: Auth0 returns a new refresh token in the exchange response"; device binding `ip|asn|none`; cascade revocation): https://auth0.com/docs/authenticate/single-sign-on/native-to-web/configure-implement-native-to-web (overview: .../native-to-web)

Auth0.swift 2.15.1 (`firefox-ios/SourcePackages/checkouts/Auth0.swift`):
- `Auth0/SSOCredentials.swift`: `refreshToken` doc "Rotated refresh token... make sure to store this new refresh token replacing the previous one".
- `Auth0/Auth0Authentication.swift:441-447` `ssoExchange` (refresh_token grant, session_transfer audience); `:449-475` `renew`.
- `Auth0/CredentialsManager.swift`: thread-safety warning L14-21; serial queue L32; `retrieveCredentials(scope:...forceRenewal:)` ~L632-690 (stores `credentials.refreshToken ?? refreshToken`; `storeFailed` path); `retrieveSSOCredentials` ~L692-737 (stores rotated RT via `ssoCredentials.refreshToken ?? refreshToken`); `renew()` L602 = `forceRenewal: true`; docs L305-340/L557-575 "do not call from multiple Credentials Manager instances".
- `Documentation.docc/RefreshTokens.md`: reuse error text, "typically a symptom of concurrency issues in your app", causes = multiple CredentialsManager instances; using the Authentication API `renew()` alongside the manager.
- `EXAMPLES.md` ~L1486-1488: with rotation "you should store the new refresh token"; "If you're using the Credentials Manager... use its `ssoCredentials()` method... whereas this method [raw API] is not [thread-safe]".
- `Auth0/AuthenticationError.swift` (`isInvalidRefreshToken`, `isRefreshTokenDeleted`, `isAccessDenied`, `isLoginRequired`), `Auth0/Auth0APIError.swift:38-60,95-108` (`isNetworkError`), `Auth0/CredentialsManagerError.swift`.
- `SimpleKeychain` default accessibility `.afterFirstUnlock`.

Platform repo (`origin/main:infrastructure/auth0/{dev,staging,prod}/clients.tf`, resource `ecosia_ios_browser`; identical across envs except noted): `rotation_type = "non-rotating"`, no `leeway` attribute, `expiration_type = "expiring"`, `idle_token_lifetime = 1209600` (14d), `token_lifetime = 2592000` (30d), `grant_types = [authorization_code, refresh_token]`, `session_transfer { can_create_session_transfer_token = true, enforce_device_binding = "ip", enforce_cascade_revocation = false }` (true in **dev**, false in staging/prod), scopes include `offline_access`. Other clients: `ecosia_browser` rotating, leeway 30 (prod L226-232); `ecosia_android_browser` non-rotating.

iOS callers:
- `Ecosia/Account/Auth/CredentialsManager/DefaultCredentialsManager.swift`: wraps one SDK `CredentialsManager`; no `ssoCredentials()`.
- `Ecosia/Account/Auth/NativeToWebSSOAuth0Provider.swift:20-28`: init builds its **own** `DefaultCredentialsManager` instance; `getSSOCredentials()` (~L83-98) reads RT via `credentials()`, then raw `Auth0.authentication(...).ssoExchange(...)` and discards `refreshToken`.
- `Ecosia/Account/Auth/EcosiaAuthenticationService.swift:25` static `defaultCredentialsManager` (a second instance, referenced only by the protocol-extension default which the provider's stored property shadows, so effectively unused); `:94` shared service uses `NativeToWebSSOAuth0Provider()`; `:250-271` launch does `credentials()` (renews if expired) then immediately `renewCredentialsIfNeeded()`; `:278-292` `renewCredentialsIfNeeded()` calls `renew()` = **forced** exchange every time (name is misleading); `:358-367` `getSessionTransferToken()`.
- `Ecosia/Account/Auth/Auth0ProviderProtocol.swift:~110` `renewCredentials()` -> `credentialsManager.renew()`.
- Forced-renew callers: `Ecosia/Core/Accounts/Service/AccountsService.swift:35-47` (on 401), `Ecosia/Core/FileUpload/FileUploadService.swift:184-194` (`validAccessToken()` on every upload batch), `Client/Ecosia/Account/Auth/EcosiaAuth.swift:263`.
- SSO caller: `Client/Ecosia/Account/Auth/EcosiaAuthFlow.swift:223` -> `InvisibleTabSession.installSessionCookie`.

### Uncertainties
- No empirical run: rotation is not enabled for the iOS client in any tenant, so exact error strings/HTTP codes for reuse, the effective behaviour of an unset `leeway` (Terraform provider default vs Auth0 default), and whether the first rotation (migration of existing non-rotating RTs on the first exchange, per Auth0 "enabling rotation" notes) behaves as documented should be verified once on dev/staging before prod.
- The Auth0 doc pages were read through a summarising fetch; the refresh-token-rotation page did not itself mention leeway, which comes from the configure page. Maximum leeway value not stated in what was retrieved.
- Auth0 docs retrieved do not state explicitly whether idle lifetime resets per rotation, nor the exact interaction of cascade revocation (`enforce_cascade_revocation`, true on dev) with reuse-triggered family revocation (would likely also tear down the web session on dev); not confirmed.
- One doc line (Native to Web SSO page) says RTs from a prior session transfer transaction don't yield new session transfer tokens; relevance to our flow unclear, worth a staging check.
- Which of the two `DefaultCredentialsManager` instances other code (tests, debug settings) touches was not exhaustively traced; production path uses the provider's instance only.
- Auth0 reuse-error `error_description` and the SDK's `isInvalidRefreshToken` string match ("Unknown or invalid refresh token.") may or may not apply to the reuse case; classifying on `invalid_grant` is the safer rule.
