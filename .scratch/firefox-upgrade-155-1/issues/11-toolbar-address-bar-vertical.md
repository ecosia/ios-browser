# 11: Toolbar / Address Bar vertical

**What to build:** The address bar and navigation toolbar continue to reflect Ecosia's search branding, custom gesture handling, and toolbar behavior correctly after upstream's continued toolbar refactor and the `AddressBarPanGestureHandler` → `TabSwipeGestureHandler` rename.

**Blocked by:** 10

**Status:** done

- [x] Every Ecosia customization in the toolbar/address-bar file group is reconciled per the intent-diff manifest (address toolbar container and its model, navigation toolbar container model, toolbar and navigation-bar Redux state, toolbar middleware and action configuration)
- [x] The gesture-handler rename is accounted for wherever Ecosia's code referenced the old name
- [x] Any toolbar-specific tests affected by this area are updated alongside the production code, not left for a later pass
- [x] This vertical's files share no overlap with any other vertical ticket — confirm no collateral edits landed outside this file group

## Verification standard (applies to every AC in this ticket)

Nothing in the repo compiles until ticket 19 — the rebase is in progress with hundreds of files
still carrying conflict markers inside the same `Client` target, so `xcodebuild` fails on the first
unresolved file and never reaches this vertical. **Do not read "compiles", "passes" or "behaves
correctly" in an AC as requiring a build or a test run.** They are satisfied by the static
substitutes the earlier tickets established:

- `xcrun swiftc -parse <file>` on every file touched, plus a check that no conflict markers remain.
- A symbol-dependency sweep: every non-SDK symbol the reconciled code references still resolves in
  the tree (this is what catches the silent losses a clean auto-merge produces).
- `cd firefox-ios && tuist generate --no-open` when the file set or module imports changed.
- `swiftlint --strict` — run it bare from the repo root, not with explicit paths (see ticket 10's
  tooling notes for why).
- `plutil -lint` for plists/`.strings`; `bin/nimbus-fml.sh` for Nimbus manifest work.

Actual compilation and test execution are ticket 19's job. State plainly in your findings which ACs
were verified statically rather than executed, and hand any runtime risk you could not settle to
ticket 19.


## Inherited findings

- `ToolbarMiddleware.swift` is **already resolved and verified** (ticket 04): tuple shape correct, Ecosia's QR-scanner substitution and NTP history destination intact, and its commented-out upstream original is **not stale** (upstream's `case .search:` block is byte-identical between 147.2 and 155.1). No action needed there.
- `AddressBarState.swift` (3 conflicts) and `NavigationBarState.swift` (5 conflicts) were deliberately left for you. Their **Redux tuple shape already auto-merged correctly** — remaining conflicts are toolbar business logic only.
- `NavigationBarStateTests.swift` is already resolved (uses `reducer.legacyReducer(...)`).
- The `AddressBarPanGestureHandler` → `TabSwipeGestureHandler` rename in the ticket body was not investigated in earlier tickets — still to verify.

**Google Lens is already decided — do not re-open it.** Upstream's Google Lens code stays intact and
reconciled; it is suppressed by flag, not commented out. `nimbus-features/googleLensFeature.yaml` is
`enabled: false` on every channel (ticket 10), and every entry point additionally requires
`defaultEngine.isGoogleEngine`, which is false for Ecosia. If you touch `AddressBarState.googleLensAction`,
`ToolbarMiddleware.isGoogleLensAvailable`, or the menu/settings surfaces that reference it, keep upstream's
code and its gates as-is — reconcile, don't remove.

## Outcome

**15 files resolved and staged** (13 conflicted with 38 conflict markers, 2 delete/modify), plus two
non-conflicted follow-ups. Unmerged count went 511 → 496, and no unmerged file mentioning "toolbar"
remains — AC-4 confirmed: nothing outside this file group was touched.

### Production files

