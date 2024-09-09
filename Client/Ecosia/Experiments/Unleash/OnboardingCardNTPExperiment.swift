// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Core

struct OnboardingCardNTPExperiment {
    private enum Variant: String {
        case control
        case first = "test1"
        case second = "test2"
    }
    
    private init() {}
    
    static var isEnabled: Bool {
        Unleash.isEnabled(.onboardingCardNTP) && variant != .control
    }
    
    static private var variant: Variant {
        Variant(rawValue: Unleash.getVariant(.onboardingCardNTP).name) ?? .control
    }
    
    // MARK: Card dismissed
    static private let cardDismissedKey = "onboardingCardNTPExperimentDismissed"
    
    static var shouldShowCard: Bool {
        isEnabled && !UserDefaults.standard.bool(forKey: cardDismissedKey)
    }
    
    static func setCardDismissed() {
        UserDefaults.standard.set(true, forKey: cardDismissedKey)
    }
    
    // MARK: Texts
    static var title: String {
        switch variant {
        case .first:
            return .localized(.onboardingCardNTPExperimentTitle1)
        case .second:
            return .localized(.onboardingCardNTPExperimentTitle2)
        default:
            return ""
        }
    }
    
    static var description: String {
        switch variant {
        case .first:
            return .localized(.onboardingCardNTPExperimentDescription1)
        case .second:
            return .localized(.onboardingCardNTPExperimentDescription2)
        default:
            return ""
        }
    }
    
    static var buttonTitle: String {
        switch variant {
        case .first:
            return .localized(.onboardingCardNTPExperimentButtonText1)
        case .second:
            return .localized(.onboardingCardNTPExperimentButtonText2)
        default:
            return ""
        }
    }
}
