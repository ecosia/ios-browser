// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import XCTest
@testable import Client

/// Locks the product decisions about Firefox's features (upgrade ticket 10, MOB-5036). Each test reads
/// the resolved value through the app's feature-flag layer, so a future upgrade or `main` sync that
/// flips one in `nimbus-features/*.yaml` fails here instead of shipping.
///
/// Unit tests run the `Testing` configuration, which generates the `developer` channel's values.
/// `EcosiaUpgrade/tools/check-feature-config.sh` checks the same decisions on `beta` and `release`.
final class FeatureConfigurationTests: XCTestCase {

    private let layer = NimbusFeatureFlagLayer()
    /// Empty, so no debug-menu override can stand in for the configured value.
    private let prefs = MockProfilePrefs()

    // MARK: - Kept

    func testTranslationsAreOn() {
        XCTAssertTrue(isEnabled(.translation), "Translations are kept")
    }

    func testSearchTermInAddressBarIsOn() {
        XCTAssertTrue(isEnabled(.searchTermInAddressBar), "Ecosia results pages show the query, not the URL")
    }

    /// Upstream's interactive variant: `enabled_swipe` would replace it with the plain swipe.
    func testAddressBarGestureToOpenTabTrayIsOn() {
        XCTAssertTrue(isEnabled(.addressBarGestureToOpenTabTrayInteractive),
                      "Swipe up on the address bar opens the tab tray")
        XCTAssertTrue(isEnabled(.addressBarGestureToOpenTabTrayCloseTab), "Drag a tab to the top to close it")
        XCTAssertFalse(isEnabled(.addressBarGestureToOpenTabTraySwipe), "The interactive gesture, not the plain swipe")
    }

    // MARK: - Production defaults

    /// Upstream's default is "Last tab" since 156.1. Users who never picked a start screen, including
    /// those updating from production, store nothing, so Settings shows this default (MOB-5307).
    func testStartScreenDefaultsToHomepageAfterFourHours() {
        XCTAssertEqual(layer.checkStartAtHomeConfiguration(), .afterFourHours, "Production's default")
        let userPreferences = UserFeaturePreferenceManager(prefs: prefs, backendLayer: layer, userInterfaceIdiom: .phone)
        XCTAssertEqual(
            userPreferences.startAtHomeSetting,
            .afterFourHours,
            "Settings shows the default when the user never picked a start screen"
        )
    }

    // MARK: - Summaries on-device only

    /// The hosted summarizer is also switched off in code (`OnDeviceSummariesTests`); this keeps the
    /// configuration, and what the debug menu shows, truthful.
    func testHostedSummarizerAndAppAttestAuthAreOff() {
        XCTAssertFalse(isEnabled(.hostedSummarizer), "Page summaries run on-device only")
        XCTAssertFalse(isEnabled(.summarizerAppAttestAuth),
                       "App Attest only authenticates the hosted summarizer")
    }

    // MARK: - Left out

    func testGoogleLensIsOff() {
        XCTAssertFalse(isEnabled(.googleLens), "Google Lens is not part of Ecosia")
        XCTAssertFalse(isEnabled(.googleLensSearchInterstitial), "Google Lens is not part of Ecosia")
    }

    func testQuickAnswersAreOff() {
        XCTAssertFalse(isEnabled(.quickAnswers), "Quick Answers are not part of Ecosia")
    }

    func testVPNIsOff() {
        XCTAssertFalse(isEnabled(.vpnFeature), "VPN is not part of Ecosia")
    }

    /// The ad blocker's list hides the ads on Ecosia's own search results, which fund tree planting.
    func testAdBlockerAndItsBadgeAreOff() {
        XCTAssertFalse(isEnabled(.adBlocker), "No Block Ads toggle")
        XCTAssertFalse(isEnabled(.adBlockerBadge), "No ad blocker badge in the Site Menu")
    }

    func testNovaDesignIsOff() {
        XCTAssertFalse(isEnabled(.novaDesign), "Ecosia keeps its own design")
    }

    /// The report is a Glean ping to Mozilla, and Ecosia's Glean never uploads. On by default upstream since 157.0.
    func testReportBrokenSiteIsOff() {
        XCTAssertFalse(isEnabled(.reportBrokenSite), "A report would never reach anyone")
    }

    func testPrivacyDashboardIsOff() {
        XCTAssertFalse(isEnabled(.privacyDashboard), "Ecosia's homepage has its own impact and privacy content")
    }

    func testMultiDayOnboardingIsOff() {
        XCTAssertFalse(isEnabled(.multiDayOnboarding), "Ecosia has its own onboarding")
    }

    /// Since 160.0 only this flag keeps search config v3 off: `SearchEnginesManager` lost its hardcoded `false`.
    func testSearchConfigV3IsOff() {
        XCTAssertFalse(isEnabled(.searchConfigV3), "Ecosia's default engine depends on the current configuration")
    }

    /// The reinstall check keeps an install history in the keychain and sends it to Mozilla through Glean.
    func testCheckForReinstallsIsOff() {
        XCTAssertFalse(isEnabled(.checkForReinstalls), "No reinstall telemetry")
    }

    func testWallpaperEngagementSheetIsOff() {
        XCTAssertFalse(isEnabled(.wallpaperEngagementSheet), "Ecosia has its own wallpapers and homepage")
    }

    // MARK: - Helpers

    private func isEnabled(_ featureID: FeatureFlagID) -> Bool {
        layer.checkNimbusConfigFor(featureID, with: prefs)
    }
}
