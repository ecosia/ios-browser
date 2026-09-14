# 05: Adapt to Nova theming (suppressed)

**What to build:** Ecosia's theme manager compiles and behaves correctly against upstream's Nova design-system rename (`isNewAppearanceMenuOn` → `isNovaDesignOn`, the removed `hasMigratedToNewAppearanceMenu`), with Nova itself confirmed suppressed per the product decision — both upstream's own Nimbus default and Ecosia's override should leave it off, so this is a rename/removal fix, not a design adoption.

**Blocked by:** 02

**Status:** done

- [x] Ecosia's theme manager no longer references the renamed/removed upstream properties
- [x] Nova is confirmed off by default after the change (verify the flag default, don't just assume it)
- [x] Every existing Ecosia theme behavior (light/dark/private-mode theme selection, the Ecosia-specific theme overrides) is preserved, per the intent-diff manifest
- [x] `ThemeSettingsControllerTests.swift` (deleted upstream) — the Ecosia-relevant assertions it carried are ported to wherever equivalent coverage now lives, or confirmed no longer applicable

## Comments

### The ticket's premise was slightly off

`isNewAppearanceMenuOn` was **not renamed inside the `ThemeManager` protocol** — it was *removed from the protocol entirely*. At 147.2 the protocol required it; at 155.1 the protocol has neither it nor `isNovaDesignOn`. Nova now lives only as a concrete `public var isNovaDesignOn` on `DefaultThemeManager`.

Consequence: `EcosiaThemeManager` would have *compiled untouched* (extra non-protocol members are legal). The work was still right to do — the names were misleading and the migration code was dead — but nothing forced it. What genuinely did not compile was elsewhere (see the palette section).

### Delta applied to `EcosiaThemeManager`

Mirrored upstream's own 147.2 → 155.1 `DefaultThemeManager` diff, minus Nova adoption:

- `ThemeKeys.hasMigratedToNewAppearanceMenu` — removed
- `isNewAppearanceMenuOnClosure` / `isNewAppearanceMenuOn` → `isNovaDesignOnClosure` / `isNovaDesignOn`
- `hasMigratedToNewAppearanceMenu` accessor — removed
- `migratedTheme()` — removed in full (upstream completed its `FXIOS-11655` cleanup)
- `determineUserTheme()`: `if !isNewAppearanceMenuOn && nightModeIsOn` → `if nightModeIsOn`

**Behaviour is bit-identical.** Ecosia's closure was `{ featureFlags.isFeatureEnabled(.appearanceMenu, checking: .buildOnly) }`, i.e. off, so `!isNewAppearanceMenuOn` was always `true` (the guard was a no-op) and `migratedTheme()` always returned `nil` without side effects. Deliberately **not** adopted: `novaTheme(for:)`, the `isNovaDesignOn` theme branch, the `resolvedTheme`/`windowNonspecificTheme` refactors, and the Nova text-tint appearance code.

`isNovaDesignOn` is kept even though nothing in the file now reads it, so Ecosia's constructor stays signature-compatible with upstream's and ticket 18's `AppDelegate` can mirror upstream verbatim.

### AC 2 — Nova off, verified two ways

1. **Flag default**, read from the merged tree (`firefox-ios/nimbus-features/novaDesignFeature.yaml`): `enabled` default `false`, with explicit `false` overrides for the `beta` and `developer` channels; release inherits the `false` default. `FeatureFlagID.novaDesign` exists and is registered in the Nimbus-backed flag list.
2. **Structurally**, which is the stronger guarantee: `EcosiaThemeManager.getThemeFrom(type:)` has **no Nova branch at all**. Even with the flag forced on, Ecosia cannot return a Nova theme — only `EcosiaLightTheme` / `EcosiaDarkTheme`.

### The real breakage: 27 new palette requirements

`ThemeColourPalette` gained **27 new members** at 155.1 (18 `UIColor`, 8 `Gradient`, 1 `FaviconLetterColorSet`) with **no default extension**. `EcosiaLightColourPalette` conforms directly, so it was missing all 27 and could not compile — nothing in the ticket predicted this.

Added to `EcosiaLightColourPalette` following the file's own established pattern, `var x: T { fallbackTheme.colors.x }`, grouped to match upstream's own sectioning (`gradientAIStrongStop1-3` into Gradient, `faviconLetterColorSet`, then a `// MARK: - Nova tokens` block). `EcosiaDarkColourPalette` subclasses it and overrides `fallbackTheme`, so dark is covered for free. Verified programmatically: **107 requirements, 0 missing** for `EcosiaLightColourPalette`, `EcosiaDarkColourPalette` and `TabTrayPanelSwipePalette`.

### The new Nova theme files needed the standard Ecosia treatment

`NovaDarkTheme.swift`, `NovaLightTheme.swift`, `NovaPrivateTheme.swift` are new upstream files whose palettes conform to plain `ThemeColourPalette` — which does not satisfy Ecosia's `Theme` protocol (`colors: EcosiaThemeColourPalette`). Applied exactly the pattern already used for `DarkTheme`/`LightTheme`/`PrivateModeTheme`: conform each palette to `EcosiaThemeColourPalette` with `var ecosia: EcosiaSemanticColors = FakeEcosiaSemanticColors()` (the helper that exists for precisely this, commented "Should never end up in production UI!"), and widen each `Theme` struct's `colors` to `EcosiaThemeColourPalette`, keeping the original commented above.

### Conflicts resolved

| File | Type | Resolution |
| --- | --- | --- |
| `BrowserKit/…/Theme.swift` | substitution + addition | kept Ecosia's `colors: EcosiaThemeColourPalette`, added upstream's `isNova` requirement *and* its `false` default extension — so no Ecosia theme needs to declare it |
| `…/Animation/TabTrayPanelSwipeTheme.swift` | substitution + addition | needed **both**: the auto-merged init does `self.isNova = from.isNova`, so the stored property is mandatory |
| `EcosiaTests/Mocks/EcosiaMockThemeManager.swift` | rename | Ecosia's renamed class won over upstream's `MockThemeManager`; also dropped its now-dead `isNewAppearanceMenuOn` |
| `…/ClientTests/DefaultThemeManagerTests.swift` | 2 conflicts | `tearDown`: kept Ecosia's synchronous form **and** adopted upstream's new `DependencyHelperMock().reset()`. `createSubject`: took upstream's signature wholesale — the auto-merged body already passes `isNovaDesignOnClosure: { isNovaDesignOn }`, and Ecosia's `#file` was untouched 147.2 content, not a customization |

Also dropped the dead `isNewAppearanceMenuOn` from `EcosiaTests/UI/Themable/ThemableMockThemeManager.swift`.

### AC 4 — confirmed no longer applicable

`ThemeSettingsControllerTests.swift` was `DU` (deleted upstream, modified by Ecosia). Accepted the deletion, on two findings:

1. **There were no Ecosia-relevant assertions to port.** Ecosia's entire diff against 147.2 was test *infrastructure* (MOB-4384): sync `setUp`/`tearDown`, `@MainActor`, and rewiring to Ecosia's `StoreTestUtility` API. Every test case and every expectation was upstream's.
2. **The class under test no longer exists.** Upstream deleted `ThemeSettingsController.swift`, `ThemeSettingsAction.swift` and `ThemeSettingsState.swift`, keeping only `ThemeMiddleware.swift`.

### Product consequence — DECIDED: adopt upstream's screen

Ecosia deliberately shipped the **legacy** appearance screen — at 147.2 `SettingsCoordinator` branched on `themeManager.isNewAppearanceMenuOn` and, with the flag off, pushed `ThemeSettingsController`. Upstream 155.1 **deleted that branch and the controller**, so the merged `SettingsCoordinator` (auto-merged, no conflict) now unconditionally pushes `UIHostingController(rootView: AppearanceSettingsView(...))`.

**Ecosia users will therefore get upstream's new appearance settings screen after this upgrade.** That is a visible UI change, not a no-op, and it is the opposite of the intent recorded in Ecosia's own comment. Two options:

**Decision (product): adopt upstream's `AppearanceSettingsView`.** No production change was needed — the auto-merged coordinator already routes there. The legacy screen is *not* vendored. Still worth a look in ticket 19's simulator pass, since it is a visible change to the appearance settings UI.
