// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SnapshotTesting
import XCTest
import Common
import Shared
import Ecosia
import SwiftUI
@testable import Client

final class NTPAccountLoginCellTests: SnapshotBaseTests {

    private let commonWidth = 375

    func testNTPAccountLoginCell() {
        SnapshotTestHelper.assertSnapshot(initializingWith: {
            let cell = NTPAccountLoginCell(frame: CGRect(x: 0, y: 0, width: self.commonWidth, height: 100))

            // Create a test view model with proper EcosiaAuth
            let testAuth = EcosiaAuth(browserViewController: nil)
            let testViewModel = NTPAccountLoginViewModel(
                profile: Profile(),
                theme: self.themeManager.getCurrentTheme(for: .snapshotTestDefaultUUID),
                auth: testAuth,
                windowUUID: .snapshotTestDefaultUUID
            )

            // Configure the cell
            cell.configure(with: testViewModel, windowUUID: .snapshotTestDefaultUUID)

            return cell
        })
    }

    func testNTPAccountLoginCellSwiftUIView() {
        SnapshotTestHelper.assertSnapshot(initializingWith: {
            // Create a test view model with proper EcosiaAuth
            let testAuth = EcosiaAuth(browserViewController: nil)
            let testViewModel = NTPAccountLoginViewModel(
                profile: Profile(),
                theme: self.themeManager.getCurrentTheme(for: .snapshotTestDefaultUUID),
                auth: testAuth,
                windowUUID: .snapshotTestDefaultUUID
            )

            // Create the SwiftUI view
            let swiftUIView = NTPAccountLoginCellView(
                viewModel: testViewModel,
                windowUUID: .snapshotTestDefaultUUID
            )

            // Wrap in a hosting controller for snapshot testing
            let hostingController = UIHostingController(rootView: swiftUIView)
            hostingController.view.frame = CGRect(x: 0, y: 0, width: self.commonWidth, height: 100)

            return hostingController.view
        })
    }
}
