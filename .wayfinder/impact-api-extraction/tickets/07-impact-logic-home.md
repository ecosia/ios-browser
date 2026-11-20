---
type: wayfinder:grilling
status: open
blocked-by: []
claimed:
---
## Question
When `ImpactManager` splits (cleanup PR 5), where does the logic half live: `Ecosia/Account/Impact/` (sibling of `Account/Auth/`) or `Ecosia/Core/` (next to `Core/Accounts`)? Also: does the presentation half stay on `EcosiaAuthUIStateProvider` or become its own small UI type, and do the caches / seed manager / `ImpactSnapshot` follow the logic half? Context: nothing in `Core/` or `Account/` imports SwiftUI today; PR 1 (ecosia/ios-browser#1339) keeps `ImpactManager` in `UI/Account/Impact/` because it still holds `withAnimation` and the level-up notification (the error toast is gone since ecosia/ios-browser#1354).

## Already decided elsewhere

The auth restructure plan (`pq-auth-restructure-plan`, `.wayfinder/auth-restructure/tickets/07-impact-service-boundary.md` and `08-presenter-layer.md`) answers two of the three parts, so PR 5 should split along the same line:
- Logic half: a stateful `ImpactService` with no UI knowledge (not an `ObservableObject`) over stateless helpers, publishing plain state (seeds, level, progress, last error) and events (`balanceIncreased(by:)`, `levelUp(level)`). The caches, seed manager and `ImpactSnapshot` go with it.
- Presentation half: balance-increment timing, `balanceIncrement`, `withAnimation` and the level-up post stay in the presenter (today `EcosiaAuthUIStateProvider`, later renamed `UserManager`), not a separate small UI type.

Still open here: the folder for the logic half (`Ecosia/Account/Impact/` or `Ecosia/Core/`).
