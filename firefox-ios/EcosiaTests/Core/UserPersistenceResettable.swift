// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia

/// Conform and call `resetUserPersistence()` from `setUp()` and `tearDown()` in any test that
/// reads/writes the shared, disk-persisted `User.shared` singleton.
///
/// `User`'s `didSet` dispatches its disk write onto `User.queue` independently of whatever signal
/// (an `XCTestExpectation`, a `NotificationCenter` notification) a test waited on to decide it's
/// done — so a leftover write can still be in flight when the next test's `setUp` deletes the
/// file out from under it, or reads back a value another test just set. `User.shared` itself also
/// carries over unchanged between tests unless explicitly reset, leaking field values across
/// unrelated test methods since XCTest doesn't guarantee execution order. Draining `User.queue`
/// and resetting `User.shared` before and after each test closes both races. (MOB-4879)
protocol UserPersistenceResettable {}

extension UserPersistenceResettable where Self: XCTestCase {
    func resetUserPersistence() {
        User.queue.sync {}
        try? FileManager.default.removeItem(at: FileManager.user)
        User.shared = User()
    }
}
