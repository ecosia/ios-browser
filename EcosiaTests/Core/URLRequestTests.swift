import XCTest
@testable import Core

final class URLRequestTests: XCTestCase {

    func testAddLanguageRegionHeader() {
        var request = URLRequest(url: URL(string: "https://www.ecosia.org/search")!)
        request.addLanguageRegionHeader()

        let dashedLanguageAndRegion = Locale.current.identifier.replacingOccurrences(of: "_", with: "-").lowercased()
        XCTAssertEqual(request.value(forHTTPHeaderField: "x-ecosia-app-language-region"), dashedLanguageAndRegion)
    }
}
