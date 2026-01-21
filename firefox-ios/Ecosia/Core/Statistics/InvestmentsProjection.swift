// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@MainActor public final class InvestmentsProjection: Publisher {
    public static let shared = InvestmentsProjection()
    public var subscriptions = [Subscription<Int>]()
    private var timerTask: Task<Void, Never>?

    init() {
        startTimer()
    }

    private func startTimer() {
        timerTask = Task { [weak self] in
            guard let self = self else { return }
            // Get initial interval from Statistics actor
            let initialInterval = await self.getTimerInterval()
            
            while !Task.isCancelled {
                let count = await self.totalInvestedAt(Date())
                self.send(count)
                
                // Get updated interval (in case Statistics changed)
                let interval = await self.getTimerInterval()
                // Use nanoseconds API for iOS 15 compatibility
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }

    private func getTimerInterval() async -> Double {
        let investmentPerSecond = await Statistics.shared.investmentPerSecond
        return max(1.0 / investmentPerSecond, 1.0)
    }

    public func totalInvestedAt(_ date: Date) async -> Int {
        let investmentPerSecond = await Statistics.shared.investmentPerSecond
        let totalInvestments = await Statistics.shared.totalInvestments
        let totalInvestmentsLastUpdated = await Statistics.shared.totalInvestmentsLastUpdated
        
        let deltaTimeInSeconds = date.timeIntervalSince(totalInvestmentsLastUpdated)
        return .init(deltaTimeInSeconds * investmentPerSecond + totalInvestments)
    }

    deinit {
        timerTask?.cancel()
    }
}
