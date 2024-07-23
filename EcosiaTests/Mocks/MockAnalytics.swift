// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

final class MockAnalytics: AnalyticsProtocol {
    var activityCallCount = 0
    var lastActivity: Analytics.Action.Activity?
    
    func activity(_ action: Analytics.Action.Activity) {
        activityCallCount += 1
        lastActivity = action
    }
}
