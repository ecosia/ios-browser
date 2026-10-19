# 19: Integrate and verify

**What to build:** The single point where "green" is actually promised for this upgrade. Every other ticket's work has been happening inside one in-progress, uncommitted rebase — this ticket completes it and proves the result is correct end-to-end, not just individually plausible per-vertical.

**Blocked by:** 03, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16, 17, 18

**Status:** done

## What this ticket actually inherited

The plan assumed ticket 19 would start from a fully-resolved tree and just press
`git rebase --continue`. It did not: **404 conflicts were still unresolved**, spread across
localization, asset catalogues, app icons, stickers, CI config, repo governance files, 20 production
Swift files and 36 test files. Finishing the merge was most of this ticket; the build and test work
began only after that.

Two product decisions were escalated and answered before starting (see §3 and the end of this file).

## Acceptance criteria

- [x] `git rebase --continue` completes with no remaining conflicts, producing the final upgrade commits
- [x] `tuist generate` succeeds
- [x] The `Ecosia` scheme builds successfully
- [x] The full `EcosiaTests` suite builds and passes — 947 tests, 7 skipped, **0 failures** (§15)
- [x] All characterization tests from ticket 01 pass against the upgraded code (§15)
- [ ] Agentic iOS Simulator verification against pre-upgrade baseline screenshots — **cannot be satisfied as written** (§16)
- [ ] Any behavior flagged in ticket 01 as infeasible to unit-test is re-verified via the simulator pass — blocked by the same missing baselines (§16)
- [x] The symbol-dependency report is re-run against the final resolved code and comes back clean, or every remaining flag is triaged
- [x] `TabManagerImplementation.swift`'s resolution re-verified, and the stray `.firefox` backup deleted

### AC 1 — rebase complete

Branch `firefox-upgrade-155.1`, two commits on top of `04df3bd66b` (= `firefox-v155.1`):

```
<this commit> Add agent-skills config, upgrade glossary, and 155.1 rebase manifest
c162a7c953    Squash: Ecosia customizations since Firefox v147.2 baseline
04df3bd66b    Localize FXIOS [Strings] Import l10n from 2026-08-27 for v156 (#35430)
```

(`rebase --continue` originally produced `047c614c9f` / `60bf0fa514`; both were rewritten once at the
end of this ticket to fold in the post-rebase fixes, so the hashes above are the final ones. The
second commit is the one carrying this file, hence it cannot name its own hash.)

The second commit applied cleanly, as ticket 02 predicted, because `AGENTS.md` was resolved to
Ecosia's side (checked in advance with `git apply --check --3way`). `.scratch/…/issues/` and
`firefox-ios/Tuist/upgrade/rebase-manifest-155.1/` now exist on disk. Zero unmerged paths; a
repo-wide scan finds no conflict marker outside the three files that legitimately contain them as
documentation/tooling examples (`Tuist/upgrade/TUIST_INTEGRATION_GUIDE.md`,
`ecosia_conflict_helper.py`, `test_conflict_helper.py`).

The post-rebase fixes in §9 and §11–§15 were made after `rebase --continue` and have been folded
back into the squash commit, so the branch is still the two commits above and the upgrade is still a
single commit. Verified after folding: working tree clean, `build-for-testing` succeeds, and
`EcosiaTests` runs 947 tests with 0 failures from the committed state.

### AC 8 — symbol dependency

The pre-upgrade report flagged 32 references across 27 files. Re-checked against the final tree:

- **`SimpleToast` was a true positive** — upstream really did delete it (§9f).
- `BookmarkItem`, `Customization`, `Intro`, `Provider` are false positives: `Ecosia.BookmarkItem`
  lives in the Ecosia module and resolves; the other three are ordinary words occurring in comments.
- The flagged *method* names (`append`, `animate`, `isFeatureEnabled`, …) are the "a flagged symbol is
  often just a name" case recorded as trap 4c2.

More to the point: **the type checker is now the report.** A successful build of the `Ecosia` scheme
proves every non-SDK symbol in the app target resolves — a strictly stronger statement than the
regex scan can make, and the reason ticket 19 exists.
## Findings — part 1: finishing the merge (404 conflicts)

Ticket 19 inherited **404 unresolved conflicts**, so AC 1 could not start until the merge was
actually finished. They fell into eight groups.

### 1. Ecosia deletions honoured (161 paths)

- **83 × `Client/Assets/AppIcons.xcassets/…`** — Ecosia deleted all 196 Firefox app-icon assets at
  the fork point already; upstream only touched them. `git rm`. (The `AppIconSelection` screen
  upstream ships was already in this state pre-upgrade — not a regression to fix here.)
- **63 × `firefox-ios/Sticker/…` and `firefox-ios/sticker/…`** — upstream **case-renamed**
  `sticker/` → `Sticker/` in 155.1; Ecosia had deleted all 59 files at the fork point and nothing in
  Tuist, `Project.swift` or CI references the sticker pack. Both spellings removed.
- **15 × `.github/workflows/firefox-*.yml` etc.** — Ecosia replaced Mozilla's CI with their own six
  workflows and deleted the rest.

### 2. Targets Ecosia does not build (52 paths) — take upstream

