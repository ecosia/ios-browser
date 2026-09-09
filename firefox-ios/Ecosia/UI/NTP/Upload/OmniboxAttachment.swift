// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct OmniboxAttachment: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let fileName: String
    public let layout: Layout
    public var state: State

    public enum Layout: String, Sendable {
        case file
        case image
    }

    public enum State: Equatable, Sendable {
        case loading
        case ready(byteCount: Int, fileId: String, mimeType: String)
        case failed
    }

    public init(id: UUID = UUID(), fileName: String, layout: Layout, state: State) {
        self.id = id
        self.fileName = fileName
        self.layout = layout
        self.state = state
    }

    public var fileId: String? {
        if case .ready(_, let fileId, _) = state { return fileId }
        return nil
    }

    /// Metadata for the web AI chat `files` query parameter.
    public var chatFileQuery: AIChatFileQuery? {
        guard case .ready(let byteCount, let fileId, let mimeType) = state else { return nil }
        return AIChatFileQuery(
            fileId: fileId,
            filename: fileName,
            mimeType: mimeType,
            sizeBytes: byteCount
        )
    }

    public var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    public var isFailed: Bool {
        if case .failed = state { return true }
        return false
    }

    public var isReady: Bool {
        fileId != nil
    }
}
