// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@MainActor public final class TreesProjection: Publisher {
    public static let shared = TreesProjection()
    public var subscriptions = [Subscription<Int>]()
    private var timerTask: Task<Void, Never>?

    init() {
        startTimer()
    }

    private func startTimer() {
        timerTask = Task { [weak self] in
            guard let self = self else { return }
            // Get initial interval from Statistics actor
            let initialInterval = await Statistics.shared.timePerTree
            
            while !Task.isCancelled {
                let count = await self.treesAt(Date())
                self.send(count)
                
                // Get updated interval (in case Statistics changed)
                let interval = await Statistics.shared.timePerTree
                // Use nanoseconds API for iOS 15 compatibility
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }

    public func treesAt(_ date: Date) async -> Int {
        let timePerTree = await Statistics.shared.timePerTree
        let treesPlanted = await Statistics.shared.treesPlanted
        let treesPlantedLastUpdated = await Statistics.shared.treesPlantedLastUpdated
        
        let timeSinceLastUpdate = date.timeIntervalSince(treesPlantedLastUpdated)
        return .init(timeSinceLastUpdate / timePerTree + treesPlanted - 1)
    }

    deinit {
        timerTask?.cancel()
    }
}
