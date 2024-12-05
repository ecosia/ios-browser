import Foundation

struct List<E>: Decodable where E: Decodable {
    var items = [E]()

    init(from: Decoder) throws {
        var root = try from.unkeyedContainer()
        while !root.isAtEnd {
            if let item = try? root.decode(E.self) {
                items.append(item)
            } else {
                _ = try root.nestedContainer(keyedBy: Discard.self)
            }
        }
    }
}

private enum Discard: CodingKey { }
