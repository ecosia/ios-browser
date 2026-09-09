// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import XCTest
import MozillaAppServices
import OnboardingKit

@testable import Client
// Ecosia: IntroScreenManager tests use User.shared, which lives in the Ecosia module
@testable import Ecosia

final class IntroScreenManagerTests: XCTestCase {
    var prefs: MockProfilePrefs!

    override func setUp() async throws {
        try await super.setUp()
        prefs = MockProfilePrefs()
        let mockProfile = MockProfile(databasePrefix: "IntroScreenManagerTests_")
        await DependencyHelperMock().bootstrapDependencies(injectedProfile: mockProfile)
        // Ecosia: `shouldShowIntroScreen` is also gated on `User.shared.firstTime`, so pin it here to
        // keep upstream's assertions below deterministic.
        User.shared.firstTime = true
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        prefs = nil
        // Ecosia: restore the factory default so this class does not leak state into other tests.
        User.shared.firstTime = true
        try await super.tearDown()
    }

    // MARK: - shouldShowIntroScreen Tests

    func testHasntSeenIntroScreenYet_shouldShowIt() {
        let subject = IntroScreenManager(prefs: prefs)
        XCTAssertTrue(subject.shouldShowIntroScreen)
    }

    func testHasSeenIntroScreen_shouldNotShowIt() {
        let subject = IntroScreenManager(prefs: prefs)
        subject.didSeeIntroScreen()
        XCTAssertFalse(subject.shouldShowIntroScreen)
    }

    func testIntroScreenPrefSetToNonNilValue_shouldNotShowIt() {
        // Set pref to a value other than nil (simulating it was seen)
        prefs.setInt(0, forKey: PrefsKeys.IntroSeen)
        let subject = IntroScreenManager(prefs: prefs)
        XCTAssertFalse(subject.shouldShowIntroScreen)
    }

    // MARK: - didSeeIntroScreen Tests

    // MARK: - Ecosia: the `User.shared.firstTime` half of `shouldShowIntroScreen`

    func testUpgradeFromMain_doesNotShowIntroScreen() {
        // Given: user upgrading from main — IntroSeen was never written on main, but
        // handleFirstTimeUserActions() set firstTime=false on first browser load.
        User.shared.firstTime = false
        let subject = IntroScreenManager(prefs: prefs)
        XCTAssertFalse(
            subject.shouldShowIntroScreen,
            "Welcome screen must not re-appear for users upgrading from main."
        )
    }

    func testIntroSeenWithFirstTimeFalse_doesNotShowIntroScreen() {
        // Given: fully onboarded develop user
        User.shared.firstTime = false
        prefs.setInt(1, forKey: PrefsKeys.IntroSeen)
        let subject = IntroScreenManager(prefs: prefs)
        XCTAssertFalse(subject.shouldShowIntroScreen)
    }

    func testDidSeeIntroScreen_setsPrefValue() {
        let subject = IntroScreenManager(prefs: prefs)
        XCTAssertNil(prefs.intForKey(PrefsKeys.IntroSeen))

        subject.didSeeIntroScreen()

        XCTAssertEqual(prefs.intForKey(PrefsKeys.IntroSeen), 1)
    }

    // MARK: - isModernOnboardingEnabled Tests

    func testIsModernOnboardingEnabled_whenFeatureFlagDisabled_returnsFalse() {
        setupNimbusFeatureFlags(enableModernUi: false, shouldUseJapanConfiguration: false)
        let subject = IntroScreenManager(prefs: prefs)
        XCTAssertFalse(subject.isModernOnboardingEnabled)
    }

    func testIsModernOnboardingEnabled_whenFeatureFlagEnabled_returnsTrue() {
        setupNimbusFeatureFlags(enableModernUi: true, shouldUseJapanConfiguration: false)
        let subject = IntroScreenManager(prefs: prefs)
        XCTAssertTrue(subject.isModernOnboardingEnabled)
    }

    // MARK: - shouldUseJapanConfiguration Tests

    func testShouldUseJapanConfiguration_whenFeatureFlagDisabled_returnsFalse() {
        setupNimbusFeatureFlags(enableModernUi: false, shouldUseJapanConfiguration: false)
        let subject = IntroScreenManager(prefs: prefs)
        XCTAssertFalse(subject.shouldUseJapanConfiguration)
    }

    func testShouldUseJapanConfiguration_whenFeatureFlagEnabled_returnsTrue() {
        setupNimbusFeatureFlags(enableModernUi: false, shouldUseJapanConfiguration: true)
        let subject = IntroScreenManager(prefs: prefs)
        XCTAssertTrue(subject.shouldUseJapanConfiguration)
    }

    // MARK: - onboardingVariant Tests

    func testOnboardingVariant_whenBothFlagsDisabled_returnsModern() {
        setupNimbusFeatureFlags(enableModernUi: false, shouldUseJapanConfiguration: false)
        let subject = IntroScreenManager(prefs: prefs)
        XCTAssertEqual(subject.onboardingVariant, .modern)
    }

    func testOnboardingVariant_whenModernEnabledButJapanDisabled_returnsModern() {
        setupNimbusFeatureFlags(enableModernUi: true, shouldUseJapanConfiguration: false)
        let subject = IntroScreenManager(prefs: prefs)
        XCTAssertEqual(subject.onboardingVariant, .brandRefresh)
    }

    func testOnboardingVariant_whenBothFlagsEnabled_returnsJapan() {
        setupNimbusFeatureFlags(enableModernUi: true, shouldUseJapanConfiguration: true)
        let subject = IntroScreenManager(prefs: prefs)
        XCTAssertEqual(subject.onboardingVariant, .japan)
    }

    func testOnboardingVariant_whenModernDisabledButJapanEnabled_returnsModern() {
        // Japan configuration requires modern UI to be enabled; otherwise it falls through to modern
        setupNimbusFeatureFlags(enableModernUi: false, shouldUseJapanConfiguration: true)
        let subject = IntroScreenManager(prefs: prefs)
        XCTAssertEqual(subject.onboardingVariant, .modern)
    }

    // MARK: - shouldShowVideoIntro Tests

    func testShouldShowVideoIntro() {
        setupNimbusFeatureFlags(enableModernUi: false, shouldUseJapanConfiguration: false)
        let subject = IntroScreenManager(prefs: prefs)

        XCTAssertFalse(subject.shouldShowVideoIntro)
    }

    // MARK: - Helper Methods

    private func setupNimbusFeatureFlags(enableModernUi: Bool,
                                         shouldUseBrandRefreshConfiguration: Bool = true,
                                         shouldUseJapanConfiguration: Bool,
                                         enableVideoIntro: Bool = false) {
        FxNimbus.shared.features.onboardingFrameworkFeature.with { appContext, _ in
            OnboardingFrameworkFeature(
                appContext,
                UserDefaults.standard,
                cards: [:],
                conditions: ["ALWAYS": "true"],
                dismissable: false,
                enableModernUi: enableModernUi,
                enableVideoIntro: enableVideoIntro,
                shouldUseBrandRefreshConfiguration: shouldUseBrandRefreshConfiguration,
                shouldUseJapanConfiguration: shouldUseJapanConfiguration
            )
        }
    }
}
