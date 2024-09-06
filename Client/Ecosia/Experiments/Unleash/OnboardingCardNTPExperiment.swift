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
    
    // TODO: Link to actual Unleash flag
    static var isEnabled: Bool {
        true
    }
    
    static private var variant: Variant {
        Variant(rawValue: "test1") ?? .control
    }
    
    // TODO: Link to correct translations
    static var title: String {
        switch variant {
        case .first:
            return "First title"
        case .second:
            return "Second title"
        default:
            return ""
        }
    }
    
    static var description: String {
        switch variant {
        case .first:
            return "First description that need to be more long than the title"
        case .second:
            return "Second description that need to be more long than the title"
        default:
            return ""
        }
    }
    
    static var buttonTitle: String {
        switch variant {
        case .first:
            return "First button"
        case .second:
            return "Second button"
        default:
            return ""
        }
    }
}
