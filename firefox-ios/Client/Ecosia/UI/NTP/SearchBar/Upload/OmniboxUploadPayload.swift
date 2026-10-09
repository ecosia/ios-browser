// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import UniformTypeIdentifiers
import Ecosia

/// Local payload produced by a picker after the user selects content.
struct OmniboxUploadLocalPayload {
    let fileName: String
    let mimeType: String
    let data: Data
    let layout: OmniboxAttachment.Layout
    let previewImage: UIImage?
}

/// Deferred load closure used while the system picker hands back a selection.
struct OmniboxUploadPendingItem: Sendable {
    let fileName: String
    let layout: OmniboxAttachment.Layout
    let load: @Sendable () async throws -> OmniboxUploadLocalPayload

    init(
        fileName: String,
        layout: OmniboxAttachment.Layout,
        load: @escaping @Sendable () async throws -> OmniboxUploadLocalPayload
    ) {
        self.fileName = fileName
        self.layout = layout
        self.load = load
    }

    func loadPayload() async throws -> OmniboxUploadLocalPayload {
        let load = load
        return try await Task.detached(priority: .userInitiated) {
            try await load()
        }.value
    }
}

enum OmniboxUploadSecurityScopedAccess {
    static func withAccess<T>(to url: URL, _ work: () throws -> T) rethrows -> T {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }
        return try work()
    }

    static func fileSize(for url: URL) -> Int? {
        withAccess(to: url) {
            let values = try? url.resourceValues(forKeys: [.fileSizeKey])
            return values?.fileSize
        }
    }
}

enum OmniboxUploadPayloadLoader {

    static let maxFileSizeBytes = 5 * 1024 * 1024

    static func loadFile(from url: URL) async throws -> OmniboxUploadLocalPayload {
        // Run blocking file IO off the calling actor
        let (data, mimeType) = try await Task.detached(priority: .userInitiated) { () throws -> (Data, String) in
            try validateFileSize(at: url)
            let data = try OmniboxUploadSecurityScopedAccess.withAccess(to: url) {
                try Data(contentsOf: url)
            }
            try validateSize(data)
            let mimeType = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
            return (data, mimeType)
        }.value
        let layout: OmniboxAttachment.Layout = mimeType.hasPrefix("image/") ? .image : .file
        let previewImage = layout == .image ? UIImage(data: data) : nil
        return OmniboxUploadLocalPayload(
            fileName: fileNameWithExtension(url.lastPathComponent, mimeType: mimeType),
            mimeType: mimeType,
            data: data,
            layout: layout,
            previewImage: previewImage
        )
    }

    /// Replaces the extension with `.jpg` when image bytes are JPEG-encoded under a HEIC/HEIF name.
    static func normalizedJPEGFileName(from fileName: String, fallback: String = "photo.jpg") -> String {
        let stem = (fileName as NSString).deletingPathExtension
        guard !stem.isEmpty else { return fallback }
        return "\(stem).jpg"
    }

    /// Unique JPEG name for camera/photo fallbacks so concurrent picks do not collide on the backend.
    static func uniqueJPEGFileName(prefix: String) -> String {
        "\(prefix)-\(UUID().uuidString.prefix(8)).jpg"
    }

    static func loadImage(data: Data, fileName: String, mimeType: String) throws -> OmniboxUploadLocalPayload {
        try validateSize(data)
        return OmniboxUploadLocalPayload(
            fileName: fileNameWithExtension(fileName, mimeType: mimeType),
            mimeType: mimeType,
            data: data,
            layout: .image,
            previewImage: UIImage(data: data)
        )
    }

    /// PHPicker `suggestedName` often omits an extension (`IMG_1234`). Append one
    /// derived from the MIME type so analytics `file_type` and UI labels stay useful.
    static func fileNameWithExtension(_ fileName: String, mimeType: String) -> String {
        let nsName = fileName as NSString
        guard nsName.pathExtension.isEmpty else { return fileName }
        let stem = fileName.isEmpty ? "file" : fileName
        let ext = preferredExtension(forMimeType: mimeType) ?? "bin"
        return "\(stem).\(ext)"
    }

    private static func preferredExtension(forMimeType mimeType: String) -> String? {
        if let ext = UTType(mimeType: mimeType)?.preferredFilenameExtension {
            return ext == "jpeg" ? "jpg" : ext
        }
        return Analytics.fileUploadFileType(fromMimeType: mimeType)
    }

    static func validateSize(_ data: Data) throws {
        guard data.count <= maxFileSizeBytes else {
            throw OmniboxUploadPayloadError.fileTooLarge
        }
    }

    static func validateFileSize(at url: URL) throws {
        if let fileSize = OmniboxUploadSecurityScopedAccess.fileSize(for: url),
           fileSize > maxFileSizeBytes {
            throw OmniboxUploadPayloadError.fileTooLarge
        }
    }
}

enum OmniboxUploadPayloadError: Error, Equatable {
    case fileTooLarge
    case unreadable
}
