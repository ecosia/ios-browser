// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest
// swiftlint:disable implicitly_unwrapped_optional

final class URLTests: XCTestCase, @unchecked Sendable {

    private var root: String!
    var urlProvider: URLProvider = .production

    override func setUp() {
        root = "\(urlProvider.root.scheme!)" + "://" + urlProvider.root.host!
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: FileManager.user)
    }

    // MARK: - `ecosiaSearchWithQuery`

    func testSearchUrl() {
        let expect = expectation(description: "")
        let suffix = "&tt=iosapp"
        User.queue.async {
            XCTAssertEqual(self.root + "/search?q=somefakesitecom" + suffix, URL.ecosiaSearchWithQuery("somefakesitecom", urlProvider: self.urlProvider).absoluteString)
            XCTAssertEqual(self.root + "/search?q=some%20fakes%20ite.com" + suffix, URL.ecosiaSearchWithQuery("some fakes ite.com", urlProvider: self.urlProvider).absoluteString)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testEncodedQuery() {
        let expect = expectation(description: "")
        User.queue.async {
            XCTAssertEqual(self.root + "/search?q=Paul+Coffee%3DGood,%20right?&tt=iosapp", URL.ecosiaSearchWithQuery("Paul+Coffee=Good, right?", urlProvider: self.urlProvider).absoluteString)
            XCTAssertEqual(self.root + "/search?q=Hello%20THEre!&tt=iosapp", URL.ecosiaSearchWithQuery("Hello THEre!", urlProvider: self.urlProvider).absoluteString)
            XCTAssertEqual(self.root + "/search?q=quinney%20for%20%20president&tt=iosapp", URL.ecosiaSearchWithQuery("quinney for  president", urlProvider: self.urlProvider).absoluteString)
            XCTAssertEqual(self.root + "/search?q=+?%25&tt=iosapp", URL.ecosiaSearchWithQuery("+?%", urlProvider: self.urlProvider).absoluteString)
            XCTAssertEqual(self.root + "/search?q=Hello%2520THEre%2521&tt=iosapp", URL.ecosiaSearchWithQuery("Hello%20THEre%21", urlProvider: self.urlProvider).absoluteString)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testSearchUrl_defaultVertical_producesSearchPath() {
        let expect = expectation(description: "")
        User.queue.async {
            XCTAssertEqual(
                self.root + "/search?q=trees&tt=iosapp",
                URL.ecosiaSearchWithQuery("trees", urlProvider: self.urlProvider).absoluteString
            )
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testSearchUrl_imagesVertical_producesImagesPath() {
        let expect = expectation(description: "")
        User.queue.async {
            XCTAssertEqual(
                self.root + "/images?q=trees&tt=iosapp",
                URL.ecosiaSearchWithQuery("trees", vertical: .images, urlProvider: self.urlProvider).absoluteString
            )
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testSearchUrl_videosVertical_producesVideosPath() {
        let expect = expectation(description: "")
        User.queue.async {
            XCTAssertEqual(
                self.root + "/videos?q=trees&tt=iosapp",
                URL.ecosiaSearchWithQuery("trees", vertical: .videos, urlProvider: self.urlProvider).absoluteString
            )
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testSearchUrl_newsVertical_producesNewsPath() {
        let expect = expectation(description: "")
        User.queue.async {
            XCTAssertEqual(
                self.root + "/news?q=trees&tt=iosapp",
                URL.ecosiaSearchWithQuery("trees", vertical: .news, urlProvider: self.urlProvider).absoluteString
            )
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    // MARK: - `EcosiaSearchVertical(path:)` — used by vertical retention logic

    func testEcosiaSearchVerticalInit_searchPath_returnsSearch() {
        XCTAssertEqual(URL.EcosiaSearchVertical(path: "/search"), .search)
    }

    func testEcosiaSearchVerticalInit_imagesPath_returnsImages() {
        XCTAssertEqual(URL.EcosiaSearchVertical(path: "/images"), .images)
    }

    func testEcosiaSearchVerticalInit_videosPath_returnsVideos() {
        XCTAssertEqual(URL.EcosiaSearchVertical(path: "/videos"), .videos)
    }

    func testEcosiaSearchVerticalInit_newsPath_returnsNews() {
        XCTAssertEqual(URL.EcosiaSearchVertical(path: "/news"), .news)
    }

    func testEcosiaSearchVerticalInit_nonSearchPath_returnsNil() {
        XCTAssertNil(URL.EcosiaSearchVertical(path: "/wiki/Forest"))
        XCTAssertNil(URL.EcosiaSearchVertical(path: "/settings"))
        XCTAssertNil(URL.EcosiaSearchVertical(path: "/"))
    }

    func testEcosiaSearchVerticalInit_url_returnsMatchingVertical() {
        let imagesURL = URL(string: "https://www.ecosia.org/images?q=trees")!
        XCTAssertEqual(URL.EcosiaSearchVertical(url: imagesURL, urlProvider: urlProvider), .images)

        let searchURL = URL(string: "https://www.ecosia.org/search?q=trees")!
        XCTAssertEqual(URL.EcosiaSearchVertical(url: searchURL, urlProvider: urlProvider), .search)

        let settingsURL = URL(string: "https://www.ecosia.org/settings")!
        XCTAssertNil(URL.EcosiaSearchVertical(url: settingsURL, urlProvider: urlProvider))
    }

    // MARK: - Vertical preservation

    func testPreservingVerticalFrom_imagesPage_producesImagesPath() {
        let expect = expectation(description: "")
        let imagesPage = URL(string: "https://www.ecosia.org/images?q=trees")!
        User.queue.async {
            XCTAssertEqual(
                self.root + "/images?q=flowers&tt=iosapp",
                URL.ecosiaSearchWithQuery("flowers", preservingVerticalFrom: imagesPage, urlProvider: self.urlProvider).absoluteString
            )
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testPreservingVerticalFrom_searchPage_producesSearchPath() {
        let expect = expectation(description: "")
        let searchPage = URL(string: "https://www.ecosia.org/search?q=trees")!
        User.queue.async {
            XCTAssertEqual(
                self.root + "/search?q=flowers&tt=iosapp",
                URL.ecosiaSearchWithQuery("flowers", preservingVerticalFrom: searchPage, urlProvider: self.urlProvider).absoluteString
            )
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testPreservingVerticalFrom_nonSearchPage_producesSearchPath() {
        let expect = expectation(description: "")
        let wikiPage = URL(string: "https://www.ecosia.org/wiki/Forest")!
        User.queue.async {
            XCTAssertEqual(
                self.root + "/search?q=flowers&tt=iosapp",
                URL.ecosiaSearchWithQuery("flowers", preservingVerticalFrom: wikiPage, urlProvider: self.urlProvider).absoluteString
            )
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testRewriteTextSerp_preservesImagesVertical() {
        let imagesPage = URL(string: "https://www.ecosia.org/images?q=trees")!
        let textSerp = URL(string: "https://www.ecosia.org/search?q=flowers")!
        let rewritten = textSerp.ecosiaSearchURLPreservingVertical(from: imagesPage, urlProvider: urlProvider)
        XCTAssertEqual(rewritten?.path, "/images")
        XCTAssertEqual(rewritten?.getEcosiaSearchQuery(urlProvider), "flowers")
    }

    func testRewriteTextSerp_sameQueryOnSearchPage_doesNotRewrite() {
        let searchPage = URL(string: "https://www.ecosia.org/search?q=trees")!
        let textSerp = URL(string: "https://www.ecosia.org/search?q=flowers")!
        XCTAssertNil(textSerp.ecosiaSearchURLPreservingVertical(from: searchPage, urlProvider: urlProvider))
    }

    func testRewriteTextSerp_alreadyOnImages_doesNotRewrite() {
        let imagesPage = URL(string: "https://www.ecosia.org/images?q=flowers")!
        let imagesSerp = URL(string: "https://www.ecosia.org/images?q=flowers")!
        XCTAssertNil(imagesSerp.ecosiaSearchURLPreservingVertical(from: imagesPage, urlProvider: urlProvider))
    }

    // MARK: - `isEcosiaSearchQuery`

    func testAssertIsNotEcosiaSearchURLOnNonEcosiaURL() {
        let nonEcosiaURL = URL(string: "https://www.non-ecosia.com/search")!
        XCTAssertFalse(nonEcosiaURL.isEcosiaSearchQuery(urlProvider))
    }

    func testAssertIsNotEcosiaSearchURLOnNonEcosiaSearchQueryURL() {
        let nonSearchEcosiaURL = URL(string: "https://www.ecosia.org/example")!
        XCTAssertFalse(nonSearchEcosiaURL.isEcosiaSearchQuery(urlProvider))
    }

    func testAssertIsEcosiaSearchURLOnEcosiaSearchQueryURL() {
        let searchEcosiaURL = URL(string: "https://www.ecosia.org/search")!
        XCTAssertTrue(searchEcosiaURL.isEcosiaSearchQuery(urlProvider))
    }

    // MARK: - `isEcosiaSearchVertical` & `getEcosiaSearchVerticalPath`

    func testAssertNotEcosiaSearchVerticalOnNonEcosiaURL() {
        let nonEcosiaURL = URL(string: "https://www.non-ecosia.com/search")!
        XCTAssertFalse(nonEcosiaURL.isEcosiaSearchVertical(urlProvider))
        XCTAssertNil(nonEcosiaURL.getEcosiaSearchVerticalPath(urlProvider))
    }

    func testAssertNotEcosiaSearchVerticalOnNonSearchPage() {
        let settingsURL = URL(string: "https://www.ecosia.org/settings")!
        XCTAssertFalse(settingsURL.isEcosiaSearchVertical(urlProvider))
        XCTAssertNil(settingsURL.getEcosiaSearchVerticalPath(urlProvider))
    }

    func testAssertEcosiaSearchVerticalOnEnumCases() {
        for path in URL.EcosiaSearchVertical.allCases.map(\.rawValue) {
            let url = URL(string: "https://www.ecosia.org/\(path)?q=test")!
            XCTAssertTrue(url.isEcosiaSearchVertical(urlProvider))
            XCTAssertEqual(url.getEcosiaSearchVerticalPath(urlProvider), path)
        }
    }

    // MARK: - `getEcosiaSearchQuery` & `getEcosiaSearchPage`

    func testAssertEcosiaSearchQueryAndPageOnNonEcosiaURL() {
        let nonEcosiaURL = URL(string: "https://www.non-ecosia.com/search?q=test&p=1")!
        XCTAssertNil(nonEcosiaURL.getEcosiaSearchQuery(urlProvider))
        XCTAssertNil(nonEcosiaURL.getEcosiaSearchPage(urlProvider))
    }

    func testAssertEcosiaSearchQueryAndPageOnEcosiaURL() {
        let ecosiaUrl = URL(string: "https://www.ecosia.org?q=test&p=1")!
        XCTAssertEqual(ecosiaUrl.getEcosiaSearchQuery(urlProvider), "test")
        XCTAssertEqual(ecosiaUrl.getEcosiaSearchPage(urlProvider), 1)
    }

    // MARK: - `shouldEcosify`

    func testAssertShouldEcosifyOnNonEcosiaURL() {
        let nonSearchEcosiaURL = URL(string: "https://www.google.com")!
        XCTAssertFalse(nonSearchEcosiaURL.shouldEcosify(urlProvider))
    }

    func testAssertShouldEcosifyOnAllEcosiaURLs() {
        let ecosiaURLs = [
            "https://ecosia.org",
            "https://www.ecosia.org/search?q=foo",
            "https://ecosia.org/image?q=test",
            "https://ecosia.org/chat?q=test",
            "https://ecosia.org/news?q=test",
            "https://blog.ecosia.org/",
            "https://www.ecosia.org/settings"
        ]
        ecosiaURLs.forEach { urlString in
            XCTAssertTrue(URL(string: urlString)!.shouldEcosify(urlProvider))
        }
    }

    // MARK: - `ecosified`

    func testAvoidEcosifyWrongScheme() {
        let ecosified = URL(string: "gmsg://ecosia.org")!.ecosified(isIncognitoEnabled: false)
        XCTAssertEqual(ecosified, URL(string: "gmsg://ecosia.org"))
    }

    func testDontEcosifyIfNotEcosia() {
        let ecosified = URL(string: "https://guacamole.org")!.ecosified(isIncognitoEnabled: false)
        XCTAssertEqual(ecosified, URL(string: "https://guacamole.org"))
    }

    func testPatchWithAnalyticsId() {
        let id = UUID()
        User.shared.sendAnonymousUsageData = true
        User.shared.cookieConsentValue = "a"
        User.shared.analyticsId = id

        let domain = URL(string: "https://ecosia.org")!.ecosified(isIncognitoEnabled: false, urlProvider: self.urlProvider)
        XCTAssertEqual(domain, URL(string: "https://ecosia.org?_sp=\(id.uuidString)"))

        let search = URL(string: "https://www.www.ecosia.org/search?q=foo")!.ecosified(isIncognitoEnabled: false, urlProvider: self.urlProvider)
        XCTAssertEqual(search, URL(string: "https://www.www.ecosia.org/search?q=foo&_sp=\(id.uuidString)"))

        let alreadyPatched = URL(string: "https://www.www.ecosia.org/search?q=foo&_sp=12345")!.ecosified(isIncognitoEnabled: false)
        XCTAssertEqual(alreadyPatched, URL(string: "https://www.www.ecosia.org/search?q=foo&_sp=12345"))

        let multiPatch = URL(string: "https://ecosia.org")!.ecosified(isIncognitoEnabled: false, urlProvider: self.urlProvider)
        XCTAssertEqual(multiPatch, URL(string: "https://ecosia.org?_sp=\(id.uuidString)"))
    }

    func testPatchWithNULLAnalyticsId() {
        let id = UUID()
        User.shared.sendAnonymousUsageData = false
        User.shared.analyticsId = id

        let domain = URL(string: "https://ecosia.org")!.ecosified(isIncognitoEnabled: false, urlProvider: self.urlProvider)
        XCTAssertEqual(domain, URL(string: "https://ecosia.org?_sp=\(UUID(uuid: UUID_NULL).uuidString)"))

        let search = URL(string: "https://www.www.ecosia.org/search?q=foo")!.ecosified(isIncognitoEnabled: false, urlProvider: self.urlProvider)
        XCTAssertEqual(search, URL(string: "https://www.www.ecosia.org/search?q=foo&_sp=\(UUID(uuid: UUID_NULL).uuidString)"))

        let multiPatch = URL(string: "https://ecosia.org")!.ecosified(isIncognitoEnabled: false, urlProvider: self.urlProvider)
        XCTAssertEqual(multiPatch, URL(string: "https://ecosia.org?_sp=\(UUID(uuid: UUID_NULL).uuidString)"))
    }

    func testURLEcosifiedInIncognitoMode() {
        let domain = URL(string: "https://ecosia.org")!.ecosified(isIncognitoEnabled: true, urlProvider: self.urlProvider)
        XCTAssertEqual(domain, URL(string: "https://ecosia.org?_sp=\(UUID(uuid: UUID_NULL).uuidString)"))
    }

    func testURLEcosifiedWithAnonymousUsageDataToggleOFF() {
        User.shared.sendAnonymousUsageData = false
        let domain = URL(string: "https://ecosia.org")!.ecosified(isIncognitoEnabled: false, urlProvider: self.urlProvider)
        XCTAssertEqual(domain, URL(string: "https://ecosia.org?_sp=\(UUID(uuid: UUID_NULL).uuidString)"))
    }

    func testURLEcosifiedWithRejectedAnalyticsCookies() {
        User.shared.cookieConsentValue = "e"
        let domain = URL(string: "https://ecosia.org")!.ecosified(isIncognitoEnabled: false, urlProvider: self.urlProvider)
        XCTAssertEqual(domain, URL(string: "https://ecosia.org?_sp=\(UUID(uuid: UUID_NULL).uuidString)"))
    }

    func testURLEcosifiedWithAnonymousUsageDataToggleOFFButRejectedAnalyticsCookies() {
        User.shared.sendAnonymousUsageData = false
        User.shared.cookieConsentValue = "e"
        let domain = URL(string: "https://ecosia.org")!.ecosified(isIncognitoEnabled: false, urlProvider: self.urlProvider)
        XCTAssertEqual(domain, URL(string: "https://ecosia.org?_sp=\(UUID(uuid: UUID_NULL).uuidString)"))
    }

    func testURLEcosifiedWithAnonymousUsageDataToggleONAndRejectedAnalyticsCookies() {
        User.shared.sendAnonymousUsageData = true
        User.shared.cookieConsentValue = "e"
        let domain = URL(string: "https://ecosia.org")!.ecosified(isIncognitoEnabled: false, urlProvider: self.urlProvider)
        XCTAssertEqual(domain, URL(string: "https://ecosia.org?_sp=\(UUID(uuid: UUID_NULL).uuidString)"))
    }

    func testEcosify() {
        User.shared.sendAnonymousUsageData = true
        User.shared.cookieConsentValue = "a"
        let ecosified = URL(string: "https://ecosia.org")!.ecosified(isIncognitoEnabled: false, urlProvider: self.urlProvider)
        XCTAssertEqual(ecosified, URL(string: "https://ecosia.org?_sp=\(User.shared.analyticsId.uuidString)"))
    }

    func testEcosifyWithNULLAnalyticsID() {
        User.shared.sendAnonymousUsageData = false
        let ecosified = URL(string: "https://ecosia.org")!.ecosified(isIncognitoEnabled: false, urlProvider: self.urlProvider)
        XCTAssertEqual(ecosified, URL(string: "https://ecosia.org?_sp=\(UUID(uuid: UUID_NULL).uuidString)"))
    }

    // MARK: - `hasEcosiaUserId`

    func testHasEcosiaUserIdReturnsFalseWhenAbsent() {
        XCTAssertFalse(URL(string: "https://www.ecosia.org/search?q=cats")!.hasEcosiaUserId)
    }

    func testHasEcosiaUserIdReturnsTrueWhenPresent() {
        XCTAssertTrue(URL(string: "https://www.ecosia.org/search?q=cats&_sp=abc123")!.hasEcosiaUserId)
    }

    func testHasEcosiaUserIdReturnsFalseWhenOtherParamsPresent() {
        XCTAssertFalse(URL(string: "https://www.ecosia.org/search?q=cats&tt=iosapp")!.hasEcosiaUserId)
    }

    func testEcosifiedURLHasEcosiaUserId() {
        User.shared.sendAnonymousUsageData = true
        User.shared.cookieConsentValue = "a"
        let url = URL(string: "https://www.ecosia.org/search?q=cats")!
            .ecosified(isIncognitoEnabled: false, urlProvider: urlProvider)
        XCTAssertTrue(url.hasEcosiaUserId)
    }

    // MARK: - `policy`

    func testPolicyAllow() {
        XCTAssertEqual(.allow, URL(string: "ecosia.org")!.policy)
        XCTAssertEqual(.allow, URL(string: "http://ecosia.org")!.policy)
        XCTAssertEqual(.allow, URL(string: "http://www.ecosia.org")!.policy)
        XCTAssertEqual(.allow, URL(string: "https://www.ecosia.org")!.policy)
        XCTAssertEqual(.allow, URL(string: "ecosia://ecosia.org")!.policy)
        XCTAssertEqual(.allow, URL(string: "maps://ecosia.org")!.policy)
    }

    func testPolicyCancel() {
        XCTAssertEqual(.cancel, URL(string: "gmsg://mobileads.google.com/appEvent?name=sitedefault&info=true&google.afma.Notify_dt=1625136586354")!.policy)
        XCTAssertEqual(.cancel, URL(string: "gmsg://mobileads.google.com")!.policy)
        XCTAssertEqual(.cancel, URL(string: "gmsg://something")!.policy)
        XCTAssertEqual(.cancel, URL(string: "gmsg://")!.policy)
    }
}
// swiftlint:enable implicitly_unwrapped_optional
