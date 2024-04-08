// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Core

struct BingDistributionExperiment {
    
    private init() {}
    
    static func incrementCounter() {
        BingDistributionExperimentCounter.increment()
    }
    
    static func getCounterCurrentCount() -> Int {
        BingDistributionExperimentCounter.read()
    }
    
    static var isEnabled: Bool {
        Unleash.isEnabled(.bingDistribution)
    }
    
    static func makeBingSearchURLFromURL(_ sourceURL: URL) -> URL? {
        var urlComponents = URLComponents(url: sourceURL.absoluteURL, resolvingAgainstBaseURL: false)
        urlComponents?.host = "bing.com"
        urlComponents?.queryItems = [
            URLQueryItem(name: "PC", value: "ECAA"),
            URLQueryItem(name: "FROM", value: "ECAA01"),
            URLQueryItem(name: "PTAG", value: "st_ios_bing_distribution_test")
        ]
        return urlComponents?.url
    }
    
    static func appendControlGroupAdditionalTypeTagTo(_ sourceURL: URL) -> URL {
        var urlToUpdate = sourceURL
        let queryItem = URLQueryItem(name: "tts", value: "st_ios_bing_distribution_control")
        if #available(iOS 16.0, *) {
            urlToUpdate.append(queryItems: [queryItem])
        } else {
            // Construct the query string manually
            if var components = URLComponents(url: sourceURL, resolvingAgainstBaseURL: true) {
                if components.queryItems == nil {
                    components.queryItems = [queryItem]
                } else {
                    components.queryItems?.append(queryItem)
                }
                urlToUpdate = components.url!
            }
        }
        return urlToUpdate
    }
    
    static func trackAnalytics() {
        Analytics.shared.userSearchesViaBingABTest()
    }
}

extension BingDistributionExperiment {
    
    static var shouldShowBingSERP: Bool {
        
        guard BingDistributionExperiment.isEnabled else {
            return false
        }
        
        let variant = Unleash.getVariant(.braze)
        switch variant.name {
        case "control": return false
        case "test": return true
        default: return false
        }
    }
}
