// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

@MainActor
class NotificationManagerTests: XCTestCase, @unchecked Sendable {
    private var center: MockUserNotificationCenter!
    private var notificationManager: NotificationManager!

    override func setUp() {
        super.setUp()
        center = MockUserNotificationCenter()
        notificationManager = NotificationManager(center: center)
    }

    override func tearDown() {
        super.tearDown()
        center = nil
        notificationManager = nil
    }

    func testRequestAuthorization() {
        let center = self.center!
        notificationManager.requestAuthorization { (granted, error) in
            XCTAssertTrue(granted)
            XCTAssertTrue(center.requestAuthorizationWasCalled)
        }
    }

    func testGetNotificationSettings() async {
        _ = await notificationManager.getNotificationSettings(sendTelemetry: false)
        XCTAssertTrue(center.getSettingsWasCalled)
    }

    func testScheduleInterval() {
        notificationManager.schedule(title: "Title",
                                     body: "Body",
                                     id: "test-id",
                                     interval: 50)
        XCTAssertTrue(center.addWasCalled)
    }

    func testFindDeliveredNotificationForId() async {
        _ = await notificationManager.findDeliveredNotificationForId(id: "id1")
        XCTAssertTrue(center.getDeliveredWasCalled)
    }

    func testCloseRemoteTabNotification() {
        let notificationContent = UNMutableNotificationContent()
        // Test with the categoryIdentify being the close remote tab identifier
        notificationContent.categoryIdentifier = NotificationCloseTabs.notificationCategoryId
        let request = UNNotificationRequest(identifier: "id1",
                                            content: notificationContent,
                                            trigger: nil)

        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error {
                XCTFail("Error adding notification request: \(error)")
            }
        }
    }
}
