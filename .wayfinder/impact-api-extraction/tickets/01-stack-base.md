---
type: wayfinder:grilling
status: closed
blocked-by: []
claimed: Paul
---
## Question
What does the stack build on: fresh from `main`, or revive parts of the closed 4236 work (static `ImpactManager`, user-id-keyed single cache)? Decide what, if anything, is mined from it, and what that implies for the cache-unification fog.

## Resolution

- Base: fresh branches off `origin/main`; `pq-mob-4799-braze-core-markets` is unrelated and not a base.
- The closed 4236 work (PR 1281: static `ImpactManager`, single user-id-keyed cache) is open reference material, not ruled out. Reuse is judged per PR by one criterion: small, digestible review, especially for the first few PRs.
- Injection is not a goal in itself. A stateless static `ImpactManager` is acceptable; DI is used only where it buys something. The auth -> API dependency (the API needs a token) is the one seam that must be injected or reactive.
- Stacking: superseded by ticket 05, which merges PRs one at a time off `main`. Merging still needs explicit consent.
- The unwired `AccountsProviderWrapper` (debug API-error simulation) is left alone in PR 1; fixing it belongs with the Core API-service PR.
