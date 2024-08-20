// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct LocaleRetriever {
    
    private init() {}
    
    // Function to get locales from the environment variable
    static func getLocales() -> [Locale] {
        // Retrieve the LOCALES environment variable
        if let localesString = ProcessInfo.processInfo.environment["LOCALES"] {
            // Split the string by commas and map them to Locale objects
            let localeIdentifiers = localesString.split(separator: ",").map { String($0) }
            return localeIdentifiers.map { Locale(identifier: $0) }
        } else {
            // Fallback to default locale if LOCALES is not set
            return [Locale(identifier: "en")]
        }
    }
}
