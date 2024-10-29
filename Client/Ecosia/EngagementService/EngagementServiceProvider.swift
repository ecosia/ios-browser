/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

public protocol EngagementServiceProvider {
    
    // MARK: - Initialization
    
    func initialize(parameters: [String: Any]) throws
    
    func presentNextQueuedMessage()
    
    func logCustomEvent(name: String)
    
    // MARK: - APN Consent
    
    func requestAPNConsent(notificationCenterDelegate: UNUserNotificationCenterDelegate,
                           completionHandler: @escaping (Bool, Swift.Error?) -> Void)
    
    func requestAPNConsent(notificationCenterDelegate: UNUserNotificationCenterDelegate) async throws -> Bool
    
    // MARK: - APN Registration Refresh
    
    func refreshAPNRegistrationIfNeeded(notificationCenterDelegate: UNUserNotificationCenterDelegate) async

    // MARK: - Device Token Registration
    
    func registerDeviceToken(_ deviceToken: Data)
}
