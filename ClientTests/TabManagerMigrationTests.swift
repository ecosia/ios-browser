/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest
@testable import Client
@testable import Core

class EcosiaTabMigrationTests: TabManagerStoreTests {

    func testEcosiaImportTabs() {
        try? FileManager.default.removeItem(at: FileManager.pages)
        try? FileManager.default.removeItem(at: FileManager.snapshots)
        Core.User.shared.migrated = false

        let urls = [URL(string: "https://ecosia.org")!,
                    URL(string: "https://guacamole.com")!]

        let tabs = Core.Tabs()
        urls.forEach { tabs.new($0) }

        let expectation = XCTestExpectation()
        PageStore.queue.async {
            DispatchQueue.main.async {
                _ = self.manager.store.restoreStartupTabs(clearPrivateTabs: false, tabManager: self.manager)
                XCTAssertEqual(self.manager.normalTabs.count, 2, "There should be 2 normal tabs")
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 4)
    }
}
