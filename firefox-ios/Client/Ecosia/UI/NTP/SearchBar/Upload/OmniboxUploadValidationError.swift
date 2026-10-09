// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Ecosia

enum OmniboxUploadValidationError: Hashable, CaseIterable {
    case tooManyFiles
    case fileTooLarge
    case unsupportedFileType
    case uploadFailed

    var localizedMessage: String {
        switch self {
        case .tooManyFiles:
            return String.localized(.uploadErrorTooManyFiles)
        case .fileTooLarge:
            return String.localized(.uploadErrorFileTooLarge)
        case .unsupportedFileType:
            return String.localized(.uploadErrorUnsupportedFileType)
        case .uploadFailed:
            return String.localized(.uploadErrorGeneric)
        }
    }

    static func orderedMessages(for errors: Set<OmniboxUploadValidationError>) -> [String] {
        allCases
            .filter { errors.contains($0) }
            .map(\.localizedMessage)
    }
}
