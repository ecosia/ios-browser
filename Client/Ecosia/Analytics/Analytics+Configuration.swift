// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SnowplowTracker
import Core

extension Analytics {
    
    static let trackerConfiguration = TrackerConfiguration()
        .appId(Bundle.version)
        .sessionContext(true)
        .applicationContext(true)
        .platformContext(true)
        .platformContextProperties([]) // track minimal device properties
        .geoLocationContext(true)
        .deepLinkContext(false)
        .screenContext(false)
    
    static let subjectConfiguration = SubjectConfiguration()
        .userId(User.shared.analyticsId.uuidString)

    static var appResumeDailyTrackingPluginConfiguration: PluginConfiguration {
        let plugin = PluginConfiguration(identifier: "appResumeDailyTrackingPluginConfiguration")
        return plugin.filter(schemas: [
            "se" // Structured Events
        ]) { event in
            let isInAppLabel = event.payload["se_la"] as? String == Analytics.Label.Navigation.inapp.rawValue
            let isResumeEvent = event.payload["se_ac"] as? String == Analytics.Action.Activity.resume.rawValue
            let isInAppResumeEvent = isInAppLabel && isResumeEvent
            
            guard isInAppResumeEvent else {
                return true
            }
            
            return Self.hasDayPassedSinceLastCheck(for: "appResumeDailyTrackingPluginConfiguration")
        }
    }
}
