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

/// A utility class to facilitate snapshot testing across different UI themes and device configurations
/// for both UIViews and UIViewControllers.
final class SnapshotTestHelper {
    
    /// Performs a snapshot test on dynamically initialized content within a specified window environment,
    /// applying theme settings and device configurations beforehand.
    ///
    /// - Parameters:
    ///   - initializer: A closure that returns newly initialized content (UIView or UIViewController).
    ///   - devices: An array of `DeviceType` specifying the device configurations for the snapshot.
    ///   - wait: The time interval to wait before taking the snapshot.
    ///   - precision: The precision of the snapshot comparison.
    ///   - file: The file in which failures should be reported.
    ///   - testName: The name of the test.
    ///   - line: The line number in the source code file where the failure occurred.
    private static func performSnapshot<T>(
        initializingWith initializer: @escaping () -> T,
        devices: [DeviceType],
        wait: TimeInterval,
        precision: CGFloat,
        file: StaticString,
        testName: String,
        line: UInt
    ) {
        let themes: [(UIUserInterfaceStyle, ThemeConfiguration.Theme)] = [
            (.light, .light),
            (.dark, .dark)
        ]
        
        let themeManager: ThemeManager = AppContainer.shared.resolve()
        var window = UIWindow(frame: CGRect(origin: .zero, size: UIScreen.main.bounds.size))
        if devices.isEmpty {
            themes.forEach { theme, suffix in
                changeThemeTo(theme, suffix: suffix, themeManager: themeManager)
                updateContentInitializingWith(initializer, inWindow: window)
                RunLoop.current.run(until: Date(timeIntervalSinceNow: wait))
                let snapshotting = Snapshotting<UIView, UIImage>.image(precision: Float(precision))
                let snapshotName = "\(String.cleanFunctionName(testName))_\(suffix.rawValue)"
                SnapshotTesting.assertSnapshot(of: window, as: snapshotting, file: file, testName: snapshotName, line: line)
            }
        } else {
            devices.forEach { device in
                themes.forEach { theme, suffix in
                    let config = device.config
                    window = UIWindow(frame: CGRect(origin: .zero, size: config.size!))
                    changeThemeTo(theme, suffix: suffix, themeManager: themeManager)
                    updateContentInitializingWith(initializer, inWindow: window)
                    RunLoop.current.run(until: Date(timeIntervalSinceNow: wait))
                    let snapshotting = Snapshotting<UIView, UIImage>.image(precision: Float(precision), traits: config.traits)
                    let snapshotName = "\(String.cleanFunctionName(testName))_\(suffix.rawValue)_\(device.rawValue)"
                    SnapshotTesting.assertSnapshot(of: window, as: snapshotting, file: file, testName: snapshotName, line: line)
                }
            }
        }
    }
    
    /// Updates the window with newly initialized content and makes it visible.
    /// This method initializes content using a provided initializer closure, sets up the content within the specified window,
    /// and makes the window key and visible, ready for interaction or snapshotting.
    ///
    /// - Parameters:
    ///   - initializer: A closure that returns newly initialized content (UIView or UIViewController).
    ///   - window: The UIWindow in which the content will be displayed.
    private static func updateContentInitializingWith<T>(_ initializer: @escaping () -> T, inWindow window: UIWindow) {
        let content = initializer()
        setupContent(content, in: window)
        window.makeKeyAndVisible()
    }

    /// Changes the current theme to a specified UI style and updates the LegacyThemeManager accordingly.
    /// This method applies a specified theme and updates the global theme settings through a theme manager.
    ///
    /// - Parameters:
    ///   - theme: The UIUserInterfaceStyle to set, e.g., .light or .dark.
    ///   - suffix: The ThemeConfiguration.Theme that specifies additional theme details, typically used for naming or logging.
    ///   - themeManager: The ThemeManager responsible for applying theme changes across the app.
    private static func changeThemeTo(_ theme: UIUserInterfaceStyle, suffix: ThemeConfiguration.Theme, themeManager: ThemeManager) {
        LegacyThemeManager.instance.current = suffix == .light ? LegacyNormalTheme() : LegacyDarkTheme()
        themeManager.changeCurrentTheme(suffix == .light ? .light : .dark)
    }
    
    /// Captures snapshots of a UIViewController across multiple device configurations.
    ///
    /// - Parameters:
    ///   - initializer: A closure that returns a newly initialized UIViewController.
    ///   - devices: An array of `DeviceType` for different device configurations.
    ///   - wait: The time interval to delay the snapshot.
    ///   - precision: The precision of the snapshot comparison.
    ///   - file: The file in which failures should be reported.
    ///   - testName: The name of the test.
    ///   - line: The line number to report failures.
    static func assertSnapshot(
        initializingWith initializer: @escaping () -> UIViewController,
        devices: [DeviceType] = [.iPhone12Pro_Portrait],
        wait: TimeInterval = 0,
        precision: CGFloat = 1.0,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        performSnapshot(
            initializingWith: initializer,
            devices: devices,
            wait: wait,
            precision: precision,
            file: file,
            testName: testName,
            line: line
        )
    }
    
    /// Captures snapshots of a UIView across multiple device configurations.
    ///
    /// - Parameters:
    ///   - initializer: A closure that returns a newly initialized UIView.
    ///   - devices: An array of `DeviceType` for different device configurations.
    ///   - wait: The time interval to delay the snapshot.
    ///   - precision: The precision of the snapshot comparison.
    ///   - file: The file in which failures should be reported.
    ///   - testName: The name of the test.
    ///   - line: The line number to report failures.
    static func assertSnapshot(
        initializingWith initializer: @escaping () -> UIView,
        devices: [DeviceType] = [],
        wait: TimeInterval = 0,
        precision: CGFloat = 1.0,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        performSnapshot(
            initializingWith: initializer,
            devices: devices,
            wait: wait,
            precision: precision,
            file: file,
            testName: testName,
            line: line
        )
    }
    
    /// Setup function for adding content to a UIWindow, used in snapshot testing.
    ///
    /// - Parameters:
    ///   - content: Thecontent to be added, either a UIView or UIViewController.
    ///   - window: The UIWindow to which the content will be added.
    private static func setupContent<T>(_ content: T, in window: UIWindow) {
        if let view = content as? UIView {
            window.addSubview(view)
            window.bounds = view.bounds
            view.frame = window.bounds
        } else if let viewController = content as? UIViewController {
            window.rootViewController = viewController
            window.bounds = viewController.view.bounds
            viewController.view.frame = window.bounds
            viewController.loadViewIfNeeded()
        }
        applyDataReloadAndLayoutIfNeeded(for: window)
    }
    
    /// Recursively searches the view hierarchy starting from the provided view
    /// and applies `reloadData()` and `layoutIfNeeded` on any `UICollectionView` or `UITableView`.
    ///
    /// - Parameter view: The root view from which to start the search.
    private static func applyDataReloadAndLayoutIfNeeded(for view: UIView) {
        if let collectionView = view as? UICollectionView {
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
        } else if let tableView = view as? UITableView {
            tableView.reloadData()
            tableView.layoutIfNeeded()
        }
        
        for subview in view.subviews {
            applyDataReloadAndLayoutIfNeeded(for: subview)
        }
    }
}
