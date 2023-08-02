// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension Analytics {
    
    static func hasDayPassedSinceLastCheck(for identifier: String) -> Bool {
        let now = Date()
        let defaults = UserDefaults.standard
        
        // get the date of the last check from UserDefaults
        if let lastCheck = defaults.object(forKey: identifier) as? Date {
            // calculate the difference in days between now and the last check
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day], from: lastCheck, to: now)
            
            if let day = components.day {
                // if a day or more has passed
                if day >= 1 {
                    defaults.set(now, forKey: identifier) // update the last check date
                    return true
                } else {
                    // less than a day has passed
                    return false
                }
            }
        } else {
            // if the last check date does not exist in UserDefaults, set it to now
            defaults.set(now, forKey: identifier)
            return false
        }
        
        return false
    }
}
