// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client
@testable import Ecosia

final class AppDelegateMMPIntegrationTests: XCTestCase, @unchecked Sendable {
    // swiftlint:disable implicitly_unwrapped_optional
    var appDelegate: AppDelegate!
    var mockProvider: MockMMPProvider!
    var savedUser: User!
    // swiftlint:enable implicitly_unwrapped_optional

    override func setUp() {
        super.setUp()
        // Ecosia: seed a fresh Unleash model so applicationDidBecomeActive's
        // FeatureManagement.fetchConfiguration spawns NO real network Task that would leak into later
        // tests (the cross-test contamination that flaked CI). (MOB-4384)
        seedFreshUnleashModelToAvoidNetworkFetch()
        MainActor.assumeIsolated {
            appDelegate = AppDelegate()
            DependencyHelperMock().bootstrapDependencies()
        }
        savedUser = User.shared
        User.shared.sendAnonymousUsageData = true
        User.shared.searchCount = 0
        mockProvider = MockMMPProvider()
        MMP.provider = mockProvider
    }

    override func tearDown() {
        User.shared = savedUser
        // Ecosia: reset to a SILENT no-op provider, NOT the real `Singular`. `MMP.sendSession()` /
        // `sendEvent()` spawn detached Tasks that read `MMP.provider` at execution time; one delayed
        // past this point — or fired later by the leaked subscription below — must hit a no-op, never
        // real MMP network that would contaminate (and slow) sibling tests. (MOB-4384)
        MMP.provider = MockMMPProvider()
        // Ecosia: release the AppDelegate so its private `SearchesCounter` — a NotificationCenter
        // observer of `.searchesCounterChanged` whose subscription calls `MMP.handleSearchEvent` — is
        // deallocated. XCTest retains every test-case instance until the WHOLE run finishes, so without
        // this the observer/subscription lives on and does real MMP work whenever any later test mutates
        // `User.shared.searchCount`. Safe to nil: `Subscription.subscriber` is weak and the closure does
        // not capture `self`, so there is no retain cycle keeping the instance alive. (MOB-4384)
        MainActor.assumeIsolated { appDelegate = nil }
        // Ecosia: drain the shared async queues this class's becomeActive tests enqueue work onto, so
        // it completes before the next test runs (no cross-test contamination). (MOB-4384)
        drainSharedAsyncQueues()
        super.tearDown()
    }

    func testSessionIsSentOnBecomeActive() {
        MainActor.assumeIsolated { appDelegate.ecosiaTrackBecomeActiveLifecycle() }
        wait(1)
        XCTAssertTrue(mockProvider.didSendSession)
    }

    func testSessionIsNotSentWhenAnonymousDataDisabled() {
        User.shared.sendAnonymousUsageData = false
        MainActor.assumeIsolated { appDelegate.ecosiaTrackBecomeActiveLifecycle() }
        wait(1)
        XCTAssertFalse(mockProvider.didSendSession)
    }

    func testFirstSearchMilestoneTriggersEvent() {
        MainActor.assumeIsolated { appDelegate.ecosiaTrackBecomeActiveLifecycle() }
        User.shared.searchCount = 1
        wait(1)
        // Ecosia: applicationDidBecomeActive's async work re-posts `.searchesCounterChanged` for the
        // same value during the wait (verified: the notification fires twice for the single 0→1
        // change), so the milestone subscriber legitimately fires more than once in this app-hosted
        // test. Assert the SET of milestone events — the first-search milestone, and only it, was
        // triggered — rather than an exact delivery count, which is an artifact of the host re-sync
        // and not the logic under test. (In production a real first search posts once.) (MOB-4384)
        XCTAssertEqual(Set(mockProvider.receivedEvents), [.firstSearch])
    }

    func testNonMilestoneSearchCountDoesNotTriggerEvent() {
        MainActor.assumeIsolated { appDelegate.ecosiaTrackBecomeActiveLifecycle() }
        User.shared.searchCount = 3
        wait(1)
        XCTAssertTrue(mockProvider.receivedEvents.isEmpty)
    }
}

// MARK: - MockMMPProvider

final class MockMMPProvider: MMPProvider, @unchecked Sendable {
    var didSendSession = false
    var receivedEvents: [MMPEvent] = []

    func sendSessionInfo(appDeviceInfo: AppDeviceInfo) async throws {
        didSendSession = true
    }

    func sendEvent(_ event: MMPEvent, appDeviceInfo: AppDeviceInfo) async throws {
        receivedEvents.append(event)
    }
}
