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

    /// Ecosia: Drains the shared serial queues that app-hosted lifecycle tests enqueue async writes
    /// onto, so a contaminating test's pending work completes BEFORE the next test runs. Both queues
    /// are serial, so a `sync {}` barrier blocks until every previously-enqueued block has finished.
    ///
    /// Why this matters: driving `applicationDidBecomeActive` (MMP / AnalyticsSpy lifecycle tests)
    /// kicks off async writes on `User.queue` (User.shared saves from searchCount/etc. mutations) and
    /// `PageStore.queue` (loadBackgroundTabs / history). Left undrained, those land DURING a later test
    /// — backing the queue up so its 1-2s-timeout expectations fail (ReferralsModelTests "multiple
    /// fulfill", TabEcosia webview timeout) and rewriting shared files so the later test reads stale
    /// state (FavouritesTests). Draining here in the contaminating class's tearDown makes each
    /// subsequent test start from quiescent shared queues. Pairs with
    /// `seedFreshUnleashModelToAvoidNetworkFetch()` (which removes the Unleash-network vector). (MOB-4384)
    func drainSharedAsyncQueues() {
        User.queue.sync {}
        PageStore.queue.sync {}
    }
}
