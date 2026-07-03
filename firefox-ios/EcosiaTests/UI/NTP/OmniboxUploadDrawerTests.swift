// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import SwiftUI
import Common
@testable import Client
@testable import Ecosia

@MainActor
final class OmniboxUploadDrawerTests: XCTestCase {

    func testUploadOptionsExposeAllCases() {
        XCTAssertEqual(OmniboxUploadOption.allCases.count, 3)
        XCTAssertEqual(Set(OmniboxUploadOption.allCases), Set([.photos, .camera, .files]))
    }

    func testUploadOptionAccessibilityMetadata() {
        XCTAssertEqual(OmniboxUploadOption.photos.accessibilityLabel, String.localized(.photos))
        XCTAssertEqual(OmniboxUploadOption.photos.accessibilityHint, String.localized(.uploadPhotosAccessibilityHint))
        XCTAssertEqual(OmniboxUploadOption.photos.accessibilityIdentifier, "OmniboxUploadPhotosOption")

        XCTAssertEqual(OmniboxUploadOption.camera.accessibilityLabel, String.localized(.camera))
        XCTAssertEqual(OmniboxUploadOption.camera.accessibilityHint, String.localized(.uploadCameraAccessibilityHint))
        XCTAssertEqual(OmniboxUploadOption.camera.accessibilityIdentifier, "OmniboxUploadCameraOption")

        XCTAssertEqual(OmniboxUploadOption.files.accessibilityLabel, String.localized(.files))
        XCTAssertEqual(OmniboxUploadOption.files.accessibilityHint, String.localized(.uploadFilesAccessibilityHint))
        XCTAssertEqual(OmniboxUploadOption.files.accessibilityIdentifier, "OmniboxUploadFilesOption")
    }

    @available(iOS 16.0, *)
    func testLightThemeDrawerAndIconTilesHaveDistinctBackgrounds() {
        var theme = OmniboxUploadDrawerViewTheme()
        let lightTheme = EcosiaLightTheme()
        theme.applyTheme(theme: lightTheme)

        XCTAssertEqual(theme.backgroundColor, Color(lightTheme.colors.ecosia.backgroundPrimaryDecorative))
        XCTAssertEqual(theme.iconBackgroundColor, Color(lightTheme.colors.ecosia.backgroundElevation1))
        XCTAssertNotEqual(theme.backgroundColor, theme.iconBackgroundColor)
    }

    func testUploadDrawerIconsLoadFromFrameworkBundle() {
        XCTAssertNotNil(UIImage.ecosia(named: "upload-photos"))
        XCTAssertNotNil(UIImage.ecosia(named: "upload-camera"))
        XCTAssertNotNil(UIImage.ecosia(named: "upload-files"))
    }

    func testUploadOptionsRenderInDesignOrder() {
        XCTAssertEqual(OmniboxUploadOption.allCases, [.photos, .camera, .files])
    }

    func testChatModesExposeAllCases() {
        XCTAssertEqual(OmniboxChatMode.allCases.count, 4)
        XCTAssertEqual(OmniboxChatMode.allCases, [.standard, .thinkLonger, .displaySources, .learning])
    }

    func testChatModeAccessibilityMetadata() {
        XCTAssertEqual(OmniboxChatMode.standard.accessibilityLabel, String.localized(.chatModeStandard))
        XCTAssertEqual(OmniboxChatMode.standard.accessibilityIdentifier, "OmniboxChatModeStandardOption")
        XCTAssertEqual(OmniboxChatMode.thinkLonger.accessibilityIdentifier, "OmniboxChatModeThinkLongerOption")
        XCTAssertEqual(OmniboxChatMode.displaySources.accessibilityIdentifier, "OmniboxChatModeDisplaySourcesOption")
        XCTAssertEqual(OmniboxChatMode.learning.accessibilityIdentifier, "OmniboxChatModeLearningOption")
    }

    func testChatModeIconsLoadFromFrameworkBundle() {
        XCTAssertNotNil(UIImage.ecosia(named: "chatmodes-standard-ai-chat"))
        XCTAssertNotNil(UIImage.ecosia(named: "chatmodes-think-longer"))
        XCTAssertNotNil(UIImage.ecosia(named: "chatmodes-display-sources"))
        XCTAssertNotNil(UIImage.ecosia(named: "chatmodes-learning"))
    }

    func testChatModeAIChatQueryItemsMapToBackendFlags() {
        XCTAssertTrue(OmniboxChatMode.standard.aiChatQueryItems.isEmpty)
        XCTAssertEqual(OmniboxChatMode.thinkLonger.aiChatQueryItems,
                       [URLQueryItem(name: "t", value: "1")])
        XCTAssertEqual(OmniboxChatMode.displaySources.aiChatQueryItems,
                       [URLQueryItem(name: "m", value: "2")])
        XCTAssertEqual(OmniboxChatMode.learning.aiChatQueryItems,
                       [URLQueryItem(name: "m", value: "1")])
    }

