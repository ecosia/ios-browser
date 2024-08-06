// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SnapshotTesting
import UIKit

final class SnapshotTestHelper {

    static func assertSnapshot<T: UIViewController>(
        of viewController: T,
        wait: TimeInterval = 1.0,
        precision: CGFloat = 1.0,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        viewController.loadViewIfNeeded()
        
        let snapshotting = Snapshotting<UIView, UIImage>.image(precision: Float(precision))
        DispatchQueue.main.asyncAfter(deadline: .now() + wait) {
            SnapshotTesting.assertSnapshot(of: window.rootViewController!.view, as: snapshotting, file: file, testName: testName, line: line)
        }
    }

    static func assertSnapshot(
        of view: UIView,
        wait: TimeInterval = 1.0,
        precision: CGFloat = 1.0,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let snapshotting = Snapshotting<UIView, UIImage>.image(precision: Float(precision))
        DispatchQueue.main.asyncAfter(deadline: .now() + wait) {
            SnapshotTesting.assertSnapshot(of: view, as: snapshotting, file: file, testName: testName, line: line)
        }
    }
}
