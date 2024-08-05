// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

final class EcosiaSnapshotTestsLaunchTests: EcosiaBaseSnapshotTests {
    
    func testTakeOnbaordingSnapshots() async throws {
        await waitForExistence(app.staticTexts[String.localized(.skipWelcomeTour)], timeout: 15)
        await snapshot("01OnboardingScreen")
        await app.buttons[String.localized(.getStarted)].tap()
        await waitForExistence(app.staticTexts[String.localized(.grennestWayToSearch)], timeout: 15)
        await snapshot("02OnboardingScreen")
        await app.buttons[String.localized(.onboardingContinueCTAButtonAccessibility)].tap()
        await waitForExistence(app.staticTexts[String.localized(.hundredPercentOfProfits)], timeout: 15)
        await snapshot("03OnboardingScreen")
        await app.buttons[String.localized(.onboardingContinueCTAButtonAccessibility)].tap()
        await waitForExistence(app.staticTexts[String.localized(.collectiveAction)], timeout: 15)
        await snapshot("04OnboardingScreen")
        await app.buttons[String.localized(.onboardingContinueCTAButtonAccessibility)].tap()
        await waitForExistence(app.staticTexts[String.localized(.realResults)], timeout: 15)
        await snapshot("05OnboardingScreen")
    }
}
