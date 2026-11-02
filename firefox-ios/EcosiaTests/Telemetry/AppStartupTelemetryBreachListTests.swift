// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Storage
@testable import Client

@MainActor
final class AppStartupTelemetryBreachListTests: XCTestCase {
    func testSendStartupTelemetry_doesNotLoadLoginsOrBreaches() {
        let profile = LoginsAccessCountingProfile()
        let telemetry = DefaultAppStartupTelemetry(profile: profile)

        telemetry.sendStartupTelemetry()

        XCTAssertEqual(profile.loginsAccessCount, 0)
    }
}

private final class LoginsAccessCountingProfile: MockProfile, @unchecked Sendable {
    var loginsAccessCount = 0

    override var logins: RustLogins {
        get {
            loginsAccessCount += 1
            return super.logins
        }
        set { super.logins = newValue }
    }
}
