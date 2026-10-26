// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia

/// Records calls instead of touching real `UserDefaults`, so tests don't depend on
/// `EcosiaAuthenticationService.shared`'s live (unmockable) singleton state.
final class MockLoggedInImpactCache: LoggedInImpactCacheProtocol {
    nonisolated(unsafe) static var stored: ImpactSnapshot?
    nonisolated(unsafe) static var clearCallCount = 0

    static func load() -> ImpactSnapshot? {
        stored
    }

    static func save(_ snapshot: ImpactSnapshot) {
        stored = snapshot
    }

    static func clear() {
        clearCallCount += 1
        stored = nil
    }

    static func reset() {
        stored = nil
        clearCallCount = 0
    }
}
