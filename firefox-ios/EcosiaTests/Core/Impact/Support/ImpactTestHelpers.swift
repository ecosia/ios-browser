// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

/// Posts the real `.EcosiaAuthStateChanged` notification production code posts, with the same
/// `userInfo` shape (`AuthNotificationSystemTests` confirms `"actionType"` is the key it reads).
@MainActor
func postAuthStateChanged(_ actionType: EcosiaAuthActionType) {
    NotificationCenter.default.post(
        name: .EcosiaAuthStateChanged,
        object: nil,
        userInfo: ["actionType": actionType]
    )
}

extension XCTestCase {

    /// Runs `trigger`, then waits for `.EcosiaImpactCacheUpdated` to fire (or times out), returning
    /// the notification's `userInfo` for inline assertions. Use when exactly one write is expected;
    /// for a sequence of writes (e.g. logout's reset-then-collect), prefer `waitUntil`.
    @MainActor
    @discardableResult
    func waitForImpactCacheUpdate(timeout: TimeInterval = 2, after trigger: @escaping () -> Void) async -> [AnyHashable: Any]? {
        let notificationExpectation = expectation(description: "EcosiaImpactCacheUpdated")
        var receivedUserInfo: [AnyHashable: Any]?
        let observer = NotificationCenter.default.addObserver(forName: .EcosiaImpactCacheUpdated, object: nil, queue: .main) { notification in
            receivedUserInfo = notification.userInfo
            notificationExpectation.fulfill()
        }
        trigger()
        await fulfillment(of: [notificationExpectation], timeout: timeout)
        NotificationCenter.default.removeObserver(observer)
        return receivedUserInfo
    }

    /// Runs `trigger`, then waits for `.EcosiaImpactUpdateFailed` to fire (or times out).
    @MainActor
    func waitForImpactUpdateFailure(timeout: TimeInterval = 2, after trigger: @escaping () -> Void) async {
        let notificationExpectation = expectation(description: "EcosiaImpactUpdateFailed")
        let observer = NotificationCenter.default.addObserver(forName: .EcosiaImpactUpdateFailed, object: nil, queue: .main) { _ in
            notificationExpectation.fulfill()
        }
        trigger()
        await fulfillment(of: [notificationExpectation], timeout: timeout)
        NotificationCenter.default.removeObserver(observer)
    }

    /// Polls `condition` until it's true or `timeout` elapses. Used instead of a single-notification
    /// wait when a sequence of more than one write is expected (e.g. logout's reset-to-zero
    /// immediately followed by collecting today's seed both post `.EcosiaImpactCacheUpdated`, and
    /// waiting for only the first would race the second's effect).
    @MainActor
    func waitUntil(timeout: TimeInterval = 2, _ condition: @escaping () -> Bool) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }
}
