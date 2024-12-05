@testable import Ecosia
import XCTest

final class ListTests: XCTestCase {
    func testIncomplete() {
        let json = """
[{
 "name": "test",
 "id": 1
},
{
 "id": 2
}]
"""
        XCTAssertNil(try? JSONDecoder().decode([Model].self, from: .init(json.utf8)))
        XCTAssertEqual("test", (try? JSONDecoder().decode(List<Model>.self, from: .init(json.utf8)).items.first?.name))
    }
}

private struct Model: Decodable {
    let name: String
    let id: Int
}
