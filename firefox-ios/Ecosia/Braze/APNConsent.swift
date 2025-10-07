// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct APNConsent {
    private init() {}

    private static var isEnabled: Bool {
        // Depends on Braze Integration being enabled
        BrazeIntegrationExperiment.isEnabled
    }

    public static func requestIfNeeded() async {
        guard isEnabled, BrazeService.shared.notificationAuthorizationStatus == .notDetermined else {
            return
        }
        Analytics.shared.apnConsent(.view)
        do {
            let granted = try await BrazeService.shared.requestAPNConsent()
            Analytics.shared.apnConsent(granted ? .allow : .deny)
        } catch {
            Analytics.shared.apnConsent(.error)
        }
    }
}