| File | Conflicts | Resolution |
| --- | --- | --- |
| `Redux/ToolbarActionConfiguration.swift` | 1 | Pure addition. Upstream's `bottomBadgeImage` **plus** Ecosia's four badge-customisation fields. Ecosia's `case history` auto-merged. Result = upstream + Ecosia's exact delta. |
| `ToolbarKit/ToolbarElement.swift` | 2 | Pure additions in the init signature and body — kept both sides. Ecosia's badge fields are deliberately *not* in `==`; that is pre-existing and was left alone. |
| `ToolbarKit/ToolbarButton.swift` | 4 | Upstream rewrote the badge machinery: added `removeBadgeAndMaskFromSuperview()`, a `bottomBadgeImage` branch, `setContainerIcons`-style `.build(nil)` construction via `badgeContainerView()`, and a `configuration?.image != nil` position branch in `applyBadgeConstraints`. All four Ecosia intents were re-homed onto that: params forwarded from `configure`, template rendering folded into upstream's `.build(nil)` closure, `xOffset`/`yOffset` applied to upstream's *first* position branch only (the one Ecosia's original modified — upstream's new text-button branch left untouched), and the no-mask badge tint kept as `foregroundColorNormal` while preserving upstream's new `theme.isNova ? colors.iconPrivate : …` for the masked case. |
| `LocationView/LocationContainer.swift` | 1 | Upstream renamed `updateShadowOpacityBasedOn(scrollAlpha: CGFloat)` → `(isAddressBarMinimized: Bool)`. Took upstream's signature and converted Ecosia's cached `scrollAlpha` to `isAddressBarMinimized`, so `refreshEditingBorder()`'s `!scrollAlpha.isZero` became `!isAddressBarMinimized`. Kept Ecosia's `guard` → `if` change (it must fall through to refresh the border). `BrowserAddressToolbar` already calls both the new signature and Ecosia's `updateBorder(isEditing:theme:)`. |
| `LocationView/LocationTextField.swift` | 2 | Kept upstream's `lastMarkedText` alongside Ecosia's `commitsAutocompleteOnEndEditing`. **`applyTheme` had a silent loss:** the auto-merge had swallowed upstream's new `editingAccessoryRightView.applyTheme(theme: theme)` *inside* Ecosia's `/* Ecosia: … */` colour block, along with its marked-text refresh block. Both are behaviour, not colour choices Ecosia overrode — they are now live, with only the three colour lines commented out. Note upstream dropped its own `textColor` assignment, so the commented-out original no longer carries one while Ecosia's `textColor` replacement stays. |
| `LocationView/LocationView.swift` | 10 | The largest file here — see the per-conflict notes below. |
| `Toolbars/AddressToolbarContainer.swift` | 2 | Kept Ecosia's `overlayLocationText` / `setOverlayLocationText` passthroughs and took upstream's init (upstream dropped the `isMinimalAddressBarEnabled` parameter). For `applyProgressBarTheme`, Ecosia replaces the whole gradient with its highlighter styling, so upstream's **new Nova early-return** went inside the commented-out original rather than staying live — it is part of the Firefox implementation Ecosia substitutes. |
| `Toolbars/Models/AddressToolbarContainerModel.swift` | 1 | Upstream extracted the `ToolbarElement(…)` construction into `mapAction(_:isShowingTopTabs:windowUUID:)`. Took the extracted call and moved Ecosia's four badge-param forwards **into** `mapAction`, next to upstream's `bottomBadgeImage`. |
| `Redux/AddressBarState.swift` | 3 | Imports merged. For `handleDidSetTextInLocationViewAction`, upstream migrated to the `@Copyable` `.copy()` chain; Ecosia's "preserve `shouldShowKeyboard` / `didStartTyping`" substitution became *omitting* those two `.copy` calls (the chain starts from `state`, so omission preserves), with the Firefox originals kept commented for the next intent diff. `tabsAction`'s incognito badge re-homed onto upstream's new `iconName:`-parameterised signature, with upstream's Nova-derived `badgeImageName`/`isNovaPrivate` locals moved inside the comment block so they don't become unused bindings. |
| `Redux/NavigationBarState.swift` | 5 | Imports merged. Upstream **deleted** `dataClearanceAction` and its gating in `getMiddleButtonAction`, so Ecosia's copies of both went with them. Upstream added a `tabTrayButtonStyle`-derived `iconName` local plus `previousTabScreenshot`/`nextTabScreenshot`: kept live, and **Ecosia's live `tabsAction(numberOfTabs:isPrivateMode:)` call was upgraded to upstream's full signature** so the tab-swipe screenshot preview and the screenshot tab-tray style still work through Ecosia's always-version2 layout. Same incognito-badge re-homing as `AddressBarState`. |

