import Foundation

struct TimeBasedRefreshingRule: RefreshingRule {

    let interval: TimeInterval
    let timestampProvider: TimestampProvider

    init(interval: TimeInterval, timestampProvider: TimestampProvider = Date()) {
        self.interval = interval
        self.timestampProvider = timestampProvider
    }

    var shouldRefresh: Bool {
        return timestampProvider.currentTimestamp - Unleash.model.updated.timeIntervalSince1970 > interval
    }
}
