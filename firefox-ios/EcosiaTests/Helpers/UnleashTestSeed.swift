// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import Common
@testable import Ecosia

extension XCTestCase {
    /// Ecosia: Seeds a fresh Unleash model on disk so all three refresh rules evaluate `false`
    /// (`AppUpdateRule`: matching appVersion, `DeviceRegionChangeRule`: matching region,
    /// `TwentyFourHoursCacheExpirationRule`: `updated == now`). With `Unleash.shouldRefresh == false`,
    /// `FeatureManagement.fetchConfiguration()` → `Unleash.start` → `refresh` returns the cached model
    /// and makes **no network call** at all.
    ///
    /// Why this matters: app-hosted tests that drive `applicationDidBecomeActive` /
    /// `didFinishLaunchingWithOptions` spawn a fire-and-forget `Task { await
    /// FeatureManagement.fetchConfiguration() }`. With a stale/empty model that Task issues a real
    /// Unleash network request that can outlive the test and mutate the global `Unleash.model` while a
    /// LATER, unrelated test is running — the cross-test contamination that flaked CI (different victim
    /// tests + a crash across runs). Seeding here removes the network call, so the Task completes
    /// instantly and leaks nothing. Call in `setUp` before driving the AppDelegate lifecycle. (MOB-4384)
    func seedFreshUnleashModelToAvoidNetworkFetch() {
        var model = Unleash.Model()
        model.appVersion = AppInfo.ecosiaAppVersion
        model.deviceRegion = Locale.current.regionIdentifierLowercasedWithFallbackValue
        model.updated = Date()
        Unleash.clearInstanceModel()
        try? JSONEncoder().encode(model).write(to: FileManager.unleash, options: .atomic)
    }
}
