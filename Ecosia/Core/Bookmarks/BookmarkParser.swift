// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftSoup

private typealias DateTag = String

public enum BookmarkParserError: Error {
    case noLeadingDL, noBody, cancelled
}

public protocol BookmarkParseable {
    func parseBookmarks() async throws -> [BookmarkItem]
}

/// Swift Concurrency-safe bookmark parser
public class BookmarkParser: BookmarkParseable {
    private let document: Document

    public init(html: String) throws {
        let document = try SwiftSoup.parse(html)
        self.document = try document.normalizedDocumentIfRequired()
    }

    public func parseBookmarks() async throws -> [BookmarkItem] {
        // Perform parsing on background task
        return try await Task.detached {
            try self.parse(element: try self.document.getLeadingDL())
        }.value
    }
}

private extension BookmarkParser {
    func parse(element: Element) throws -> [BookmarkItem] {
        var items = [BookmarkItem]()

        let children = try element.getLeadingDL()
            .children()
            .filter({ try $0.select(.dt).hasText() }) /// only <DT> is a valid bookmark/folder element

        for child in children {
            let h3 = try child.select(.h3)
            if let nextFolderItem = h3.first() {
                guard let title = try? nextFolderItem.text() else { continue }
                items.append(.folder(title, try parse(element: child), h3.extractBookmarkMetadata()))
                continue /// item is a folder, don't process as bookmark
            }

            let link = try child.select(.a)
            let href = try link.attr(.href)
            let title = try link.text()

            items.append(.bookmark(title, href, link.extractBookmarkMetadata()))
        }

        return items
    }
}

private extension Elements {
    func extractDate(_ tag: DateTag) -> Date? {
        guard
            let timeIntervalString = try? attr(tag),
            let timeInterval = TimeInterval(timeIntervalString)
        else {
            return nil
        }
        return Date(timeIntervalSince1970: timeInterval)
    }

    func extractBookmarkMetadata() -> BookmarkMetadata {
        BookmarkMetadata(
            addedAt: extractDate(.addDate),
            modifiedAt: extractDate(.lastModified)
        )
    }
}

private extension Element {
    func getLeadingDL() throws -> Element {
        guard let leadingDL = try select(.dl).first() else {
            throw BookmarkParserError.noLeadingDL
        }
        return leadingDL
    }
}
