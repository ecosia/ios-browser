// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

class MockUIApplication: UIApplicationInterface {
    var mockDefaultApplicationValue = false
    private var mockError: Error?

    @available(iOS 18.2, *)
    func isDefault(_ category: UIApplication.Category) throws -> Bool {
        if let error = mockError {
            throw error
        }
        return mockDefaultApplicationValue
    }

    // Ecosia: support error testing for DefaultBrowserUtility
    @available(iOS 18.2, *)
    func setupCategoryDefaultErrorWith(userInfo: [String: Any]) {
        let error = NSError(
            domain: "UIApplicationCategoryDefaultError",
            code: 1,
            userInfo: userInfo
        )
        mockError = error
    }
}
