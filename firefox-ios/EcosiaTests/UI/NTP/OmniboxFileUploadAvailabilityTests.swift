// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia

final class OmniboxFileUploadAvailabilityTests: XCTestCase {

    func testEcosiaSourcesRequireAuthenticationAndNoOptOut() {
        let uploadInputs = OmniboxFileUploadAvailability.UploadInputs(
            hasOptedOutOfChatThreads: false,
            usesEcosiaAIBackend: true
        )
        XCTAssertTrue(uploadInputs.areInAppSourcesEnabled(isAuthenticated: true))
        XCTAssertFalse(uploadInputs.areInAppSourcesEnabled(isAuthenticated: false))

        let optedOut = OmniboxFileUploadAvailability.UploadInputs(
            hasOptedOutOfChatThreads: true,
            usesEcosiaAIBackend: true
        )
        XCTAssertFalse(optedOut.areInAppSourcesEnabled(isAuthenticated: true))
    }

    func testUnauthenticatedDoesNotTreatMissingClaimAsOptOut() {
        let uploadInputs = OmniboxFileUploadAvailability.UploadInputs(
            hasOptedOutOfChatThreads: false,
            usesEcosiaAIBackend: true
        )
        XCTAssertFalse(uploadInputs.areInAppSourcesEnabled(isAuthenticated: false))
    }

    func testThirdPartySourcesStayEnabledWhenOptedOut() {
        let uploadInputs = OmniboxFileUploadAvailability.UploadInputs(
            hasOptedOutOfChatThreads: true,
            usesEcosiaAIBackend: false
        )
        XCTAssertTrue(uploadInputs.areInAppSourcesEnabled(isAuthenticated: true))
    }

    func testEcosiaUploadBlockedWhenChatHistoryOptedOut() {
        let uploadInputs = OmniboxFileUploadAvailability.UploadInputs(
            hasOptedOutOfChatThreads: true,
            usesEcosiaAIBackend: true
        )
        XCTAssertTrue(uploadInputs.blocksEcosiaUploadDueToChatHistoryOptOut)
    }

    func testThirdPartyUploadNotBlockedByChatHistoryOptOut() {
        let uploadInputs = OmniboxFileUploadAvailability.UploadInputs(
            hasOptedOutOfChatThreads: true,
            usesEcosiaAIBackend: false
        )
        XCTAssertFalse(uploadInputs.blocksEcosiaUploadDueToChatHistoryOptOut)
    }

    func testEcosiaUploadAllowedWhenClaimAbsentOrFalse() {
        let uploadInputs = OmniboxFileUploadAvailability.UploadInputs(
            hasOptedOutOfChatThreads: false,
            usesEcosiaAIBackend: true
        )
        XCTAssertFalse(uploadInputs.blocksEcosiaUploadDueToChatHistoryOptOut)
    }
}
