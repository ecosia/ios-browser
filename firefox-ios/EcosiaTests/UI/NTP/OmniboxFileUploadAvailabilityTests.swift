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

    func testEcosiaUploadBlockedAndDimmedWhenChatHistoryOptedOut() {
        XCTAssertTrue(
            OmniboxFileUploadAvailability.blocksEcosiaUploadDueToChatHistoryOptOut(
                hasOptedOutOfChatThreads: true,
                usesEcosiaAIBackend: true
            )
        )
        XCTAssertTrue(
            OmniboxFileUploadAvailability.shouldDimOmniboxUploadControlForChatHistoryOptOut(
                hasOptedOutOfChatThreads: true,
                usesEcosiaAIBackend: true
            )
        )
        XCTAssertTrue(
            OmniboxFileUploadAvailability.shouldPresentChatHistoryOptOutErrorOnUploadTap(
                hasOptedOutOfChatThreads: true,
                usesEcosiaAIBackend: true
            )
        )
    }

    func testThirdPartyUploadNotBlockedByChatHistoryOptOut() {
        XCTAssertFalse(
            OmniboxFileUploadAvailability.shouldPresentChatHistoryOptOutErrorOnUploadTap(
                hasOptedOutOfChatThreads: true,
                usesEcosiaAIBackend: false
            )
        )
    }

    func testEcosiaUploadAllowedWhenClaimAbsentOrFalse() {
        XCTAssertFalse(
            OmniboxFileUploadAvailability.shouldPresentChatHistoryOptOutErrorOnUploadTap(
                hasOptedOutOfChatThreads: false,
                usesEcosiaAIBackend: true
            )
        )
    }
}
