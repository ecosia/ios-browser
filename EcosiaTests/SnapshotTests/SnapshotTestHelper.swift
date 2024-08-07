// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SnapshotTesting
import UIKit
import Common
@testable import Client

struct ThemeConfiguration {
    enum Theme: String, CaseIterable {
        case light, dark
    }
    
    let theme: Theme
}

/// A utility class to facilitate snapshot testing across different UI themes for both UIViews and UIViewControllers.
final class SnapshotTestHelper {
    
    /// Performs a snapshot test on dynamically initialized content within a specified window environment,
    /// applying theme settings beforehand. This method supports both UIView and UIViewController,
    /// ensuring that UI components are correctly themed and displayed within their respective containers.
    ///
    /// - Parameters:
    ///   - initializer: A closure that returns newly initialized content (UIView or UIViewController) configured with the current theme.
    ///   - container: A closure that provides a UIWindow where the content is displayed for snapshot testing.
    ///   - wait: The time interval to wait before taking the snapshot, allowing for UI updates and animations to complete.
    ///   - precision: The precision of the snapshot comparison, where 1.0 represents pixel perfect accuracy.
    ///   - file: The file in which failures should be reported, usually the file of the caller.
    ///   - testName: The name of the test, used for snapshot file naming and identification.
    ///   - line: The line number in the source code file where the failure occurred, for precise reporting.
    private static func performSnapshot<T>(
        initializingWith initializer: @escaping () -> T,
        within container: () -> UIWindow,
        wait: TimeInterval = 0.0,
        precision: CGFloat = 1.0,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let themes: [(UIUserInterfaceStyle, ThemeConfiguration.Theme)] = [
            (.light, .light),
            (.dark, .dark)
        ]
        
        let themeManager: ThemeManager = AppContainer.shared.resolve()
        
        themes.forEach { theme, suffix in
            // Set the theme before initializing the content to ensure it's applied correctly.
            LegacyThemeManager.instance.current = suffix == .light ? LegacyNormalTheme() : LegacyDarkTheme()
            themeManager.changeCurrentTheme(suffix == .light ? .light : .dark)
            
            let content = initializer()  // Create the content within the configured theme context.
            let window = container()
            if let view = content as? UIView {
                window.addSubview(view)
                window.bounds = view.bounds
                view.frame = window.bounds
            } else if let viewController = content as? UIViewController {
                window.rootViewController = viewController
                window.bounds = viewController.view.bounds
                viewController.view.frame = window.bounds
                viewController.loadViewIfNeeded()
                viewController.view.layoutSubviews()
            }
            
            window.makeKeyAndVisible()
            applyDataReloadAndLayoutIfNeeded(for: window)
            
            RunLoop.current.run(until: Date(timeIntervalSinceNow: wait))
            
            let snapshotting = Snapshotting<UIView, UIImage>.image(precision: Float(precision))
            let snapshotName = "\(String.cleanFunctionName(testName))_\(suffix.rawValue)"
            SnapshotTesting.assertSnapshot(of: window, as: snapshotting, file: file, testName: snapshotName, line: line)
        }
    }
    
    /// Captures snapshots of a UIViewController across light and dark themes. Ensures the UIViewController
    /// is fresh and properly themed before capturing the snapshot.
    ///
    /// - Parameters:
    ///   - initializer: A closure that returns a newly initialized UIViewController.
    ///   - wait: The time interval to delay the snapshot.
    ///   - precision: The precision of the snapshot comparison.
    ///   - file: The file in which failures should be reported.
    ///   - testName: The name of the test.
    ///   - line: The line number to report failures.
    static func assertSnapshot(
        initializingWith initializer: @escaping () -> UIViewController,
        wait: TimeInterval = 1.0,
        precision: CGFloat = 1.0,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        performSnapshot(
            initializingWith: initializer,
            within: { UIWindow(frame: UIScreen.main.bounds) },
            wait: wait,
            precision: precision,
            file: file,
            testName: testName,
            line: line
        )
    }
    
    /// Captures snapshots of a UIView across light and dark themes. Ensures the UIView
    /// is fresh and properly themed before capturing the snapshot.
    ///
    /// - Parameters:
    ///   - initializer: A closure that returns a newly initialized UIView.
    ///   - wait: The time interval to delay the snapshot.
    ///   - precision: The precision of the snapshot comparison.
    ///   - file: The file in which failures should be reported.
    ///   - testName: The name of the test.
    ///   - line: The line number to report failures.
    static func assertSnapshot(
        initializingWith initializer: @escaping () -> UIView,
        wait: TimeInterval = 1.0,
        precision: CGFloat = 1.0,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        performSnapshot(
            initializingWith: initializer,
            within: { UIWindow(frame: CGRect(origin: .zero, size: UIScreen.main.bounds.size)) },
            wait: wait,
            precision: precision,
            file: file,
            testName: testName,
            line: line
        )
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
