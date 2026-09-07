// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SnapshotTesting
import XCTest
import SwiftUI
import Common
import Shared
import Storage
import Ecosia
import SiteImageView
@testable import Client

final class EcosiaAccountImpactViewTests: SnapshotBaseTests {
    private let commonWidth: CGFloat = 375
    private let topSiteCellSize = CGSize(width: 100, height: 120)
    private let englishOnlyLocales = [Locale(identifier: "en")]

    @available(iOS 16, *)
    func testImpactView() {
        SnapshotTestHelper.assertSnapshot(
            initializingWith: { self.makeHostingController() },
            locales: englishOnlyLocales
        )
    }
}

private extension EcosiaAccountImpactViewTests {
    
    @available(iOS 16, *)
    func makeHostingController() -> UIViewController {
        makeSnapshotHostingController(
            content: { EcosiaAccountImpactView(
                    viewModel: EcosiaAccountImpactViewModel(
                        onLogin: {},
                        onDismiss: {}
                    ),
                    windowUUID: .XCTestDefaultUUID
            ) },
            size: CGSize(width: 160, height: 72)
        )
    }
    
    func makeSnapshotHostingController<Content: View>(
        @ViewBuilder content: () -> Content,
        size: CGSize
    ) -> UIViewController {
        let root = ZStack {
            content()
        }
            .frame(width: size.width, height: size.height)
        
        let controller = UIHostingController(rootView: root)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        return controller
    }
}