Per trap 6, `XCUITests`, `L10nSnapshotTests`, `SyncIntegrationTests` and `ExperimentIntegrationTests`
are not Tuist targets here. Took upstream's side for all of them plus the five `.xctestplan` files
(the open item ticket 00 flagged), and honoured upstream's deletion of three XCUITests files.

### 3. Localization (92 conflicts + 873 collateral files)

Resolved per the product decision recorded in this ticket: upstream's side everywhere, then
`python3 ecosify-strings.py firefox-ios`.

The decisive finding that made this the right call: in `de.lproj/InfoPlist.strings` only
`NSCameraUsageDescription` actually conflicted, but the **auto-merged** part already contained
`"NSSpeechRecognitionUsageDescription" = "Firefox verwendet Spracherkennung…"` — a freshly imported
upstream string with Firefox branding sitting live in Ecosia's build. The script had to run
regardless; it rebranded **873 further `.strings` files** that were never conflicted at all.

Verified afterwards: every remaining "Firefox"/"Mozilla" occurrence in a translated *value* across
the resolved set is a `firefox.com/pair` URL, which the script deliberately preserves. All 92 files
pass `plutil -lint`.

### 4. Asset catalogues (32 conflicts)

Rule applied: Ecosia-owned paths keep Ecosia's blob; upstream-only new assets (`audioWaveLarge`,
`logoGoogleLensMedium`, QuickAnswersKit `Media.xcassets`) take upstream's; Ecosia's deletions are
honoured. Two traps here:

- **Git's rename detection paired unrelated assets.** A blanket "keep theirs" put Ecosia's
  `shareMedium.pdf` `Contents.json` into upstream's `syncLarge.imageset`. Caught by re-hashing every
  resolved asset against `c5afa25d3b:<same path>` and `04df3bd66b:<same path>` — anything matching
  neither side is a rename artifact, not a resolution.
- **Orphaned imagesets.** Ecosia deleted `pinFillLarge` / `saveFileLarge` / `shieldCheckmarkLarge` /
  `downloadLarge` *including* their `Contents.json`; restoring only the `.pdf` would leave an
  `.imageset` directory the asset compiler rejects. Also found `shareMedium.imageset` left with an
  orphan PDF after upstream deleted the whole imageset in 155.1 — removed.

### 5. Repo governance files

