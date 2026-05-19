import ProjectDescription

/// All test targets (unit tests and UI tests).
public enum TestTargets {

    public static func all() -> [Target] {
        [
            accountTests(),
            clientTests(),
            storagePerfTests(),
            storageTests(),
            sharedTests(),
            syncTelemetryTests(),
            syncTests(),
            l10nSnapshotTests(),
            ecosiaSnapshotTests(),
            ecosiaTests(),
        ]
    }

    static func accountTests() -> Target {
        .target(
            name: "AccountTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "org.mozilla.ios.AccountTests",
            infoPlist: .default,
            sources: ["firefox-ios-tests/Tests/AccountTests/**/*.swift"],
            dependencies: [
                .sdk(name: "RustMozillaAppServices", type: .framework),
                .package(product: "Shared"),
            ],
            settings: .settings(base: BuildConfigurations.testBaseSettings.merging([
                "SWIFT_OBJC_BRIDGING_HEADER": "$SRCROOT/Account/Account-Bridging-Header.h"
            ], uniquingKeysWith: { _, new in new }))
        )
    }

    static func clientTests() -> Target {
        .target(
            name: "ClientTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "org.mozilla.ios.ClientTests",
            // Ecosia (MOB-4384): one-time bundle-level dependency bootstrap so the ~184
            // ClientTests classes that never call DependencyHelperMock().bootstrapDependencies()
            // still see a populated, correctly-keyed AppContainer.
            infoPlist: .extendingDefault(with: ["NSPrincipalClass": "EcosiaTestBundleBootstrap"]),
            sources: ["firefox-ios-tests/Tests/ClientTests/**/*.swift"],
            dependencies: [
                .target(name: "Client"),
                .target(name: "RustMozillaAppServices"),
                .package(product: "Common"),
                .package(product: "Fuzi"),
                .package(product: "GCDWebServers"),
                .package(product: "Kingfisher"),
                .package(product: "Shared"),
                .package(product: "SiteImageView"),
                .package(product: "TabDataStore"),
                .sdk(name: "z", type: .library),
            ],
            settings: .settings(base: BuildConfigurations.testBaseSettings)
        )
    }

    static func storagePerfTests() -> Target {
        .target(
            name: "StoragePerfTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "org.mozilla.ios.StoragePerfTests",
            infoPlist: .default,
            sources: ["firefox-ios-tests/Tests/StoragePerfTests/**/*.swift"],
            dependencies: [
                .target(name: "Storage"),
                .package(product: "Common"),
                .package(product: "Fuzi"),
                .package(product: "GCDWebServers"),
                .package(product: "SiteImageView"),
                .package(product: "TabDataStore"),
            ],
            settings: .settings(base: BuildConfigurations.testBaseSettings)
        )
    }

    static func storageTests() -> Target {
        .target(
            name: "StorageTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "org.mozilla.ios.StorageTests",
            infoPlist: .default,
            sources: ["firefox-ios-tests/Tests/StorageTests/**/*.swift"],
            resources: [
                // Ecosia: certificate files and DB fixtures required by CertTests and TestBrowserDB.
                .glob(pattern: "firefox-ios-tests/Tests/StorageTests/**/*.pem"),
                .glob(pattern: "firefox-ios-tests/Tests/StorageTests/fixtures/**"),
            ],
            dependencies: [
                .target(name: "Client"),
                .target(name: "Storage"),
                // Ecosia: RustAutofillTests and RustRemoteTabsTests import MozillaAppServices directly,
                // so StorageTests must link RustMozillaAppServices to resolve those symbols at link time.
                .target(name: "RustMozillaAppServices"),
                .package(product: "Common"),
                .package(product: "Shared"),
                .package(product: "Fuzi"),
                .package(product: "GCDWebServers"),
                .package(product: "SiteImageView"),
                .package(product: "TabDataStore"),
            ],
            settings: .settings(base: BuildConfigurations.testBaseSettings.merging([
                "SWIFT_OBJC_BRIDGING_HEADER": "$SRCROOT/Storage/Storage-Bridging-Header.h"
            ], uniquingKeysWith: { _, new in new }))
        )
    }

    static func sharedTests() -> Target {
        .target(
            name: "SharedTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "org.mozilla.ios.SharedTests",
            infoPlist: .default,
            sources: ["firefox-ios-tests/Tests/SharedTests/**/*.swift"],
            dependencies: [
                .package(product: "Common"),
                .package(product: "Shared"),
            ],
            settings: .settings(base: BuildConfigurations.testBaseSettings.merging([
                "SWIFT_OBJC_BRIDGING_HEADER": "$SRCROOT/Shared/Shared-Bridging-Header.h"
            ], uniquingKeysWith: { _, new in new }))
        )
    }

    static func syncTelemetryTests() -> Target {
        .target(
            name: "SyncTelemetryTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "org.mozilla.ios.SyncTelemetryTests",
            infoPlist: .default,
            sources: ["firefox-ios-tests/Tests/SyncTelemetryTests/**/*.swift"],
            dependencies: [
                .target(name: "Client"),
                .package(product: "Glean"),
                .package(product: "Shared"),
            ],
            settings: .settings(base: BuildConfigurations.testBaseSettings)
        )
    }

