// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class URLProviderTests: XCTestCase {

    var urlProvider: URLProvider = .staging

    func testFinancialReports() {
        let def = Language.current
        Language.current = .en
        XCTAssertNotNil(urlProvider.financialReports)
        XCTAssertEqual(urlProvider.financialReports.pathComponents.last, "ecosia-financial-reports-tree-planting-receipts")

        Language.current = .fr
        XCTAssertNotNil(urlProvider.financialReports)
        XCTAssertEqual(urlProvider.financialReports.pathComponents.last, "rapports-financiers-recus-de-plantations-arbres")

        Language.current = .de
        XCTAssertNotNil(urlProvider.financialReports)
        XCTAssertEqual(urlProvider.financialReports.pathComponents.last, "ecosia-finanzberichte-baumplanzbelege")

        Language.current = def
    }

    func testBlog() {
        let def = Language.current
        Language.current = .en
        XCTAssertNotNil(urlProvider.blog)
        XCTAssertEqual(urlProvider.blog.absoluteString, "https://blog.ecosia.org/")

        Language.current = .fr
        XCTAssertNotNil(urlProvider.blog)
        XCTAssertEqual(urlProvider.blog.absoluteString, "https://fr.blog.ecosia.org/")

        Language.current = .de
        XCTAssertNotNil(urlProvider.blog)
        XCTAssertEqual(urlProvider.blog.absoluteString, "https://de.blog.ecosia.org/")

        Language.current = def
    }

    // MARK: - Auth0 Configuration Tests

    func testAuth0Domain_production() {
        let provider = URLProvider.production
        XCTAssertEqual(provider.auth0Domain, "login.ecosia.org")
    }

    func testAuth0Domain_staging() {
        let provider = URLProvider.staging
        XCTAssertEqual(provider.auth0Domain, "login.ecosia-staging.xyz")
    }

    func testAuth0Domain_debug() {
        let provider = URLProvider.debug
        XCTAssertEqual(provider.auth0Domain, "login.ecosia.org")
    }

    func testAuth0CookieDomain_production() {
        let provider = URLProvider.production
        XCTAssertEqual(provider.auth0CookieDomain, "login.ecosia.org")
    }

    func testAuth0CookieDomain_staging() {
        let provider = URLProvider.staging
        XCTAssertEqual(provider.auth0CookieDomain, "login.ecosia-staging.xyz")
    }

    func testAuth0CookieDomain_debug() {
        let provider = URLProvider.debug
        XCTAssertEqual(provider.auth0CookieDomain, "login.ecosia.org")
    }

    func testAuth0CookieDomainMatchesAuth0Domain() {
        // Verify that cookie domain always matches auth0Domain for all environments
        XCTAssertEqual(URLProvider.production.auth0CookieDomain, URLProvider.production.auth0Domain)
        XCTAssertEqual(URLProvider.staging.auth0CookieDomain, URLProvider.staging.auth0Domain)
        XCTAssertEqual(URLProvider.debug.auth0CookieDomain, URLProvider.debug.auth0Domain)
    }

    // MARK: - Environment to URLProvider Mapping Tests

    func testEnvironmentDebugMapsToURLProviderDebug() {
        let environment = Environment.debug
        XCTAssertEqual(environment.urlProvider, URLProvider.debug)
    }

    func testEnvironmentProductionMapsToURLProviderProduction() {
        let environment = Environment.production
        XCTAssertEqual(environment.urlProvider, URLProvider.production)
    }

    func testEnvironmentStagingMapsToURLProviderStaging() {
        let environment = Environment.staging
        XCTAssertEqual(environment.urlProvider, URLProvider.staging)
    }

    // MARK: - Debug Configuration Tests

    func testDebugFollowsProductionConfiguration() {
        let debugProvider = URLProvider.debug
        let productionProvider = URLProvider.production

        // Debug should follow production for these properties
        XCTAssertEqual(debugProvider.root, productionProvider.root)
        XCTAssertEqual(debugProvider.apiRoot, productionProvider.apiRoot)
        XCTAssertEqual(debugProvider.snowplow, productionProvider.snowplow)
        XCTAssertEqual(debugProvider.snowplowMicro, productionProvider.snowplowMicro)
        XCTAssertEqual(debugProvider.unleash, productionProvider.unleash)
        XCTAssertEqual(debugProvider.brazeEndpoint, productionProvider.brazeEndpoint)
        XCTAssertEqual(debugProvider.statistics, productionProvider.statistics)
    }

    func testSnowplowStaging() {
        let provider = URLProvider.staging
        XCTAssertEqual(provider.snowplow, "https://osc.ecosia-staging.xyz")
    }

    func testTrees() {
        let def = Language.current
        Language.current = .en
        XCTAssertNotNil(urlProvider.trees)
        XCTAssertTrue(urlProvider.trees.absoluteString.hasSuffix("tag/where-does-ecosia-plant-trees/"))

        Language.current = .fr
        XCTAssertNotNil(urlProvider.trees)
        XCTAssertTrue(urlProvider.trees.absoluteString.hasSuffix("tag/projets/"))

        Language.current = .de
        XCTAssertNotNil(urlProvider.trees)
        XCTAssertTrue(urlProvider.trees.absoluteString.hasSuffix("tag/projekte/"))

        Language.current = def
    }

    func testBetaProgram() {
        let def = Language.current
        Language.current = .en
        XCTAssertNotNil(urlProvider.betaProgram)
        XCTAssertEqual(urlProvider.betaProgram.absoluteString, "https://ecosia.typeform.com/to/EeMLqL3X")

        Language.current = .fr
        XCTAssertNotNil(urlProvider.betaProgram)
        XCTAssertEqual(urlProvider.betaProgram.absoluteString, "https://ecosia.typeform.com/to/oaFZzT0F")

        Language.current = .de
        XCTAssertNotNil(urlProvider.betaProgram)
        XCTAssertEqual(urlProvider.betaProgram.absoluteString, "https://ecosia.typeform.com/to/catmFLuA")

        Language.current = def
    }

    func testBetaFeedback() {
        let def = Language.current
        Language.current = .en
        XCTAssertNotNil(urlProvider.betaFeedback)
        XCTAssertEqual(urlProvider.betaFeedback.absoluteString, "https://ecosia.typeform.com/to/LlUGlFT9")

        Language.current = .fr
        XCTAssertNotNil(urlProvider.betaFeedback)
        XCTAssertEqual(urlProvider.betaFeedback.absoluteString, "https://ecosia.typeform.com/to/PRw7550n")

        Language.current = .de
        XCTAssertNotNil(urlProvider.betaFeedback)
        XCTAssertEqual(urlProvider.betaFeedback.absoluteString, "https://ecosia.typeform.com/to/pIQ3uwp9")

        Language.current = def
    }

    // MARK: - AI Chat Tests

    func testAIChatWithoutOrigin() {
        let url = urlProvider.aiChat(origin: nil)
        XCTAssertTrue(url.absoluteString.hasSuffix("/ai-chat"))
        XCTAssertNil(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
    }

    func testAIChatWithNTPOrigin() {
        let url = urlProvider.aiChat(origin: .ntp)
        XCTAssertTrue(url.absoluteString.contains("/ai-chat?origin=newtabbutton"))
    }

    func testAIChatWithAutocompleteOrigin() {
        let url = urlProvider.aiChat(origin: .autocomplete)
        XCTAssertTrue(url.absoluteString.contains("/ai-chat?origin=autocomplete_app"))
    }

    func testAIChatWithQueryAndFiles() throws {
        let files = [
            AIChatFileQuery(
                fileId: "a",
                filename: "notes.pdf",
                mimeType: "application/pdf",
                sizeBytes: 1024
            ),
            AIChatFileQuery(
                fileId: "b",
                filename: "photo.png",
                mimeType: "image/png",
                sizeBytes: 2048
            ),
        ]
        let url = urlProvider.aiChat(origin: .omnibox, query: "summarize this", files: files)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let items = Dictionary(uniqueKeysWithValues: (components?.queryItems ?? []).map { ($0.name, $0.value) })
        XCTAssertEqual(items["origin"], "omnibox_app")
        XCTAssertEqual(items["q"], "summarize this")

        let filesJSON = try XCTUnwrap(items["files"].flatMap { $0 })
        let decoded = try JSONDecoder().decode([AIChatFileQuery].self, from: Data(filesJSON.utf8))
        XCTAssertEqual(decoded, files)
        XCTAssertFalse(url.absoluteString.contains("file_ids"))
    }

    func testAIChatEncodesQuestionMarkInQuerySoFilesParamIsPreserved() throws {
        let files = [
            AIChatFileQuery(
                fileId: "39cc9dd7-6e32-444f-a0ff-8a9a615b1441",
                filename: "IMG_0111",
                mimeType: "image/jpeg",
                sizeBytes: 5212725
            ),
        ]
        let url = urlProvider.aiChat(
            origin: .omnibox,
            query: "Cosa sono queste immagini?",
            files: files
        )

        XCTAssertTrue(url.absoluteString.contains("immagini%3F"))
        XCTAssertFalse(url.absoluteString.contains("immagini?&"))

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let items = Dictionary(uniqueKeysWithValues: (components?.queryItems ?? []).map { ($0.name, $0.value) })
        XCTAssertEqual(items["q"], "Cosa sono queste immagini?")

        let filesJSON = try XCTUnwrap(items["files"].flatMap { $0 })
        let decoded = try JSONDecoder().decode([AIChatFileQuery].self, from: Data(filesJSON.utf8))
        XCTAssertEqual(decoded, files)
    }
}
