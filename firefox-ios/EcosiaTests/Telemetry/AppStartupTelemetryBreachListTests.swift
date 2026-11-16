// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Storage
@testable import Client

@MainActor
final class AppStartupTelemetryBreachListTests: XCTestCase {
    func testSendStartupTelemetry_doesNotLoadLoginsOrBreaches() {
        let profile = makeProfile()
        let telemetry = DefaultAppStartupTelemetry(profile: profile)

        telemetry.sendStartupTelemetry()

        // MockProfile is final, so check the logins database its lazy `logins` creates on first access
        XCTAssertFalse(profile.files.exists("loginsPerField.db"))
    }
}
