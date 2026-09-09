# 07: Configure suppressed and limited feature flags

**What to build:** The product decisions on which new upstream features are exposed take effect via configuration, not code changes: VPN promotion fully off, Ad Blocker available as a real functional setting but without its Site Menu badge/promotional surfacing, Nova confirmed off (cross-check with ticket 05, which fixes the code that would otherwise break when this flag is queried).

**Blocked by:** 02

**Status:** done

- [x] VPN feature flag is off; no VPN entry point is reachable anywhere in the app
- [x] Ad Blocker's functional flag is on (available in Browsing settings) while its badge/promotional variable is off (no Site Menu callout)
- [x] Nova's flag is confirmed off (shared verification with ticket 05)
- [~] A quick manual/simulator pass confirms none of the three surfaces appear where they shouldn't — *not possible: 548 unmerged files, nothing builds. Verified instead from the generated Nimbus code, which is stronger than a visual check for "is the flag off"; the visual confirmation is deferred to ticket 19*

## Comments

### Channel mapping established first

All three Nimbus channels ship for Ecosia, so every one had to be checked — the fix is not just "the default":

| Ecosia build configuration | `MOZ_CHANNEL_*` | Nimbus channel |
| --- | --- | --- |
| `Release` (App Store) | `RELEASE` | `release` |
| `Development_TestFlight`, `Development_Firebase` | `BETA` | `beta` |
| `Debug`, `BetaDebug`, `Testing` | `FENNEC` | `developer` |

Mapping comes from `firefox-ios/bin/nimbus-fml-configuration.sh`, which Ecosia has already extended with its own configuration names.

### Changes made — configuration only, no code

**`vpnFeature.yaml`** — upstream shipped `developer: enabled: true`. Set to `false`, so VPN is off on release, beta *and* developer. Follows Ecosia's existing convention in `firefoxSuggestFeature.yaml`: override the channel entry, leave upstream's variable default alone, add a `# Ecosia:` reason.

**`googleLensFeature.yaml`** — **gap in this ticket, closed later by ticket 10.** This ticket resolved `NimbusFeatureFlagLayer`'s new `checkGoogleLensFeature()` but never configured the YAML, which upstream shipped with `developer: enabled: true`. Google Lens is not an Ecosia product surface, so it is now `enabled: false` on beta and developer, same convention as `vpnFeature.yaml`. Note the flag is the *second* gate — every entry point also requires `defaultEngine.isGoogleEngine` — but the flag alone selected the camera-permission alert copy, so Debug builds were showing Google Lens wording in Ecosia's QR-scanner alert.

**`adBlockerFeature.yaml`** — textbook promotional suppression. Upstream had `badge-enabled: true` on beta and developer, and a variable default of `enabled: false` that release would have inherited. Now every channel is `enabled: true` + `badge-enabled: false`. A `release` entry is listed **explicitly** rather than changing upstream's variable default, so the Ecosia override sits in the `defaults:` block where the convention lives and upstream's own default is untouched.

### Verified from generated code, not by reading YAML

`bin/nimbus-fml.sh` ran clean, and the manifest **validates on all three channels** (`✅ developer / ✅ beta / ✅ release`). Regenerating `Client/Generated/FxNimbus.swift` per configuration gives the actually-resolved values:

| Channel | `VpnFeature.enabled` | `AdBlockerFeature.enabled` | `AdBlockerFeature.badgeEnabled` | `NovaDesignFeature.enabled` |
| --- | --- | --- | --- | --- |
| release | `false` | `true` | `false` | `false` |
| beta | `false` | `true` | `false` | `false` |
| developer | `false` | `true` | `false` | `false` |

The generated files are gitignored (`.gitignore:76`), so nothing leaked into the rebase.

### AC 1 — VPN is doubly off

Beyond the flag, **155.1 ships no VPN UI at all.** Tracing every `vpn` reference in `Client` finds only: the `FeatureFlagID.vpnFeature` case, the Nimbus layer's `checkVPNFeature()`, and a toggle row in `FeatureFlagsDebugViewController` (the hidden debug screen). **Nothing gates a user-facing entry point on it** — upstream landed the flag ahead of the feature. So "no VPN entry point is reachable" holds by construction, not just by configuration. (The `vpn` hits in BrowserKit are public-suffix entries like `in-vpn.de` in `EffectiveTLDNames.swift`.)

### AC 2 — traced both surfaces to their gates

- **Function on:** `BrowsingSettingsViewController` wraps the row in `if featureFlagsProvider.isEnabled(.adBlocker)`, so the Block Ads toggle appears. `FirefoxTabContentBlocker` then gates the actual blocking on `isEnabled(.adBlocker) && userPrefs.boolForKey(PrefsKeys.BlockAds)` — capability available, user in control.
- **Promotion off:** `MainMenuViewController` builds the badge behind `guard featureFlagsProvider.isEnabled(.adBlocker), featureFlagsProvider.isEnabled(.adBlockerBadge) else { return nil }`. With `badge-enabled: false` the badge is `nil`, so there is no Site Menu callout.

The two flags are genuinely independent in the layer — `checkAdBlockerFeature()` reads `.enabled`, `checkAdBlockerBadgeFeature()` reads `.badgeEnabled` — which is what makes this suppression possible without touching code.

Note for **ticket 12**: the Ad Blocker *menu entry* is separate from the badge and is not suppressed, matching that ticket's "Ad Blocker present without a badge".

### AC 3 — Nova

Confirmed off on all three channels in the table above. Ticket 05 additionally established the structural guarantee: `EcosiaThemeManager.getThemeFrom(type:)` has no Nova branch, so no Nova theme can be produced even if the flag were forced on.

### One code change, and why it was a deletion

`NimbusFeatureFlagLayer.swift` had one conflict: upstream added `checkGoogleLensFeature()`, Ecosia had `checkMenuDefaultBrowserBanner(from:)` suppressing Firefox's menu default-browser banner (MOB-3998). Kept upstream's, **deleted Ecosia's** — it was dead code: upstream removed `menuRefactorFeature` entirely (its YAML is gone, and there is no `FeatureFlagID` case or switch case for `menuDefaultBrowserBanner`), so there is no longer a banner to suppress. Upstream's method by contrast is required — `.googleLens` is wired through `FeatureFlagID` and the layer's switch.

**Manifest gap worth fixing:** `NimbusFeatureFlagLayer.swift` has **no entry in `core_modified_files.txt` and no intent diff**, despite carrying an Ecosia customization. Verified against the fork point directly (`git diff firefox-v147.2 c5afa25d3b`) to confirm that suppression was Ecosia's *only* change to the file — so nothing was silently lost. This is the second such gap after `BrowserKit/Package.swift` in ticket 03; the manifest generator's input list needs review before the next upgrade.

The file is now byte-identical to `firefox-v155.1`, which is the ideal end state — zero conflict surface next time.

### Adjacent conflicts left for their owners

`hntSponsoredShortcutsFeature.yaml` (homepage/sponsored shortcuts → ticket 13), `SummarizerNimbusUtils.swift`, and `NimbusOnboardingFeatureLayerTests.swift` (→ ticket 17) are Nimbus-adjacent but not flag-suppression decisions.
