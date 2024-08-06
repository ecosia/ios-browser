// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SnapshotTesting
import UIKit

final class SnapshotTestHelper {

    static func assertSnapshot<T: UIViewController>(of viewController: T, wait: TimeInterval = 0.1, file: StaticString = #file, testName: String = #function, line: UInt = #line) {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        viewController.loadViewIfNeeded()
        let snapshotting = Snapshotting<UIView, UIImage>.wait(for: wait, on: .image)
        SnapshotTesting.assertSnapshot(of: window.rootViewController!.view, as: snapshotting, file: file, testName: testName, line: line)
    }

    static func assertSnapshot(of view: UIView, wait: TimeInterval = 0.1, file: StaticString = #file, testName: String = #function, line: UInt = #line) {
        let snapshotting = Snapshotting<UIView, UIImage>.wait(for: wait, on: .image)
        SnapshotTesting.assertSnapshot(of: view, as: snapshotting, file: file, testName: testName, line: line)
    }
}
