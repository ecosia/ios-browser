// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

/// Regression test: `MOZ_WALLPAPER_ASSET_URL=https://cdn.ecosia.org/...` was silently truncated
/// to `https:` because Xcode's xcconfig parser treats an unescaped `//` as the start of a line
/// comment, even mid-value. `WallpaperURLProvider` can't catch this at runtime — it bypasses the
/// real bundle lookup entirely under `AppConstants.isRunningTest` — so this reads the xcconfig
/// file itself, the only place the bug is observable.
final class BuildSettingsConfigurationTests: XCTestCase {
    func testWallpaperAssetURLDoesNotContainAnUnescapedDoubleSlash() throws {
        let configPath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // Core
            .deletingLastPathComponent() // EcosiaTests
            .deletingLastPathComponent() // firefox-ios
            .appendingPathComponent("Client/Ecosia/BuildSettingsConfigurations/EcosiaCommon.xcconfig")

        let contents = try String(contentsOf: configPath, encoding: .utf8)
        guard let line = contents.components(separatedBy: .newlines)
            .first(where: { $0.hasPrefix("MOZ_WALLPAPER_ASSET_URL") }) else {
            XCTFail("MOZ_WALLPAPER_ASSET_URL is no longer defined in \(configPath.lastPathComponent)")
            return
        }

        let value = line.split(separator: "=", maxSplits: 1)[1].trimmingCharacters(in: .whitespaces)

        XCTAssertFalse(
            value.contains("//"),
            """
            "\(line)" contains an unescaped "//". Xcode's xcconfig parser treats that as a comment \
            start and silently truncates the value. Split the slashes with an empty macro instead, \
            e.g. https:/$()/host/path.
            """
        )
    }
}
