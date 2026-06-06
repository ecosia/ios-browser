// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import ToolbarKit

/// Tests for the address bar search query display in collapsed state.
///
/// The address bar must show the user's typed search query rather than the raw URL
/// whenever a `searchTerm` is available — both when editing and when collapsed.
///
/// Each case drives the SUT through a single `assertAddressBar(...)` helper. The whole SUT
/// lifecycle (create → configure → assert behaviour → release) runs inside an explicit
/// `autoreleasepool`, and leak detection asserts the SUT and its delegate are deallocated
/// *after* that pool drains. This is deliberate: XCTest's per-test autorelease pool only drains
/// after the test (and `addTeardownBlock` blocks) finish, so the `+1` autoreleased temporaries
/// created by `LocationView(...)`, `configure(...)` and walking the view tree would otherwise make
/// `trackForMemoryLeaks` report a false-positive leak even though the view does not actually leak.
/// `LocationView.configure` also schedules short `UIView.animate`/main-queue work that briefly
/// captures the view, so the run loop is pumped before the assertion to let that settle. (MOB-4384)
@MainActor
final class LocationViewTests: XCTestCase {
    // MARK: - Collapsed bar (isEditing = false)

    func testCollapsedBar_withTextSearchTerm_showsSearchTermNotURL() {
        assertAddressBar(
            url: URL(string: "https://www.ecosia.org/search?q=climate+change")!,
            searchTerm: "climate change",
            isEditing: false,
            shows: "climate change"
        )
    }

    func testCollapsedBar_withImageVerticalSearchTerm_showsSearchTermNotURL() {
        assertAddressBar(
            url: URL(string: "https://www.ecosia.org/images?q=ocean")!,
            searchTerm: "ocean",
            isEditing: false,
            shows: "ocean"
        )
    }

    func testCollapsedBar_withVideoVerticalSearchTerm_showsSearchTermNotURL() {
        assertAddressBar(
            url: URL(string: "https://www.ecosia.org/videos?q=reforestation")!,
            searchTerm: "reforestation",
            isEditing: false,
            shows: "reforestation"
        )
    }

    func testCollapsedBar_withNewsVerticalSearchTerm_showsSearchTermNotURL() {
        assertAddressBar(
            url: URL(string: "https://www.ecosia.org/news?q=solar+energy")!,
            searchTerm: "solar energy",
            isEditing: false,
            shows: "solar energy"
        )
    }

    func testCollapsedBar_withStagingSearchTerm_showsSearchTermNotURL() {
        assertAddressBar(
            url: URL(string: "https://www.ecosia-staging.xyz/search?q=mangroves")!,
            searchTerm: "mangroves",
            isEditing: false,
            shows: "mangroves"
        )
    }

    func testCollapsedBar_withNoSearchTerm_showsURLHostname() {
        // formatAndTruncateURLTextField reduces the URL to its normalised host.
        assertAddressBar(
            url: URL(string: "https://www.example.com/page")!,
            searchTerm: nil,
            isEditing: false,
            shows: "example.com"
        )
    }

    func testCollapsedBar_withNonEcosiaSearchURL_showsURLHostname() {
        // When searching on a non-Ecosia engine the model passes searchTerm = nil;
        // the bar must show the URL, not the raw query string.
        assertAddressBar(
            url: URL(string: "https://www.google.com/search?q=trees")!,
            searchTerm: nil,
            isEditing: false,
            shows: "google.com"
        )
    }

    func testCollapsedBar_withRegularWebsite_showsURLHostname() {
        assertAddressBar(
            url: URL(string: "https://www.wikipedia.org/wiki/Reforestation")!,
            searchTerm: nil,
            isEditing: false,
            shows: "wikipedia.org"
        )
    }

    func testCollapsedBar_withNoURLAndNoSearchTerm_isNilOrEmpty() {
        assertAddressBar(
            url: nil,
            searchTerm: nil,
            isEditing: false,
            shows: "",
            message: "URL bar should be empty when neither a URL nor a search term is provided"
        )
    }

