---
type: wayfinder:grilling
status: open
blocked-by: []
claimed:
---
## Question
When `ImpactManager` splits (cleanup PR 5), where does the logic half live: `Ecosia/Account/Impact/` (sibling of `Account/Auth/`) or `Ecosia/Core/` (next to `Core/Accounts`)? Also: does the presentation half stay on `EcosiaAuthUIStateProvider` or become its own small UI type, and do the caches / seed manager / `ImpactSnapshot` follow the logic half? Context: nothing in `Core/` or `Account/` imports SwiftUI today; PR 1 (ecosia/ios-browser#1339) keeps `ImpactManager` in `UI/Account/Impact/` because it still holds `withAnimation`, the error toast and the level-up notification.
