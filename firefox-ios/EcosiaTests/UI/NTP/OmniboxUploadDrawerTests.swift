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
}

@MainActor
final class NTPSearchBarUploadDelegateTests: XCTestCase {

    override func setUp() {
        super.setUp()
        enableFileUploadFlag(true)
    }

    override func tearDown() {
        Unleash.clearInstanceModel()
        super.tearDown()
    }

    private func enableFileUploadFlag(_ enabled: Bool) {
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
        enableFileUploadFlag(false)
        let bar = NTPSearchBarView(frame: CGRect(x: 0, y: 0, width: 320, height: 110))

        let uploadButton = bar.subviews.compactMap { $0 as? EcosiaOmniboxUploadButton }.first
        let button = try XCTUnwrap(uploadButton)
        XCTAssertTrue(button.isHidden)
    }
}
