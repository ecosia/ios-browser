// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Core

struct BingDistributionExperiment {
    
    private init() {}
    
    static func incrementCounter() {
        User.shared.searchCount += 1
    }
    
    static func getCounterCurrentCount() -> Int {
        User.shared.searchCount
    }
    
    static var isEnabled: Bool {
        Unleash.isEnabled(.bingDistribution)
    }
    
    static func makeBingSearchURLFromURL(_ sourceURL: URL) -> URL? {
        var urlComponents = URLComponents(url: sourceURL.absoluteURL, resolvingAgainstBaseURL: false)
        urlComponents?.host = "bing.com"
        var queryItems = [URLQueryItem]()
        if let existingSearchQuery = urlComponents?.queryItems?.first(where: { $0.name == "q" }) {
            queryItems.append(existingSearchQuery)
        }
        queryItems.append(contentsOf: [
            URLQueryItem(name: "PC", value: "ECAA"),
            URLQueryItem(name: "FORM", value: "ECAA01"),
            URLQueryItem(name: "PTAG", value: "st_ios_bing_distribution_test")
        ])
        urlComponents?.queryItems = queryItems
        print("[TEST] Using Bing url: \(urlComponents!.url)")
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
        
        return Unleash.getVariant(.bingDistribution).name == "test"
    }
}
