// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Core

struct SeedCounterNTPExperiment {
    private enum Variant: String {
        case control
        case test
    }
    
    private init() {}
    
    static var progressManagerType: SeedProgressManagerProtocol.Type = UserDefaultsSeedProgressManager.self
    
    static var isEnabled: Bool {
        Unleash.isEnabled(.seedCounterNTP) &&
        variant != .control &&
        SeedCounterNTPExperiment.seedLevelConfig != nil
    }
    
    static private var variant: Variant {
        Variant(rawValue: Unleash.getVariant(.seedCounterNTP).name) ?? .control
    }
    
    // MARK: Analytics

    static func trackSeedCollectionIfNewDayAppOpening() {
        let seedCollectionExperimentIdentifier = "seedCollectionNTPExperimentIdentifier"
        guard Analytics.hasDayPassedSinceLastCheck(for: seedCollectionExperimentIdentifier) else {
            return
        }
        Analytics.shared.ntpSeedCounterExperiment(.view,
                                                  value: NSNumber(integerLiteral: 1))
        UserDefaults.standard.setValue(true, forKey: seedCollectionExperimentIdentifier)
    }
    
    static func trackTapOnSeedCounter() {
        Analytics.shared.ntpSeedCounterExperiment(.click,
                                                  value: NSNumber(integerLiteral: progressManagerType.loadTotalSeedsCollected()))
    }
    
    static func trackSeedLevellingUp() {
        Analytics.shared.ntpSeedCounterExperiment(.level,
                                                  value: NSNumber(integerLiteral: progressManagerType.loadCurrentLevel()))
    }
    
    static var seedLevelConfig: SeedLevelConfig? {
        guard let payloadString = Unleash.getVariant(.seedCounterNTP).payload?.value,
              let payloadData = payloadString.data(using: .utf8),
              let seedLevelConfig = try? JSONDecoder().decode(SeedLevelConfig.self, from: payloadData)
        else {
            return nil
        }
        return seedLevelConfig
    }
}
