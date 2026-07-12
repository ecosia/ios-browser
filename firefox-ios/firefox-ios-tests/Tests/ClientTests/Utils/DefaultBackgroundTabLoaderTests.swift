// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Storage
import XCTest
@testable import Client

@MainActor
class DefaultBackgroundTabLoaderTests: XCTestCase {
    private var applicationHelper: MockApplicationHelper!
    private var tabQueue: MockTabQueue!

    override func setUp() {
        super.setUp()
        self.applicationHelper = MockApplicationHelper()
        self.tabQueue = MockTabQueue()
    }

    override func tearDown() {
        super.tearDown()
        self.applicationHelper = nil
        self.tabQueue = nil
    }

    func testLoadBackgroundTabs_noTabs_doesntLoad() {
        let subject = createSubject()

        subject.loadBackgroundTabs()

        XCTAssertEqual(tabQueue.getQueuedTabsCalled, 1)
        XCTAssertEqual(applicationHelper.openURLCalled, 0)
    }

    func testLoadBackgroundTabs_withTabs_load() async {
        let urlString = "https://www.mozilla.com"
        tabQueue.queuedTabs = [ShareItem(url: urlString, title: "Title 1"),
                               ShareItem(url: urlString, title: "Title 2"),
                               ShareItem(url: urlString, title: "Title 3")]
        let subject = createSubject()

        subject.loadBackgroundTabs()

        // Ecosia: MockTabQueue.getQueuedTabs delivers its completion on a main-actor Task, so let it run before
        // asserting the URLs were opened and the queue cleared.
        await Task.yield()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(tabQueue.getQueuedTabsCalled, 1)
        XCTAssertEqual(applicationHelper.openURLCalled, 3)
        XCTAssertEqual(tabQueue.clearQueuedTabsCalled, 1)
    }

    // MARK: Helper functions

    func createSubject() -> DefaultBackgroundTabLoader {
        let subject = DefaultBackgroundTabLoader(tabQueue: tabQueue,
                                                 applicationHelper: applicationHelper,
                                                 backgroundQueue: MockDispatchQueue())
        trackForMemoryLeaks(subject)
        return subject
    }
}
