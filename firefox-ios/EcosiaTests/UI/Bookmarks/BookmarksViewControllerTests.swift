// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

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
        let subject = createSubject(
            bookmarkNodes: [
                MockFxBookmarkNode(
                    type: .bookmark,
                    guid: "bookmark-guid",
                    parentGUID: nil,
                    position: 0,
                    isRoot: false,
                    title: "Saved bookmark"
                )
            ]
        )
        trackForMemoryLeaks(subject)
    }

    func test_viewWillAppear_whenBookmarksAreEmpty_showsEmptyBookmarksView() {
        let subject = createSubject(bookmarkNodes: [])
        subject.loadViewIfNeeded()
        subject.viewWillAppear(false)

        XCTAssertTrue(subject.view.subviews.contains { $0 is EmptyBookmarksView })
    }

    func test_viewWillAppear_whenBookmarksExist_hidesEmptyBookmarksView() {
        let subject = createSubject(
            bookmarkNodes: [
                MockFxBookmarkNode(
                    type: .bookmark,
                    guid: "bookmark-guid",
                    parentGUID: nil,
                    position: 0,
                    isRoot: false,
                    title: "Saved bookmark"
                )
            ]
        )
        subject.loadViewIfNeeded()
        subject.viewWillAppear(false)

        XCTAssertFalse(subject.view.subviews.contains { $0 is EmptyBookmarksView })
    }

    private func createSubject(bookmarkNodes: [FxBookmarkNode]) -> BookmarksViewController {
        let viewModel = BookmarksPanelViewModel(
            profile: MockProfile(),
            bookmarksHandler: BookmarksHandlerMock(),
            bookmarkFolderGUID: BookmarkRoots.MobileFolderGUID
        )
        viewModel.bookmarkNodes = bookmarkNodes

        let subject = BookmarksViewController(viewModel: viewModel, windowUUID: .XCTestDefaultUUID)
        trackForMemoryLeaks(subject)
        return subject
    }
}
