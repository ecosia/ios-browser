// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
@testable import Ecosia

import Common
import XCTest

@MainActor
final class NTPImpactCellTitleTests: XCTestCase {
    private typealias UX = NTPImpactCell.UX

    func testTitleReservedHeight_portrait_fitsThreeLinesOfTheTitleFont() {
        XCTAssertGreaterThanOrEqual(UX.titleReservedHeight, UX.titleFont.lineHeight * 3)
    }

    func testTitleReservedHeight_landscape_fitsTwoLinesOfTheTitleFont() {
        XCTAssertGreaterThanOrEqual(UX.titleReservedHeightLandscape, UX.titleFont.lineHeight * 2)
    }

    func testTitleLabel_portrait_isLimitedToThreeLinesAndCanShrink() throws {
        let cell = NTPImpactCell(frame: CGRect(x: 0, y: 0, width: 375, height: 400))
        cell.configure(items: [],
                       title: "Wir sind dem Planeten verpflichtet, nicht Investoren",
                       delegate: nil,
                       theme: LightTheme())

        let label = try XCTUnwrap(titleLabel(in: cell))

        XCTAssertEqual(label.numberOfLines, UX.titleMaxLines)
        XCTAssertEqual(label.lineBreakMode, .byTruncatingTail)
        XCTAssertTrue(label.adjustsFontSizeToFitWidth)
        XCTAssertLessThan(label.minimumScaleFactor, 1)
    }

    func testTitleLabel_longGermanTitle_fitsTheReservedHeightOnASmallPhone() throws {
        let cell = NTPImpactCell(frame: CGRect(x: 0, y: 0, width: 375, height: 400))
        cell.configure(items: [],
                       title: "Wir sind dem Planeten verpflichtet, nicht Investoren",
                       delegate: nil,
                       theme: LightTheme())
        cell.setNeedsLayout()
        cell.layoutIfNeeded()

        let label = try XCTUnwrap(titleLabel(in: cell))

        XCTAssertLessThanOrEqual(label.frame.height, UX.titleReservedHeight)
        XCTAssertGreaterThanOrEqual(label.frame.minY, 0)
    }

    // MARK: - Helpers

    private func titleLabel(in view: UIView) -> UILabel? {
        if let label = view as? UILabel,
           label.accessibilityIdentifier == EcosiaAccessibilityIdentifiers.NTP.rotatingTitle {
            return label
        }
        for subview in view.subviews {
            if let label = titleLabel(in: subview) { return label }
        }
        return nil
    }
}
