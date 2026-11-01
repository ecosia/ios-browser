// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Decides whether a silent web session re-transfer may start.
///
/// Each re-transfer spends a refresh token on the SSO exchange, so attempts are capped per window with backoff after failures.
@MainActor
public final class WebSessionRetransferGate {

    public enum Decision: Equatable {
        case start
        case alreadyRunning
        /// A login, sign-up or logout flow is running and will settle the web session itself
        case blocked
        case retryAfter(TimeInterval)
        case limitReached
    }

    private let maxAttempts: Int
    private let attemptWindow: TimeInterval
    private let baseBackoff: TimeInterval
    private let now: () -> Date

    private var attemptDates: [Date] = []
    private var consecutiveFailures = 0
    private var isRunning = false
    private var blockingOperationCount = 0

    public init(maxAttempts: Int = 3,
                attemptWindow: TimeInterval = 15 * 60,
                baseBackoff: TimeInterval = 30,
                now: @escaping () -> Date = Date.init) {
        self.maxAttempts = maxAttempts
        self.attemptWindow = attemptWindow
        self.baseBackoff = baseBackoff
        self.now = now
    }

    public var isBlocked: Bool {
        blockingOperationCount > 0
    }

    public func beginBlockingOperation() {
        blockingOperationCount += 1
    }

    public func endBlockingOperation() {
        blockingOperationCount = max(0, blockingOperationCount - 1)
    }

    /// Returns `.start` and records the attempt when a re-transfer may run now; the caller must then call `finish(succeeded:)`.
    public func requestStart() -> Decision {
        guard !isRunning else { return .alreadyRunning }
        guard !isBlocked else { return .blocked }

        let currentDate = now()
        attemptDates.removeAll { currentDate.timeIntervalSince($0) >= attemptWindow }
        guard attemptDates.count < maxAttempts else { return .limitReached }

        // A successful re-transfer means the next loss is a new one, so only failures back off
        if consecutiveFailures > 0, let lastAttempt = attemptDates.last {
            let backoff = baseBackoff * pow(2, Double(consecutiveFailures - 1))
            let remaining = backoff - currentDate.timeIntervalSince(lastAttempt)
            if remaining > 0 {
                return .retryAfter(remaining)
            }
        }

        attemptDates.append(currentDate)
        isRunning = true
        return .start
    }

    public func finish(succeeded: Bool) {
        isRunning = false
        consecutiveFailures = succeeded ? 0 : consecutiveFailures + 1
    }
}
