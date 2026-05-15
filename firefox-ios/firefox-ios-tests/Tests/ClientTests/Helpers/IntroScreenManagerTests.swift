// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import XCTest

@testable import Client
// Ecosia: IntroScreenManager tests use User.shared which lives in the Ecosia module
@testable import Ecosia

final class IntroScreenManagerTests: XCTestCase {
    var prefs: MockProfilePrefs!

    override func setUp() {
        super.setUp()
        prefs = MockProfilePrefs()
        User.shared.firstTime = true
    }

    override func tearDown() {
        super.tearDown()
        prefs = nil
        User.shared.firstTime = true
    }

    /* Ecosia: we are basing the onboarding/intro on different flags
    func testHasntSeenIntroScreenYet_shouldShowIt() {
        let subject = IntroScreenManager(prefs: prefs)
        XCTAssertTrue(subject.shouldShowIntroScreen)
    }

    func testHasSeenIntroScreen_shouldNotShowIt() {
        let subject = IntroScreenManager(prefs: prefs)
        subject.didSeeIntroScreen()
        XCTAssertFalse(subject.shouldShowIntroScreen)
    }
     */

    // MARK: - Ecosia: shouldShowIntroScreen

    func testFreshInstall_showsIntroScreen() {
        // Given: no IntroSeen, firstTime=true (factory defaults for a new install)
        let subject = IntroScreenManager(prefs: prefs)
        XCTAssertTrue(subject.shouldShowIntroScreen)
    }

    func testAfterDidSeeIntroScreen_doesNotShowIntroScreen() {
        // Given: user completed onboarding on develop (IntroSeen written, firstTime=false)
        let subject = IntroScreenManager(prefs: prefs)
        subject.didSeeIntroScreen()
        XCTAssertFalse(subject.shouldShowIntroScreen)
    }

    func testUpgradeFromMain_doesNotShowIntroScreen() {
        // Given: user upgrading from main — IntroSeen was never written on main but
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
}
