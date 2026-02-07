// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class AppIconManagerTests: XCTestCase {

    override func setUp() {
        try? FileManager.default.removeItem(at: FileManager.user)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: FileManager.user)
    }

    // MARK: - AppIcon enum tests

    func testDefaultIconRawValue() {
        XCTAssertEqual(AppIcon.default.rawValue, "AppIcon")
    }

    func testGreenIconRawValue() {
        XCTAssertEqual(AppIcon.green.rawValue, "AppIconGreen")
    }

    func testBlackIconRawValue() {
        XCTAssertEqual(AppIcon.black.rawValue, "AppIconBlack")
    }

    func testDefaultIconAlternateNameIsNil() {
        XCTAssertNil(AppIcon.default.alternateIconName)
    }

    func testGreenIconAlternateName() {
        XCTAssertEqual(AppIcon.green.alternateIconName, "AppIconGreen")
    }

    func testBlackIconAlternateName() {
        XCTAssertEqual(AppIcon.black.alternateIconName, "AppIconBlack")
    }

    func testAllCasesCount() {
        XCTAssertEqual(AppIcon.allCases.count, 3)
    }

    func testCurrentReturnsDefaultForNilName() {
        let icon = AppIcon.current(alternateIconName: nil)
        XCTAssertEqual(icon, .default)
    }

    func testCurrentReturnsGreenForMatchingName() {
        let icon = AppIcon.current(alternateIconName: "AppIconGreen")
        XCTAssertEqual(icon, .green)
    }

    func testCurrentReturnsBlackForMatchingName() {
        let icon = AppIcon.current(alternateIconName: "AppIconBlack")
        XCTAssertEqual(icon, .black)
    }

    func testCurrentReturnsDefaultForUnknownName() {
        let icon = AppIcon.current(alternateIconName: "UnknownIcon")
        XCTAssertEqual(icon, .default)
    }

    func testPreviewImageName() {
        XCTAssertEqual(AppIcon.default.previewImageName, "AppIconPreview")
        XCTAssertEqual(AppIcon.green.previewImageName, "AppIconGreenPreview")
        XCTAssertEqual(AppIcon.black.previewImageName, "AppIconBlackPreview")
    }

    func testLocalizedTitleKeys() {
        XCTAssertEqual(AppIcon.default.localizedTitleKey, .appIconDefault)
        XCTAssertEqual(AppIcon.green.localizedTitleKey, .appIconGreen)
        XCTAssertEqual(AppIcon.black.localizedTitleKey, .appIconBlack)
    }

    // MARK: - AppIcon Codable tests

    func testAppIconEncodingDecoding() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for icon in AppIcon.allCases {
            let data = try encoder.encode(icon)
            let decoded = try decoder.decode(AppIcon.self, from: data)
            XCTAssertEqual(icon, decoded)
        }
    }

    func testAppIconDecodingUnknownFallback() {
        let data = "\"UnknownValue\"".data(using: .utf8)!
        let decoded = try? JSONDecoder().decode(AppIcon.self, from: data)
        XCTAssertNil(decoded, "Decoding an unknown raw value should fail")
    }

    // MARK: - User persistence tests

    func testUserAppIconDefaultValue() {
        let user = User()
        XCTAssertEqual(user.appIcon, .default)
    }

    func testUserAppIconPersistence() {
        let expect = expectation(description: "appIcon persists")
        User.shared.appIcon = .green
        User.queue.async {
            let user = User()
            XCTAssertEqual(user.appIcon, .green)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testUserAppIconPersistenceBlack() {
        let expect = expectation(description: "appIcon persists black")
        User.shared.appIcon = .black
        User.queue.async {
            let user = User()
            XCTAssertEqual(user.appIcon, .black)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    // MARK: - AppIconManager tests

    func testManagerWithNilApplicationDoesNotSupportAlternateIcons() {
        let manager = AppIconManager(application: nil)
        XCTAssertFalse(manager.supportsAlternateIcons)
    }

    func testManagerCurrentIconDefaultsToDefault() {
        let manager = AppIconManager(application: nil)
        XCTAssertEqual(manager.currentIcon, .default)
    }
}
