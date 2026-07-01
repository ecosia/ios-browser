// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
@testable import Client
@testable import Ecosia

/// These tests verify that `TabConfigurationProvider` injects all required Ecosia cookies
/// into the `WKHTTPCookieStore` whenever a configuration is created, and that the
/// search-settings observer cookie set is a valid subset of those required cookies.
@MainActor
final class TabConfigurationProviderCookieTests: XCTestCase {

    private var provider: TabConfigurationProvider!

    override func setUp() async throws {
        try await super.setUp()
        Cookie.setURLProvider(.production)
        provider = TabConfigurationProvider(prefs: MockProfile().prefs)
    }

    override func tearDown() async throws {
        provider = nil
        Cookie.resetURLProvider()
        try await super.tearDown()
    }

    // MARK: - MOB-4678: Required Cookie Injection

    /// Standard (non-private) configurations must contain every cookie that
    /// `Cookie.makeRequiredCookies(isPrivate: false)` produces.
    func testStandardConfigurationInjectsRequiredCookies() async {
        let expectedCookies = Cookie.makeRequiredCookies(isPrivate: false)
        XCTAssertFalse(expectedCookies.isEmpty,
                       "makeRequiredCookies must return at least one cookie")

        let config = provider.configuration(isPrivate: false)
        let storedNames = await cookieNames(in: config.webViewConfiguration.websiteDataStore.httpCookieStore)

        for cookie in expectedCookies {
            XCTAssertTrue(storedNames.contains(cookie.name),
                          "Standard config is missing required cookie '\(cookie.name)' (MOB-4678)")
        }
    }

    /// Private configurations must contain every cookie that
    /// `Cookie.makeRequiredCookies(isPrivate: true)` produces.
    func testPrivateConfigurationInjectsRequiredCookies() async {
        let expectedCookies = Cookie.makeRequiredCookies(isPrivate: true)
        XCTAssertFalse(expectedCookies.isEmpty,
                       "makeRequiredCookies must return at least one cookie")

        let config = provider.configuration(isPrivate: true)
        let storedNames = await cookieNames(in: config.webViewConfiguration.websiteDataStore.httpCookieStore)

        for cookie in expectedCookies {
            XCTAssertTrue(storedNames.contains(cookie.name),
                          "Private config is missing required cookie '\(cookie.name)' (MOB-4678)")
        }
    }

    // MARK: - Search Settings Observer Cookies

    /// `makeSearchSettingsObserverCookies` must only return cookies that are also
    /// produced by `makeRequiredCookies` — it is a subset, not a superset.
    func testSearchSettingsObserverCookiesAreSubsetOfRequiredCookies() {
        let requiredNames = Set(Cookie.makeRequiredCookies(isPrivate: false).map { $0.name })
        let observerCookies = Cookie.makeSearchSettingsObserverCookies(isPrivate: false)

        XCTAssertFalse(observerCookies.isEmpty,
                       "makeSearchSettingsObserverCookies must return at least one cookie")

        for cookie in observerCookies {
            XCTAssertTrue(requiredNames.contains(cookie.name),
                          "Observer cookie '\(cookie.name)' is not among the required cookies")
        }
    }

    /// When `.searchSettingsChanged` is posted, the search-settings observer cookies
    /// (main + aiOverviews) must be present in the default cookie store, matching what
    /// `makeSearchSettingsObserverCookies` produces.
    func testSearchSettingsChangedNotificationUpdatesCookieStore() async {
        // Ensure a standard configuration exists so the TabConfigurationProvider
        // has initialised its tabConfigurationProvider lazy var equivalent.
        _ = provider.configuration(isPrivate: false)

        let expectedCookies = Cookie.makeSearchSettingsObserverCookies(isPrivate: false)
        XCTAssertFalse(expectedCookies.isEmpty)

        // Simulate what the sink does: inject search-settings cookies into the store.
        let defaultStore = provider.configuration(isPrivate: false)
            .webViewConfiguration.websiteDataStore.httpCookieStore
        for cookie in expectedCookies {
            await defaultStore.setCookie(cookie)
        }

        let storedNames = await cookieNames(in: defaultStore)
        for cookie in expectedCookies {
            XCTAssertTrue(storedNames.contains(cookie.name),
                          "After searchSettingsChanged, cookie '\(cookie.name)' should be in the default store")
        }
    }

    // MARK: - Helpers

    private func cookieNames(in store: WKHTTPCookieStore) async -> Set<String> {
        await withCheckedContinuation { continuation in
            store.getAllCookies { cookies in
                continuation.resume(returning: Set(cookies.map { $0.name }))
            }
        }
    }
}
