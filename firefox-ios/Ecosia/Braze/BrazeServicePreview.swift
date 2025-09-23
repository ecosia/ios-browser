// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import UserNotifications

#if !canImport(BrazeKit)

/// Stub implementation of BrazeService when BrazeKit is not available
/// This completely avoids BrazeKit dependencies for faster preview builds
public final class BrazeService: NSObject {
    override private init() {}

    public static let shared = BrazeService()
    private(set) var notificationAuthorizationStatus: UNAuthorizationStatus?

    private var userId: String {
        // Use a fixed ID for previews
        "preview-user-id"
    }

    // MARK: - Public API (Stub Implementations)

    public func initialize() async {
        print("🎭 BrazeService.initialize() - Preview stub implementation")
    }

    public func registerDeviceToken(_ deviceToken: Data) {
        print("🎭 BrazeService.registerDeviceToken() - Preview stub implementation")
    }

    public func logCustomEvent(_ event: CustomEvent) {
        print("🎭 BrazeService.logCustomEvent(\(event.rawValue)) - Preview stub implementation")
    }

    func requestAPNConsent() async throws -> Bool {
        print("🎭 BrazeService.requestAPNConsent() - Preview stub implementation")
        return false // Always return false for previews
    }

    func refreshAPNRegistrationIfNeeded() async {
        print("🎭 BrazeService.refreshAPNRegistrationIfNeeded() - Preview stub implementation")
    }

    public func handleBackgroundNotification(userInfo: [AnyHashable: Any], completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Bool {
        print("🎭 BrazeService.handleBackgroundNotification() - Preview stub implementation")
        completionHandler(.noData)
        return false
    }
}

// MARK: - UNUserNotificationCenterDelegate Stub

extension BrazeService: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("🎭 BrazeService.userNotificationCenter:didReceive - Preview stub implementation")
        completionHandler()
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("🎭 BrazeService.userNotificationCenter:willPresent - Preview stub implementation")
        completionHandler([.list, .banner, .sound, .badge])
    }
}

#endif
