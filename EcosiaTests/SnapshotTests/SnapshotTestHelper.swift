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
        
        // Iterate through the view hierarchy to find and handle UICollectionView and UITableView
        applyDataReloadAndLayoutIfNeeded(for: viewController.view)
        
        RunLoop.main.run(until: Date(timeIntervalSinceNow: wait))

        let snapshotting = Snapshotting<UIView, UIImage>.image(precision: Float(precision))
        SnapshotTesting.assertSnapshot(of: window.rootViewController!.view, as: snapshotting, file: file, testName: testName, line: line)
    }

    static func assertSnapshot(
        of view: UIView,
        wait: TimeInterval = 1.0,
        precision: CGFloat = 1.0,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        // Iterate through the view hierarchy to find and handle UICollectionView and UITableView
        applyDataReloadAndLayoutIfNeeded(for: view)

        let snapshotting = Snapshotting<UIView, UIImage>.image(precision: Float(precision))
        DispatchQueue.main.asyncAfter(deadline: .now() + wait) {
            SnapshotTesting.assertSnapshot(of: view, as: snapshotting, file: file, testName: testName, line: line)
        }
    }
}

extension SnapshotTestHelper {
    /// Recursively searches the view hierarchy starting from the provided view
    /// and applies `reloadData()` and `layoutIfNeeded()` on any `UICollectionView`
    /// or `UITableView` that it encounters.
    ///
    /// This method is intended to ensure that collection views and table views are
    /// fully loaded and laid out before snapshotting. It traverses the entire view
    /// hierarchy, so it will handle nested views as well.
    ///
    /// - Parameter view: The root view from which to start the search. Typically,
    ///   this will be the view of a view controller.
    private static func applyDataReloadAndLayoutIfNeeded(for view: UIView) {
        // Check if the view is a UICollectionView or UITableView and apply reloadData and layoutIfNeeded
        if let collectionView = view as? UICollectionView {
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
        } else if let tableView = view as? UITableView {
            tableView.reloadData()
            tableView.layoutIfNeeded()
        }

        // Recursively apply the same for subviews
        for subview in view.subviews {
            applyDataReloadAndLayoutIfNeeded(for: subview)
        }
    }
}
