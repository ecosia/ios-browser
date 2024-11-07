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

/// A utility class to facilitate snapshot testing across different UI themes and device configurations
/// for both UIViews and UIViewControllers.
final class SnapshotTestHelper {
    
    /// Performs a snapshot test on dynamically initialized content within a specified window environment,
    /// applying theme settings and device configurations beforehand.
    ///
    /// - Parameters:
    ///   - initializer: A closure that returns newly initialized content (`UIView` or `UIViewController`).
    ///   - locales: An array of `Locale` specifying the locales for the snapshot.
    ///   - wait: The time interval to wait before taking the snapshot.
    ///   - precision: The precision of the snapshot comparison.
    ///   - file: The file in which failures should be reported.
    ///   - testName: The name of the test.
    ///   - line: The line number in the source code file where the failure occurred.
    private static func performSnapshot<T>(
        initializingWith initializer: @escaping () -> T,
        locales: [Locale],
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
        
        guard let testBundle = Bundle(identifier: "com.ecosia.ecosiaapp.EcosiaSnapshotTests"),
              let path = testBundle.path(forResource: "environment", ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data, options: []),
              let dict = json as? [String: String],
              let deviceName = dict["DEVICE_NAME"],
              let orientation = dict["ORIENTATION"] else {
            fatalError("Script error. Could not retrieve DEVICE_NAME or ORIENTATION")
        }
                
        let deviceType = DeviceType.from(deviceName: deviceName, orientation: orientation)
        let config = deviceType.config
        let themeManager: ThemeManager = AppContainer.shared.resolve()
        let window = UIWindow(frame: CGRect(origin: .zero, size: config.size!))
        
        locales.forEach { locale in
            themes.forEach { theme, suffix in
                setLocale(locale)
                changeThemeTo(theme, suffix: suffix, themeManager: themeManager)
                updateContentInitializingWith(initializer, inWindow: window)
                RunLoop.current.run(until: Date(timeIntervalSinceNow: wait))
                let snapshotting = Snapshotting<UIView, UIImage>.image(precision: Float(precision), traits: config.traits)
                let snapshotName = "\(String.cleanFunctionName(testName))_\(suffix.rawValue)_\(deviceName)_\(locale.identifier)"
                SnapshotTesting.assertSnapshot(of: window, as: snapshotting, file: file, testName: snapshotName, line: line)
            }
        }
    }
    
    /// Sets the application's locale to the specified locale for testing.
    ///
    /// - Parameter locale: The locale to set for the application.
    private static func setLocale(_ locale: Locale) {
        overriddenLocaleIdentifier = locale.identifier
        UserDefaults.standard.set([locale.identifier], forKey: "AppleLanguages")
        UserDefaults.standard.set(locale.identifier, forKey: "AppleLocale")
        UserDefaults.standard.synchronize()
        swizzleMainBundle()  // Swap the main bundle to use your custom bundle
    }
    
    /// Swaps the main bundle to use a custom bundle for localization override during testing.
    private static func swizzleMainBundle() {
        object_setClass(Bundle.main, LocalizationOverrideTestingBundle.self)
    }
    
    /// Updates the window with newly initialized content and makes it visible.
    /// This method initializes content using a provided initializer closure, sets up the content within the specified window,
    /// and makes the window key and visible, ready for interaction or snapshotting.
    ///
    /// - Parameters:
    ///   - initializer: A closure that returns newly initialized content (`UIView` or `UIViewController`).
    ///   - window: The `UIWindow` in which the content will be displayed.
    private static func updateContentInitializingWith<T>(_ initializer: @escaping () -> T, inWindow window: UIWindow) {
        let content = initializer()
        setupContent(content, in: window)
        window.makeKeyAndVisible()
    }
    
    /// Changes the current theme to a specified UI style and updates the LegacyThemeManager accordingly.
    /// This method applies a specified theme and updates the global theme settings through a theme manager.
    ///
    /// - Parameters:
    ///   - theme: The `UIUserInterfaceStyle` to set, e.g., `.light` or `.dark`.
    ///   - suffix: The `ThemeConfiguration.Theme` that specifies additional theme details, typically used for naming or logging.
    ///   - themeManager: The `ThemeManager` responsible for applying theme changes across the app.
    private static func changeThemeTo(_ theme: UIUserInterfaceStyle, suffix: ThemeConfiguration.Theme, themeManager: ThemeManager) {
        LegacyThemeManager.instance.current = suffix == .light ? LegacyNormalTheme() : LegacyDarkTheme()
        themeManager.changeCurrentTheme(suffix == .light ? .light : .dark)
    }
    
    /// Captures snapshots of a `UIViewController` across multiple device configurations.
    ///
    /// - Parameters:
    ///   - initializer: A closure that returns a newly initialized `UIViewController`.
    ///   - locales: An array of `Locale` specifying the locales for the snapshot. Defaults to the loaded from `snapshot_configuration.json` of each test if no other array is passed.
    ///   - wait: The time interval to delay the snapshot.
    ///   - precision: The precision of the snapshot comparison. Default to 0.99 to allow slightly different colors between CI and local runs.
    ///   - file: The file in which failures should be reported.
    ///   - testName: The name of the test.
    ///   - line: The line number to report failures.
    static func assertSnapshot(
        initializingWith initializer: @escaping () -> UIViewController,
        locales: [Locale] = LocaleRetriever.getLocales(),
        wait: TimeInterval = 0.5,
        precision: CGFloat = 0.99,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        performSnapshot(
            initializingWith: initializer,
            locales: locales,
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
    ///   - locales: An array of `Locale` specifying the locales for the snapshot. Defaults to the loaded from `snapshot_configuration.json` of each test if no other array is passed.
    ///   - wait: The time interval to delay the snapshot.
    ///   - precision: The precision of the snapshot comparison. Default to 0.99 to allow slightly different colors between CI and local runs.
    ///   - file: The file in which failures should be reported.
    ///   - testName: The name of the test.
    ///   - line: The line number to report failures.
    static func assertSnapshot(
        initializingWith initializer: @escaping () -> UIView,
        locales: [Locale] = LocaleRetriever.getLocales(),
        wait: TimeInterval = 0.5,
        precision: CGFloat = 0.99,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        performSnapshot(
            initializingWith: initializer,
            locales: locales,
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
            viewController.view.layoutIfNeeded()
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
