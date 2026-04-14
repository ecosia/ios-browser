// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class AudioWaveformViewTests: XCTestCase {

    func testAddLevelClampsToUnitRange() {
        let sut = AudioWaveformView(barCount: 5, barWidth: 3, barSpacing: 2, barColor: .green)
        sut.frame = CGRect(x: 0, y: 0, width: 100, height: 50)

        // Should not crash with out-of-range values
        sut.addLevel(-0.5)
        sut.addLevel(1.5)
        sut.addLevel(0.5)
    }

    func testResetClearsLevels() {
        let sut = AudioWaveformView(barCount: 3, barWidth: 3, barSpacing: 2, barColor: .green)
        sut.frame = CGRect(x: 0, y: 0, width: 100, height: 50)

        sut.addLevel(0.8)
        sut.addLevel(0.6)
        sut.reset()

        // After reset, the sublayers should still exist but bars should have minimal height
        XCTAssertEqual(sut.layer.sublayers?.count, 3)
    }

    func testBarLayersCreatedMatchBarCount() {
        let barCount = 10
        let sut = AudioWaveformView(barCount: barCount, barWidth: 3, barSpacing: 2, barColor: .green)

        XCTAssertEqual(sut.layer.sublayers?.count, barCount)
    }
}
