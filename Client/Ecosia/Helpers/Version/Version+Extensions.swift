// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

/// Extension handling previous version retrieval and saving current version.
extension Version {
    
    static var current: Version {
        Version(AppInfo.ecosiaAppVersion)!
    }
    
    static func saved(forKey key: String, using prefs: UserDefaults = UserDefaults.standard) -> Version? {
        guard let savedKey = prefs.string(forKey: key) else { return nil }
        return Version(savedKey)
    }
    
    
    static func updateFromCurrent(forKey key: String, using prefs: UserDefaults = UserDefaults.standard) {
        prefs.set(current.description, forKey: key)
    }
}
