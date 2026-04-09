// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client
@testable import Ecosia

final class AppDelegateMMPIntegrationTests: XCTestCase, @unchecked Sendable {
    // swiftlint:disable implicitly_unwrapped_optional
    var appDelegate: AppDelegate!
    var mockProvider: MockMMPProvider!
    var savedUser: User!
    // swiftlint:enable implicitly_unwrapped_optional

    override func setUp() {
        super.setUp()
        MainActor.assumeIsolated {
            appDelegate = AppDelegate()
            DependencyHelperMock().bootstrapDependencies()
        }
        savedUser = User.shared
        User.shared.sendAnonymousUsageData = true
        User.shared.searchCount = 0
        mockProvider = MockMMPProvider()
        MMP.provider = mockProvider
    }

    override func tearDown() {
        User.shared = savedUser
        MMP.provider = Singular(includeSKAN: true)
        super.tearDown()
    }

    func testSessionIsSentOnBecomeActive() {
        MainActor.assumeIsolated { appDelegate.applicationDidBecomeActive(UIApplication.shared) }
        wait(1)
        XCTAssertTrue(mockProvider.didSendSession)
    }

    func testSessionIsNotSentWhenAnonymousDataDisabled() {
        User.shared.sendAnonymousUsageData = false
        MainActor.assumeIsolated { appDelegate.applicationDidBecomeActive(UIApplication.shared) }
        wait(1)
        XCTAssertFalse(mockProvider.didSendSession)
    }

    func testFirstSearchMilestoneTriggersEvent() {
        MainActor.assumeIsolated { appDelegate.applicationDidBecomeActive(UIApplication.shared) }
        User.shared.searchCount = 1
        wait(1)
        XCTAssertEqual(mockProvider.receivedEvents, [.firstSearch])
    }

    func testNonMilestoneSearchCountDoesNotTriggerEvent() {
        MainActor.assumeIsolated { appDelegate.applicationDidBecomeActive(UIApplication.shared) }
        User.shared.searchCount = 3
        wait(1)
        XCTAssertTrue(mockProvider.receivedEvents.isEmpty)
    }
}

// MARK: - MockMMPProvider

final class MockMMPProvider: MMPProvider, @unchecked Sendable {
    var didSendSession = false
    var receivedEvents: [MMPEvent] = []

    func sendSessionInfo(appDeviceInfo: AppDeviceInfo) async throws {
        didSendSession = true
    }

    func sendEvent(_ event: MMPEvent, appDeviceInfo: AppDeviceInfo) async throws {
        receivedEvents.append(event)
    }
}
