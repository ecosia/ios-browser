// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum OmniboxUploadDebugSimulation {
    static func simulatedValidationErrors() -> Set<OmniboxUploadValidationError> {
        var errors = Set<OmniboxUploadValidationError>()
        if SimulateUploadValidationErrorSetting.isEnabled(for: .tooManyFiles) {
            errors.insert(.tooManyFiles)
        }
        if SimulateUploadValidationErrorSetting.isEnabled(for: .fileTooLarge) {
            errors.insert(.fileTooLarge)
        }
        if SimulateUploadValidationErrorSetting.isEnabled(for: .unsupportedFileType) {
            errors.insert(.unsupportedFileType)
        }
        return errors
    }

    static var shouldSimulateUploadAPIFailure: Bool {
        SimulateFileUploadAPIErrorSetting.isEnabled
    }
}
