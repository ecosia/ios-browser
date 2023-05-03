// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Core

struct BingSearchExperimentCounter {
    
    private init() {}
    
    static func increment() {
        Core.BingSearchExperimentCounter.increment()
    }
}

extension URL {
    
    static func makeBingSearchURLFromURL(_ sourceURL: URL) -> URL? {
        let baseDomain = sourceURL.normalizedHost ?? URL.domain
        let bingDomain = "bing.com"
        let bingFullURLString = sourceURL.absoluteString.replacingOccurrences(of: baseDomain, with: bingDomain)
        return URL(string: bingFullURLString)
    }
}
