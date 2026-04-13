// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import Shared

/// A class that adheres to all the requirements for a profile's pinned sites
class MockablePinnedSites: PinnedSites, @unchecked Sendable {
    func remove(pinnedSite site: Storage.Site) async throws { fatalError() }
    func addPinnedTopSite(_ site: Storage.Site, completion: @escaping @Sendable (Result<Void, any Error>) -> Void) { fatalError() }
    func removeFromPinnedTopSites(_ site: Site) -> Success { fatalError() }
    func isPinnedTopSite(_ url: String) -> Deferred<Maybe<Bool>> { fatalError()}
    func addPinnedTopSite(_ site: Site) -> Success { fatalError() }
    func getPinnedTopSites() -> Deferred<Maybe<Cursor<Site>>> { fatalError() }
}
