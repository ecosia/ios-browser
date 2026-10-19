// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Ecosia
import TabDataStore
import XCTest
@testable import Client

final class TabDataEcosiaAuthTests: XCTestCase {
    private let interceptor = EcosiaURLInterceptor(urlProvider: .production)

    func testRemovingEcosiaAuthTabs_dropsTabsOnInterceptedAuthURLs() {
        let tabs = [
            makeTabData(siteUrl: "https://www.example.com/page"),
            makeTabData(siteUrl: URLProvider.production.signInURL.absoluteString),
            makeTabData(siteUrl: URLProvider.production.root.absoluteString)
        ]

        let result = tabs.removingEcosiaAuthTabs(interceptor: interceptor)

        XCTAssertEqual(result.map(\.siteUrl), [
            "https://www.example.com/page",
            URLProvider.production.root.absoluteString
        ])
    }

    func testRemovingEcosiaAuthTabs_keepsTabsWithoutAParsableURL() {
        let tabs = [makeTabData(siteUrl: "")]

        let result = tabs.removingEcosiaAuthTabs(interceptor: interceptor)

        XCTAssertEqual(result.count, 1)
    }

    private func makeTabData(siteUrl: String) -> TabData {
        TabData(id: UUID(),
                title: "Tab",
                siteUrl: siteUrl,
                faviconURL: "",
                isPrivate: false,
                lastUsedTime: Date(),
                createdAtTime: Date(),
                temporaryDocumentSession: [:])
    }
}
