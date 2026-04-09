// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Storage
import UIKit
import XCTest

@testable import Client

// Ecosia: Tests for the native UIContextMenuConfiguration on NTP top sites (iOS 26 Liquid Glass context menu).
@MainActor
final class TopSiteNativeContextMenuTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var subject: HomepageViewController!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        subject = HomepageViewController(
            windowUUID: .XCTestDefaultUUID,
            overlayManager: DefaultOverlayModeManager(),
            toastContainer: UIView()
        )
        trackForMemoryLeaks(subject)
    }

    override func tearDown() async throws {
        subject = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // MARK: - Regular top site

    // Ecosia: Verifies that a regular (non-pinned) top site menu contains a Pin action as its first item.
    func test_regularTopSite_menuContainsPinAction() {
        let site = Site.createBasicSite(url: "https://example.com", title: "Example")
        let menu = subject.makeTopSiteContextMenu(for: site, sourceView: UIView())

        let pinGroup = menu.children.first as? UIMenu
        let pinAction = pinGroup?.children.first as? UIAction
        XCTAssertEqual(pinAction?.title, String.PinTopsiteActionTitle2)
    }

    // Ecosia: Verifies that the navigation group contains Open in New Tab and Open in Private Tab actions.
    func test_regularTopSite_menuContainsNavigationActions() {
        let site = Site.createBasicSite(url: "https://example.com", title: "Example")
        let menu = subject.makeTopSiteContextMenu(for: site, sourceView: UIView())

        let navGroup = menu.children[safe: 1] as? UIMenu
        XCTAssertEqual(navGroup?.children.count, 2)

        let openNewTab = navGroup?.children[safe: 0] as? UIAction
        XCTAssertEqual(openNewTab?.title, String.OpenInNewTabContextMenuTitle)

        let openPrivateTab = navGroup?.children[safe: 1] as? UIAction
        XCTAssertEqual(openPrivateTab?.title, String.OpenInNewPrivateTabContextMenuTitle)
    }

    // Ecosia: Verifies that the Remove action is marked destructive so iOS renders it in red.
    func test_regularTopSite_menuContainsDestructiveRemoveAction() {
        let site = Site.createBasicSite(url: "https://example.com", title: "Example")
        let menu = subject.makeTopSiteContextMenu(for: site, sourceView: UIView())

        let destructiveGroup = menu.children[safe: 2] as? UIMenu
        let removeAction = destructiveGroup?.children.first as? UIAction
        XCTAssertEqual(removeAction?.title, String.RemoveContextMenuTitle)
        XCTAssertTrue(removeAction?.attributes.contains(.destructive) ?? false)
    }

    // Ecosia: Verifies that Share is present as a standalone action at the bottom of the menu.
    func test_regularTopSite_menuContainsShareAction() {
        let site = Site.createBasicSite(url: "https://example.com", title: "Example")
        let menu = subject.makeTopSiteContextMenu(for: site, sourceView: UIView())

        let shareAction = menu.children[safe: 3] as? UIAction
        XCTAssertEqual(shareAction?.title, String.ShareContextMenuTitle)
    }

    // MARK: - Pinned top site

    // Ecosia: Verifies that a pinned top site menu shows Unpin instead of Pin.
    func test_pinnedTopSite_menuContainsUnpinAction() {
        let site = Site.createPinnedSite(url: "https://example.com", title: "Example", isGooglePinnedTile: false)
        let menu = subject.makeTopSiteContextMenu(for: site, sourceView: UIView())

        let pinGroup = menu.children.first as? UIMenu
        let unpinAction = pinGroup?.children.first as? UIAction
        XCTAssertEqual(unpinAction?.title, String.UnpinTopsiteActionTitle2)
    }
}

// Ecosia: Safe subscript used in native context menu tests to avoid out-of-bounds crashes.
private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
