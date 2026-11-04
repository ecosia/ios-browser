// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean
import Shared

extension GleanUsageReportingMetricsService {
    /// A stored profile ID means usage-reporting ran before: ask Mozilla once to delete it, then the ID is gone.
    func disableUsageReporting(deletionRequest: GleanUsageDeletionRequest = DefaultGleanUsageDeletionRequest()) {
        guard profile.prefs.stringForKey(PrefsKeys.Usage.profileId) != nil else { return }
        deletionRequest.enable()
        checkAndSetUsageProfileId()
        stop()
    }
}

protocol GleanUsageDeletionRequest {
    func enable()
}

/// The ping is disabled by default, so `stop()` would submit nothing without this.
struct DefaultGleanUsageDeletionRequest: GleanUsageDeletionRequest {
    func enable() {
        GleanMetrics.Pings.shared.usageDeletionRequest.setEnabled(enabled: true)
    }
}