    static func syncTests() -> Target {
        .target(
            name: "SyncTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "org.mozilla.ios.SyncTests",
            infoPlist: .default,
            sources: ["firefox-ios-tests/Tests/SyncTests/**/*.swift"],
            dependencies: [
                .target(name: "Sync"),
                .target(name: "RustMozillaAppServices"),
                .package(product: "Common"),
                .package(product: "Shared"),
                .package(product: "Fuzi"),
                .package(product: "GCDWebServers"),
                .package(product: "SiteImageView"),
                .package(product: "TabDataStore"),
            ],
            settings: .settings(base: BuildConfigurations.testBaseSettings.merging([
                "SWIFT_OBJC_BRIDGING_HEADER": "$SRCROOT/firefox-ios-tests/Tests/SyncTests/SyncTests-Bridging-Header.h",
                "HEADER_SEARCH_PATHS": ["$(inherited)", "$(SRCROOT)/Sync", "$(SRCROOT)/Shared", "$(SRCROOT)/Storage"]
            ], uniquingKeysWith: { _, new in new }))
        )
    }

    static func l10nSnapshotTests() -> Target {
        .target(
            name: "L10nSnapshotTests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "org.mozilla.ios.L10nSnapshotTests",
            infoPlist: .default,
            sources: ["firefox-ios-tests/Tests/L10nSnapshotTests/**/*.swift"],
            dependencies: [
                .target(name: "Client"),
                .package(product: "Common"),
                .package(product: "Fuzi"),
                .package(product: "GCDWebServers"),
                .package(product: "MappaMundi"),
                .package(product: "SiteImageView"),
                .package(product: "TabDataStore"),
            ],
            settings: .settings(base: BuildConfigurations.testBaseSettings)
        )
    }

    static func ecosiaSnapshotTests() -> Target {
        .target(
            name: "EcosiaSnapshotTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.ecosia.tests.EcosiaSnapshot",
            infoPlist: .default,
            sources: ["EcosiaTests/SnapshotTests/**/*.swift"],
            dependencies: [
                .package(product: "Common"),
                .package(product: "Fuzi"),
                .package(product: "GCDWebServers"),
                .package(product: "SiteImageView"),
                .package(product: "SnapshotTesting"),
                .package(product: "TabDataStore"),
            ],
            settings: .settings(base: BuildConfigurations.testBaseSettings)
        )
    }

    static func ecosiaTests() -> Target {
        .target(
            name: "EcosiaTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.ecosia.tests.Ecosia",
            // Ecosia (MOB-4384): one-time bundle-level dependency bootstrap (see ClientTests).
            infoPlist: .extendingDefault(with: ["NSPrincipalClass": "EcosiaTestBundleBootstrap"]),
            sources: [
                .glob("EcosiaTests/**/*.swift", excluding: ["EcosiaTests/SnapshotTests/**/*.swift"]),
                // Shared ClientTests helpers required by integration tests
                "firefox-ios-tests/Tests/ClientTests/XCTestCaseExtensions.swift",
                "firefox-ios-tests/Tests/ClientTests/ProfileTest.swift",
                "firefox-ios-tests/Tests/ClientTests/DependencyInjection/*.swift",
                "firefox-ios-tests/Tests/ClientTests/Mocks/*.swift",
                "firefox-ios-tests/Tests/ClientTests/Coordinators/Mocks/*.swift",
                "firefox-ios-tests/Tests/ClientTests/Frontend/Theme/MockThemeManager.swift",
                "firefox-ios-tests/Tests/ClientTests/Utils/StoreTestUtility.swift",
                "firefox-ios-tests/Tests/ClientTests/Microsurvey/Mock/MockMicrosurveySurfaceManager.swift",
            ],
            resources: [
                // Ecosia: JSON fixtures, HTML import/export files, and other test assets
                // required by NewsTests, ReferralsTests, and bookmark import/export tests.
                // Bundle identifier must match bundleId ("com.ecosia.tests.Ecosia") in Bundle+EcosiaTests.swift.
                .glob(pattern: "EcosiaTests/Core/Resources/**"),
            ],
            dependencies: [
                .target(name: "Client"),
                .target(name: "Ecosia"),
                .target(name: "Storage"),
                // Ecosia: EcosiaTests includes MockProfile, MockHistoryHandler, and
                // BookmarksHandlerMock which import MozillaAppServices directly.
                // RustMozillaAppServices must be linked to resolve those symbols at link time.
                .target(name: "RustMozillaAppServices"),
                .package(product: "Common"),
                .package(product: "Fuzi"),
                .package(product: "GCDWebServers"),
                .package(product: "Shared"),
                .package(product: "SiteImageView"),
                .package(product: "SnowplowTracker"),
                .package(product: "TabDataStore"),
                .package(product: "ToolbarKit"),
                .package(product: "ViewInspector"),
            ],
            settings: .settings(base: BuildConfigurations.testBaseSettings)
        )
    }
}
