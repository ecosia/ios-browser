# 04: Adapt to the Redux ModernAction migration

**What to build:** Every Ecosia customization built on the shared Redux `Action`/`Middleware`/`Reducer` shapes continues to dispatch and reduce correctly under upstream's new `ModernAction` typealias reshape, using one consistently-applied approach (stay on the legacy `Action` path, which upstream still supports side-by-side) rather than a different fix improvised per file.

This is the "expand" step for this wide change: get the 9 confirmed-affected files compiling and behaviorally correct against the new shape. Business-logic conflicts specific to a given feature area's Redux state are resolved in that feature's own vertical ticket (10–17), not here — this ticket only unblocks them.

**Blocked by:** 02

**Status:** done

- [~] All 9 files confirmed in this session to declare `Middleware<...>`/`Reducer<...>` directly compile against the new typealias shape — *type shape verified for all 9; literal compilation blocked in 3 of them by vertical-owned conflicts (see below)*
- [x] The chosen approach (legacy path vs. adopting `ModernAction`) is applied consistently across all 9, not decided per-file
- [x] Per the intent-diff manifest, every Ecosia-specific Redux behavior in these files (not just the type signatures) is preserved
- [~] The start-at-home characterization test (ticket 01) still passes against the adapted `EcosiaStartAtHomeMiddleware` — *adapted and lint-clean, but cannot be executed: the tree has 558 unmerged files*

## Comments

### The "9 files" were not recorded anywhere — reconstructed

The planning session's list was lost. Rebuilt it as: **files that declare a `Middleware<…>`/`Reducer<…>`-typed member AND appear in the intent-diff manifest's own file lists** (`ecosia_owned_files.txt` ∪ `core_modified_files.txt`). That definition yields exactly nine, which is strong evidence it matches the original.

For the record: 62 files in the tree declare these types, but 53 are untouched Firefox core that upstream already migrated, so they arrive correct and never conflict.

| # | File | Needed |
| --- | --- | --- |
| 1 | `Client/Ecosia/UI/StartAtHome/EcosiaStartAtHomeMiddleware.swift` | **adapted by hand** |
| 2 | `Client/Frontend/Browser/BrowserViewController/State/BrowserViewControllerState.swift` | shape already correct — 2 conflicts left for **ticket 10** |
| 3 | `Client/Frontend/Browser/MainMenu/Redux/MainMenuMiddleware.swift` | **resolved** |
| 4 | `Client/Frontend/Browser/Toolbars/Redux/AddressBarState.swift` | shape already correct — 3 conflicts left for **ticket 11** |
| 5 | `Client/Frontend/Browser/Toolbars/Redux/NavigationBarState.swift` | shape already correct — 5 conflicts left for **ticket 11** |
| 6 | `Client/Frontend/Browser/Toolbars/Redux/ToolbarMiddleware.swift` | nothing — auto-merged correctly, verified |
| 7 | `…/ClientTests/Frontend/Browser/SearchEngines/SearchEngineSelectionStateTests.swift` | **resolved** |
| 8 | `…/ClientTests/Toolbar/NavigationBarStateTests.swift` | nothing — auto-merged correctly, verified |
| 9 | `…/ClientTests/Utils/StoreTestUtility.swift` | nothing — still valid, verified |

Three more Ecosia-touched files *call* `reducer(…)` without declaring the type, so they fall outside this ticket's stated set but will break the same way: `BrowserViewControllerStateTests.swift`, `HomepageViewControllerTests.swift`, `HomepageDiffableDataSourceTests.swift` (the last two are already named in ticket 13).

### What upstream actually changed

`Action` and `ActionType` are **unchanged**; `ModernAction` is purely additive. The breakage is that the two typealiases became **tuples**:

