// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import ToolbarKit

/// Tests for the address bar search query display in collapsed state.
///
/// The address bar must show the user's typed search query rather than the raw URL
/// whenever a `searchTerm` is available — both when editing and when collapsed.
@MainActor
final class LocationViewTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var sut: LocationView!
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var mockDelegate: MockLocationViewDelegate!

    override func setUp() async throws {
        try await super.setUp()
        sut = LocationView(frame: .zero)
        mockDelegate = MockLocationViewDelegate()
        trackForMemoryLeaks(sut)
        trackForMemoryLeaks(mockDelegate)
    }

    override func tearDown() async throws {
        sut = nil
        mockDelegate = nil
        try await super.tearDown()
    }

    // MARK: - Collapsed bar (isEditing = false)

    func testCollapsedBar_withTextSearchTerm_showsSearchTermNotURL() {
        let searchTerm = "climate change"
        let url = URL(string: "https://www.ecosia.org/search?q=climate+change")!
        configure(url: url, searchTerm: searchTerm, isEditing: false)

        XCTAssertEqual(textFieldText(), searchTerm)
    }

    func testCollapsedBar_withImageVerticalSearchTerm_showsSearchTermNotURL() {
        let searchTerm = "ocean"
        let url = URL(string: "https://www.ecosia.org/images?q=ocean")!
        configure(url: url, searchTerm: searchTerm, isEditing: false)

        XCTAssertEqual(textFieldText(), searchTerm)
    }

    func testCollapsedBar_withVideoVerticalSearchTerm_showsSearchTermNotURL() {
        let searchTerm = "reforestation"
        let url = URL(string: "https://www.ecosia.org/videos?q=reforestation")!
        configure(url: url, searchTerm: searchTerm, isEditing: false)

        XCTAssertEqual(textFieldText(), searchTerm)
    }

    func testCollapsedBar_withNewsVerticalSearchTerm_showsSearchTermNotURL() {
        let searchTerm = "solar energy"
        let url = URL(string: "https://www.ecosia.org/news?q=solar+energy")!
        configure(url: url, searchTerm: searchTerm, isEditing: false)

        XCTAssertEqual(textFieldText(), searchTerm)
    }

    func testCollapsedBar_withStagingSearchTerm_showsSearchTermNotURL() {
        let searchTerm = "mangroves"
        let url = URL(string: "https://www.ecosia-staging.xyz/search?q=mangroves")!
        configure(url: url, searchTerm: searchTerm, isEditing: false)

        XCTAssertEqual(textFieldText(), searchTerm)
    }

    func testCollapsedBar_withNoSearchTerm_showsURLHostname() {
        let url = URL(string: "https://www.example.com/page")!
        configure(url: url, searchTerm: nil, isEditing: false)

        // formatAndTruncateURLTextField reduces the URL to its normalised host.
        XCTAssertEqual(textFieldText(), "example.com")
    }

    func testCollapsedBar_withNonEcosiaSearchURL_showsURLHostname() {
        // When searching on a non-Ecosia engine the model passes searchTerm = nil;
        // the bar must show the URL, not the raw query string.
        let url = URL(string: "https://www.google.com/search?q=trees")!
        configure(url: url, searchTerm: nil, isEditing: false)

        XCTAssertEqual(textFieldText(), "google.com")
    }

    func testCollapsedBar_withRegularWebsite_showsURLHostname() {
        let url = URL(string: "https://www.wikipedia.org/wiki/Reforestation")!
        configure(url: url, searchTerm: nil, isEditing: false)

        XCTAssertEqual(textFieldText(), "wikipedia.org")
    }

    func testCollapsedBar_withNoURLAndNoSearchTerm_isNilOrEmpty() {
        configure(url: nil, searchTerm: nil, isEditing: false)

        let text = textFieldText() ?? ""
        XCTAssertTrue(text.isEmpty, "URL bar should be empty when neither a URL nor a search term is provided")
    }

    // MARK: - Editing bar (isEditing = true)

    func testEditingBar_withSearchTerm_showsSearchTerm() {
        let searchTerm = "rainforest"
        let url = URL(string: "https://www.ecosia.org/search?q=rainforest")!
        configure(url: url, searchTerm: searchTerm, isEditing: true)

        XCTAssertEqual(textFieldText(), searchTerm)
    }

    func testEditingBar_withNoSearchTerm_showsURL() {
        let url = URL(string: "https://www.ecosia.org/search?q=rainforest")!
        configure(url: url, searchTerm: nil, isEditing: true)

        XCTAssertEqual(textFieldText(), url.absoluteString)
    }

    // MARK: - Helpers

    private func configure(url: URL?, searchTerm: String?, isEditing: Bool) {
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
                      delegate: mockDelegate,
                      isUnifiedSearchEnabled: false,
                      uxConfig: .experiment(),
                      addressBarPosition: .top)
    }

    private func textFieldText() -> String? {
        findTextField(in: sut)?.text
    }

    private func findTextField(in view: UIView) -> UITextField? {
        for subview in view.subviews {
            if let tf = subview as? UITextField { return tf }
            if let found = findTextField(in: subview) { return found }
        }
        return nil
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
