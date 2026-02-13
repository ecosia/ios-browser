# Accounts in Chrome NTP

* Status: proposed
* Deciders: Native Apps Team, Journey Team
* Date: 2024-11-27
* Jira: MOB-2976

## Context and Problem Statement

The current Accounts auth solution prepared by the Journey team relies on sharing session information via a Fastify plugin which can safely encrypt and decrypt the auth session cookie. Chrome NTP is one of the applications that don't have a Fastify backend, but also need to be integrated with Accounts.

## Decision Drivers

* Need to integrate Accounts with Chrome NTP without a Fastify backend
* Security requirements for handling session cookies
* Performance and scalability considerations
* Avoiding tight coupling between services

## Considered Options

* **Option 1**: JSON endpoint on accounts service
* **Option 2**: Use the NTP Worker as a secure backend

## Decision Outcome

Chosen option: **Option 2 - Use the NTP Worker as a secure backend**, because it is the most secure and future-proof solution and it would also enable any Worker-based service to make use of session storage cookie in other ways, e.g. to call APIs using the embedded access token or making use of other data that is confidential.

Unlike a pure SPA, the NTP does have a secure backend available (the Worker itself). Since the [NTP is served from an ecosia.org domain](https://github.com/ecosia/core/blob/8aa4a28eaaa345a043c39def08043d072c793906/web-extensions/new-tab-static-worker/wrangler.toml#L41), all our Ecosia cookies will be forwarded to the worker. We can create another Worker service that has the same secrets for encrypting/decrypting the session as our Fastify apps do. It can act as an API for other Workers (like the NTP), using [Service Bindings](https://developers.cloudflare.com/workers/runtime-apis/bindings/service-bindings/). It can decrypt the existing EASC (session cookie) and communicate with new-tab-static worker session status (logged-in/out).

Since the Journey team opted-in to use a key instead of secret+salt during encryption (see [ticket](https://ecosia.atlassian.net/browse/JO-2767)), it allows us to decrypt the session cookie easily ([see PoC](https://github.com/ecosia/core/pull/22018)).

### Positive Consequences

* Taking advantage of the existing backend, which can in a secure way handle auth logic
* The information behind the session storage would be kept inside of backends
* Future-proof solution that enables other Worker-based services to use session storage

### Negative Consequences

* The currently used encryption way by Accounts ([libsodium-native](https://sodium-friends.github.io/docs/docs/secretkeyboxencryption)) does not use the standard web crypto API and uses an algorithm (cryptobox/[XSalsa20](https://doc.libsodium.org/public-key_cryptography/authenticated_encryption#algorithm-details)) that is **not** supported by [Workers web crypto](https://developers.cloudflare.com/workers/runtime-apis/web-crypto/#supported-algorithms)
* To decrypt cookies in the worker we need to introduce a workaround, such as WASM or a JavaScript port, which come with tradeoffs like the impact on performance

## Pros and Cons of the Options

### Option 1: JSON endpoint on accounts service

New-tab-static worker could simply receive non-encrypted information from the Accounts service, without having to duplicate the decryption logic already included in the Accounts service. Accounts service instead of only setting the cookie could respond with a logged-in/logged-out status alongside with user picture.

* Good, because adding the logic of encrypting/decrypting the session cookie in the worker would add a lot of complexity, possibly with performance tradeoffs
* Good, because it avoids duplication of the encrypting/decrypting mechanics already existing in the Accounts service
* Bad, because it couples NTP Worker to Accounts service, which could affect scaling characteristics
  * It would be a client-side call, which makes this less of a tight coupling but still would cause extra load on the Accounts service that ideally we can avoid if we handle the cookie in the Worker that's already serving the page (also avoids potentially having to tweak Cloudflare WAF rules etc.)
  * This might not remain a client-side call (e.g. because logic is needed in the backend/Worker) and then the coupling becomes tight
* Bad, because it expands the security surface by exposing decrypted cookie contents outside of backends
  * Initially, it's only a few non-critical data points like user profile picture, but over time this will grow. For some data (e.g. access tokens or other sensitive/internal data) this is not a feasible way and will need another solution for those scenarios in any case
  * It is advisable to avoid opening up additional endpoints that could be abused generally

### Option 2: Use the NTP Worker as a secure backend

* Good, because it takes advantage of the existing backend, which can in a secure way handle auth logic
* Good, because the information behind the session storage would be kept inside of backends
* Bad, because the currently used encryption is not natively supported by Workers and requires a workaround

## Links

* Original Confluence entry: NAPPS-1
* [MOB-2976 - Spike](https://ecosia.atlassian.net/browse/MOB-2976)
* [Architecture diagram](https://miro.com/app/board/uXjVLJL_2ik=/)
* [Potential blockers documentation](https://ecosia.atlassian.net/wiki/spaces/MOB/pages/3534192651)
* [Encryption solution documentation](https://ecosia.atlassian.net/wiki/spaces/MOB/pages/3528654901)
* [JO-2767 - Journey team encryption ticket](https://ecosia.atlassian.net/browse/JO-2767)
* [PoC Pull Request](https://github.com/ecosia/core/pull/22018)
