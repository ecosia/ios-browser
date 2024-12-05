import Foundation

extension Date: TimestampProvider {
    public var currentTimestamp: TimeInterval {
        return self.timeIntervalSince1970
    }
}
