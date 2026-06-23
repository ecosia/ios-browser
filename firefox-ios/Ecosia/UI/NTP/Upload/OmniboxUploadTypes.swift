// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public enum OmniboxUploadOption: CaseIterable, Hashable {
    case photos
    case camera
    case files
}

/// Placeholder model for selected upload items. Upload handling is wired in a follow-up.
public struct OmniboxUploadItem: Equatable {
    public enum Source {
        case photos
        case camera
        case files
    }

    public let source: Source
    public let fileName: String
    public let contentTypeIdentifier: String?

    public init(source: Source, fileName: String, contentTypeIdentifier: String?) {
        self.source = source
        self.fileName = fileName
        self.contentTypeIdentifier = contentTypeIdentifier
    }
}

public extension OmniboxUploadOption {
    var iconName: String {
        switch self {
        case .photos: return "upload-photos"
        case .camera: return "upload-camera"
        case .files: return "upload-files"
        }
    }

    var title: String {
        switch self {
        case .photos: return String.localized(.photos)
        case .camera: return String.localized(.camera)
        case .files: return String.localized(.files)
        }
    }

    var accessibilityLabel: String { title }

    var accessibilityHint: String {
        switch self {
        case .photos: return String.localized(.uploadPhotosAccessibilityHint)
        case .camera: return String.localized(.uploadCameraAccessibilityHint)
        case .files: return String.localized(.uploadFilesAccessibilityHint)
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .photos: return "OmniboxUploadPhotosOption"
        case .camera: return "OmniboxUploadCameraOption"
        case .files: return "OmniboxUploadFilesOption"
        }
    }
}
