// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client
import Shared

/// Tests for MOB-4323 — Ecosia default-browser promo triggered after search-count threshold.
///
/// The eligibility logic is isolated in `BrowserViewController.isEligibleForEcosiaDefaultBrowserSearchPromo`,
/// which makes it straightforward to unit-test without spinning up a real `BrowserViewController`.
final class DefaultBrowserSearchPromoTests: XCTestCase {

    // swiftlint:disable:next implicitly_unwrapped_optional
    private var profile: MockProfile!

    override func setUp() {
        super.setUp()
        profile = MockProfile()
    }

    override func tearDown() {
        profile.prefs.clearAll()
        profile = nil
        super.tearDown()
    }

    // MARK: - Threshold constant

    func testMinSearchCountToTriggerIs50() {
        XCTAssertEqual(
            DefaultBrowserViewController.minSearchCountToTrigger,
            50,
            "Threshold changed — re-verify analytics and QA guidance for MOB-4323."
        )
    }

    // MARK: - isEligibleForEcosiaDefaultBrowserSearchPromo

    func testEligible_whenCountAboveThreshold_notDefault_notShown() {
        XCTAssertTrue(eligible(searchCount: 51, isDefaultBrowser: false, promoAlreadyShown: false))
    }

    func testEligible_exactlyAtThresholdPlusOne() {
        XCTAssertTrue(eligible(searchCount: DefaultBrowserViewController.minSearchCountToTrigger + 1,
                               isDefaultBrowser: false,
                               promoAlreadyShown: false))
    }

    func testNotEligible_exactlyAtThreshold() {
        XCTAssertFalse(eligible(searchCount: DefaultBrowserViewController.minSearchCountToTrigger,
                                isDefaultBrowser: false,
                                promoAlreadyShown: false),
                       "Promo requires count *greater than* the threshold, not equal.")
    }

    func testNotEligible_countBelowThreshold() {
        XCTAssertFalse(eligible(searchCount: 10, isDefaultBrowser: false, promoAlreadyShown: false))
    }

    func testNotEligible_alreadyDefaultBrowser() {
        XCTAssertFalse(eligible(searchCount: 100, isDefaultBrowser: true, promoAlreadyShown: false))
    }

    func testNotEligible_promoAlreadyShown() {
        XCTAssertFalse(eligible(searchCount: 100, isDefaultBrowser: false, promoAlreadyShown: true))
    }

    func testNotEligible_alreadyDefaultAndPromoShown() {
        XCTAssertFalse(eligible(searchCount: 100, isDefaultBrowser: true, promoAlreadyShown: true))
    }

    func testNotEligible_zeroSearchCount() {
        XCTAssertFalse(eligible(searchCount: 0, isDefaultBrowser: false, promoAlreadyShown: false))
    }

    // MARK: - Prefs key name stability

    func testPromoPrefsKeyIsStable() {
        XCTAssertEqual(
            BrowserViewController.ecosiaSearchPromoShownKey,
            "EcosiaSearchPromoShown",
            "Changing this key silently resets every user's promo-shown flag."
        )
    }

    // MARK: - Migration from PrefsKeys.IntroSeen

    func testMigration_introSeenSet_setsNewKey() {
        let prefs = profile.prefs
        let key = BrowserViewController.ecosiaSearchPromoShownKey
        prefs.setInt(1, forKey: PrefsKeys.IntroSeen)

        XCTAssertNil(prefs.boolForKey(key), "New key should not exist before migration.")

        migrateIfNeeded(prefs: prefs)

        XCTAssertEqual(
            prefs.boolForKey(key),
            true,
            "Users blocked under the old key must stay blocked under the new one."
        )
    }

    func testMigration_introSeenNotSet_doesNotSetNewKey() {
        let prefs = profile.prefs
        let key = BrowserViewController.ecosiaSearchPromoShownKey

        migrateIfNeeded(prefs: prefs)

        XCTAssertNil(prefs.boolForKey(key), "Fresh user should not be pre-blocked.")
    }

    func testMigration_newKeyAlreadySet_isNoOp() {
        let prefs = profile.prefs
        let key = BrowserViewController.ecosiaSearchPromoShownKey
        prefs.setBool(true, forKey: key)
        prefs.setInt(1, forKey: PrefsKeys.IntroSeen)

        migrateIfNeeded(prefs: prefs)

        XCTAssertEqual(
            prefs.boolForKey(key),
            true,
            "Migration must be a no-op once the new key is already written."
        )
    }

    // MARK: - Helpers

    private func eligible(searchCount: Int, isDefaultBrowser: Bool, promoAlreadyShown: Bool) -> Bool {
        BrowserViewController.isEligibleForEcosiaDefaultBrowserSearchPromo(
            searchCount: searchCount,
            isDefaultBrowser: isDefaultBrowser,
            promoAlreadyShown: promoAlreadyShown
        )
    }

    /// Mirrors `ecosiaMigrateDefaultBrowserPromoFlagIfNeeded` without requiring a BVC instance.
    private func migrateIfNeeded(prefs: Prefs) {
        let key = BrowserViewController.ecosiaSearchPromoShownKey
        guard prefs.boolForKey(key) == nil else { return }
        if prefs.intForKey(PrefsKeys.IntroSeen) != nil {
            prefs.setBool(true, forKey: key)
        }
    }
}
