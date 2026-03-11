// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class WallpaperCodableTests: XCTestCase {

    // MARK: - Encoding Tests

    func testEncodeWallpaperWithBundledAsset() throws {
        let wallpaper = Wallpaper(
            id: "test-wallpaper",
            textColor: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
            cardColor: UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0),
            logoTextColor: UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0),
            bundledAssetName: "testAsset"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(wallpaper)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(json)
        XCTAssertEqual(json?["id"] as? String, "test-wallpaper")
        XCTAssertEqual(json?["bundled-asset-name"] as? String, "testAsset")
        XCTAssertNotNil(json?["text-color"])
        XCTAssertNotNil(json?["card-color"])
        XCTAssertNotNil(json?["logo-text-color"])
    }

    func testEncodeWallpaperWithoutBundledAsset() throws {
        let wallpaper = Wallpaper(
            id: "test-wallpaper",
            textColor: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
            cardColor: UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0),
            logoTextColor: UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0),
            bundledAssetName: nil
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(wallpaper)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(json)
        XCTAssertEqual(json?["id"] as? String, "test-wallpaper")
        XCTAssertNil(json?["bundled-asset-name"])  // Should not be present when nil
    }

    // MARK: - Decoding Tests

    func testDecodeWallpaperWithBundledAsset() throws {
        let jsonString = """
        {
            "id": "ecosia-default",
            "text-color": "FFFFFF",
            "card-color": "1A4D2E",
            "logo-text-color": "E8F5E9",
            "bundled-asset-name": "ntpBackground"
        }
        """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let wallpaper = try decoder.decode(Wallpaper.self, from: data)

        XCTAssertEqual(wallpaper.id, "ecosia-default")
        XCTAssertEqual(wallpaper.bundledAssetName, "ntpBackground")
        XCTAssertNotNil(wallpaper.textColor)
        XCTAssertNotNil(wallpaper.cardColor)
        XCTAssertNotNil(wallpaper.logoTextColor)
    }

    func testDecodeWallpaperWithoutBundledAsset() throws {
        let jsonString = """
        {
            "id": "beachVibes",
            "text-color": "ADD8E6",
            "card-color": "ADD8E6",
            "logo-text-color": "ADD8E6"
        }
        """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let wallpaper = try decoder.decode(Wallpaper.self, from: data)

        XCTAssertEqual(wallpaper.id, "beachVibes")
        XCTAssertNil(wallpaper.bundledAssetName)  // Should be nil when not present
        XCTAssertNotNil(wallpaper.textColor)
        XCTAssertNotNil(wallpaper.cardColor)
        XCTAssertNotNil(wallpaper.logoTextColor)
    }

    // MARK: - Round-trip Tests

    func testRoundTripEncodingDecodingWithBundledAsset() throws {
        let original = Wallpaper(
            id: "ecosia-forest",
            textColor: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
            cardColor: UIColor(red: 0.1, green: 0.3, blue: 0.18, alpha: 1.0),
            logoTextColor: UIColor(red: 0.91, green: 0.96, blue: 0.91, alpha: 1.0),
            bundledAssetName: "forestBackground"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Wallpaper.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.bundledAssetName, original.bundledAssetName)
        XCTAssertEqual(decoded, original)
    }

    func testRoundTripEncodingDecodingWithoutBundledAsset() throws {
        let original = Wallpaper(
            id: "beach-vibes",
            textColor: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
            cardColor: UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0),
            logoTextColor: UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0),
            bundledAssetName: nil
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Wallpaper.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertNil(decoded.bundledAssetName)
        XCTAssertEqual(decoded, original)
    }

    // MARK: - Ecosia Default Tests

    func testEcosiaDefaultWallpaperHasBundledAsset() {
        let ecosiaDefault = Wallpaper.ecosiaDefault

        XCTAssertEqual(ecosiaDefault.id, "ecosia-default")
        XCTAssertEqual(ecosiaDefault.bundledAssetName, "ntpBackground")
        XCTAssertNotNil(ecosiaDefault.textColor)
        XCTAssertNotNil(ecosiaDefault.cardColor)
        XCTAssertNotNil(ecosiaDefault.logoTextColor)
        XCTAssertTrue(ecosiaDefault.hasImage)
    }

    func testBaseWallpaperHasNoBundledAsset() {
        let baseWallpaper = Wallpaper.baseWallpaper

        XCTAssertEqual(baseWallpaper.id, "fxDefault")
        XCTAssertNil(baseWallpaper.bundledAssetName)
        XCTAssertFalse(baseWallpaper.hasImage)
    }

    func testEcosiaDefaultRoundTrip() throws {
        let ecosiaDefault = Wallpaper.ecosiaDefault

        let encoder = JSONEncoder()
        let data = try encoder.encode(ecosiaDefault)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Wallpaper.self, from: data)

        XCTAssertEqual(decoded.id, ecosiaDefault.id)
        XCTAssertEqual(decoded.bundledAssetName, "ntpBackground")
        XCTAssertEqual(decoded, ecosiaDefault)
    }
}
