// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Common
import XCTest

/// MOB-5282: settings values (search region, safe search, …) were drawn in caption1 (12pt)
/// on 159.x. Only switch rows' subtitles use caption1.
@MainActor
final class SettingsDetailFontTests: XCTestCase {
    private let caption1 = FXFontStyles.Regular.caption1.scaledFont()

    func testValueCell_detailText_isNotCaption1() throws {
        let cell = ThemedTableViewCell(style: .value1, reuseIdentifier: nil)
        let font = try XCTUnwrap(cell.detailTextLabel?.font)

        XCTAssertGreaterThan(font.pointSize, caption1.pointSize)
    }

    func testValueCell_afterReuse_detailTextIsNotCaption1() throws {
        let cell = ThemedTableViewCell(style: .value1, reuseIdentifier: nil)
        cell.prepareForReuse()
        let font = try XCTUnwrap(cell.detailTextLabel?.font)

        XCTAssertGreaterThan(font.pointSize, caption1.pointSize)
    }

    func testSwitchCell_subtitle_isCaption1() throws {
        let cell = ThemedSwitchTableViewCell(style: .subtitle, reuseIdentifier: nil)
        let font = try XCTUnwrap(cell.detailTextLabel?.font)

        XCTAssertEqual(font.pointSize, caption1.pointSize)
    }
}
