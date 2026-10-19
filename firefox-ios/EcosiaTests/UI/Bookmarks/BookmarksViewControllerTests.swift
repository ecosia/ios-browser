// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Storage
import XCTest

@testable import Client

// Ecosia: Lifecycle tests for the Ecosia empty bookmarks state on BookmarksViewController.
@MainActor
final class BookmarksViewControllerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        super.tearDown()
    }

    // Regression: deinit must not create EmptyBookmarksView (delegate = self) during teardown.
    func test_deinit_whenEmptyStateWasNeverShown_doesNotLeak() {
        let subject = createSubject(bookmarkCount: 1)
        trackForMemoryLeaks(subject)
    }

    func test_viewWillAppear_whenBookmarksAreEmpty_showsEmptyBookmarksView() {
        let subject = createSubject(bookmarkCount: 0)
        subject.loadViewIfNeeded()
        subject.viewWillAppear(false)

        XCTAssertTrue(subject.view.subviews.contains { $0 is EmptyBookmarksView })
    }

    func test_viewWillAppear_whenBookmarksExist_hidesEmptyBookmarksView() {
        let subject = createSubject(bookmarkCount: 1)
        subject.loadViewIfNeeded()
        subject.viewWillAppear(false)

        XCTAssertFalse(subject.view.subviews.contains { $0 is EmptyBookmarksView })
    }

    // Ecosia: 155.1 made `BookmarksPanelViewModel`'s node array private (`allBookmarkNodes`) and
    // exposes only `isCurrentFolderEmpty` / `displayedBookmarkNodes`, so the nodes can no longer be
    // assigned directly. They are now seeded through `MockBookmarksHandler`'s folder data and pulled
    // in with `reloadData`, which is how upstream's own view-model tests do it.
    private func createSubject(bookmarkCount: Int) -> BookmarksViewController {
        let children: [BookmarkNodeData] = (0..<bookmarkCount).map { index in
            BookmarkItemData(
                guid: "bookmark-\(index)",
                dateAdded: Int64(Date().toTimestamp()),
                lastModified: Int64(Date().toTimestamp()),
                parentGUID: BookmarkRoots.MobileFolderGUID,
                position: UInt32(index),
                url: "https://example.com/\(index)",
                title: "Saved bookmark \(index)"
            )
        }
        let folderData = BookmarkFolderData(
            guid: BookmarkRoots.MobileFolderGUID,
            dateAdded: Int64(Date().toTimestamp()),
            lastModified: Int64(Date().toTimestamp()),
            parentGUID: nil,
            position: 0,
            title: "",
            childGUIDs: children.map { $0.guid },
            children: children
        )

        let viewModel = BookmarksPanelViewModel(
            profile: MockProfile(),
            // Ecosia: renamed upstream in 155.1 (BookmarksHandlerMock -> MockBookmarksHandler).
            bookmarksHandler: MockBookmarksHandler(folderData: folderData),
            bookmarkFolderGUID: BookmarkRoots.MobileFolderGUID
        )

        let loaded = expectation(description: "view model reloaded")
        viewModel.reloadData { loaded.fulfill() }
        wait(for: [loaded], timeout: 5)

        let subject = BookmarksViewController(viewModel: viewModel, windowUUID: .XCTestDefaultUUID)
        trackForMemoryLeaks(subject)
        return subject
    }
}
