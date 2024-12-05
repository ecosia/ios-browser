@testable import Core
import XCTest

final class ProductionURLProviderTests: XCTestCase {

    var urlProvider: URLProvider = .production

    func testProduction() {
        XCTAssertEqual("https://www.ecosia.org", urlProvider.root.absoluteString)
    }

    func testProductionURLsAreValid() {
        XCTAssertNotNil(urlProvider.root)
        XCTAssertNotNil(urlProvider.statistics)
        XCTAssertNotNil(urlProvider.privacy)
        XCTAssertNotNil(urlProvider.faq)
        XCTAssertNotNil(urlProvider.terms)
        XCTAssertNotNil(urlProvider.aboutCounter)
        XCTAssertNotNil(urlProvider.snowplow)
        XCTAssertNotNil(urlProvider.notifications)
    }
}
