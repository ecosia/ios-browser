import Foundation
@testable import Core

final class MockTimestampProvider: TimestampProvider {

    var currentTimestamp: TimeInterval

    init(currentTimestamp: TimeInterval) {
        self.currentTimestamp = currentTimestamp
    }
}
