/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

public struct EngagementService {
    // MARK: - Properties
    
    public let provider: EngagementServiceProvider
    
    // MARK: - Initialization
    
    public init(provider: EngagementServiceProvider) {
        self.provider = provider
    }
    
    public func initialize(parameters: [String: Any]) throws {
        try provider.initialize(parameters: parameters)
    }
    
    // MARK: - Device Token Registration
    
    public func registerDeviceToken(_ deviceToken: Data) {
        provider.registerDeviceToken(deviceToken)
    }
    
    // MARK: - APN Consent
    
    public func requestAPNConsent(notificationCenterDelegate: UNUserNotificationCenterDelegate,
                                  completionHandler: @escaping (Bool, Swift.Error?) -> Void) {
        provider.requestAPNConsent(notificationCenterDelegate: notificationCenterDelegate,
                                   completionHandler: completionHandler)
    }
    
    public func requestAPNConsent(notificationCenterDelegate: UNUserNotificationCenterDelegate) async throws -> Bool {
        try await provider.requestAPNConsent(notificationCenterDelegate: notificationCenterDelegate)
    }
    
    // MARK: - APN Registration Refresh
    
    public func refreshAPNRegistrationIfNeeded(notificationCenterDelegate: UNUserNotificationCenterDelegate) async {
        await provider.refreshAPNRegistrationIfNeeded(notificationCenterDelegate: notificationCenterDelegate)
    }
}
