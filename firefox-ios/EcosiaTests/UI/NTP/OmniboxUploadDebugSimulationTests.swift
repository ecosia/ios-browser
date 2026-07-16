// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class OmniboxUploadDebugSimulationTests: XCTestCase {

    override func tearDown() {
        for error in OmniboxUploadValidationError.allCases where error != .uploadFailed {
            UserDefaults.standard.removeObject(forKey: SimulateUploadValidationErrorSetting.debugKey(for: error))
        }
        UserDefaults.standard.removeObject(forKey: SimulateFileUploadAPIErrorSetting.debugKey)
        super.tearDown()
    }

    func testSimulatedValidationErrorsReflectEnabledToggles() {
        UserDefaults.standard.set(true, forKey: SimulateUploadValidationErrorSetting.debugKey(for: .fileTooLarge))
        UserDefaults.standard.set(true, forKey: SimulateUploadValidationErrorSetting.debugKey(for: .unsupportedFileType))

        XCTAssertEqual(
            OmniboxUploadDebugSimulation.simulatedValidationErrors(),
            [.fileTooLarge, .unsupportedFileType]
        )
    }

    func testSimulatedValidationErrorsIncludeUploadAPIFailureWhenEnabled() {
        UserDefaults.standard.set(true, forKey: SimulateUploadValidationErrorSetting.debugKey(for: .tooManyFiles))
        UserDefaults.standard.set(true, forKey: SimulateFileUploadAPIErrorSetting.debugKey)

        XCTAssertEqual(
            OmniboxUploadDebugSimulation.simulatedValidationErrors(),
            [.tooManyFiles, .uploadFailed]
        )
    }

    func testUploadAPIFailureToggle() {
        XCTAssertFalse(OmniboxUploadDebugSimulation.shouldSimulateUploadAPIFailure)

        UserDefaults.standard.set(true, forKey: SimulateFileUploadAPIErrorSetting.debugKey)
        XCTAssertTrue(OmniboxUploadDebugSimulation.shouldSimulateUploadAPIFailure)
    }
}
