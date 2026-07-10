// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UniformTypeIdentifiers

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
        Array(urls.filter(isAllowed(_:)).prefix(maxFileCount))
    }

    static func isAllowed(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        guard !ext.isEmpty else { return false }
        if blockedExtensions.contains(ext) { return false }
        return supportedExtensions.contains(ext)
    }
}
