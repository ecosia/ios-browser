# 14: Bookmarks vertical

**What to build:** Bookmarks continue to behave correctly for Ecosia users after upstream's new Bookmark Folder Tree redesign.

**Blocked by:** 10

**Status:** done

- [x] The bookmarks view controller's Ecosia customization is reconciled per the intent-diff manifest against the folder-tree redesign
- [x] `BookmarkPanelViewModelTests` and `DefaultBookmarksSaverTests` are updated alongside the production code
- [x] The `BookmarkItem` symbol flagged in the symbol-dependency report as possibly renamed/removed is resolved — **the flag was a false positive; see Findings §4.** No change to `BookmarksExchange.swift` was needed

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


---

# Findings (session completing ticket 14)

**Outcome:** 5 conflicted files and 2 delete/modify conflicts resolved, plus 3 auto-merged files
corrected. Unmerged count 472 → 465. No commits.

## 1. Scope

| State | File | Resolution |
| --- | --- | --- |
| `UU` 5 | `Client/Frontend/Library/Bookmarks/BookmarksViewController.swift` | see §2 |
| `UU` 13 | `…/XCUITests/BookmarksTests.swift` | took upstream — trap 6 (re-confirmed: `grep -rn XCUITests firefox-ios/Tuist/ firefox-ios/Project.swift` is still empty) |
| `UU` 9 | `…/ClientTests/Library/Bookmarks/BookmarkPanelViewModelTests.swift` | took upstream, see §5 |
| `UU` 3 | `…/ClientTests/Library/Bookmarks/DefaultBookmarksSaverTests.swift` | took upstream, see §5 |
| `UU` 1 | `…/ClientTests/CanRemoveQuickActionBookmarkTests.swift` | took upstream, see §3 |
| `DU` | `Client/BookmarkItemsHelper.swift` | accepted upstream's deletion, see §4 |
| `UD` | `Client/Assets/Images.xcassets/bookmarkTrayLarge.imageset/bookmarkTrayLarge.pdf` | completed Ecosia's deletion, see §6 |
| `M ` | `…/ClientTests/Coordinators/Library/BookmarksCoordinatorTests.swift` | took upstream, see §5 |
| `M ` | `MozillaRustComponents/…/Places/Bookmark.swift` | took upstream (brace-style only) |
| `M ` | `…/ClientTests/Frontend/Homepage/Redux/BookmarksMiddlewareTests.swift` | left as-is (class annotations only) |
| `A ` | `Client/Ecosia/Bookmarks/BookmarksExchange.swift`, `Client/Ecosia/UI/EmptyBookmarksView{,Delegate}.swift`, `Ecosia/Core/Bookmarks/*`, the Ecosia bookmark imagesets | verified, unchanged |

**Both bookmark feature flags are off on every channel** (`bookmarksSearchFeature` and
`newBookmarkFolderTreeFeature`: variable default `false`, beta `false`, developer `false`, no release
override). Both yaml files are clean upstream — no Ecosia delta, not conflicted. So the folder-tree
redesign this ticket is named after, and the new bookmarks search bar, are both dark in every Ecosia
build; the reconciliation below is about the code still compiling and behaving, not about a visible
UI change.

## 2. BookmarksViewController — upstream added a search mode around Ecosia's customizations

Ecosia owns four things here: the **More button** (import/export) in the toolbar, the **Ecosia empty
state** replacing `BookmarksFolderEmptyStateView`, the **import/export extensions**, and the
`EmptyBookmarksViewDelegate` conformance. All preserved. What had to be re-adapted:

- **Toolbar.** Upstream restructured `toolbarButtonItems` around a computed `searchItems` and added a
  `.bookmarks(state: .search)` case. Ecosia's substitution became
  `return [moreButton] + searchItems + [flexibleSpace, bottomRightButton]`. Ecosia's two
  `if #available(iOS 26.0, *) { bottomRightButton.tintColor = … }` lines went with upstream — they were
  upstream v147.2 code Ecosia never customized, and upstream moved that tinting into
  `applyThemeToButtons()`.
- **`viewModel.bookmarkNodes` no longer exists.** `BookmarksPanelViewModelProtocol` replaced it with
  `displayedBookmarkNodes` (filtered when searching) plus `isCurrentFolderEmpty`; on the concrete class
  the backing array is now `private var allBookmarkNodes`. One use was inside a conflict
  (`deleteBookmarkNodeAtIndexPath` → `displayedBookmarkNodes`), **the other was not**: Ecosia's own
  `updateEmptyState` used `viewModel.bookmarkNodes.isEmpty` and auto-merged clean. Rewritten to
  `viewModel.isCurrentFolderEmpty`.
