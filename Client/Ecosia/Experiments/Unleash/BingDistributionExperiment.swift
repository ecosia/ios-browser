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
    
    static var isEnabled: Bool {
        Unleash.isEnabled(.bingDistribution)
    }
    
    static private var isTestVariant: Bool {
        return Unleash.getVariant(.bingDistribution).name == "test"
    }
    
    static func bingSearchWithQuery(_ query: String) -> URL? {
        guard let rootUrl = URL(string: "https://www.bing.com"),
              var components = URLComponents(url: rootUrl, resolvingAgainstBaseURL: false) else {
            return nil
        }
        components.path = "/search"
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "PC", value: "ECAA"),
            URLQueryItem(name: "FORM", value: "ECAA01"),
            URLQueryItem(name: "PTAG", value: "st_ios_bing_distribution_test"),
        ]
        return components.url
    }
    
    static func ecosiaSearchWithTypetag(_ query: String) -> URL? {
        let url = URL.ecosiaSearchWithQuery(query)
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        components.queryItems?.append(URLQueryItem(name: "tts", value: "st_ios_bing_distribution_control"))
        return components.url
    }
    
    static func searchURLForQuery(_ query: String) -> URL? {
        if isTestVariant {
            // Increment counter everytime we use bing's url
            BingDistributionExperiment.incrementCounter()
            return bingSearchWithQuery(query)
        } else {
            return ecosiaSearchWithTypetag(query)
        }
    }
}
