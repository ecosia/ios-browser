// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SnapshotTesting
import SwiftUI
import XCTest
import Common
import Ecosia
@testable import Client
@testable import Ecosia

@available(iOS 16.0, *)
final class NTPOmniboxUploadDrawerSnapshotTests: SnapshotBaseTests {

    private let drawerWidth: CGFloat = 375

    override func setUp() {
        super.setUp()
        enableUploadDrawerFeatureFlags()
    }

    override func tearDown() {
        Unleash.clearInstanceModel()
        super.tearDown()
    }

    func testOmniboxUploadDrawerSheet() {
        SnapshotTestHelper.assertSnapshot(
            initializingWith: { self.makeOmniboxUploadDrawerHostingController() },
            wait: 0.3,
            precision: 0.97
        )
    }
}

@available(iOS 16.0, *)
private extension NTPOmniboxUploadDrawerSnapshotTests {

    func makeOmniboxUploadDrawerHostingController() -> UIViewController {
        let sheet = OmniboxUploadDrawerSheet(
            windowUUID: .snapshotTestDefaultUUID,
            provider: .ecosia,
            selectedChatMode: .standard,
            isAuthenticated: true,
            onSelect: { _ in },
            onSelectChatMode: { _ in },
            onLogin: {}
        )

        let controller = UIHostingController(
            rootView: sheet.frame(width: drawerWidth)
        )
        let fittedHeight = controller.sizeThatFits(
            in: CGSize(width: drawerWidth, height: CGFloat.greatestFiniteMagnitude)
        ).height
        let height = max(fittedHeight, 1)

        controller.view.bounds = CGRect(x: 0, y: 0, width: drawerWidth, height: height)
        controller.view.backgroundColor = .clear
        return controller
    }

    func enableUploadDrawerFeatureFlags() {
        let toggles: Set<Unleash.Toggle> = [
            Unleash.Toggle(
                name: Unleash.Toggle.Name.fileUpload.rawValue,
                enabled: true,
                variant: Unleash.Variant(name: "", enabled: false, payload: nil)
            ),
            Unleash.Toggle(
                name: Unleash.Toggle.Name.chatModes.rawValue,
                enabled: true,
                variant: Unleash.Variant(name: "", enabled: false, payload: nil)
            )
        ]
        Unleash.model = Unleash.Model(toggles: toggles)
    }
}
