// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia
@testable import Client

/// `registerVisit` should never be called for a logged-out `updateSeeds` - if it is, something
/// routed the wrong login state through.
private struct UnreachableAccountsProvider: AccountsProviderProtocol {
    func registerVisit(accessToken: String) async throws -> AccountVisitResponse {
        XCTFail("registerVisit must not be called for a logged-out user")
        throw URLError(.badServerResponse)
    }
}

/// Tests for logged-out user seed collection: `LoggedOutSeedProgressManager`'s pure decisions,
/// and `ImpactManager`'s use of them end to end. Users start at 0 seeds and level 1.
final class UserDefaultsSeedProgressManagerTests: XCTestCase {

    private let cache = ImpactCache()
    private lazy var loggedOutManager = LoggedOutSeedProgressManager(cache: cache)
    private lazy var impactManager = ImpactManager(cache: cache, loggedOutManager: loggedOutManager)

    override func setUp() {
        super.setUp()
        cache.clear()
        UserDefaults.standard.removeObject(forKey: "LastAppOpenDate")

        // Default Seed Levels for testing (arbitrary levels)
        loggedOutManager.seedCounterConfig = SeedCounterConfig(
            sparklesAnimationDuration: 10,
            maxCappedLevel: nil,
            maxCappedSeeds: nil,
            levels: [
                SeedCounterConfig.SeedLevel(level: 1, requiredSeeds: 2),
                SeedCounterConfig.SeedLevel(level: 2, requiredSeeds: 3)
            ]
        )
    }

    // MARK: - LoggedOutSeedProgressManager: pure decisions

    func test_calculateInnerProgress_reflectsSeedCount() {
        // requiredSeeds: 2 for level 1, from the config set in setUp
        XCTAssertEqual(loggedOutManager.calculateInnerProgress(seedCount: 2), 1.0, accuracy: 0.0001)
        XCTAssertEqual(loggedOutManager.calculateInnerProgress(seedCount: 0), 0.0, accuracy: 0.0001)
    }

    // MARK: - ImpactManager: end-to-end logged-out behavior

    func test_initial_seed_progress_state() {
        let snapshot = impactManager.loadSeeds(isLoggedIn: false, userId: nil)

        XCTAssertEqual(snapshot.currentLevelNumber, 1, "Initial level should be 1")
        XCTAssertEqual(snapshot.seedCount, 0, "Initial seed count should be 0")
    }

    func test_logged_out_users_never_level_up() {
        impactManager.debugAddLoggedOutSeeds(2)
        var snapshot = impactManager.loadSeeds(isLoggedIn: false, userId: nil)
        XCTAssertEqual(snapshot.currentLevelNumber, 1)
        XCTAssertEqual(snapshot.seedCount, 2)

        impactManager.debugAddLoggedOutSeeds(10)
        snapshot = impactManager.loadSeeds(isLoggedIn: false, userId: nil)
        XCTAssertEqual(snapshot.currentLevelNumber, 1)
        XCTAssertEqual(snapshot.seedCount, 3)
    }

    func test_reset_local_seed_progress() {
        impactManager.debugAddLoggedOutSeeds(2)

        impactManager.reset()

        let snapshot = impactManager.loadSeeds(isLoggedIn: false, userId: nil)
        XCTAssertEqual(snapshot.currentLevelNumber, 1)
        XCTAssertEqual(snapshot.seedCount, 0)
        let lastOpenDateMessage = "Last app open date should be cleared to allow immediate seed collection"
        XCTAssertNil(UserDefaults.standard.object(forKey: "LastAppOpenDate"), lastOpenDateMessage)
    }

    func test_collect_seed_once_per_day() async {
        let initial = impactManager.loadSeeds(isLoggedIn: false, userId: nil)
        XCTAssertEqual(initial.seedCount, 0)

        _ = await impactManager.updateSeeds(isLoggedIn: false, userId: nil, accessToken: nil, accountsProvider: UnreachableAccountsProvider())
        let afterFirstCollect = impactManager.loadSeeds(isLoggedIn: false, userId: nil)

        _ = await impactManager.updateSeeds(isLoggedIn: false, userId: nil, accessToken: nil, accountsProvider: UnreachableAccountsProvider())
        let afterSecondCollect = impactManager.loadSeeds(isLoggedIn: false, userId: nil)

        XCTAssertEqual(afterFirstCollect.seedCount, 1)
        XCTAssertEqual(afterSecondCollect.seedCount, 1)
    }

