// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import Common

@testable import Client

@MainActor
class AccessoryViewProviderTests: XCTestCase {
    var accessoryViewProvider: AccessoryViewProvider!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()

        accessoryViewProvider = AccessoryViewProvider()
    }

    override func tearDown() {
        super.tearDown()

        accessoryViewProvider = nil
        AppContainer.shared.reset()
    }

    func testReloadForCreditCardView() {
        // Ecosia: showCreditCard property removed in v147; just verify reload doesn't crash
        accessoryViewProvider.reloadViewFor(.creditCard)
    }

    func testReloadForStandardView() {
        // Ecosia: showCreditCard property removed in v147; just verify reload doesn't crash
        accessoryViewProvider.reloadViewFor(.standard)
    }
}