    // MARK: - Editing bar (isEditing = true)

    func testEditingBar_withSearchTerm_showsSearchTerm() {
        assertAddressBar(
            url: URL(string: "https://www.ecosia.org/search?q=rainforest")!,
            searchTerm: "rainforest",
            isEditing: true,
            shows: "rainforest"
        )
    }

    func testEditingBar_withNoSearchTerm_showsURL() {
        let url = URL(string: "https://www.ecosia.org/search?q=rainforest")!
        assertAddressBar(
            url: url,
            searchTerm: nil,
            isEditing: true,
            shows: url.absoluteString
        )
    }

    // MARK: - Helpers

    /// Configures a fresh `LocationView` and asserts the URL text field shows `shows`, then asserts
    /// the view and its delegate are deallocated. See the type doc for why the lifecycle is wrapped
    /// in an explicit `autoreleasepool` and the run loop is pumped before the leak assertion.
    private func assertAddressBar(
        url: URL?,
        searchTerm: String?,
        isEditing: Bool,
        shows expected: String,
        message: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        weak var weakSut: LocationView?
        weak var weakDelegate: MockLocationViewDelegate?

        autoreleasepool {
            let sut = LocationView(frame: .zero)
            let delegate = MockLocationViewDelegate()
            weakSut = sut
            weakDelegate = delegate

            let config = LocationViewConfiguration(
                searchEngineImageViewA11yId: "searchEngine",
                searchEngineImageViewA11yLabel: "Search Engine",
                lockIconButtonA11yId: "lockIcon",
                lockIconButtonA11yLabel: "Lock",
                urlTextFieldPlaceholder: "Search or enter address",
                urlTextFieldA11yId: "urlTextField",
                searchEngineImage: nil,
                lockIconImageName: nil,
                lockIconNeedsTheming: false,
                safeListedURLImageName: nil,
                url: url,
                droppableUrl: nil,
                searchTerm: searchTerm,
                isEditing: isEditing,
                didStartTyping: false,
                shouldShowKeyboard: false,
                shouldSelectSearchTerm: false
            )
            sut.configure(config,
                          delegate: delegate,
                          isUnifiedSearchEnabled: false,
                          uxConfig: .experiment(),
                          addressBarPosition: .top)

            let actual = findTextField(in: sut)?.text ?? ""
            XCTAssertEqual(actual, expected, message ?? "", file: file, line: line)
        }

        Self.drainMainRunLoop(for: 0.3)
        XCTAssertNil(weakSut, "LocationView leaked", file: file, line: line)
        XCTAssertNil(weakDelegate, "LocationViewDelegate leaked", file: file, line: line)
    }

    private func findTextField(in view: UIView) -> UITextField? {
        for subview in view.subviews {
            if let tf = subview as? UITextField { return tf }
            if let found = findTextField(in: subview) { return found }
        }
        return nil
    }

    /// Synchronously pumps the main run loop for `seconds`, letting deferred main-queue blocks and
    /// timers (e.g. `UIView.animate`'s delayed start) fire and the run-loop autorelease pool drain.
    /// Lives in a non-`async` context because the run-loop APIs are unavailable from async contexts.
    private nonisolated static func drainMainRunLoop(for seconds: TimeInterval) {
        let deadline = Date().addingTimeInterval(seconds)
        while Date() < deadline {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.02))
        }
    }
}

// MARK: - Mock

private final class MockLocationViewDelegate: LocationViewDelegate {
    func locationViewDidEnterText(_ text: String) {}
    func locationViewDidClearText() {}
    func locationViewDidBeginEditing(_ text: String, shouldShowSuggestions: Bool) {}
    func locationViewDidSubmitText(_ text: String) {}
    func locationViewDidTapSearchEngine<T: SearchEngineView>(_ searchEngine: T) {}
    func locationViewAccessibilityActions() -> [UIAccessibilityCustomAction]? { nil }
    func locationTextFieldNeedsSearchReset() {}
}
