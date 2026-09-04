// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SnapshotTesting
import UIKit
import Common
import XCTest
@testable import Client
// swiftlint:disable implicitly_unwrapped_optional

struct ThemeConfiguration {
    enum Theme: String, CaseIterable {
        case light, dark
    }

    let theme: Theme
}

/// A utility class to facilitate snapshot testing across different UI themes and device configurations
/// for both UIViews and UIViewControllers.
final class SnapshotTestHelper {

    private static let snapshotReferencePointerPath = "/tmp/ecosia_snapshot_reference_dir"
    private static let snapshotRecordingPointerPath = "/tmp/ecosia_snapshot_testing_record"
    private static let snapshotEnvironmentPath = "/tmp/ecosia_snapshot_environment.json"

    private static func referenceRoot(from file: StaticString) -> URL {
        if let env = ProcessInfo.processInfo.environment["SNAPSHOT_REFERENCE_DIR"],
           !env.isEmpty,
           !env.contains("$(") {
            return URL(fileURLWithPath: env, isDirectory: true)
        }

        if let pointerPath = try? String(
            contentsOf: URL(fileURLWithPath: snapshotReferencePointerPath),
            encoding: .utf8
        ) {
            let trimmedPath = pointerPath.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedPath.isEmpty {
                return URL(fileURLWithPath: trimmedPath, isDirectory: true)
            }
        }

        let fileUrl = URL(fileURLWithPath: "\(file)", isDirectory: false)
        return fileUrl
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("SnapshotArtifacts", isDirectory: true)
    }

    private static var isRecordingSnapshots: Bool {
        let recordValue = ProcessInfo.processInfo.environment["SNAPSHOT_TESTING_RECORD"]
            ?? (try? String(
                contentsOf: URL(fileURLWithPath: snapshotRecordingPointerPath),
                encoding: .utf8
            ))?.trimmingCharacters(in: .whitespacesAndNewlines)

        switch recordValue {
        case "all", "1", "YES", "true", "missing":
            return true
        default:
            return false
        }
    }

    private static func domainName(for testClassName: String) -> String {
        switch testClassName {
        case "OnboardingTests":
            return "Onboarding"
        case "HomepageComponentTests":
            return "Homepage"
        case let name where name.hasPrefix("NTP"):
            return "NTP"
        default:
            if testClassName.hasSuffix("Tests") {
                return String(testClassName.dropLast(5))
            }
            return testClassName
        }
    }

    private static func referenceDirectory(
        testClassName: String,
        referenceRoot: URL
    ) -> URL? {
        let fileManager = FileManager.default
        if let domainDirectories = try? fileManager.contentsOfDirectory(
            at: referenceRoot,
            includingPropertiesForKeys: [.isDirectoryKey]
        ) {
            for domainDirectory in domainDirectories {
                let candidate = domainDirectory
                    .appendingPathComponent(testClassName, isDirectory: true)
                var isDirectory: ObjCBool = false
                if fileManager.fileExists(atPath: candidate.path, isDirectory: &isDirectory), isDirectory.boolValue {
                    return candidate
                }
            }
        }

        guard isRecordingSnapshots else {
            return nil
        }

        return referenceRoot
            .appendingPathComponent(domainName(for: testClassName), isDirectory: true)
            .appendingPathComponent(testClassName, isDirectory: true)
    }

    private static func snapshotDirectory(
        for file: StaticString,
        testClassName: String
    ) throws -> String {
        let referenceRoot = referenceRoot(from: file)

        guard let referenceDirectory = referenceDirectory(
            testClassName: testClassName,
            referenceRoot: referenceRoot
        ) else {
            throw NSError(
                domain: "SnapshotTestHelper",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Could not find snapshot references for \(testClassName) under \(referenceRoot.path)"
                ]
            )
        }

        let fileManager = FileManager.default

        if isRecordingSnapshots {
            try fileManager.createDirectory(at: referenceDirectory, withIntermediateDirectories: true)
            return referenceDirectory.path
        }

        if fileManager.isWritableFile(atPath: referenceDirectory.path) {
            return referenceDirectory.path
        }

        // Simulator-hosted tests cannot write into the checkout, so copy references to a
        // writable temp directory and compare from there.
        let writableDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("EcosiaSnapshotArtifacts", isDirectory: true)
            .appendingPathComponent(testClassName, isDirectory: true)

        if !fileManager.fileExists(atPath: writableDirectory.path) {
            try fileManager.createDirectory(at: writableDirectory, withIntermediateDirectories: true)
            let references = try fileManager.contentsOfDirectory(
                at: referenceDirectory,
                includingPropertiesForKeys: nil
            )
            for reference in references {
                try fileManager.copyItem(
                    at: reference,
                    to: writableDirectory.appendingPathComponent(reference.lastPathComponent)
                )
            }
        }

