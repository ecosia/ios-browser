// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia

final class OmniboxFileUploadAvailabilityTests: XCTestCase {

    func testEcosiaSourcesRequireAuthenticationAndNoOptOut() {
        XCTAssertTrue(
            OmniboxFileUploadAvailability.areSourcesEnabled(
                isEcosiaProvider: true,
                isAuthenticated: true,
                hasOptedOutOfChatThreads: false
            )
        )
        XCTAssertFalse(
            OmniboxFileUploadAvailability.areSourcesEnabled(
                isEcosiaProvider: true,
                isAuthenticated: true,
                hasOptedOutOfChatThreads: true
            )
        )
        XCTAssertFalse(
            OmniboxFileUploadAvailability.areSourcesEnabled(
                isEcosiaProvider: true,
                isAuthenticated: false,
                hasOptedOutOfChatThreads: false
            )
        )
    }

    func testUnauthenticatedDoesNotTreatMissingClaimAsOptOut() {
        XCTAssertFalse(
            OmniboxFileUploadAvailability.areSourcesEnabled(
                isEcosiaProvider: true,
                isAuthenticated: false,
                hasOptedOutOfChatThreads: false
            )
        )
    }

    func testThirdPartySourcesStayEnabledWhenOptedOut() {
        XCTAssertTrue(
            OmniboxFileUploadAvailability.areSourcesEnabled(
                isEcosiaProvider: false,
                isAuthenticated: true,
                hasOptedOutOfChatThreads: true
            )
        )
    }

    func testOmniboxControlStaysEnabledForChatModesWhenOptedOut() {
        XCTAssertTrue(
            OmniboxFileUploadAvailability.isOmniboxControlEnabled(
                hasOptedOutOfChatThreads: true,
                isChatModesEnabled: true,
                usesEcosiaAIBackend: true
            )
        )
    }

    func testOmniboxControlDisablesPaperclipWhenOptedOut() {
        XCTAssertFalse(
            OmniboxFileUploadAvailability.isOmniboxControlEnabled(
                hasOptedOutOfChatThreads: true,
                isChatModesEnabled: false,
                usesEcosiaAIBackend: true
            )
        )
    }

    func testOmniboxControlStaysEnabledWhenClaimAbsentOrFalse() {
        XCTAssertTrue(
            OmniboxFileUploadAvailability.isOmniboxControlEnabled(
                hasOptedOutOfChatThreads: false,
                isChatModesEnabled: false,
                usesEcosiaAIBackend: true
            )
        )
    }

    func testOmniboxControlStaysEnabledForThirdPartyWhenOptedOut() {
        XCTAssertTrue(
            OmniboxFileUploadAvailability.isOmniboxControlEnabled(
                hasOptedOutOfChatThreads: true,
                isChatModesEnabled: false,
                usesEcosiaAIBackend: false
            )
        )
    }
}
