// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Client
@testable import Ecosia

@MainActor
final class OmniboxUploadDrawerTests: XCTestCase {

    private final class DrawerDelegateSpy: OmniboxUploadDrawerDelegate {
        var selectedOption: OmniboxUploadOption?
        var selectedSourceView: UIView?
        var didDismiss = false

        func omniboxUploadDrawer(_ drawer: OmniboxUploadDrawerViewController,
                                 didSelect option: OmniboxUploadOption,
                                 sourceView: UIView) {
            selectedOption = option
            selectedSourceView = sourceView
        }

        func omniboxUploadDrawerDidDismiss(_ drawer: OmniboxUploadDrawerViewController) {
            didDismiss = true
        }
    }

    func testDrawerContentExposesThreeOptions() {
        let content = OmniboxUploadDrawerContentView(frame: CGRect(x: 0, y: 0, width: 320, height: 180))

        XCTAssertEqual(content.optionViews.count, 3)
        XCTAssertEqual(Set(content.optionViews.map(\.option)), Set(OmniboxUploadOption.allCases))
    }

    func testOptionViewsHaveAccessibilityMetadata() {
        let photos = OmniboxUploadOptionView(option: .photos)
        let camera = OmniboxUploadOptionView(option: .camera)
        let files = OmniboxUploadOptionView(option: .files)

        XCTAssertEqual(photos.accessibilityLabel, String.localized(.photos))
        XCTAssertEqual(photos.accessibilityHint, String.localized(.uploadPhotosAccessibilityHint))
        XCTAssertEqual(photos.accessibilityIdentifier, "OmniboxUploadPhotosOption")

        XCTAssertEqual(camera.accessibilityLabel, String.localized(.camera))
        XCTAssertEqual(camera.accessibilityHint, String.localized(.uploadCameraAccessibilityHint))
        XCTAssertEqual(camera.accessibilityIdentifier, "OmniboxUploadCameraOption")

        XCTAssertEqual(files.accessibilityLabel, String.localized(.files))
        XCTAssertEqual(files.accessibilityHint, String.localized(.uploadFilesAccessibilityHint))
        XCTAssertEqual(files.accessibilityIdentifier, "OmniboxUploadFilesOption")
    }

    func testSelectingOptionNotifiesDelegateWithSourceView() throws {
        let drawer = OmniboxUploadDrawerViewController(windowUUID: .XCTestDefaultUUID)
        let spy = DrawerDelegateSpy()
        drawer.delegate = spy

        _ = drawer.view
        let content = drawer.contentViewForTesting
        let photosView = try XCTUnwrap(content.optionViews.first { $0.option == .photos })

        photosView.sendActions(for: .touchUpInside)

        XCTAssertEqual(spy.selectedOption, .photos)
        XCTAssertIdentical(spy.selectedSourceView, photosView)
    }

    func testUploadDrawerIconsLoadFromFrameworkBundle() {
        XCTAssertNotNil(UIImage.ecosia(named: "upload-photos"))
        XCTAssertNotNil(UIImage.ecosia(named: "upload-camera"))
        XCTAssertNotNil(UIImage.ecosia(named: "upload-files"))
    }
}

@MainActor
final class NTPSearchBarUploadDelegateTests: XCTestCase {

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
}
