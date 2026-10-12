---
title: Presenter layer: UserManager vs slimmed EcosiaAuthUIStateProvider
type: grilling
status: closed
assignee: paul
blocked-by: []
---
## Question
With `AuthSession` (ticket 04) and `ImpactService` (ticket 07) decided, what do SwiftUI views observe? Decide: introduce `UserManager` (an `ObservableObject` composing auth + impact, per the earlier planned direction) or slim `EcosiaAuthUIStateProvider` in place; what the presenter derives (display name, avatar normalisation incl. email-as-name and Gravatar, level text/progress, animation state, level-up event, error toast trigger); how views and view models (`EcosiaAccountImpactViewModel`, `EcosiaAccountAvatarViewModel`, `NTPHeaderViewModel`, `EcosiaAccountNavButton`, `EcosiaAvatar`, `User.swift`) migrate; whether the migration is one PR or split; `.shared` singleton vs injection at the composition root. Constraint: iOS 15, so `ObservableObject`/`@Published`/Combine only (no `@Observable`).

## Resolution

Decided with Paul (all recommendations accepted). iOS 15 floor: `ObservableObject`/`@Published`/Combine only. Footprint is small: eight files observe `EcosiaAuthUIStateProvider` (`EcosiaAccountAvatarViewModel`, `EcosiaAccountImpactViewModel`, `EcosiaAccountImpactView`, `EcosiaAvatar`, `EcosiaAccountNavButton`, `NTPHeaderViewModel`, `User.swift`, debug settings) plus one test file, using about 15 properties.

1. **Name and role.** The presenter becomes `UserManager`, a `@MainActor` `ObservableObject` that only binds `AuthSession` and `ImpactService` for views and owns animation; no business logic. The rename from `EcosiaAuthUIStateProvider` is a mechanical final step in the chain, not mixed into behavioural PRs.
2. **Exposed surface.** Views keep today's property names (`isLoggedIn`, `avatarURL`, `username`/`userDisplayText`, `seedCount`, `currentLevelNumber`, `levelProgress`, `levelDisplayText`, `balanceIncrement`, the error flag), so migrating a view is a rename only. Values derive from the snapshot's claims with today's display behaviour unchanged (Gravatar stripping, `name ?? nickname`); no new email masking. `UserProfile` stays as a type built from claims, since `BrowserViewController` reads `userProfile?.sub`.
3. **Binding and first frame.** Subscribes over Combine (delivered on the main queue) to the snapshot, `ImpactService.state` and the service events. Initial values are read synchronously in `init` (snapshot, plus cached impact for the persisted `lastKnownUserId` or the legacy slot), preserving the no-flicker behaviour of today's synchronous initialiser.
4. **Composition and singletons.** One composition function builds the graph (`AuthSession` + gateway, `WebSessionSync`, `ImpactService`, `UserManager`); `.shared` stays as a thin accessor over it, matching the existing pattern and keeping the Firefox-side diff small. Views/view models take an injectable `UserManager` defaulting to `.shared`; tests build isolated graphs with fakes. `User.swift` reads the seed count from `ImpactService`, not the UI layer. Removing singletons entirely is out of scope.
5. **Animation and debug hooks.** Balance-increment timing (1 s delay, 3 s hold, `withAnimation`) moves into `UserManager` unchanged, driven by the service's `balanceIncreased` and `levelUp` events; `levelUp` still posts via `EcosiaAccountNotificationCenter.postLevelUp`. `debugAddSeeds`, `debugTriggerLevelUpAnimation` and `debugUpdateBalance` stay on `UserManager`, synthesising the same events.
6. **Error toast.** A failed refresh is an event: the service's event stream gains `refreshFailed` alongside `lastError` state (amends ticket 07 item 5 slightly). `UserManager` shows the register-visit toast once per failed refresh, as today, via `EcosiaErrorToastPresenter` with its existing availability guard; no state-transition suppression.
