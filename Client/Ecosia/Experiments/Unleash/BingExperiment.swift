// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Core

struct BingSearchExperiment {
    
    private init() {}
    
    static func incrementCounter() {
        BingSearchExperimentCounter.increment()
    }
    
    static func getCounterCurrentCount() -> Int {
        BingSearchExperimentCounter.read()
    }
    
    static var isEnabled: Bool {
        Unleash.isEnabled(.bingSearch)
    }
    
    static func makeBingSearchURLFromURL(_ sourceURL: URL) -> URL? {
        var urlComponents = URLComponents(url: sourceURL.absoluteURL, resolvingAgainstBaseURL: false)
        urlComponents?.host = "bing.com"
        return urlComponents?.url
    }
    
    static func trackAnalytics() {
        Analytics.shared.userSearchViaBingABTest()
    }
}

extension BingSearchExperiment {
    
    static var shouldShowBingSERP: Bool {
        let variant = Unleash.getVariant(.bingSearch)
        switch variant.name {
        case "control": return false
        case "test": return true
        default: return false
        }
    }    
}
