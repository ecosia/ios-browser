---
title: Which claims does the Auth0 ID token carry?
type: research
status: closed
blocked-by: []
---
## Question
Does the iOS client's ID token (as issued by the Ecosia Auth0 tenant with the scopes in `EcosiaAuthScopes.oauthScope`) contain `sub`, `name`, `nickname`, `picture`, `email` (and any custom Ecosia claims such as an Ecosia user id)? Are they present for all identity providers (email, Apple, Google) and are they present again after a refresh-token renewal? Is anything only available via `/userinfo`? Sources: `/Users/paul/Development/ecosia/platform` (Auth0 terraform + action scripts, read `origin/main` via `git show`), `/Users/paul/Development/ecosia/core/accounts` and the iOS code (`EcosiaAuthScopes.swift`, `Credentials+AccountOrigin.swift`, `UserProfile.swift`, `EcosiaAuthenticationService.fetchUserInfoFromAuth0`).

## Resolution

Sources read: `ecosia/platform` @ `origin/main` 1f510c698f, `ecosia/core` @ `origin/main` 82a10f5b91 (both via `git show`/`git grep`, working trees untouched), ios-browser `main` working tree, Auth0.swift source (checkout in DerivedData, 2.17.0), Auth0 public docs.

### Answer

Yes, with one caveat about optional claims. The tenant does nothing to suppress or rewrite standard claims, so the ID token for the iOS client carries them on every issuance that includes `openid`:

| Claim | In ID token? | Source of guarantee |
| --- | --- | --- |
| `sub` | Always | OIDC / Auth0 `openid`. It is also the Ecosia user id: core uses `profile.user_id` (= `sub`) as `userId`. There is no separate Ecosia id claim. |
| `name`, `nickname`, `picture` | Yes when set on the Auth0 user (`profile` scope) | Auth0 docs; `profile` is requested and allowed for the iOS client. Optional per OIDC; absent when the user profile has no value. |
| `email`, `email_verified` | Yes when set (`email` scope) | Auth0 docs; `email` is requested and allowed. |
| `https://ecosia.org/created_at`, `/is_sign_up`, `/newsletter_opt_in`, `/chat_threads_opt_out`, `/chat_data_consent_opt_in` | Yes, set by the `add_data_to_id_token_claims` post-login action | platform actions. Only `created_at` is consumed by iOS today (`Credentials+AccountOrigin.swift`). |
| Anything only available via `/userinfo` | Nothing identified | Auth0 docs: standard claims are in both the ID token and `/userinfo`. The only difference is freshness (see below). |

Refresh: a refresh-token exchange returns a new `id_token` when the original grant included `openid` (Auth0 docs), and the post-login actions run on refresh exchanges (the platform action `add_conversation_scopes_for_native_clients.js` says so in its header and relies on it; `add_data_to_id_token_claims` has no protocol guard, so its claims are re-applied). Auth0.swift `CredentialsManager.renew()` stores the id token from the renewal response, so claims are present again after renewal, and are refreshed from the current Auth0 user profile at that moment.

Recommended contract for the plan: `sub` is the only claim to treat as required (decode failure or missing `sub` means "claims unavailable", fall back to `/userinfo` or the access-token `sub`). `name`, `nickname`, `picture`, `email` are optional. Decode locally on every credentials change, as the map assumes; `/userinfo` as fallback is justified but should be rare.

### Evidence

Scopes and client config
- Requested scopes: `EcosiaAuthScopes.oauthScope` = `openid profile email offline_access read:impact write:impact read:conversations ...` (`firefox-ios/Ecosia/Account/Auth/EcosiaAuthScopes.swift:9-11`), applied in `NativeToWebSSOAuth0Provider.swift:43` with audience `authApiAudience`.
- iOS client `allowed_scopes` includes `openid profile email offline_access ...` in dev, staging and prod (`infrastructure/auth0/prod/clients.tf:323`, same text in dev/staging). `restrict_scopes.js` only calls `api.accessToken.removeScope` for scopes not in `allowed_scopes`, so it does not strip profile/email.
- iOS client: `app_type = "native"`, grant types `authorization_code` + `refresh_token`, `native_social_login` apple/facebook disabled (`clients.tf:308-363`), so Apple and Google sign-in run through Universal Login web flow like email, not a native token exchange. Refresh tokens: expiring, 30 d absolute / 14 d idle, `non-rotating` (`clients.tf:358-363`). ID token lifetime 36000 s (`clients.tf:352`), access token 3600 s (`resources.tf`, `ecosia_accounts_web`).
- `restrict_unverified_users.js` redirects users with `email_verified == false` away during login, so a token minted for a signed-in native session always has `email_verified: true` (except the CTE path, not relevant).

