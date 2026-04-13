// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UserNotifications
@testable import Client

final class MockUserNotificationCenter: UserNotificationCenterProtocol, @unchecked Sendable {
    var pendingRequests = [UNNotificationRequest]()

    var getSettingsWasCalled = false
    func notificationSettings() async -> UNNotificationSettings {
        getSettingsWasCalled = true
        return await UNUserNotificationCenter.current().notificationSettings()
    }

    func getNotificationSettings(completionHandler: @escaping (UNNotificationSettings) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: completionHandler)
    }

    var requestAuthorizationWasCalled = false
    var requestAuthorizationResult: (Bool, Error?) = (true, nil)
    func requestAuthorization(options: UNAuthorizationOptions,
                              completionHandler: @escaping @Sendable (Bool, Error?) -> Void) {
        requestAuthorizationWasCalled = true
        completionHandler(requestAuthorizationResult.0, requestAuthorizationResult.1)
    }

    var addWasCalled = false
    func add(_ request: UNNotificationRequest,
             withCompletionHandler completionHandler: (@Sendable (Error?) -> Void)?) {
        addWasCalled = true
    }

    var getPendingRequestsWasCalled = false
    func getPendingNotificationRequests(completionHandler: @escaping @Sendable ([UNNotificationRequest]) -> Void) {
        getPendingRequestsWasCalled = true
        completionHandler(pendingRequests)
    }

    var getPendingRequestsWithIdWasCalled = false
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        getPendingRequestsWithIdWasCalled = true
        pendingRequests.removeAll(where: { identifiers.contains($0.identifier) })
    }

    var removeAllPendingRequestsWasCalled = false
    func removeAllPendingNotificationRequests() {
        removeAllPendingRequestsWasCalled = true
        pendingRequests.removeAll()
    }

    var getDeliveredWasCalled = false
    func deliveredNotifications() async -> [UNNotification] {
        getDeliveredWasCalled = true
        return []
    }

    func getDeliveredNotifications(completionHandler: @escaping ([UNNotification]) -> Void) {
        completionHandler([])
    }

    var removeDeliveredWithIdsWasCalled = false
    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        removeDeliveredWithIdsWasCalled = true
    }

    var removeAllDeliveredWasCalled = false
    func removeAllDeliveredNotifications() {
        removeAllDeliveredWasCalled = true
    }
}
