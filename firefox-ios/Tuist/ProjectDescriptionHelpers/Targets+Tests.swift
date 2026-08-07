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

    // MARK: - Ecosia: forcing package products onto app-hosted test bundles' link lines

    /// Ecosia (MOB-4384): an SPM dynamic package product that an app-hosted test bundle must name on
    /// its own link line.
    ///
    /// Xcode omits *every* dynamic package product from the link command of an app-hosted `.xctest`
    /// bundle, treating them as already provided by the test host, and leaves `ld` to resolve them
    /// transitively through `Client.debug.dylib`'s indirect dylib load commands. That resolution
    /// happens locally but not on CI, so test code calling package API directly (`Maybe`, `Deferred`,
    /// `Date.now()`, `SnowplowTracker.Structured`, …) fails to link with "Undefined symbols for
    /// architecture arm64". Note the generated project is *correct* — the products are present in both
    /// `packageProductDependencies` and the Frameworks build phase — so declaring the dependency is not
    /// enough; the framework has to be named explicitly. Native framework targets (`Storage`, `Ecosia`,
    /// `RustMozillaAppServices`) are unaffected, they are never omitted.
    ///
    /// Raw values are Xcode's own product-framework names, whose hash suffix is deterministic and has
    /// been stable across machines and CI runs — it changes only if BrowserKit's package structure does.
    /// A stale name fails loudly with "framework not found" rather than silently, so drift is easy to
    /// spot; recover the current name from a build log or from
    /// `ls DerivedData/Build/Products/*/PackageFrameworks`.
    ///
    /// Only add products that CI builds *dynamically*. Some (e.g. `ToolbarKit`, `TabDataStore`) are
    /// linked statically on CI and naming them here would break the build outright.
    enum ForceLinkedPackageProduct: String {
        case shared = "Shared_1BC5906757289D_PackageProduct"
        case snowplowTracker = "SnowplowTracker_-1C7C7D3E02D5A8BC_PackageProduct"
    }

    /// Ecosia (MOB-4384): `OTHER_LDFLAGS` naming the given package products, for merging into a test
    /// target's settings. See ``ForceLinkedPackageProduct`` for why this is necessary.
    static func forceLink(_ products: [ForceLinkedPackageProduct]) -> SettingsDictionary {
        ["OTHER_LDFLAGS": .array(["$(inherited)"] + products.flatMap { ["-framework", $0.rawValue] })]
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
            infoPlist: .default,
            sources: ["firefox-ios-tests/Tests/ClientTests/**/*.swift"],
            resources: [
                // Ecosia: Test fixtures ClientTests loads from its own bundle (wallpaper JSON, search/pocket
                // lists, images, search-engine xcassets). Upstream's Client.xcodeproj bundles these; the Tuist
                // migration dropped them, causing `Fatal error: Missing file: wallpaper*.json` /
                // `Couldn't find test file` crashes. (MOB-4384)
                .glob(pattern: "firefox-ios-tests/Tests/ClientTests/**/*.json",
                      excluding: ["firefox-ios-tests/Tests/ClientTests/**/*.xcassets/**"]),
                "firefox-ios-tests/Tests/ClientTests/image.png",
                "firefox-ios-tests/Tests/ClientTests/image.gif",
                "firefox-ios-tests/Tests/ClientTests/Frontend/Browser/SearchEngines/SearchEngineTestAssets.xcassets",
            ],
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
                // Ecosia: ClientTests/Toolbar/ToolbarMiddlewareTests imports ToolbarKit directly.
                // Xcode 26.5's stricter linker no longer resolves ToolbarKit's Swift type metadata
                // transitively via the Client host (-bundle_loader), so the test target must link it. (MOB-4384)
                .package(product: "ToolbarKit"),
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
            settings: .settings(base: BuildConfigurations.testBaseSettings
                .merging(forceLink([.shared]), uniquingKeysWith: { _, new in new })
                .merging([
                    "SWIFT_OBJC_BRIDGING_HEADER": "$SRCROOT/Storage/Storage-Bridging-Header.h",
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
                // Ecosia: Host SharedTests in the Client app so Bundle.main is the .app bundle. The Ecosia
                // UserAgent/SupportUtils tests exercise production code that reads AppInfo.applicationBundle,
                // which fatalErrors when Bundle.main is the bare xctest agent (logic-test host). Depending on the
                // Client app target makes Tuist app-host the test bundle, matching ClientTests/EcosiaTests. (MOB-4384)
                .target(name: "Client"),
                .package(product: "Common"),
                .package(product: "Shared"),
            ],
            settings: .settings(base: BuildConfigurations.testBaseSettings
                .merging(forceLink([.shared]), uniquingKeysWith: { _, new in new })
                .merging([
                    "SWIFT_OBJC_BRIDGING_HEADER": "$SRCROOT/Shared/Shared-Bridging-Header.h",
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
            infoPlist: .default,
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
            // Ecosia (MOB-4384): EcosiaTests calls both Shared API (Maybe/Deferred/succeed, PrefsKeys,
            // MockProfilePrefs, String.asURL) and SnowplowTracker API (Structured, Event,
            // SelfDescribingJson) directly from its mocks and tests. See ``ForceLinkedPackageProduct``.
            settings: .settings(base: BuildConfigurations.testBaseSettings
                .merging(forceLink([.shared, .snowplowTracker]), uniquingKeysWith: { _, new in new }))
        )
    }
}