        return writableDirectory.path
    }

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
    @MainActor
    private static func performSnapshot<T>(
        initializingWith initializer: @escaping () -> T,
        locales: [Locale],
        themes: [ThemeConfiguration.Theme],
        wait: TimeInterval,
        precision: CGFloat,
        file: StaticString,
        testName: String,
        line: UInt
    ) {
        guard let testBundle = Bundle(identifier: "com.ecosia.ecosiaapp.EcosiaSnapshotTests"),
              let envPath = runtimeEnvironmentPath(testBundle: testBundle),
              let envData = try? Data(contentsOf: URL(fileURLWithPath: envPath)),
              let envJson = try? JSONSerialization.jsonObject(with: envData, options: []),
              let envDict = envJson as? [String: Any],
              let devicesArray = envDict["DEVICES"] as? [[String: Any]],
              let localesArray = envDict["LOCALES"] as? [String],
              let simulatorDeviceName = envDict["SIMULATOR_DEVICE_NAME"] as? String else {
            fatalError("Could not retrieve devices and locales from environment.json")
        }

        let themeStyles = themes.isEmpty
            ? themesFromEnvironment(envDict)
            : themeStyles(for: themes)

        let themeManager: ThemeManager = AppContainer.shared.resolve()

        // Map devices from environment.json
        let devicesToTest: [DeviceType] = devicesArray.compactMap { deviceDict in
            guard let deviceName = deviceDict["name"] as? String,
                  let orientation = deviceDict["orientation"] as? String else {
                print("Invalid device entry: \(deviceDict)")
                return nil
            }
            return DeviceType.from(deviceName: deviceName, orientation: orientation)
        }

        // Map locales from environment.json
        let localesToTest = locales.isEmpty
            ? localesArray.map { Locale(identifier: $0) }
            : locales

        let snapshotDirectory: String
        do {
            let className = URL(fileURLWithPath: "\(file)", isDirectory: false)
                .deletingPathExtension()
                .lastPathComponent
            snapshotDirectory = try Self.snapshotDirectory(
                for: file,
                testClassName: className
            )
        } catch {
            XCTFail("Failed to prepare snapshot directory: \(error)", file: file, line: line)
            return
        }

        for deviceType in devicesToTest {
            let config = deviceType.config
            let deviceName = deviceType.name
            let window = UIWindow(frame: CGRect(origin: .zero, size: config.size!))
            let traits: UITraitCollection = .init(traitsFrom: [config.traits])

            for locale in localesToTest {
                for (themeStyle, themeSuffix) in themeStyles {
                    setLocale(locale)
                    changeThemeTo(themeStyle, suffix: themeSuffix, themeManager: themeManager)
                    updateContentInitializingWith(initializer, inWindow: window)
                    RunLoop.current.run(until: Date(timeIntervalSinceNow: wait))

                    let isCurrentDeviceMatchingSimulator = deviceName == simulatorDeviceName

                    let snapshotting = Snapshotting<UIView, UIImage>.image(
                        precision: Float(precision),
                        size: isCurrentDeviceMatchingSimulator ? nil : config.size!,
                        traits: traits
                    )

                    let snapshotName = "\(String.cleanFunctionName(testName))_\(themeSuffix.rawValue)_\(deviceType.rawValue)_\(locale.identifier)"

                    let failure = verifySnapshot(
                        of: window,
                        as: snapshotting,
                        snapshotDirectory: snapshotDirectory,
                        file: file,
                        testName: snapshotName
                    )

                    if let message = failure {
                        XCTFail(message, file: file, line: line)
                    }
                }
            }
        }
    }

    private static func runtimeEnvironmentPath(testBundle: Bundle) -> String? {
        if FileManager.default.fileExists(atPath: snapshotEnvironmentPath) {
            return snapshotEnvironmentPath
        }
        return testBundle.path(forResource: "environment", ofType: "json")
    }

    private static func themesFromEnvironment(
        _ envDict: [String: Any]
    ) -> [(UIUserInterfaceStyle, ThemeConfiguration.Theme)] {
        let configuredThemes: [ThemeConfiguration.Theme]
        if let themesArray = envDict["THEMES"] as? [String] {
            configuredThemes = themesArray.compactMap(ThemeConfiguration.Theme.init(rawValue:))
        } else {
            configuredThemes = ThemeConfiguration.Theme.allCases
        }

        let themes = configuredThemes.isEmpty ? ThemeConfiguration.Theme.allCases : configuredThemes
        return themeStyles(for: themes)
    }

    private static func themeStyles(
        for themes: [ThemeConfiguration.Theme]
    ) -> [(UIUserInterfaceStyle, ThemeConfiguration.Theme)] {
        themes.map { theme in
            switch theme {
            case .light:
                return (.light, .light)
            case .dark:
                return (.dark, .dark)
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
        object_setClass(Bundle.ecosia, LocalizationOverrideTestingBundle.self)
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
    @MainActor
    private static func changeThemeTo(_ theme: UIUserInterfaceStyle, suffix: ThemeConfiguration.Theme, themeManager: ThemeManager) {
        themeManager.setManualTheme(to: suffix == .light ? .light : .dark)
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
    @MainActor
    static func assertSnapshot(
        initializingWith initializer: @escaping () -> UIViewController,
        locales: [Locale] = [],
        themes: [ThemeConfiguration.Theme] = [],
        wait: TimeInterval = 0.5,
        precision: CGFloat = 0.99,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        performSnapshot(
            initializingWith: initializer,
            locales: locales,
            themes: themes,
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
    @MainActor
    static func assertSnapshot(
        initializingWith initializer: @escaping () -> UIView,
        locales: [Locale] = [],
        themes: [ThemeConfiguration.Theme] = [],
        wait: TimeInterval = 0.5,
        precision: CGFloat = 0.99,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        performSnapshot(
            initializingWith: initializer,
            locales: locales,
            themes: themes,
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
        } else if let viewController = content as? UIViewController {
            window.rootViewController = viewController
            window.bounds = viewController.view.bounds
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
// swiftlint:enable implicitly_unwrapped_optional