    func test_collect_seed_next_day_stays_level_1() async {
        _ = await impactManager.updateSeeds(isLoggedIn: false, userId: nil, accessToken: nil, accountsProvider: UnreachableAccountsProvider())
        var snapshot = impactManager.loadSeeds(isLoggedIn: false, userId: nil)
        XCTAssertEqual(snapshot.seedCount, 1)

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        UserDefaults.standard.set(yesterday, forKey: "LastAppOpenDate")
        _ = await impactManager.updateSeeds(isLoggedIn: false, userId: nil, accessToken: nil, accountsProvider: UnreachableAccountsProvider())

        snapshot = impactManager.loadSeeds(isLoggedIn: false, userId: nil)
        XCTAssertEqual(snapshot.seedCount, 2)
        XCTAssertEqual(snapshot.currentLevelNumber, 1)
    }

    func test_logged_out_users_capped_at_max_seeds_and_level_1() {
        let initial = impactManager.loadSeeds(isLoggedIn: false, userId: nil)
        XCTAssertEqual(initial.seedCount, 0)
        XCTAssertEqual(initial.currentLevelNumber, 1)

        impactManager.debugAddLoggedOutSeeds(3)
        var snapshot = impactManager.loadSeeds(isLoggedIn: false, userId: nil)
        XCTAssertEqual(snapshot.seedCount, LoggedOutSeedProgressManager.maxSeedsForLoggedOutUsers)
        XCTAssertEqual(snapshot.currentLevelNumber, 1)

        impactManager.debugAddLoggedOutSeeds(5)
        snapshot = impactManager.loadSeeds(isLoggedIn: false, userId: nil)
        XCTAssertEqual(snapshot.seedCount, LoggedOutSeedProgressManager.maxSeedsForLoggedOutUsers)
        XCTAssertEqual(snapshot.currentLevelNumber, 1)
    }

    func test_logged_out_users_bulk_addition_caps_at_3_seeds_level_1() {
        let initial = impactManager.loadSeeds(isLoggedIn: false, userId: nil)
        XCTAssertEqual(initial.seedCount, 0)

        impactManager.debugAddLoggedOutSeeds(10)

        let snapshot = impactManager.loadSeeds(isLoggedIn: false, userId: nil)
        XCTAssertEqual(snapshot.seedCount, LoggedOutSeedProgressManager.maxSeedsForLoggedOutUsers)
        XCTAssertEqual(snapshot.currentLevelNumber, 1)
    }

    func test_logged_out_users_daily_seed_respects_cap_and_level_1() async {
        impactManager.debugAddLoggedOutSeeds(3)
        var snapshot = impactManager.loadSeeds(isLoggedIn: false, userId: nil)
        XCTAssertEqual(snapshot.seedCount, 3)
        XCTAssertEqual(snapshot.currentLevelNumber, 1)

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        UserDefaults.standard.set(yesterday, forKey: "LastAppOpenDate")
        _ = await impactManager.updateSeeds(isLoggedIn: false, userId: nil, accessToken: nil, accountsProvider: UnreachableAccountsProvider())

        snapshot = impactManager.loadSeeds(isLoggedIn: false, userId: nil)
        XCTAssertEqual(snapshot.seedCount, LoggedOutSeedProgressManager.maxSeedsForLoggedOutUsers)
        XCTAssertEqual(snapshot.currentLevelNumber, 1)
    }

    func test_loadSeeds_reflectsLocalProgress() {
        impactManager.debugAddLoggedOutSeeds(2) // exactly reaches level 1's threshold (requiredSeeds: 2)

        let snapshot = impactManager.loadSeeds(isLoggedIn: false, userId: nil)

        XCTAssertEqual(snapshot.seedCount, 2)
        XCTAssertEqual(snapshot.currentLevelNumber, 1)
        XCTAssertEqual(snapshot.currentProgress, 1.0, accuracy: 0.0001)
    }
}
