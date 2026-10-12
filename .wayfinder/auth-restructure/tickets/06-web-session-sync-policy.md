---
title: WebSessionSync triggers and reconciliation policy
type: grilling
status: closed
assignee: paul
blocked-by: [03-web-session-lifetime, 04-auth-snapshot-and-events]
---
## Question
With native as truth: when does `WebSessionSync` push native→web (login, app foreground if the web session is missing/stale, after identity change, after rotation if SSO needs it), how does it react to the web saying "signed out" while native is signed in (today: force logout + relogin — keep, soften, or silently re-transfer?), how does it surface success/failure to `AuthSession`/UI, what happens to the EASC→HTTPCookieStorage copy for uploads, and does the invisible tab stay the mechanism?

## Resolution

Decided with Paul (all recommendations accepted). iOS 15 floor.

1. **Mechanism and shape.** The invisible tab stays the transfer mechanism: session-transfer token from the gateway (`sessionTransferToken()`), cookie installed before the tab is created. `WebSessionSync` has one app-wide single-flight "reconcile" operation with two entry points: user-initiated login awaits `establishWebSession()` (UI needs the result); a subscriber on `AuthSession`'s identity stream and the lifecycle observer call the same operation in the background. Two windows never run two transfers at once.
2. **Push triggers.** Login success, identity (`userId`) change, foreground. Native `signedIn` and no `EASC` in the web cookie jar: silent re-transfer. Native `signedOut` and `EASC`/Auth0-domain cookies present: clear them (native is truth). No polling, no liveness probe (cookie presence is one-sided; a present-but-dead `EASC` is only discovered when the web redirects to sign-in). The `/accounts/refresh-token` probe is left out of the plan.
3. **Web signed out, native signed in.** The sign-in URL interception in `handleSignInAndSignUpDetection` stops forcing logout + re-login; it does a silent re-transfer then reloads the tab. Loop guard: one silent re-transfer per `credentialsVersion` within a short window (~60 s); a second interception in the window goes to the failure policy (item 5).
4. **Sign-out flows.** User-initiated: native sign-out clears cookies, then loads the logout URL in an invisible tab (as today) so the web can finish its server-side logout. Web-initiated (sign-out URL interception): native signs out with `webSignedOut` and clears cookies; the logout-URL tab is skipped since the web already signed out.
5. **Failure policy.** Failed transfer in a user-initiated login: native signs out with `sessionTransferFailed` (today's behaviour). A failed background reconcile never signs out: native stays `signedIn`, web is marked out of sync, the next trigger retries, no toast. `WebSessionSync` publishes its own small state (`idle | syncing | inSync | outOfSync`), separate from the `AuthSession` snapshot.
6. **`EASC` for native uploads.** `FileUploadAuthCookieSync` and the cookie-observer mirroring in `TabManagerImplementation` move into `WebSessionSync` as the single place web cookies cross into native requests. On a presign 403 it does one silent re-transfer and the upload retries once. Bearer support in the AI worker would remove all of this but is a backend change, out of scope; the plan records it as a dependency.
7. **Hosting window.** Cookie store is shared (`WKWebsiteDataStore.default()`). The tab is hosted by the window that triggered the call, or the foreground scene's `BrowserViewController` for background triggers. Tab completion comes from its own landing detection and timeout, not `EcosiaAuthStateChanged`, so `TabAutoCloseManager` loses its notification dependency.