    func testAIChatURLCarriesChatModeQueryItems() {
        let provider = URLProvider.production

        let standardURL = provider.aiChat(origin: .omnibox,
                                          query: "hello",
                                          additionalQueryItems: OmniboxChatMode.standard.aiChatQueryItems)
        let standardItems = URLComponents(url: standardURL, resolvingAgainstBaseURL: false)?.queryItems ?? []
        XCTAssertTrue(standardURL.path.hasSuffix("/ai-chat"))
        XCTAssertFalse(standardItems.contains { $0.name == "t" || $0.name == "m" })

        let learningURL = provider.aiChat(origin: .omnibox,
                                          query: "hello",
                                          additionalQueryItems: OmniboxChatMode.learning.aiChatQueryItems)
        let learningItems = URLComponents(url: learningURL, resolvingAgainstBaseURL: false)?.queryItems ?? []
        XCTAssertTrue(learningItems.contains(URLQueryItem(name: "m", value: "1")))
        XCTAssertTrue(learningItems.contains(URLQueryItem(name: "q", value: "hello")))
    }
}

@MainActor
final class NTPOmniboxSheetStateTests: XCTestCase {

    func testSelectedOptionIsDeliveredAfterDrawerDismisses() {
        let state = NTPOmniboxSheetState()
        var received: OmniboxUploadOption?
        state.presentUploadDrawer(onSelectUpload: { received = $0 }, onChatModeSelectionChanged: { _ in })

        state.handleUploadOptionSelected(.files)
        XCTAssertFalse(state.showUploadDrawer)
        XCTAssertNil(received)

        state.handleUploadDrawerDismissed()
        XCTAssertEqual(received, .files)
    }

    func testSelectedChatModeAppliesImmediatelyOnTap() {
        let state = NTPOmniboxSheetState()
        var changes: [OmniboxChatMode?] = []
        var receivedUpload: OmniboxUploadOption?
        state.presentUploadDrawer(onSelectUpload: { receivedUpload = $0 },
                                  onChatModeSelectionChanged: { changes.append($0) })

        state.handleChatModeSelected(.thinkLonger)
        // Delivered on tap — not deferred until the sheet dismisses.
        XCTAssertEqual(state.selectedChatMode, .thinkLonger)
        XCTAssertEqual(changes, [.thinkLonger])
        XCTAssertFalse(state.showUploadDrawer)
        XCTAssertNil(receivedUpload)
    }

    func testSelectingChatModeReplacesThePreviousOne() {
        let state = NTPOmniboxSheetState()
        state.presentUploadDrawer(onSelectUpload: { _ in }, onChatModeSelectionChanged: { _ in })

        state.handleChatModeSelected(.thinkLonger)
        state.handleChatModeSelected(.learning)
        XCTAssertEqual(state.selectedChatMode, .learning)
    }

    func testReTappingActiveChatModeInDrawerKeepsItSelected() {
        // Deselection happens via the omnibox chip, not the drawer — re-picking
        // the active mode just closes the drawer with the mode still active.
        let state = NTPOmniboxSheetState()
        var changes: [OmniboxChatMode?] = []
        state.presentUploadDrawer(onSelectUpload: { _ in },
                                  onChatModeSelectionChanged: { changes.append($0) })

        state.handleChatModeSelected(.learning)
        state.handleChatModeSelected(.learning)
        XCTAssertEqual(state.selectedChatMode, .learning)
        XCTAssertEqual(changes, [.learning, .learning])
    }

    func testDismissWithoutSelectionDoesNotDeliverOption() {
        let state = NTPOmniboxSheetState()
        var received: OmniboxUploadOption?
        state.presentUploadDrawer(onSelectUpload: { received = $0 },
                                  onChatModeSelectionChanged: { _ in })

        state.handleUploadDrawerDismissed()
        XCTAssertNil(received)
        XCTAssertNil(state.selectedChatMode)
    }
}

@MainActor
final class NTPSearchBarUploadDelegateTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Self.enableFileUploadFlag(true)
    }

    override func tearDown() {
        Unleash.clearInstanceModel()
        super.tearDown()
    }

    private static func enableFileUploadFlag(_ enabled: Bool) {
        let toggle = Unleash.Toggle(
            name: Unleash.Toggle.Name.fileUpload.rawValue,
            enabled: enabled,
            variant: Unleash.Variant(name: "", enabled: false, payload: nil)
        )
        Unleash.model = Unleash.Model(toggles: Set([toggle]))
    }

    private final class UploadDelegateSpy: NTPSearchBarDelegate {
        var didTapUpload = false

        func ntpSearchBarDidSubmit(_ searchTerm: String) {}
        func ntpSearchBarTextDidChange(_ searchTerm: String) {}
        func ntpSearchBarNeedsSearchReset() {}
        func ntpSearchBarDidBeginEditing() {}
        func ntpSearchBarDidCancel() {}
        func ntpSearchBarRequestsOverlayDismiss() {}
        func ntpSearchBarDidTapUpload() {
            didTapUpload = true
        }
    }

    func testUploadButtonTapNotifiesDelegate() throws {
        let bar = NTPSearchBarView(frame: CGRect(x: 0, y: 0, width: 320, height: 110))
        let spy = UploadDelegateSpy()
        bar.delegate = spy

        let uploadButton = bar.subviews.compactMap { $0 as? EcosiaOmniboxUploadButton }.first
        let button = try XCTUnwrap(uploadButton)
        button.sendActions(for: .touchUpInside)

        XCTAssertTrue(spy.didTapUpload)
    }

    func testUploadButtonHiddenWhenFileUploadFlagDisabled() throws {
        Self.enableFileUploadFlag(false)
        let bar = NTPSearchBarView(frame: CGRect(x: 0, y: 0, width: 320, height: 110))

        let uploadButton = bar.subviews.compactMap { $0 as? EcosiaOmniboxUploadButton }.first
        let button = try XCTUnwrap(uploadButton)
        XCTAssertTrue(button.isHidden)
    }
}
