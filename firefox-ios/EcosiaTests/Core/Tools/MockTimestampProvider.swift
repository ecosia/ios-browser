import Foundation
@testable import Ecosia

final class MockTimestampProvider: TimestampProvider {

    var currentTimestamp: TimeInterval

    init(currentTimestamp: TimeInterval) {
        self.currentTimestamp = currentTimestamp
    }
}
