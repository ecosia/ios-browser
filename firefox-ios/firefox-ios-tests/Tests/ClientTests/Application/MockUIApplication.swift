// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

class MockUIApplication: UIApplicationInterface {
    var mockDefaultApplicationValue = false

    private var shouldThrowCategoryDefaultError = false
    private var mockErrorUserInfo: [String: Any] = [:]

    // Ecosia: Synced to upstream v147.5. The error MUST be an NSError with
    // UIApplication.CategoryDefaultError.errorDomain so it bridges to UIApplication.CategoryDefaultError and is
    // caught by DefaultBrowserUtility.processUserDefaultState (the previous mock used a plain "UIApplication
    // CategoryDefaultError" domain string + code 1, which did NOT bridge, so the error path was never taken and
    // the API-error dates were never saved). (MOB-4384)
    @available(iOS 18.2, *)
    func isDefault(_ category: UIApplication.Category) throws -> Bool {
        if shouldThrowCategoryDefaultError {
            throw NSError(
                domain: UIApplication.CategoryDefaultError.errorDomain,
                code: UIApplication.CategoryDefaultError.Code.rateLimited.rawValue,
                userInfo: mockErrorUserInfo
            )
        }
        return mockDefaultApplicationValue
    }

    func setupCategoryDefaultErrorWith(userInfo: [String: Any]) {
        shouldThrowCategoryDefaultError = true
        mockErrorUserInfo = userInfo
    }
}