- **Ecosia's `updateEmptyState` also predated the search state.** Adopted upstream's
  `&& state != .bookmarks(state: .search)` guard, so the Ecosia empty view (with its "import bookmarks"
  and "learn more" actions) cannot cover an empty *search result*, and upstream's trailing
  `sendPanelChangeNotification()` — which exists so the toolbar's search button appears/disappears with
  emptiness. Verified `sendPanelChangeNotification` is a bare `NotificationCenter.post`, so adding it is
  inert today (search flag off) and correct if the flag is ever enabled.
- The other three conflicts were plain both-sides additions (new upstream search properties/button vs.
  Ecosia's `bookmarksExchange`; the two files' new extensions at EOF).

Confirmed intact after the merge: `UIGestureRecognizerDelegate`/`FeatureFlaggable` conformances,
`setupLayout`, `bottomStackView`, `updateLayoutForKeyboard`, `updateBottomSearchBarLayout`,
`bottomSearchButtonAction`, `applyThemeToButtons`, `resetSearch`, and the `UISearchBarDelegate` /
`KeyboardHelperDelegate` extensions.

## 3. `CanRemoveQuickActionBookmarkTests` — a rename that auto-merged into an inconsistent file

Upstream renamed `BookmarksHandlerMock` → **`MockBookmarksHandler`**, replaced its
`callGetRecentBookmarksCompletion(with:)` method with a `getRecentBookmarksResult` property, and made
`CanRemoveQuickActionBookmark.removeBookmarkShortcut` **`static`**
(`removeBookmarkShortcut(withBookmarksHandler:withQuickActions:)`).

The merge produced a file that could not compile: the property declaration and `setUp` line 21 took
upstream's `MockBookmarksHandler`, the conflict region still held Ecosia's `BookmarksHandlerMock()`
(**a type that no longer exists anywhere in the tree**), and the two test bodies auto-merged to
Ecosia's stale instance-method calls. Ecosia's delta here is entirely unmarked convention noise
(class-level `@MainActor`, sync `setUp`, `@unchecked Sendable`, `nonisolated(unsafe)`), so upstream's
file was taken whole.

## 4. AC-3: the `BookmarkItem` flag was a false positive (name collision)

The symbol-dependency report flagged `BookmarkItem` as possibly renamed/removed, and it *was* removed —
but not the one `BookmarksExchange.swift` uses.

There were **two** `BookmarkItem` types in this tree:

- `protocol BookmarkItem` (plus `struct Bookmark`) in `Client/BookmarkItemsHelper.swift` — Firefox's,
  **deleted upstream in 155.1**;
- `public enum BookmarkItem` in `Ecosia/Core/Bookmarks/Bookmark.swift` — Ecosia's own, present and
  unchanged.

`BookmarksExchange.swift` and `BookmarksViewController.swift` already write **`Ecosia.BookmarkItem`**,
module-qualified precisely because of that collision. So no successor had to be found and no change was
needed — the AC is satisfied by verification, not by an edit.

`BookmarkItemsHelper.swift` itself was `DU` (upstream deleted, Ecosia had added two imports to it).
Accepted the deletion after confirming: nothing in `Client`, `Shared`, `Storage` or the tests references
`BookmarkItem` (the protocol) or constructs `Bookmark(title:url:)`/`Bookmark(bookmark:)`; the only
remaining `Bookmark` hits are string literals and `Action.Bookmark` in UI tests. Upstream had migrated
its own last use — `DefaultBookmarksSaverTests`' `let testBookmark = Bookmark(title:url:)` became a
tuple in 155.1, which is corroborating evidence that the deletion is deliberate and complete. Deleting
it also removes the collision that forced the `Ecosia.` qualification in the first place.

## 5. Test files taken from upstream (AC-2), and why the Ecosia versions were dropped

The production types these tests cover — `BookmarksPanelViewModel`, `BookmarksSaver.swift`,
`BookmarksCoordinator` — are **byte-identical to upstream with zero Ecosia delta**. Every Ecosia change
in the three test files was either unmarked staleness or a back-port that upstream has since shipped:

- **`BookmarkPanelViewModelTests`** — Ecosia's `createSubject` injected a `MockDispatchQueue`
  (MOB-4384), but `BookmarksPanelViewModel.init` **no longer takes a dispatch queue at all**, so that
  customization has no attachment point left. Its `MobileGuid_atFive` rewrite and
  `NotMobileGuid_minusIndex` clamp assertion were explicitly described in their own comments as
  "matching upstream v147.5's showingDesktopFolder variant" — upstream 155.1 now ships exactly those
  variants (`showingDesktopFolder_zeroIndex`/`_minusIndex` via a `createDesktopBookmark` helper and
  `bookmarksInTreeValue`). Its commented-out `testShouldReload_whenMobileEmptyBookmarks` ("temporarily
  remove due to a bookmark inconsistency": Ecosia's copy expected 1 desktop folder where upstream
  expected 0) is moot — upstream 155.1 expects 0 and only creates the desktop folder when
  `bookmarksInTreeValue > 0`. Ecosia's version also still used `subject.bookmarkNodes`, which is now a
  **computed property with no setter**, so `subject.bookmarkNodes.append(…)` could not compile.
