# 03: Resolve the Tuist project manifest conflict

**What to build:** The Tuist project manifest (the hand-written source of truth Tuist generates the Xcode project from — not the generated project file itself, which is taken wholesale from upstream and regenerated, never merged) continues to declare Ecosia's customization correctly against the new Firefox manifest structure.

**Blocked by:** 02

**Status:** done

- [x] The single Ecosia customization in the Tuist manifest is reconciled against upstream's new manifest content, per the intent-diff manifest for this file
- [x] `tuist generate` succeeds using the resolved manifest
- [x] No other Ecosia-specific Tuist configuration (targets, build phases, dependencies) was silently dropped in the process

## Comments

### `firefox-ios/Project.swift` never conflicted

It is Ecosia-only (post-dates the fork point), so it and all of `firefox-ios/Tuist/ProjectDescriptionHelpers/` came through the rebase as clean adds. The intent-diff index confirms this: `firefox-ios/Project.swift → NO_BASELINE_AT_147.1`.

The manifest-level conflict that actually blocked `tuist generate` was **`BrowserKit/Package.swift`**, which carries exactly one `// Ecosia:` customization. Treated as this ticket's "single Ecosia customization in the Tuist manifest".

### Caveat on "per the intent-diff manifest for this file"

Followed in spirit, not literally — **there is no intent-diff entry for `BrowserKit/Package.swift`**. It is in neither `core_modified_files.txt` nor `ecosia_owned_files.txt`, so no `.diff` was generated for it. Resolved instead by diffing the file against the fork point (`firefox-v147.2`) directly, which gave the same ground truth the manifest would have. Worth adding to the manifest generator's input list for the next upgrade.

### `BrowserKit/Package.swift` — OnboardingKit resources (substitution)

Ecosia replaces SwiftPM resource auto-discovery with an explicit declaration (Xcode 26 emits conflicting "create directory" / "Ld link" commands for the same bundle path otherwise). Upstream added `IntroVideo.mp4` in 155.1.

Resolution keeps Ecosia's explicit declaration and folds in upstream's new resource:

```swift
resources: [
    .process("Media.xcassets"),
    .process("IntroVideo.mp4")
],
```

`exclude: ["Shaders"]` was **dropped**: upstream deleted `BrowserKit/Sources/OnboardingKit/Shaders/AnimatedGradient.metal` in 155.1 (it exists at `firefox-v147.2` and on the Ecosia side, and git applied the deletion cleanly). The exclude now pointed at a nonexistent path, which SwiftPM warns on. Its explanatory comment went with it; the rest of the Ecosia comment stays.

### Generated artifacts — kept Ecosia's deletion

Ecosia gitignores everything Tuist generates and does not track it (`c5afa25d3b` has no `project.pbxproj` and no `xcshareddata/xcschemes/`). Every such conflict was resolved as "keep the deletion", **not** by merging upstream's copy:

- `firefox-ios/Client.xcodeproj/project.pbxproj`
- 13 × `firefox-ios/Client.xcodeproj/xcshareddata/xcschemes/*.xcscheme` — including `Periphery.xcscheme`, new in 155.1, which git had auto-kept; `tuist generate` removed it from the worktree and the index entry was dropped to match
- `BrowserKit/Package.resolved`, `BrowserKit/.swiftpm/xcode/xcshareddata/xcschemes/Shared.xcscheme`

After regeneration the project carries only Ecosia's schemes: `Ecosia`, `EcosiaBeta`, `EcosiaSnapshotTests`.

### New upstream dependency: ModifiedCopyMacro

155.1 introduces `@ModifiedCopy` and uses it in **32 `Client` source files** (`BrowserViewControllerState`, `MainMenuState`, `AddressBarState`, `ToolbarState`, `TabTrayState`, …) plus `ClientTests/Helpers/ModifiedCopyMacroTests.swift`. Ecosia's Tuist manifest had no equivalent, so nothing would have compiled. Added to match upstream's own `exactVersion 2.2.0`:

- `Packages+Ecosia.swift` — `.remote(url: "https://github.com/WilhelmOks/ModifiedCopyMacro.git", requirement: .exact("2.2.0"))`
- `Targets+Client.swift` — `.package(product: "ModifiedCopy")` on `Client`
- `Targets+Tests.swift` — same on `ClientTests`, which imports the module directly

**Ticket 04 depends on this** — the Redux state files it adapts are the `@ModifiedCopy` consumers.

### Amendment (found during ticket 08): four more undeclared products

This ticket caught the missing **SPM package** (`ModifiedCopyMacro`) but did not sweep **BrowserKit's local products**. Four more were missing from `Targets+Client.swift`, all new at 155.1 and all imported by `Client` sources — `QuickAnswersKit` (9 files), `WebCompatReporterKit` (3), `AppAttestKit` (1), `MLPAKit` (1). Without them the `Client` target could not compile.

Added during ticket 08 and verified in the regenerated project. The lesson for the next upgrade: after reconciling the manifest, diff *every* module imported under `firefox-ios/Client/` against the target's declared dependencies, rather than relying on resolution errors — `tuist generate` succeeds regardless, because a missing Swift module only fails at compile time.

### Two pins bumped — both forced by upstream, neither an Ecosia product decision

`tuist generate` failed twice on unsatisfiable version constraints. In both cases Ecosia's pin was mirroring upstream's own fork-point pin, so the pin was moved to upstream's new value rather than upstream being held back:

| Package | Ecosia pin | Upstream @147.2 | Upstream @155.1 | Now |
| --- | --- | --- | --- | --- |
| Kingfisher | `.exact("8.2.0")` | `BrowserKit` `exact: 8.2.0` | `BrowserKit` `exact: 8.11.0` | `.exact("8.11.0")` |
| glean-swift | `.upToNextMinor(from: "66.3.0")` | `MozillaRustComponents` `from: 66.3.0` | `MozillaRustComponents` `from: 69.0.0` | `.upToNextMinor(from: "69.0.0")` |

Every other Ecosia pin was left alone — including `lottie-ios .exact("4.4.0")` and `swift-certificates .exact("1.2.0")`, which upstream's lockfile lists higher (4.6.1, 1.19.3) but nothing in the graph actually requires. Rule applied: bump only what resolution forces.

> **Heads-up for ticket 18:** glean-swift jumps three majors (66 → 69). Its AC "Ecosia's Glean-wrapper mock still satisfies the current telemetry protocol" should be treated as likely-to-fail, not a formality.

### Lockfile

`firefox-ios/Client.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` is tracked (legacy — it predates the gitignore rule) and had 5 conflict hunks. Not hand-merged: taken from the real resolution output that `tuist generate` produced, 33 pins.

### Verification

- `tuist generate --no-open` → `✔ Success`
- Generated project contains `Client`, `Ecosia`, `EcosiaTests`, `EcosiaSnapshotTests` targets, 56 package references, 17 `ModifiedCopy` references
- No unmerged paths left anywhere in this ticket's scope
- No SwiftPM "unhandled files" / "Invalid Exclude" warnings

### Explicitly left for other tickets

Conflicted, adjacent, but not Tuist manifest scope: `firefox-ios/firefox-ios-tests/Tests/*.xctestplan` (5 files) and `package-lock.json`.
