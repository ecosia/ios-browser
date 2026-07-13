// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UniformTypeIdentifiers

struct OmniboxUploadFileSelectionResult {
    let acceptedURLs: [URL]
    let validationErrors: Set<OmniboxUploadValidationError>
}

enum OmniboxUploadFileSelectionValidator {
    static let maxFileCount = 5
    static let blockedExtensions: Set<String> = ["app", "exe"]
    static let imageExtensions: Set<String> = ["jpg", "jpeg", "png"]
    private static let documentExtensions: Set<String> = ["pdf", "txt", "doc"]
    private static let supportedExtensions = documentExtensions.union(imageExtensions)

    static var pickerContentTypes: [UTType] {
        [
            .pdf,
            .plainText,
            .jpeg,
            .png,
            UTType(filenameExtension: "doc"),
            UTType(filenameExtension: "txt"),
            UTType(filenameExtension: "jpg")
        ].compactMap { $0 }
    }

    static func allowedURLs(from urls: [URL]) -> [URL] {
        validate(urls: urls, existingAttachmentCount: 0).acceptedURLs
    }

    static func validate(urls: [URL], existingAttachmentCount: Int) -> OmniboxUploadFileSelectionResult {
        var validationErrors = Set<OmniboxUploadValidationError>()
        let remainingSlots = max(0, maxFileCount - existingAttachmentCount)

        guard !urls.isEmpty else {
            return OmniboxUploadFileSelectionResult(acceptedURLs: [], validationErrors: validationErrors)
        }

        if remainingSlots == 0 {
            validationErrors.insert(.tooManyFiles)
            return OmniboxUploadFileSelectionResult(acceptedURLs: [], validationErrors: validationErrors)
        }

        var acceptedURLs: [URL] = []
        var unsupportedFound = false
        var oversizedFound = false
        var validURLCount = 0

        for url in urls {
            guard isAllowed(url) else {
                unsupportedFound = true
                continue
            }

            if isOversized(url) {
                oversizedFound = true
                continue
            }

            validURLCount += 1
            if acceptedURLs.count < remainingSlots {
                acceptedURLs.append(url)
            }
        }

        if unsupportedFound {
            validationErrors.insert(.unsupportedFileType)
        }
        if oversizedFound {
            validationErrors.insert(.fileTooLarge)
        }
        if validURLCount > remainingSlots {
            validationErrors.insert(.tooManyFiles)
        }

        return OmniboxUploadFileSelectionResult(
            acceptedURLs: acceptedURLs,
            validationErrors: validationErrors
        )
    }

    static func validateSelectionCount(selectedCount: Int, existingAttachmentCount: Int) -> Set<OmniboxUploadValidationError> {
        let remainingSlots = max(0, maxFileCount - existingAttachmentCount)
        guard selectedCount > remainingSlots else { return [] }
        return [.tooManyFiles]
    }

    static func isAllowed(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        guard !ext.isEmpty else { return false }
        if blockedExtensions.contains(ext) { return false }
        return supportedExtensions.contains(ext)
    }

    private static func isOversized(_ url: URL) -> Bool {
        guard let fileSize = fileSize(for: url) else { return false }
        return fileSize > OmniboxUploadPayloadLoader.maxFileSizeBytes
    }

    private static func fileSize(for url: URL) -> Int? {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }
        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        return values?.fileSize
    }
}