#### `LocationView.swift`, conflict by conflict

1. **`configure`** — kept upstream's new "must be called before updateIconContainer" comment and its `updateIconContainer` call (upstream dropped `iconContainerCornerRadius:`), with Ecosia's `hasSearchTerm:` argument.
2. **`traitCollectionDidChange`** — **dropped.** Upstream deleted the override outright (no replacement trait API in this file); Ecosia had only adapted the `formatAndTruncateURLTextField` call inside it, so nothing Ecosia-owned is lost.
3. **`updateUIForSearchEngineDisplay`** — upstream replaced `removeContainerIcons()` + `addArrangedSubview` with a new idempotent `setContainerIcons(_:)`. Kept it and layered Ecosia's zero-width pin on top, because **`setContainerIcons([])` still leaves the empty stack's width ambiguous** — I checked: it only calls `removeAllArrangedViews()`, so Ecosia's workaround is still required.
4. **`updateUIForLockIconDisplay`** — upstream's `setContainerIcons([lockIconButton])` plus Ecosia's release of the zero-width constraint.
5. **`shrinkLocationView`** — the subtle one. Ecosia's customization is "keep the compact pill tappable so a tap re-expands the bar", implemented at 147.2 by commenting out `self.urlTextField.isUserInteractionEnabled = false` *inside the animation closure*. Upstream 155.1 **moved that line to the top of the method and added a view-level `isUserInteractionEnabled = false`** — and the auto-merge took both, silently re-breaking the behaviour. The phantom comment in the closure was dropped and the removal re-homed to upstream's new location, covering **both** lines (a superview with interaction disabled blocks the text field's touches too).
6. **`configureURLPlaceholder` region** — kept upstream's new `urlTextField.editingAccessoryAction` assignment and Ecosia's conditional first-responder logic, with Firefox's one-line ternary preserved as the commented original.
7. **`formatAndTruncateURLTextField`** — kept upstream's new `configureURLPlaceholder(basedOn:)` method and doc comment, applied Ecosia's `hasSearchTerm:` signature.
8. **`locationTextFieldDidEndEditing`** — took upstream's no-argument signature (the `LocationTextField` protocol declares `func locationTextFieldDidEndEditing()`, so the old `_ textField:` form would not satisfy it) and dropped the `formatAndTruncateURLTextField` call with it, since upstream removed its own. Ecosia's two real behaviours — the `else if isEditing { updateUIForEditingDisplay() }` branch and favicon-instead-of-lock-icon — are kept.
9. **`applyTheme` head** and 10. **`applyTheme` tail** — upstream refactored the colour resolution into `getPrimaryAndSecondaryColors()` and `setTextFieldPlaceholder(color:)`, and **deleted the `urlTextFieldColor`, `urlTextFieldSubdomainColor` and `lockIconImageColor` properties Ecosia was assigning to** (`safeListedURLImageColor` became a local inside `setLockIconImage()`). Ecosia's five colour substitutions were re-homed accordingly: `mainBackgroundColor` at the top, the placeholder colour in the tail, and — the important part — the URL text / subdomain / lock-button tint all now come from a single Ecosia override inside `getPrimaryAndSecondaryColors()`, which upstream routes both `applyTheme` *and* `formatAndTruncateURLTextField` through. The safe-listed dot and lock glyph tints were re-homed onto upstream's locals in `setLockIconImage()`.

Also fixed outside any conflict: `updateUIForEditingDisplay()` (an Ecosia-owned method that auto-merged untouched) still called the **deleted** `removeContainerIcons()` — now `setContainerIcons([])`.

### Tests

| File | Resolution |
| --- | --- |
| `ClientTests/Toolbar/ToolbarMiddlewareTests.swift` | Took upstream — **now byte-identical to upstream**. Ecosia's two edits were stale mock adaptations: `MockWindowManager(wrappedManager:)` (the `tabManager:` parameter has a default, so both forms compile) and a reordered `bootstrapDependencies(injectedTabManager:injectedWindowManager:)` which **would not compile at all** — Swift requires argument order to follow the declaration (`injectedProfile, injectedWindowManager, injectedTabManager, …`). |
| `ClientTests/Toolbar/AddressBarStateTests.swift` (`UD`, 1052 lines deleted by Ecosia) | **Restored upstream's 1382-line file and adapted the assertions Ecosia's behaviour changes.** Unlike ticket 10's deletions, the reason here is still live: upstream's assertions encode Firefox's editing-mode toolbar layout, which Ecosia deliberately replaces. The affected set is small and fully enumerable from Ecosia's substitutions — 4 editing-mode tests (`didPasteSearchTerm`, `didStartEditingUrl` ×2, `didSetTextInLocationView`) where `navigationActions` is `[cancelEditAction]` (count 1, not 0) and `browserActions[0]` is Ecosia's `qrCodeAction` (`.search`, not `.cancelEdit`), plus `didSetTextInLocationView`'s `shouldShowKeyboard` which Ecosia preserves rather than forcing true. Checked and left alone: the three other editing tests only assert `trailingPageActions.count == 0` (unaffected — upstream now guards `!isEditing` there itself); `test_showMenuWarningBadgeAction_*`'s badge/mask assertions are on `menuAction`, which Ecosia does not touch; and the Google Lens test passes `isGoogleLensEnabled: true` straight to the reducer, so it is independent of the suppressed flag. |
| `ClientTests/Toolbar/AddressToolbarContainerModelTests.swift` (`UD`, 263 lines deleted) | **Restored upstream's 431-line file**, with one test adapted: `testSearchWordFromURLWhenUsingGoogleSearchThenSearchWordIsCorrect` asserts a term comes back from `http://firefox.com/find?q=test`, but Ecosia's `searchTermFromURL` guards `isEcosia()` so third-party `q` values (which can carry a chat mode's prompt) never reach the address bar. Replaced with `…WhenUsingNonEcosiaSearchThenSearchWordIsNil`, original preserved in an `/* Ecosia: */` block. The Ecosia-URL path is covered in `EcosiaTests/Core/URLTests.swift`. |
| `XCUITests/ToolbarTest.swift`, `XCUITests/ToolbarMenuTests.swift` (4 + 2 conflicts) | **Took upstream verbatim for both.** `XCUITests` is **not a target in Ecosia's Tuist project** — the only test targets are `AccountTests`, `ClientTests`, `EcosiaSnapshotTests`, `EcosiaTests`, `SharedTests`, `StoragePerfTests`, `StorageTests`, `SyncTelemetryTests`, `SyncTests`, and `grep -rn XCUITests Tuist/ Project.swift` finds nothing. These files are not compiled or run in this repo, so Ecosia's edits (wholesale reverts to `BaseTestCase`, `UrlBar.url` identifiers, etc.) were dead weight; taking upstream leaves zero conflict surface next upgrade. |

`ClientTests/Toolbar/NavigationBarStateTests.swift` auto-merged (`M `) and needed no change — Ecosia had already adapted it to the always-version2 order and the NTP history button, and my `tabsAction` signature upgrade changes neither action counts nor types.

### Lint fixes made as part of this ticket

`swiftlint --strict` (run bare from the repo root) flagged exactly two violations in this file group, both introduced by the merge, both fixed:

- `LocationView.swift:684` `orphaned_doc_comment` — upstream's doc comment for `formatAndTruncateURLTextField` ended up separated from the declaration by Ecosia's `/* Ecosia: */` block. Reordered so the doc comment sits directly above the live signature.
- `ToolbarMiddleware.swift:244` `function_body_length` — `handleToolbarButtonTapActions` hit 109 lines against a 108 limit, because upstream's growth landed on top of Ecosia's ~20 added lines for the QR-code and history cases. Extracted Ecosia's `.search` disambiguation into a small `handleSearchButtonTap(action:toolbarState:)`, which is where the Ecosia-specific logic belongs anyway. (This file is ticket 04's; the change is additive and does not touch its Redux resolution.)

## AC-2: the gesture-handler rename

Fully accounted for, and it needed no work: **Ecosia never referenced either name.** `git grep AddressBarPanGestureHandler c5afa25d3b` hits ten files, all pure-upstream except `BrowserViewController.swift` and `HomepageViewController.swift` — and Ecosia's intent diffs for both contain no `gesture` lines at all. `AddressBarPanGestureHandler` now appears **nowhere** in the tree (including inside remaining conflict regions); `BrowserViewController.swift` uses `tabSwipeGestureHandler` / `TabSwipeGestureHandler` throughout after ticket 10, and `BrowserViewController+TabSwipeGestureHandlerDelegate.swift` is upstream's renamed file.

## Verification

Per the Verification standard above — all static, execution deferred to ticket 19:

- `xcrun swiftc -parse` on all 22 files in the group (15 resolved + 7 auto-merged): clean, zero conflict markers.
- Intent-diff completeness on every file: every Ecosia-added line accounted for, the only absences being the deliberate re-homings listed above.
- Intent-diff sweep over the seven auto-merged (`M `) files in the group — `AddressToolbarUXConfiguration`, `BrowserAddressToolbar`, `PlainSearchEngineView`, `NavigationToolbarContainerModel`, `OverlayModeManager`, `ToolbarMiddleware`, `NavigationBarStateTests`: **zero missing Ecosia lines**.
- Symbol-dependency sweep across all 22 files plus the two Ecosia-owned ones (`EcosiaSearchBarLocationSaver.swift`, `EcosiaTests/UI/Toolbar/LocationViewTests.swift`): every non-SDK symbol resolves. This is what surfaced the deleted `removeContainerIcons`, `urlTextFieldColor`, `urlTextFieldSubdomainColor` and `lockIconImageColor`. `LocationViewTests`' `LocationViewConfiguration(…)` call and `LocationView.configure(_:delegate:isUnifiedSearchEnabled:uxConfig:addressBarPosition:)` both still match the current signatures.
- `cd firefox-ios && tuist generate --no-open` → success.
- `swiftlint --strict` → **zero violations in any ticket 11 file** (repo-wide non-vendor count went 106 → 104).

## Hand-offs and flags

- **Ticket 19, visual check.** Several resolutions are behavioural and only a simulator pass can confirm them: (a) the compact address-bar pill must still re-expand on tap — upstream moved *and widened* the interaction-disabling this ticket had to suppress, so this is the highest-risk item; (b) the editing address bar should show the back arrow on the left and the QR-code button on the right, with no Google Lens affordance; (c) the SERP address bar should show the search query, not the hostname; (d) the private-mode tab button should show Ecosia's incognito badge (12×12, offset +6/−4), not a purple circle; (e) the progress bar should use the Ecosia highlighter colour; (f) the iPad menu button should render the `elipsis` icon rather than a blank slot.
- **Ticket 19, test expectations.** The five assertions adapted in `AddressBarStateTests` and the one in `AddressToolbarContainerModelTests` were derived by reading Ecosia's reducers, not by running them. If any fails, the fix is almost certainly the expectation rather than the production code — but check which.
- **Ticket 00, the five `.xctestplan` files.** Same finding as the XCUITests above applies to them: `XCUITests` has no Tuist target in this repo, and `ExperimentIntegrationTests` / `FullFunctionalTestPlan` / `PerformanceTestPlan` / `SyncIntegrationTestPlan` / `UnitTest.xctestplan` all reference targets Ecosia does not build. Taking upstream's side for all five is very likely the zero-risk resolution; Ecosia keeps its own plans at `EcosiaTests/SnapshotTests/SnapshotTests.xctestplan`. Worth confirming before ticket 19 rather than resolving them blind.
- **Ticket 13 (homepage).** `HomepageViewController.swift` is still `UU` and is the other file that referenced the old gesture-handler name at the Ecosia baseline. Its current worktree text already resolved to `TabSwipeGestureHandler`, so just don't reintroduce the old name.
- **Nested SwiftLint configs.** There are per-directory `.swiftlint.yml` files below the repo root — running `swiftlint` from `firefox-ios/` reports `line_length` violations (limit 120) that the root invocation does not, because a nested config re-enables the rule for the test directories. Another reason to run it bare from the repo root, as ticket 10's notes say.
