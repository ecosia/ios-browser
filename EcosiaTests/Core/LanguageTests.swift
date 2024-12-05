@testable import Core
import XCTest

final class LanguageTests: XCTestCase {
    func testCurrent() {
        XCTAssertEqual(.en, Language.current)
    }

    func testMake() {
        XCTAssertEqual(.en, Language.make(for: .init(identifier: "en-DE")))
        XCTAssertEqual(.de, Language.make(for: .init(identifier: "de-MX")))
        XCTAssertEqual(.es, Language.make(for: .init(identifier: "es-ES")))
        XCTAssertEqual(.es, Language.make(for: .init(identifier: "es-MX")))
        XCTAssertEqual(.en, Language.make(for: .init(identifier: "en-US")))
        XCTAssertEqual(.es, Language.make(for: .init(identifier: "es-US")))
        XCTAssertEqual(.en, Language.make(for: .init(identifier: "Invalid")))
    }
}
