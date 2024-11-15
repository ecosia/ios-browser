// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Core
import NotificationCenter

<<<<<<<< HEAD:Ecosia/Braze/APNConsent.swift
struct APNConsent {
    private init() {}

    private static var toggleName: Unleash.Toggle.Name {
        .apnConsent
========
public struct APNConsentOnLaunchExperiment {
    private init() {}

    public static var toggleName: Unleash.Toggle.Name {
        .apnConsentOnLaunch
>>>>>>>> e5bca0a4d ([MOB-3028] Move Analytics and dependencies to Ecosia framework):Ecosia/Experiments/Unleash/APNConsentOnLaunchExperiment.swift
    }

    private static var isEnabled: Bool {
        // Depends on Braze Integration being enabled - we should make sure targets on Unleash match
        Unleash.isEnabled(toggleName) && BrazeIntegrationExperiment.isEnabled
    }

<<<<<<<< HEAD:Ecosia/Braze/APNConsent.swift
    static func requestIfNeeded() async {
========
    public static func requestAPNConsentIfNeeded(delegate: UNUserNotificationCenterDelegate) async {
>>>>>>>> e5bca0a4d ([MOB-3028] Move Analytics and dependencies to Ecosia framework):Ecosia/Experiments/Unleash/APNConsentOnLaunchExperiment.swift
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
