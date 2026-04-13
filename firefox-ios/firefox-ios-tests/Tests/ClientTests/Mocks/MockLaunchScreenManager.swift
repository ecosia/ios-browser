// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client
import Common

class MockLaunchScreenViewModel: LaunchScreenViewModel {
    var startLoadingCalled = 0
    var loadNextLaunchTypeCalled = 0
    var mockLaunchType: LaunchType?

    override func startLoading(appVersion: String) {
        startLoadingCalled += 1
        loadNextLaunchTypeCalled += 1
        if let mockLaunchType = mockLaunchType {
            delegate?.launchWith(launchType: mockLaunchType)
        } else {
            delegate?.launchBrowser()
        }
    }
}
