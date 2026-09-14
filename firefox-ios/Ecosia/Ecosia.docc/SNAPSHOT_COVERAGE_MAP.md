# 📸 Snapshot Coverage Map

When you change a component listed here, update its snapshot test and re-record references in the `SnapshotArtifacts` submodule in the same PR.

The table below is generated from `firefox-ios/EcosiaTests/SnapshotTests/snapshot_coverage.json`. After adding coverage, update that file and run `./generate_snapshot_coverage_docs.sh` from the repo root.

<!-- snapshot-coverage-map:start -->
| UI area | Source (primary) | Snapshot test | Locales / themes |
| --- | --- | --- | --- |
| Welcome screen | `Ecosia/UI/ProductTour/WelcomeView.swift` | `OnboardingTests.testWelcomeScreen` | all locales, light only |
| NTP header logo | `Client/Ecosia/UI/NTP/Header/NTPHeader.swift` | `HomepageComponentTests.testNTPHeaderLogo` | en, light + dark |
| Customize button | `Client/Ecosia/UI/NTP/Header/NTPHeader.swift` | `HomepageComponentTests.testEcosiaCustomizeButton` | en, light + dark |
| Account nav button (logged out) | `Client/Ecosia/UI/NTP/Header/NTPHeader.swift` | `HomepageComponentTests.testEcosiaAccountNavButton_loggedOut` | en, light + dark |
| Impact cell | `Client/Ecosia/UI/NTP/Impact/NTPImpactCell.swift` | `HomepageComponentTests.testNTPImpactCell_withImpactRows` | en, light only |
| NTP search bar | `Client/Ecosia/UI/NTP/SearchBar/NTPSearchBarView.swift` | `HomepageComponentTests.testNTPSearchBar_resting` | all locales, light + dark |
| Pinned top site cell | `Client/Frontend/Home/TopSites/TopSiteItemCell.swift` | `HomepageComponentTests.testTopSiteItemCell_pinned` | en, light + dark |
| Omnibox upload drawer | `Ecosia/UI/NTP/Upload/OmniboxUploadDrawerView.swift` | `NTPOmniboxUploadDrawerSnapshotTests.testOmniboxUploadDrawerSheet` | all locales, light + dark |
<!-- snapshot-coverage-map:end -->
