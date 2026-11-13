# 📸 Snapshot Coverage Map

When you change a component listed here, update its snapshot test and re-record references in the `SnapshotArtifacts` submodule in the same PR.

The table below is generated from `firefox-ios/EcosiaTests/SnapshotTests/snapshot_coverage.json`. After adding coverage, update that file and run `./generate_snapshot_coverage_docs.sh` from the repo root.
Entries may use directory globs so new files in a covered feature are included automatically. The
registry's `sharedSourcePatterns` cover cross-cutting visual inputs such as themes, design tokens,
localization, and asset catalogs; changes to those inputs also run snapshot tests.

<!-- snapshot-coverage-map:start -->
| UI area | Source (primary) | Snapshot test | Locales / themes |
| --- | --- | --- | --- |
| Welcome screen | `Ecosia/UI/ProductTour/**` | `OnboardingTests.testWelcomeScreen` | all locales, light only |
| Customize button (on wallpaper) | `Client/Ecosia/UI/NTP/Header/**` | `HomepageComponentTests.testEcosiaCustomizeButton_onWallpaper` | en, light + dark |
| Customize button (solid background) | `Client/Ecosia/UI/NTP/Header/**` | `HomepageComponentTests.testEcosiaCustomizeButton_onSolidBackground` | en, light + dark |
| Account nav button (logged out, on wallpaper) | `Client/Ecosia/UI/NTP/Header/**` | `HomepageComponentTests.testEcosiaAccountNavButton_loggedOut_onWallpaper` | en, light + dark |
| Account nav button (logged out, solid background) | `Client/Ecosia/UI/NTP/Header/**` | `HomepageComponentTests.testEcosiaAccountNavButton_loggedOut_onSolidBackground` | en, light + dark |
| Impact cell | `Client/Ecosia/UI/NTP/Impact/**` | `HomepageComponentTests.testNTPImpactCell_withImpactRows` | en, light only |
| NTP search bar | `Client/Ecosia/UI/NTP/SearchBar/**` | `HomepageComponentTests.testNTPSearchBar_resting` | all locales, light + dark |
| Pinned top site cell | `Client/Ecosia/Frontend/Home/TopSites/**` | `HomepageComponentTests.testTopSiteItemCell_pinned` | en, light + dark |
| Omnibox upload drawer | `Ecosia/UI/NTP/Upload/**` | `NTPOmniboxUploadDrawerSnapshotTests.testOmniboxUploadDrawerSheet` | all locales, light + dark |
<!-- snapshot-coverage-map:end -->
