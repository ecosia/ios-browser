# Auth Flows

How a user signs in, stays signed in, re-authenticates and signs out across the iOS app, the accounts web pages and Auth0.

The app and the web each hold their own login. They share one WebView cookie store, which is how the native login reaches the web, and how a web login can reach native code.

- [Where auth state lives](#where-auth-state-lives)
- [App launch](#app-launch)
- [Native sign-in and session transfer](#native-sign-in-and-session-transfer)
- [Web session upkeep](#web-session-upkeep)
- [Auth links in a tab](#auth-links-in-a-tab)
- [Profile and re-auth for sensitive pages](#profile-and-re-auth-for-sensitive-pages)
- [Sign-out](#sign-out)
- [Known gaps](#known-gaps)

## Where auth state lives

| Store | Holds | Written by | Cleared by |
| --- | --- | --- | --- |
| Keychain | Native access, ID and refresh tokens (Auth0 client "Ecosia iOS Browser"). Refresh tokens rotate. | Native sign-in, renewal on expiry or forced renewal | Native sign-out, failed session transfer |
| App memory | Session transfer token (lives about 60s), user profile from `/userinfo` | Each sign-in, before the transfer | Native sign-out |
| WebView cookies | `auth0_session_transfer_token` on the Auth0 domain | App, just before the invisible tab opens | Used up by Auth0, expiry, native sign-out |
| WebView cookies | `EASC`: the web session (web tokens and the user, including `authorizedAt`) | Web sign-in callback, web token refresh | Web sign-out callback, native sign-out |
| WebView cookies | Auth0 session cookies on `login.<domain>` | Any web login inside the WebView | Native sign-out (deletes every Auth0-domain cookie) |
| Native cookie jar | Copy of `EASC` in `HTTPCookieStorage.shared`, used by native file uploads | `AuthSessionCookieHandler`, whenever the WebView's `EASC` changes | Native sign-out |

The WebView cookie store is `WKWebsiteDataStore.default()`, shared by every normal tab, the invisible auth tab and the profile modal.

## App launch

Launch restores the native login only. Nothing touches the web session, which keeps whatever `EASC` the WebView already has.

```mermaid
sequenceDiagram
  autonumber
  participant App as iOS app
  participant KC as Keychain
  participant A0N as Auth0 (iOS client)
  participant API as Impact API
  App->>KC: retrieveCredentials()
  alt access token expired
    KC-->>App: stored refresh token
    App->>A0N: refresh token grant
    A0N-->>App: new access, ID and rotated refresh token
    App->>KC: store rotated credentials
  else still valid
    KC-->>App: stored credentials
  end
  App->>A0N: /userinfo with access token
  A0N-->>App: name, avatar
  App->>App: dispatch auth state (isLoggedIn)
  App->>API: registerVisit with access token
  API-->>App: seeds, level
```

- **No forced renewal at launch.** Renewal only happens when the token has expired, because each renewal spends a rotating refresh token.
- **Forced renewal elsewhere.** Callers that need fresh claims or scopes, such as file upload, call `renewCredentials()` themselves.

Code: `EcosiaAuthenticationService.retrieveStoredCredentials()`, `renewCredentials()`, `EcosiaAuthUIStateProvider`.

## Native sign-in and session transfer

The user signs in once, natively. The app then hands that login to the web through Auth0's Native to Web SSO, using an invisible tab, so the web pages are signed in too.

```mermaid
sequenceDiagram
  autonumber
  actor U as User
  participant App as iOS app
  participant KC as Keychain
  participant A0N as Auth0 (iOS client)
  participant Tab as Invisible tab
  participant Web as Accounts web
  participant A0W as Auth0 (Ecosia Accounts)
  U->>App: Sign in (NTP, onboarding or intercepted link)
  App->>A0N: /authorize in ephemeral ASWebAuthenticationSession
  A0N->>U: Universal Login, e.g. Google
  U->>A0N: authenticates
  A0N-->>App: authorization code
  App->>A0N: exchange code (log: seacft)
  A0N-->>App: access, ID, refresh tokens (auth_time = now)
  App->>KC: store credentials
  App->>A0N: refresh token exchange for session_transfer audience (log: sertft)
  A0N-->>App: session transfer token
  App->>Tab: set auth0_session_transfer_token cookie, open /accounts/sign-up
  Tab->>Web: GET /accounts/sign-up
  Web-->>Tab: 302 to /authorize (prompt=select_account, state cookie)
  Tab->>A0W: /authorize, sends transfer token cookie
  A0W-->>Tab: 302 with code, no prompts (log: s, triggered_by_session_transfer_token)
  Tab->>Web: /accounts/sign-in/callback?code
  Web->>A0W: exchange code
  A0W-->>Web: web tokens and ID token (native auth_time not carried over)
  Web-->>Tab: Set-Cookie EASC, redirect to landing page
  Tab-->>App: lands on a page, tab closes
  alt ended on the error page, back on sign-in, or still on Auth0
    App->>KC: clear credentials (native-only sign-out)
  end
  App->>App: auth state changed, NTP and account sheet update
```

- **Every native login is a real sign-in.** The ephemeral session never reuses an Auth0 session, so steps 3 and 4 always ask the user.
- **Two Auth0 clients, two token families.** The app and the web each end up with their own tokens. The transfer token is the only link between them.
- **The web builds the transfer request.** It sends `prompt=select_account` and only passes through `promptLogin` (as `prompt=login`) and `silent` (as `prompt=none`). With `prompt=login`, Auth0 shows Universal Login instead of completing the transfer.
- **The web's login is never fresh after a transfer.** The transfer login doesn't carry the native `auth_time`, so `authorizedAt` isn't recent even straight after sign-in.

Code: `EcosiaAuthFlow.performSessionTransfer`, `NativeToWebSSOAuth0Provider`, `InvisibleTabSession`. Web (ecosia/core): `accounts/pages/src/server/handlers/auth/sign-in.js`, `sign-in-callback.js`, `accounts/client-js/src/server/utils/oauth2.js`.

## Web session upkeep

Once `EASC` exists, the web keeps itself alive with its own refresh token. The app isn't involved.

```mermaid
sequenceDiagram
  autonumber
  participant WV as Any WebView page
  participant Web as Accounts web
  participant A0W as Auth0 (Ecosia Accounts)
  WV->>Web: request with EASC cookie
  Web->>Web: attachUser (user and authorizedAt from session)
  Web->>Web: validateAccessToken
  alt valid
    Web-->>WV: page
  else expired or near expiry, refresh token present
    Web->>A0W: refresh token grant (web token family)
    A0W-->>Web: new web tokens
    Web-->>WV: page and re-encrypted EASC
  else invalid, no refresh token
    Web-->>WV: delete EASC, redirect to sign-in
  end
  opt access token issued before the forced re-auth date (feature flag)
    Web-->>WV: redirect to /accounts/sign-in?silent=true (prompt=none)
  end
```

- **Refreshes don't change `authorizedAt`.** Only a login through the sign-in callback sets it.
- **Separate from native renewal.** Native and web refresh tokens rotate independently.

Web (ecosia/core): `accounts/client-js/src/server/hooks/attach-user.js`, `validate-access-token.js`, `refresh-access-token.js`, `force-re-auth.js`.

## Auth links in a tab

When a page in a normal tab navigates to an accounts URL, the app cancels the navigation and runs the native flow instead.

```mermaid
sequenceDiagram
  autonumber
  actor U as User
  participant Tab as Normal tab
  participant App as iOS app
  U->>Tab: taps an accounts link
  Tab->>App: decidePolicyFor navigation
  App->>App: EcosiaURLInterceptor classifies the path
  alt /accounts/sign-in or /accounts/sign-up, natively signed out
    App->>App: cancel, run native sign-in
    App->>Tab: reload
  else sign-in or sign-up, natively signed in (web and app disagree)
    App->>App: cancel, native sign-out then native sign-in
    App->>Tab: reload
  else /accounts/sign-out
    App->>App: cancel, run sign-out
  else /accounts/profile
    App->>App: cancel, open the profile modal
  else anything else
    App-->>Tab: allow
  end
```

- **The invisible tab is never intercepted**, so its own redirects through `/accounts/sign-up` and the callback go through.
- **The profile modal isn't intercepted either.** It has its own navigation delegate, so a sign-in inside it is a web login.

Code: `BrowserViewController+Ecosia.detectAndHandleEcosiaURL`, `EcosiaURLInterceptor`.

## Profile and re-auth for sensitive pages

The profile is a web page in a modal. Deleting the account and managing a subscription need a login from the last 5 minutes, which the transfer login never provides, so the user always logs in again on the web.

```mermaid
sequenceDiagram
  autonumber
  actor U as User
  participant App as iOS app
  participant M as Profile modal (WebView)
  participant Web as Accounts web
  participant A0W as Auth0 (Ecosia Accounts)
  U->>App: account sheet, Profile
  App->>M: open /accounts/profile (shared cookie store, in-app user agent)
  M->>Web: GET /accounts/profile with EASC
  Web-->>M: profile page
  U->>M: Settings, Delete account (or Manage subscription)
  M->>Web: GET delete page
  Web->>Web: forceReauthIfStaleGuard: authorizedAt missing or older than 5 min
  Web-->>M: 302 /accounts/sign-in?returnTo=...and promptLogin=true
  M->>A0W: /authorize with prompt=login
  A0W->>U: Universal Login inside the WebView
  U->>A0W: authenticates (account chooser may offer another account)
  A0W-->>M: 302 with code
  M->>Web: /accounts/sign-in/callback?code
  Web->>A0W: exchange code
  A0W-->>Web: ID token with fresh auth_time
  Web-->>M: new EASC (authorizedAt = now), redirect to returnTo
  M->>Web: GET delete page, allowed for 5 minutes
  Note over App,M: The new EASC replaces the web session for every tab and is copied into the native cookie jar for file uploads
```

- **It always prompts.** Even straight after a native sign-in, because the transfer login doesn't carry the native `auth_time`.
- **Google login runs inside the WebView.** It works with the in-app user agent, but Google can block embedded logins, which is why the modal reports Google OAuth navigations to Sentry.
- **The user can pick a different account here.** The web would then act as that account while the app stays on the original one, until sign-out.

Code: `EcosiaWebViewModal`, `BrowserViewController+Ecosia.presentProfileModal`. Web (ecosia/core): `accounts/pages/src/server/routes/util.js`, `routes/profile/index.js`, `accounts/client-js/src/server/hooks/force-re-auth.js`.

## Sign-out

The app clears its own state first, then runs the web's sign-out in the invisible tab so Auth0's session ends too.

```mermaid
sequenceDiagram
  autonumber
  actor U as User
  participant App as iOS app
  participant KC as Keychain
  participant Tab as Invisible tab
  participant Web as Accounts web
  participant A0W as Auth0 (Ecosia Accounts)
  U->>App: Sign out (app UI or intercepted /accounts/sign-out)
  App->>App: delete EASC and all Auth0-domain cookies from the WebView
  App->>KC: clear credentials
  App->>App: clear native EASC copy, transfer token, profile, avatar cache
  App->>Tab: open /accounts/sign-out
  Tab->>Web: GET /accounts/sign-out
  Web-->>Tab: 302 to Auth0 logout with returnTo
  Tab->>A0W: /v2/logout
  A0W-->>Tab: 302 /accounts/sign-out/callback
  Tab->>Web: sign-out callback
  Web-->>Tab: session deleted, redirect
  Tab-->>App: tab closes
  App->>App: auth state changed, reload current tab
```

- **Clearing cookies is local.** The app deletes cookies itself rather than calling Auth0's logout from `ASWebAuthenticationSession`, which would show a system alert.
- **Everything a web login left behind goes too**, including Auth0 session cookies from a profile re-auth.

Code: `EcosiaAuthenticationService.logout`, `NativeToWebSSOAuth0Provider.clearSession`, `EcosiaAuthFlow.performSessionCleanup`. Web (ecosia/core): `accounts/pages/src/server/handlers/auth/sign-out.js`, `sign-out-callback.js`.

## Known gaps

- **The transfer login doesn't carry the native `auth_time`.** Auth0 treats it as a new web session, so the web's recent-login check never passes after a transfer. Options: an Auth0 Action that records the native login time in refresh token metadata and adds it to the web's ID token as a custom claim, or doing delete and subscription management natively.
- **A profile re-auth can sign the web in as a different account.** It isn't known whether the web checks that the re-auth user matches the existing session.
- **On the simulator, an old `EASC` can survive deleting the app.** Erase the simulator between auth tests, or test on a device.