```swift
// 147.2
public typealias Middleware<State> = (State, Action) -> Void
public typealias Reducer<State> = @MainActor (State, Action) -> State

// 155.1
public typealias Middleware<State> = (legacyMiddleware: LegacyMiddlewareClosure<State>,
                                      modernMiddleware: MiddlewareClosure<State>)
public typealias Reducer<State> = (legacyReducer: LegacyReducerMethod<State>,
                                   modernReducer: ReducerMethod<State>)
```

`DispatchFunction` was removed (unused by Ecosia). `Store.init` keeps `middlewares: [Middleware<State>]`, which is why `StoreTestUtility` needed no change — `[Middleware<AppState>]` is now an array of tuples and still compiles.

### The approach, applied uniformly

Upstream's own not-yet-migrated middleware (e.g. `StartAtHomeMiddleware` at 155.1) sets the pattern, and it is followed everywhere: real logic in the legacy member, an empty modern member.

```swift
lazy var startAtHomeProvider: Middleware<AppState> = (legacyProvider, modernProvider)

/// Ecosia: no `ModernAction` is handled — the override only ever answers the legacy
/// `didBrowserBecomeActive` action, and answers it the same way regardless of state.
lazy var modernProvider: MiddlewareClosure<AppState> = { _, _, _ in }

lazy var legacyProvider: LegacyMiddlewareClosure<AppState> = { state, action in ... }
```

`_, _, _` instead of upstream's `[self] state, action, windowUUID` — the body is empty and this is an Ecosia-owned file, so there is no future merge to align with.

`EcosiaStartAtHomeMiddlewareTests.swift`: 5 call sites moved from `startAtHomeProvider(appState, action)` to `startAtHomeProvider.legacyMiddleware(appState, action)`, matching upstream's own test convention at 155.1.

### Silent-loss audit

Compared `Ecosia:` marker counts per file against `c5afa25d3b`. No losses — the only increases are two comments added in this ticket. For `ToolbarMiddleware.swift` the Ecosia hunks (QR-scanner substitution, NTP history destination) survived verbatim, and its commented-out original is **not stale**: upstream's `case .search:` block is byte-identical between 147.2 and 155.1.

### Judgment call flagged — `SearchEngineSelectionStateTests`

Ecosia had deleted `XCTAssertNil(newState.selectedSearchEngine)` and the whole `testDidTapSearchEngine`, with **no `// Ecosia:` marker and no recorded reason** — so it may have been a deliberate removal or incidental loss in an earlier upgrade. Applied the glossary's *removal* rule: preserved the deletion, kept upstream's 155.1 version verbatim in a block comment.

Worth a decision by someone with product context: as of 155.1 upstream's own state models engines as `SearchEngineModel` and `selectedSearchEngine` exists, so **the original reason for divergence may be gone** and this coverage could likely be restored.

### Hard dependency created for ticket 12

`MainMenuMiddleware`'s telemetry `switch` has **no `default`**, so it must stay exhaustive. Its conflict was a pure addition — upstream's `.readerView` vs Ecosia's `.readingList, .help, .reportIssue` are disjoint — so both were kept. That compiles **only if** ticket 12 resolves `MenuNavigationDestination.swift` (currently `UU`, two conflicts) by keeping *both* sides' cases: upstream's `.readerView` + `.translatePage`, and Ecosia's `.readingList` + `.help` + `.reportIssue`.

### Concrete finding for ticket 10

`BrowserViewControllerState`'s `DisplayType` enum: upstream **removed** `case summarizer(config: SummarizerConfig?)` in 155.1 — it completed its own `FXIOS-13118` TODO and moved the summarizer to `NavigationDestination(.summarizer(config:trigger:))`. Ecosia's side still carries the old case. The merged file already holds upstream's new `handleShowSummarizerAction`, so when ticket 10 resolves that enum it should take upstream's three additions plus Ecosia's `.qrCode`/`.history` and **drop** `.summarizer`.

### Why compilation could not be verified

The tree has 558 unmerged files, so no target builds. AC 1 and AC 4 are verified by inspection against upstream's reference pattern only. First real compile is ticket 09's smoke build (also likely blocked) and, definitively, ticket 19.
