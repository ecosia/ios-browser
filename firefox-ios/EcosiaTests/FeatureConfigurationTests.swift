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

    // MARK: - Helpers

    private func isEnabled(_ featureID: FeatureFlagID) -> Bool {
        layer.checkNimbusConfigFor(featureID, with: prefs)
    }
}
