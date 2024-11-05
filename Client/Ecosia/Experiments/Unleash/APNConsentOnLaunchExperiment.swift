// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Core

struct APNConsentOnLaunchExperiment {
    private init() {}
    
    static var toggleName: Unleash.Toggle.Name {
        .apnConsentOnLaunch
    }

    private static var isEnabled: Bool {
        // Depends on Braze Integration being enabled - we should make sure targets on Unleash match
        Unleash.isEnabled(toggleName) && BrazeIntegrationExperiment.isEnabled
    }
    
    static func requestAPNConsentIfNeeded(delegate: UNUserNotificationCenterDelegate) async {
        guard isEnabled, BrazeService.shared.notificationAuthorizationStatus == .notDetermined else {
            return
        }
        Analytics.shared.apnConsentOnLaunchExperiment(.view)
        do {
            let granted = try await BrazeService.shared.requestAPNConsent(notificationCenterDelegate: delegate)
            Analytics.shared.apnConsentOnLaunchExperiment(granted ? .allow : .deny)
        } catch {
            Analytics.shared.apnConsentOnLaunchExperiment(.error)
        }
    }
}