- **`DefaultBookmarksSaverTests`** — Ecosia inlined `BookmarksSaverTestsHelper` into the test class and
  deleted `testRestoreBookmarkNode_restoreSeparator/_restoreFolder/_restoreBookmark` and
  `testCreateBookmark_createsNewBookmark`, with no stated reason; `restoreBookmarkNode` and
  `createBookmark` both still exist in the unchanged production file. Upstream 155.1 additionally added
  two `testCreateBookmark_*` tests that use the very helper Ecosia inlined away. Ecosia's only marked
  changes (two MOB-4384 notes about `.success(nil)`) document an assertion form upstream already used.
- **`BookmarksCoordinatorTests`** (auto-merged, not conflicted) — Ecosia deleted
  `testShowSignInViewController`, both `testShowQRCode_*` and `testDidFinishCalled` with no marker. All
  four APIs still exist on the unchanged `BookmarksCoordinator`; the one-argument
  `showQRCode(delegate:)` calls still compile via the default-argument overload in
  `extension QRCodeNavigationHandler`. Note the merge had already pulled in upstream's two *new* tests
  (`…InteractivePopGesture…`, `testShowBookmarksDetail_forFolder_doesNotLeakController`) and
  `MockInteractivePopGestureDelegate` alongside Ecosia's deletions.

All three files are now byte-identical to upstream, restoring roughly a dozen tests.

## 6. `bookmarkTrayLarge.imageset`

`UD` — Ecosia deleted the imageset (they use their own `bookmarksEmpty`), upstream touched the pdf.
Completed Ecosia's deletion after confirming `bookmarkTrayLarge` is referenced only from *inside* Ecosia
comment blocks (`MainMenuConfigurationUtility`, ticket 12) and nowhere in live code. The similarly named
`bookmarkTrayFillLarge.imageset` is a different asset and still present, which is what
`LibraryViewModel`'s live code uses.

## 7. Verification — all static, nothing executed

- `xcrun swiftc -parse` on all 11 touched files plus the Ecosia-owned bookmark sources
  (`BookmarksExchange`, `EmptyBookmarksView{,Delegate}`, `Ecosia/Core/Bookmarks/*`) — clean; zero
  conflict markers in the group.
- `intent-diff-check.py` over the group. Every `missing` entry maps to a decision above; the three in
  `BookmarksViewController` are exactly the `moreButton`/`bookmarkNodes` re-adaptations of §2, and the
  large lists belong to the files deliberately taken from upstream (§3, §5) and the XCUITest (trap 6).
- `symcheck.py` over the same set — every unresolved name is UIKit/XCTest/rust-wrapper-internal noise.
  Spot-verified the Ecosia-owned dependencies by hand: `BookmarksExchangable.export`/`` `import` ``,
  `Analytics.bookmarksPerformImportExport(_:)`, the five `String.localized` keys
  (`bookmarksPanelMore`, `importBookmarks`, `exportBookmarks`, `bookmarksExportFailedTitle`,
  `bookmarksImportFailedTitle`), `URLProvider.bookmarksHelp`,
  `AccessibilityIdentifiers.LibraryPanels.bottomLeftButton`, and `EmptyBookmarksView`'s
  `init(initialBottomMargin:)` / `applyTheme(theme:)` / `delegate`.
- `cd firefox-ios && tuist generate --no-open` — **Success** (run after the two file deletions).
- `swiftlint lint --strict --quiet`, bare from the repo root — **no violation in any ticket-14 file**.
  Non-vendor count 99 → 93.

## 8. Handed to ticket 19

1. **`EmptyBookmarksView.init(initialBottomMargin:)` ignores its parameter** (pre-existing, not
   introduced here). Harmless, but it means the Ecosia empty view's bottom margin is whatever `setup()`
   hardcodes.
2. **Ecosia's empty state is added directly to `view` with an autoresizing frame**, while upstream's now
   lives in an `a11yEmptyStateScrollView`. With the search bar's `bottomStackView` also in `view`, the
   z-order/`bringSubviewToFront` interaction is only observable at runtime — worth one look if the
   bookmarks-search flag is ever turned on.
3. **The four `BookmarksCoordinator` tests restored in §5 have never run in this fork.** They are
   upstream's, against unchanged upstream code, so the risk is low — but they are new coverage here.