Custom claims
- `add_data_to_id_token_claims.js` sets `https://ecosia.org/{chat_data_consent_opt_in, chat_threads_opt_out, created_at, is_sign_up, newsletter_opt_in}`; bound in post-login at `infrastructure/auth0/prod/actions.tf:109-128`, same script for all three envs.
- `is_sign_up` is `event.stats.logins_count === 1`; because the action also runs on refresh it stays `true` on refreshes until the next interactive login. iOS does not use it; do not use it for "new account" logic (the existing `created_at` same-UTC-day check is the safer signal and is what `accountOrigin` does).
- iOS already decodes the ID token locally: `Credentials+AccountOrigin.swift` uses JWTDecode (3.3.0) `decode(jwt:)` and reads `created_at`. Core does the same with the web ID token (`accounts/client-js/src/server/utils/oauth2.js`, via passport-auth0 `_json`).

Current iOS profile path (what gets replaced)
- `EcosiaAuthenticationService.fetchUserInfoFromAuth0` (`EcosiaAuthenticationService.swift:316-337`) calls `/userinfo` with the access token and builds `UserProfile(name: userInfo.name ?? userInfo.nickname, email, picture, sub)`. Called after login (`:155`) and after stored-credential retrieval (`:255`), but not after `renewCredentialsIfNeeded` (`:278-293`).
- `retrieveStoredCredentials` calls `credentials()` and then `renewCredentialsIfNeeded()`, which calls `credentialsManager.renew()` (`Auth0ProviderProtocol.swift:116-118`, `DefaultCredentialsManager.swift:34-36`), and Auth0.swift `renew()` forces renewal (`CredentialsManager.swift:699-707`, `forceRenewal: true`). So every cold start already fetches a fresh ID token.

SDK support for the local decode
- `CredentialsManager.user` returns `UserInfo` decoded from the stored ID token (`Auth0/CredentialsManager.swift:81-86`, added in SDK-2633, tag 1.34.0, so present in the pinned 2.15.1). `UserInfo.init?(json:)` requires only `sub` and treats everything else as optional (`Auth0/UserInfo.swift:146-186`). Ecosia's `CredentialsManagerProtocol` does not expose it yet; `JWTDecode` + `UserInfo` would do the same.
- Renewal stores `Credentials(from: credentials, refreshToken: ...)` using the response's `idToken` (`CredentialsManager.swift:~783`). `Credentials.init(from decoder:)` defaults a missing `id_token` to `""` (`Credentials.swift:~135`), so a renewal response without an id token would silently overwrite the stored one with an empty string. Treat empty/undecodable `idToken` as "claims unavailable" and keep the last good claims rather than clearing.
- SSO exchange also overwrites the stored `idToken` with the id token from the `ssoExchange` response (`CredentialsManager.swift:~853`). Claims in that token are not verified here (see below); relevant to ticket 02.

Provider and profile behaviour
- Connections: `Email-Password-Authentication` (`strategy = "auth0"`), `google-oauth2` (scopes `email profile`), `Apple-Connection` (scopes `email name`); the last two with `set_user_root_attributes = "never_on_login"` (`infrastructure/auth0/prod/main.tf:219-295`). That setting means root attributes such as name/picture are written when the user is first created and are not re-synced from the IdP on later logins.
- Core confirms two profile quirks: Auth0 uses the email as display name when no name exists (`oauth2.js:80-86` comment), and email/password users get Gravatar pictures which web deliberately discards (`oauth2.js:16, 52-68`: Gravatar URLs and URLs over 300 chars are ignored). iOS currently shows whatever `picture` is returned, including Gravatar.
- Web can change the name after the fact: `updateNameHandler` sets `name` and nulls `nickname/given_name/family_name` through the Management API (`core/accounts/pages/src/server/handlers/protected/profile.js:118-126`). Native ID-token claims therefore lag until the next renewal; `/userinfo` is always current.

### Open uncertainties / not verified

- Per-provider presence of optional claims was not verified against a real token. Config-level reasoning only: Google supplies name/picture/email; Apple supplies name only on first authorization and may supply a private-relay email, and has no avatar; email/password users get `name == email` (core comment), a Gravatar `picture`, and `nickname` = email local part (standard Auth0 behaviour, not in the repo). A real-token check for one account per provider (decode the ID token after login, including after a forced renew) would settle this in a few minutes and should be a step in the plan's verification checklist.
- Because `name` is typically populated (as the email) for database users, the existing `name ?? nickname` fallback rarely reaches `nickname`; behaviour to preserve or deliberately change is a design decision for the presenter ticket, not this one.
- The Auth0 docs I could fetch state that refresh returns a new ID token and show a post-login action branching on `oauth2-refresh-token`, but do not explicitly state that custom ID-token claims are applied on refresh. The platform repo's own action comment asserts actions run on refresh; no live confirmation was done.
- Claims in the id token returned by the SSO (`ssoExchange`) response were not checked; Auth0 docs for that exchange were not consulted.
- Auth0.swift source was read from the 2.17.0 checkout in DerivedData; `Package.resolved` pins 2.15.1. The cited code paths are old and unlikely to differ, but not diffed.
- Dev/staging terraform was only compared for the allowed-scopes and action-binding lines, not exhaustively.