`AGENTS.md` / `CLAUDE.md` → Ecosia's, and verified with `git apply --check` that the second rebase
commit's patch still applies to it. `.mergify.yml`, `.githooks/pre-push`, `PULL_REQUEST_TEMPLATE`,
`.github/ISSUE_TEMPLATE/release_checklist_template.md` → Ecosia's (fork-owned process).
`README.md`, `firefox-ios/README.md`, `l10n-screenshots.sh`, `package-lock.json` → upstream's
(Ecosia's side was stale-by-neglect: Xcode 15.4 / Swift 5.6 badges, iOS 17.5 screenshots).
`CONTRIBUTING.md` → Ecosia's header, upstream's body. `.gitignore` → both sides.
### 6. Production Swift (20 files) — the substantive resolutions

- **`TabScrollHandler.swift` / `LegacyTabScrollController.swift`** — Ecosia dropped the
  `.collapsed` half of the toolbar-tap guard (state/visual drift on the minimal pill). Upstream
  deleted **`isMinimalAddressBarEnabled` entirely** in 155.1 — the flag graduated — so Ecosia's
  replacement referenced a symbol that no longer exists. With the flag permanently true, Ecosia's
  guard is vacuous: both now call `showToolbars(animated:)` unconditionally, with the reasoning
  recorded.
- **`SearchLoader.swift`** — Ecosia's `nonisolated(unsafe) var queries` + `DispatchGroup` existed to
  make upstream's shared mutable capture Swift-6-clean. Upstream rewrote the closure with no shared
  mutable state, so the workaround has nothing to guard. Took upstream (trap 5).
- **`AppState.swift`, `ContextualHintEligibilityUtility.swift`, `ContextualHintViewController.swift`,
  `ReaderPanel.swift`, `PrivateModeButton.swift`, `ExperimentEmptyPrivateTabsView.swift`** —
  ordinary substitutions: Ecosia's replacement kept, the commented-out original updated to
  upstream's new version (`theme.isNova ? … : …` in three of them).
- **`ContextualHintView.swift` (BrowserKit)** — misaligned conflict: git paired upstream's two
  brand-new methods (`updateButtonSizeForDynamicFont`, `handleNotifications`) against Ecosia's
  `applyTheme` substitution. The class already declares `Notifiable` conformance from the
  auto-merge, so `handleNotifications` is a *required* member — dropping it would not have compiled.
  Split correctly: Ecosia's theme substitution plus both upstream methods.
- **`TopTabsViewController.swift`** — upstream moved the `privateModeButton` leading constraint out
  of the main array into an `#available(iOS 26)` branch. Ecosia's `safeAreaLayoutGuide`
  customization was **re-homed onto the `else` branch**; leaving it where it was would have silently
  stopped applying (the classic relocation trap).
- **`UserAgent.swift` (BrowserKit/Shared)** — four conflicts. Kept Ecosia's Ecosia-UA substitutions
  and the `defaultFirefoxMobileUserAgent()` split; adopted upstream's `googleDesktopUserAgent` /
  `isGoogleDomain` webcompat override but **ordered it after** the per-domain lookup so Ecosia's
  documented priority (and the MOB-4879 `cf_clearance` fix for ecosia.org) still holds; merged both
  sides' `customDesktopUAForDomain` entries; and **took upstream's Safari version bump 18.6 → 26.4**
  in `safariMobileUA` — Ecosia's delta was the *base builder*, not the version, and these overrides
  exist to look like current Safari, so pinning an old version would re-trigger the very webcompat
  bugs they fix.
- **`AutocompleteTextField.swift` + `ToolbarTextField.swift` — both deleted.** Upstream deleted
  `AutocompleteTextField` in 155.1 (it survives only in focus-ios). Its sole subclass,
  `ToolbarTextField`, has **zero references** in either version and was already dead at the fork
  point; upstream's project simply stops compiling it, while Ecosia's Tuist glob would. Ecosia's own
  customization (relaxing `applyCompletion` to internal) has no caller either — the live autocomplete
  path is `ToolbarKit/LocationTextField`. Removed both.
- **WidgetKit (5 files)** — 155.1 rewrote the widgets around `@Environment(\.theme)`; Ecosia drives
  every colour from their own bundle. `OpenTabsWidget.swift` and `ImageButtonWithLabel.swift` were
  rebuilt from upstream's version with Ecosia's deltas re-applied, which **shrank the customization
  surface substantially**: upstream funnels every content colour through one `contentColor` property,
  so a dozen scattered per-call-site overrides collapsed into a single substitution.

### 7. Tests (36 files)

Triage rule: for each conflict, check whether the Ecosia side carries an `Ecosia:` marker or whether
Ecosia's delta on the file contains one at all. Nine files had **zero** Ecosia markers — their side
was simply the pre-refactor upstream file — and took upstream per hunk.

- **Six Ecosia test deletions honoured** (`SearchViewControllerTests`, `SearchViewModelTests`,
  `TabDisplayPanelTests`, `HistoryDeletionUtilityTests`, `UserAgentBuilderTests`, `RustLoginsTests`)
  plus `TabsPanelStateTests` (deleted by Ecosia, *moved* by upstream into `TabTray/Redux/` — trap 7)
  and `WKFrameInfoExtensionsTest` (deleted by upstream).
- **`RemoteTabPanelStateTests`** — same rename shape but Ecosia had *kept* it; took upstream's
  version at the new path (Ecosia's removals there had no stated reason and `devices` /
  `remoteDevicesChanged` still exist).
- **The `LegacyFeatureFlagsManager` sweep finished.** The seven remaining call sites ticket 18
  handed over were all inside these conflicted files; every one is preceded by
  `DependencyHelperMock().bootstrapDependencies()`, which registers 155.1's replacement, so the line
  was simply dropped. **Zero references remain in the tree.**
- **`ContextualHintEligibilityUtilityTests`** — upstream removed `isToolbarUpdateCFRFeatureEnabled`
  from the utility's init, so Ecosia's bodies could not compile. Rebuilt from upstream, with the two
  `.jumpBackInSyncedTab` expectations inverted to `XCTAssertFalse` (Ecosia disables synced-tab hints)
  and the reason recorded inline.
- **`StatusBarOverlayTests`** — upstream renamed and re-expected all 26 assertions around
  translucency. Rebuilt from upstream with a single `private let theme = LightTheme()` and every
  `LightTheme().colors.layerSurfaceLow` swapped for `theme.colors.ecosia.backgroundPrimary`,
  preserving upstream's alpha handling. Same collapse as the widgets: 13 scattered substitutions
  became one.
- **`UserAgentTests`** — both sides were pure additions (upstream's Google-domain tests, Ecosia's
  Ecosia-UA and MOB-4879 tests); kept both.

### 8. Two pre-existing defects fixed in passing

`firefox-ios/Shared/{en-US,kab}.lproj/Today.strings` shipped with **real conflict markers** from an
old Ecosia merge (`<<<<<<< dc-mob-4329-widgets` / `>>>>>>> develop`) — present in `c5afa25d3b`, absent
from both v147.2 and 155.1, so not a regression from this upgrade. Worse, the kab side that "won"
renamed the *keys* to `TodayWidget.OpenEcosiaxLabel` / `SearchInEcosiaxV2`, which the code
(`String.OpenFirefoxLabel`, `String.SearchInFirefoxV2`) never looks up. Resolved to the correct keys.

### 9. Defects only the compiler could find

Two build failures were genuine upgrade defects; both were invisible to every static check tickets
01–18 relied on.

**a. Duplicated reader-mode resources (build system, not Swift).** 155.1 added
`Client/Assets/reader-mode/{fonts,styles}/` containing four `.otf` files and `Reader.css` that are
**byte-identical** to files already at `Client/Assets/Fonts/` and `Client/Frontend/Reader/Resources/`.
Upstream doesn't notice because their Xcode project lists resources explicitly; Ecosia's Tuist glob
`Client/Assets/**/*.{css,html,png,jpg,jpeg,pdf,otf,ttf}` picks up both, and app resources land flat
in `Client.app`, so the build fails with five `Multiple commands produce …` errors. Fixed by
excluding `Client/Assets/reader-mode/**` from that one glob, which leaves the bundle byte-for-byte
as it was. No Swift file is involved, so no parse, symbol or intent check could have seen it.

**b. `LocationView.formatAndTruncateURLTextField` (trap 2, purest form yet).** Ecosia added a
`hasSearchTerm:` parameter so URL truncation is skipped on SERPs, and adapted the two call sites that
existed at the fork point. 155.1 added a **third** call site inside `configureNonInteractive` — a
method that did not exist at v147.2 — so it auto-merged in calling the old zero-argument signature.
No conflict, no Ecosia marker, nothing for `intent-diff-check.py` to report (the line is upstream's,
not Ecosia's), and `swiftc -parse` accepts it because it is syntactically valid. **Only type
checking finds this.** Fixed by passing `config.searchTerm != nil`, marked like its two siblings.

The lesson to carry forward: when Ecosia *changes a signature*, every new upstream call site is a
silent break. The mirror image of trap 4's "upstream deleted the symbol" — here upstream added a
caller for a symbol whose shape Ecosia had changed.

**c. WidgetKit — four more, all the same root cause.** 155.1 rewrote the widgets around a
`@Environment(\.theme)` value and a `QuickLink.gradient(for:)` / `tintedBackgroundColor(for:)` /
`foregroundColor(for:)` API. Ecosia drives every widget colour from their own bundle and therefore
comments those accessors out, so each *new* upstream reference to them auto-merged in as a live call
to a commented-out symbol:

- `SmallQuickLink.swift` — `entry.link.gradient(for: theme)` in `widgetBackground`; restored Ecosia's
  `Gradient(colors: entry.link.backgroundColors)`.
- `ImageButtonWithLabel.swift`, `SearchQuickLinks.swift`, `TopSitesWidget.swift` — upstream's bare
  `@Environment(\.theme)` is **ambiguous** in these files because they `import Ecosia`, which brings a
  second `Environment` into scope. Ecosia had already hit this and qualifies the wrapper as
  `@SwiftUI.Environment`; the new declarations arrived unqualified. `TopSitesWidget.swift` was not
  even conflicted.

**d. `PhotonActionSheet.UX.bigSpacing` removed upstream.** 155.1 dropped `bigSpacing`, `spacing` and
`smallSpacing` from that UX struct. Ecosia's own `PageActionMenu.swift` (Ecosia-owned, `A `, never
conflicted) was the only consumer left, using it for an iPad `preferredContentSize` adjustment.
Moved the value into `PageActionMenu.UX` as `iPadPreferredContentHeightPadding`.
**e. `BookmarksViewController` — an Ecosia comment block swallowed three brand-new upstream methods.**
Ticket 14's `/* Ecosia: Replace Firefox empty state setup … */` block opened immediately before
`setupEmptyStateView()`. 155.1 inserted `setupLayout()`, `updateLayoutForKeyboard()` and
`updateBottomSearchBarLayout(isHidden:)` at exactly that point, so the merge placed all three
*inside* the comment while their five call sites stayed live. Moved the comment opener down past
them. Same shape as ticket 11's `LocationTextField.applyTheme`, and the reason a comment-aware scan
matters: a plain `grep` sees the declaration and reports no problem.

A comment-aware sweep of the whole tree afterwards (proper nested `/* */` and string handling) found
**no other** live call to a method that exists only inside an Ecosia comment.

**f. `SimpleToast` deleted upstream — vendored.** 155.1 removed
`Client/Frontend/Browser/SimpleToast.swift` and moved its own callers onto a delegate-based
`showToast(message:)` around `Toast`. Ecosia still uses `SimpleToast` in four places, including their
own `SimpleToast+Ecosia` extension. Vendored the v147.2 file verbatim to
`Client/Ecosia/UI/Toast/SimpleToast.swift` with a header explaining the provenance — it is ~140 lines
and depends only on `Toast.UX`, every member of which still exists. Migrating those four call sites
onto upstream's new plumbing is a refactor, not an upgrade step.

**This is the one flagged symbol in the pre-upgrade symbol-dependency report that was a true
positive.** The report's other flagged types — `BookmarkItem`, `Customization`, `Intro`, `Provider` —
were re-checked and are all false positives (`Ecosia.BookmarkItem` lives in the Ecosia module; the
rest are ordinary words appearing in comments).

Also worth recording: adding that one file required re-running `tuist generate` before the build
could see it (trap 3), which cost a full build cycle.
**g. `ReaderPanel.applyTheme`.** 155.1 added `emptyStateView.applyTheme(theme: currentTheme())` for
its `ReaderPanelEmptyStateView` (a `ThemeApplicable`). Ecosia substitutes `EmptyReadingListView`,
held in a `UIView`-typed property, which conforms to `Themeable` instead — it themes itself in `init`
and registers via `listenForThemeChanges`, and has no `applyTheme(theme:)`. Upstream's new line
auto-merged in and does not compile; commented out with the reason.

**h. `MultiplyImpact.swift` was silently deleted by the merge — the most serious defect found.**
A 583-line Ecosia-owned view controller (the referrals / multiply-impact screen, one of the surfaces
AC 6 lists) is present in `c5afa25d3b`, absent from both `firefox-v147.2` and `04df3bd66b`, and was
**gone from `HEAD` after the rebase**. Git matched it as a rename against an upstream-deleted file
and applied the deletion. No conflict, no marker, and nothing for `intent-diff-check.py` to compare
against — a purely Ecosia-created file has no upstream counterpart, so its disappearance produces no
signal at all. Same shape as the `MockThemeManager` loss in trap 2, but on user-facing UI.

Restored from `c5afa25d3b`. The check that finds this class of loss, and that should run once per
upgrade, is a set difference rather than a diff:

```bash
comm -23 <(comm -23 <(git ls-tree -r --name-only c5afa25d3b | sort) \
                    <(git ls-tree -r --name-only firefox-v147.2 | sort)) \
         <(git ls-tree -r --name-only HEAD | sort)
```

i.e. *files Ecosia created on top of the fork point that are missing from the result*. Re-run over the
final committed tree it returns five entries, every one of them deliberate:
`shareMedium.pdf` (orphan asset, §4), `TermsOfServiceManager.swift` (relocated by ticket 17),
`DispatchQueueHelper.swift` (byte-identical duplicate of BrowserKit's, §9), the
`TabManagerImplementation.swift.firefox` backup (§10), and `NativeErrorPageMockModel.swift` (dead
Ecosia mock, §13). `MultiplyImpact.swift` — the one entry that was *not* deliberate — is back.

**i. `WallpaperState.init(windowUUID:wallpaperConfiguration:)` removed.** 155.1 made the memberwise
initializer `private` and added two height fields, so Ecosia's call in
`HomepageViewController+EcosiaSetup` no longer resolved. Added an Ecosia-marked convenience
initializer alongside upstream's own, seeding the two new fields with the same defaults upstream uses.

### 10. `TabManagerImplementation` re-verified, backup deleted (AC 9)

Ticket 10's highest-risk resolution, re-checked now that the code compiles. All four checkpoints hold:

| Check | Result |
| --- | --- |
| `normalTabs` excludes invisible tabs | `tabSplit().normal.filter { !$0.isInvisible }` ✔ |
| `privateTabs` does **not** filter them | `tabSplit().private` ✔ |
| `shouldClearPrivateTabs` default | `?? PrefsKeysDefaultValues.Settings.closePrivateTabs` (MOB-4105) ✔ |
| cookie observer + `searchSettingsChanged` sink in `init`, cancelled in `deinit` | ✔ |

`intent-diff-check.py` reports 3 missing lines, all three being the commented-out original of the
`normalTabs` substitution — i.e. the marker itself, not lost intent.

`firefox-ios/Client/TabManagement/TabManagerImplementation.swift.firefox` — the stray pristine-v147
copy the squash committed by accident — is now unstaged and deleted. No `.firefox` files remain.
## Findings — part 2: getting the test targets to build

The app target building is not the same bar as `build-for-testing`. `ClientTests` and `EcosiaTests`
add ~1,400 more files, and they turned out to hold a distinct family of defects — thirteen more
compile errors over eight iterations, almost none of which resemble the app-target ones.

### 11. Where upstream compiles a file matters as much as what is in it

**a. `NimbusOnboardingTestingConfigUtility.swift` lost its `@testable import Client`.** The file is
byte-identical to upstream — and that is exactly the bug. Upstream compiles this test helper into the
**Client** target (confirmed by walking `Client.xcodeproj/project.pbxproj`'s `PBXSourcesBuildPhase`
entries), where the Nimbus-generated `OnboardingVariant`, `NimbusOnboardingCardData` and `FxNimbus`
are already in scope with no import at all. Ecosia's Tuist globs
`firefox-ios-tests/Tests/ClientTests/**` into `ClientTests`, so the fork's only delta on this file
was the imports needed to make that work — and taking upstream's file wholesale dropped them
(trap 4d, in a form no marker scan can see, because the file has no markers).

The fork-point delta also *removed* the `uiVariant` parameter threading. That back-port is no longer
needed: 155.1's `onboardingFrameworkFeature.yaml` defines `uiVariant`, so upstream's version compiles
once the import is back.

Systematic follow-up: only **three** files under `ClientTests/` are Client-target-only upstream
(`NimbusOnboardingTestingConfigUtility.swift`, `Mocks/MockCreditCardProvider.swift`,
`Search/MockRustFirefoxSuggest.swift`); the other two already carried what they need.

**b. Three files new in 155.1 were never added to upstream's Xcode project.** Upstream therefore
never compiles them, and two of the three do not build as written:

- `NativeErrorPageMiddlewareTests.swift` names `PresentedComponentState(screens:)`. The type is
  `PresentedComponentsState` and the label is `components:`.
- `ToolbarHelperTests.swift` does `await ToolbarHelper(userInterfaceIdiom:)` from a nonisolated
  `XCTestCase`; `ToolbarHelper` is `@MainActor`-isolated and not `Sendable`, so the value cannot
  cross back out. Marked the class `@MainActor`.
- `BrowserProfileRemoteSettingsTests.swift` happens to compile.

Both fixes carry an Ecosia marker naming the cause, because these are upstream defects Ecosia
inherits purely through globbing. Found systematically by intersecting the ClientTests tree with the
basenames present in upstream's `project.pbxproj`.

**This is the mirror image of trap 4 (§9a).** Upstream enumerates sources; Ecosia globs them. That
asymmetry cuts both ways: upstream's *additions* under a globbed path become Ecosia build failures,
and upstream's *omissions* become Ecosia compile errors in code upstream never builds.

### 12. Ecosia's side of a test file is often not a customization — it is an older Firefox

The most surprising finding of the ticket. For a whole family of `ClientTests` files, the fork-point
delta (`git diff firefox-v147.2 c5afa25d3b`) contains **no Ecosia content at all** — it is a
*reverse* diff, because Ecosia's `develop` carried a revision of that file predating the v147.2 tag.
Resolving such a conflict "in favour of HEAD", which looks right, reinstates dead APIs.

Seven files were in this state:

| File | What Ecosia's side actually was |
| --- | --- |
| `Microsurvey/MicrosurveyMiddlewareTests.swift` | Glean-assertion era; merged into a hybrid calling `subject.microsurveyProvider.legacyMiddleware` on a class with no `subject` |
| `Microsurvey/MicrosurveyPromptStateTests.swift` | pre-`FakeActionType` revision |
| `Microsurvey/Mock/MicrosurveyPromptMiddlewareTests.swift` | pre-`MockStoreForMiddleware` revision |
| `Microsurvey/MicrosurveyCoordinatorTests.swift` | `#file`, sync `setUp`, no `trackForMemoryLeaks` |
| `Microsurvey/MicrosurveyStateTests.swift` | same |
| `Microsurvey/MicrosurveyViewControllerTests.swift` | same |
| `Mocks/MockDispatchQueue.swift`, `Mocks/MockDispatchGroup.swift` | pre-call-counter revision, plus a `@testable import Client` that only existed because of the duplicate `Client/DispatchQueueHelper.swift` deleted earlier in this ticket |

All now take upstream's 155.1 file verbatim. The one file in that directory that *does* carry real
Ecosia content — `MicrosurveySurfaceManagerTests.swift`, which asserts that the microsurvey prompt is
suppressed — was rebuilt from upstream with only its four Ecosia marker blocks re-applied, so its
delta is now exactly the customization and nothing else.

Two more of the same shape:

- **`SceneCoordinatorTests`** defined a private `MockSceneIntroScreenManager` that no longer conforms
  to `IntroScreenManagerProtocol` (missing `shouldShowVideoIntro` / `onboardingKitVariant`) and set
  `onboardingVariant = .legacy`, a case that no longer exists. Upstream's shared
  `MockIntroScreenManager(isModernEnabled: false)` is exactly equivalent — `shouldShowIntro` defaults
  to `false` — so the local mock is gone and the file uses upstream's, as upstream does.
- **`ContentContainerTests`** assigned `self.profile`, a property 155.1 deleted.

**Fork drift that is still there, deliberately.** 62 test files carry the same stale sync
`setUp()`/`tearDown()` where upstream has `async throws`. Only one — `MainMenuCoordinatorTests` —
actually broke (`sending 'self' risks causing data races`, because the `@MainActor` class calls
`setupStore()` from a nonisolated override) and was restored to upstream's async shape. The other 61
compile. Rewriting them inside an upgrade commit would bury the real changes; they are listed here as
a follow-up instead.

### 13. Upstream API removals still referenced by Ecosia-authored tests

- **`ToolbarTelemetryTests.swift`** is Ecosia-created (absent at v147.2 *and* at 155.1) but tests
  upstream's `ToolbarTelemetry`. 155.1 removed the data-clearance toolbar button together with
  `dataClearanceButtonTapped` and its `toolbar.data_clearance_button_tapped` metric, and added
  `hasSummarizer:` to `readerModeButtonTapped`. The obsolete test is commented out under a marker;
  the reader-mode call gained the new argument.
- **`TelemetryWrapperTests.swift`** used `ContextualHintType.dataClearance` in three CFR tests.
  Upstream deleted exactly those three tests in the same change, keeping only their `WithoutExtras`
  counterparts. Commented out under a marker rather than silently dropped.
- **`NativeErrorPageMockModel.swift`** is Ecosia-created, was referenced by nothing at the fork point
  and is referenced by nothing now, and constructed `ErrorPageModel` as a struct — 155.1 turned it
  into an `enum`. Deleted.
- **`LaunchCoordinatorTests`** needed an explicit `import Ecosia` for `WelcomeNavigation`, which the
  fork-point file got transitively.

### 14. `StoreTestUtility` — a genuine Ecosia workaround, and a hole in it

155.1 reorganised `StoreTestUtilityHelper`: the `appState + middlewares` entry point became `static`
again, and **every body in the file was wrapped in `#if TESTING`**. Ecosia's Tuist targets define no
`TESTING` compilation condition, so those guards would compile the bodies away and silently leave the
production store in place — which is why the fork's copy has no `#if` at all. That workaround is
still valid (checked: no `TESTING` anywhere in `Tuist/ProjectDescriptionHelpers`), but it had a hole:
the `static setupStore(with appState:middlewares:)` overload had gone missing, and
`AddressBarStateTests` and `BrowserViewControllerStateTests` both call it. Restored, unguarded, with
the reason recorded inline.

### 15. AC 4 / AC 5 — the suites

```
Executed 947 tests, with 7 tests skipped and 4 failures (0 unexpected) in 49.5 seconds
```

All four failures were `EcosiaSearchBarLocationSaverTests`, and they were one defect:

**`EcosiaSearchBarLocationSaver` writes through `AppContainer`, not through its `profile` argument.**
155.1 replaced `FeatureFlaggable.set(feature:to:)` with `UserFeaturePreferring`, and ticket 11
adapted the saver accordingly — but `userPreferences` resolves from `AppContainer`, whereas the tests
assert on a `MockProfile` they construct themselves. `DependencyHelperMock` builds its
`UserFeaturePreferenceManager` over *its own* profile, so every write landed in a different prefs
store than the assertions read (`nil` vs `Optional("bottom")`). Fixed by bootstrapping the container
with the test's profile — `bootstrapDependencies(injectedProfile: profile)`.

Worth flagging beyond this ticket: `saveUserSearchBarLocation(profile:)` now reads from its argument
and writes somewhere else. In production both are the same profile so behaviour is correct, but the
signature is now misleading. Follow-up, not an upgrade fix.

The eight characterization tests from ticket 01 (`FirefoxUpgradeCharacterizationTests`) live in
`EcosiaTests` and passed in the same run — AC 5 is covered by AC 4's execution.

### 16. AC 6 / AC 7 — cannot be satisfied as written

The acceptance criterion asks for post-upgrade screens to be compared against **baseline screenshots
captured before this upgrade began**. Those baselines do not exist:

- No pre-upgrade capture pass was ever run — ticket 01 produced unit-level characterization tests, not
  screenshots, and no ticket between 02 and 18 captured any.
- The repository's own snapshot baselines live in the `SnapshotArtifacts` submodule
  (`firefox-ios/EcosiaTests/SnapshotTests/SnapshotArtifacts`, tracked with `filter=lfs`). `git-lfs` is
  not installed on this machine, so the submodule is not checked out and `EcosiaSnapshotTests` cannot
  run here either. The `EcosiaTests` target excludes `EcosiaTests/SnapshotTests/**`, which is why the
  unit suite is unaffected.

A post-upgrade-only simulator walkthrough would show whether each surface *looks plausible*, but it
cannot show *no regression against the pre-upgrade build*, which is what the criterion asks. Rather
than mark the box on a weaker check, both AC 6 and AC 7 are left open with this note. The honest way
to close them is a comparison pass on a machine with `git-lfs`, against a build of `c5afa25d3b`.

### 17. Two whole-tree sweeps over the finished merge

Both are cheap, mechanical, and would have caught several of the defects above earlier. They compare
four trees: the fork point (`firefox-v147.2`), Ecosia's squash (`c5afa25d3b`), upstream
(`04df3bd66b`) and the result.

**Sweep 1 — Ecosia had no delta, yet the result differs from upstream.** These should be empty; any
entry is a resolution that invented a difference.

```python
for path in upstream_tree:
    if base[path] != ecosia[path]:   continue   # Ecosia customised it — judgment needed
    if current.get(path) == upstream[path]: continue
    report(path)
```

23 hits, all explained: `ToolbarTextField.swift` (deliberately deleted as dead code) and 22
`.strings` files rewritten by `ecosify-strings.py`.

**Sweep 2 — resolved verbatim to Ecosia's side although upstream also changed the file.** These are
where a real upstream improvement can silently vanish.

15 hits. Twelve are Ecosia-owned by design (`.githooks/pre-push`, `.mergify.yml`,
`PULL_REQUEST_TEMPLATE`, eight rebranded PDFs, `it.lproj/Intro.strings`). The three Swift files were
each checked by hand and had already converged: `CrashManager.swift` carries 155.1's
`enableNetworkBreadcrumbs = false` and its `configureProfiling` block (Ecosia had made the same
profiling change independently, ahead of upstream); `SentryWrapper.swift` already used
`SentrySDK.lastRunStatus == .didCrash`; and `MockNotificationCenter`'s Ecosia copy is a strict
superset of upstream's.

A third sweep is worth adding next time — **files whose result is neither side verbatim** (a hybrid).
That is where the three broken Microsurvey files in §12 hid, and neither sweep above can see them.

## Open items and hand-offs

### Environment, not the upgrade

- **Xcode macro trust.** The first build failed with `Macro "ModifiedCopyMacros" from package
  "ModifiedCopy" must be enabled before it can be used`. This is Xcode's macro-validation gate, not
  an upgrade defect — approve it once in Xcode, or pass `-skipMacroValidation` (what every build in
  this ticket used). It predates the upgrade; `ModifiedCopy` was already a dependency.
- **`git-lfs` is not installed on this machine**, so the `SnapshotArtifacts` submodule
  (`firefox-ios/EcosiaTests/SnapshotTests/SnapshotArtifacts`, tracked with `filter=lfs`) is not
  checked out. `EcosiaSnapshotTests` therefore cannot run here. The `EcosiaTests` target explicitly
  excludes `EcosiaTests/SnapshotTests/**`, so this does not block the unit suite.

### Still open in ticket 00

- The five `.xctestplan` files, the sticker PNGs and the l10n workflow entry are now resolved (see §1
  and §2 above); ticket 00 should be updated. `package-lock.json` took upstream's side, matching the
  auto-merged `package.json`, and `npm ci && npm run build` succeed.

### Product decisions taken during this ticket

- **Localization:** upstream's side for every conflicted `.strings` file, then
  `python3 ecosify-strings.py firefox-ios`. Decided explicitly rather than guessed; the deciding
  evidence is in §3.
- **"Scan QR Code" quick action:** left as-is. It is dead (no `ShortcutType.qrCode`, no handler) and
  was already dead before this upgrade, so it is a pre-existing bug to file separately, not something
  to change inside an upgrade commit.

### For the next upgrade — additions to the trap list

1. **A purely Ecosia-created file can disappear with no signal at all.** `MultiplyImpact.swift` (§9h).
   Add the `comm`-based set difference in §9h to the standard verification recipe; it is the only
   check that can see this.
2. **When Ecosia changes a signature, every new upstream call site is a silent break.** Two instances
   this upgrade: `formatAndTruncateURLTextField` gained a third caller, and `ToolbarElement.init`
   gained a parameter *ahead of* Ecosia's, breaking argument order at a call site. Neither conflicts.
3. **When Ecosia's strategy is "silence/replace everything", every upstream addition is a hole in it.**
   Ticket 18 found this in `GleanWrapper`; ticket 19 found four more in WidgetKit (§9c).
4. **Build-system defects are invisible to every source-level check.** The duplicated `reader-mode`
   resources (§9a) produced five `Multiple commands produce …` errors and involve no Swift at all.
   Upstream's Xcode project lists resources explicitly; Ecosia's Tuist globs. Any upstream directory
   *addition* under a globbed path is a candidate.
5. **Where upstream compiles a file matters as much as what is in it.** Walk
   `Client.xcodeproj/project.pbxproj` and diff its source list against the globbed tree in *both*
   directions: files upstream compiles into a different target than Ecosia does (§11a), and files
   upstream compiles into no target at all (§11b). Neither is visible to any content-level check.
6. **Ecosia's side of a test file is often an older Firefox, not a customization.** Before resolving a
   test conflict in favour of HEAD, run `git diff <fork-point> <ecosia-head> -- <file>` and look for
   any Ecosia content in the delta. If it reads as a *reverse* upstream diff, take upstream (§12).
7. **A green app build is not a green test build.** Eight further compile iterations lived entirely in
   the test targets and failed for reasons the app target cannot exhibit at all.
8. **Comment-aware scanning is worth building once.** A plain `grep` cannot tell a live declaration
   from one inside an `/* Ecosia: */` block; three separate checks in this ticket only became useful
   after handling nested block comments and string literals correctly (§9e).

### Follow-ups (deliberately out of scope for an upgrade commit)

- **`EcosiaSearchBarLocationSaver.saveUserSearchBarLocation(profile:)` reads from its argument and
  writes through `AppContainer`** (§15). Correct in production, where the two are the same profile,
  but the signature is misleading — and it cost four test failures to notice.
- **62 test files carry stale sync `setUp()`/`tearDown()`** where upstream has `async throws` (§12).
  All but one compile; rewriting them inside this commit would bury the real changes.
- **Three `RustFxA/*.swift` files are picked up by the Client glob**, so `RustFirefoxAccounts` exists
  in two modules and `MockProfile` has to qualify it as `Client.RustFirefoxAccounts`. Excluding them
  from the glob would put the type back in one module.
- **`Tuist/ProjectDescriptionHelpers/Schemes+Ecosia.swift` still lists six skipped test classes that
  no longer exist** — `AdjustTelemetryHelperTests`, `PrivateBrowsingTelemetryTests` (deleted in ticket
  18), `OnboardingTelemetryDelegationTests` (ticket 17), and `DefaultSearchPrefsTests`,
  `StoriesFeedTelemetryTests`, `ToastTelemetryTests` (removed upstream). Xcode ignores skip entries
  for tests it cannot find, so they are inert — but they are exactly the kind of debt that misleads
  the next upgrade. Left alone deliberately: editing the scheme mid-verification would have forced
  another `tuist generate` and invalidated an in-flight test build.

### Before pushing

- `git-lfs` is required to check out `SnapshotArtifacts` and run `EcosiaSnapshotTests`; neither was
  possible here.
- Every build in this ticket passed `-skipMacroValidation`. On a machine where Xcode's macro trust
  prompt has been answered for `ModifiedCopy`, the flag is unnecessary; in CI it is required. This
  predates the upgrade.
- AC 6 and AC 7 are open by design (§16), not by omission.
