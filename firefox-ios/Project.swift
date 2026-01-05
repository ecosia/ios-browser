import ProjectDescription

// MARK: - Build Configurations

private let buildConfigurations: [Configuration] = [
    .debug(name: "Debug", xcconfig: "Client/Configuration/EcosiaDebug.xcconfig"),
    .debug(name: "BetaDebug", xcconfig: "Client/Configuration/EcosiaBetaDebug.xcconfig"),
    .debug(name: "Testing", xcconfig: "Client/Configuration/EcosiaTesting.xcconfig"),
    .release(name: "Release", xcconfig: "Client/Configuration/Ecosia.xcconfig"),
    .release(name: "Development_TestFlight", xcconfig: "Client/Configuration/EcosiaBeta.xcconfig"),
    .release(name: "Development_Firebase", xcconfig: "Client/Configuration/EcosiaBeta.xcconfig"),
]

// MARK: - Base Settings
// Note: Most settings are defined in xcconfig files (source of truth)
// Only minimal settings that can't be in xcconfig are defined here

private let baseSettings: SettingsDictionary = [:]

// MARK: - Swift Package Dependencies

private let packages: [Package] = [
    .local(path: "../BrowserKit"),
    .remote(url: "https://github.com/auth0/Auth0.swift.git", requirement: .upToNextMajor(from: "2.0.0")),
    .remote(url: "https://github.com/braze-inc/braze-swift-sdk.git", requirement: .upToNextMajor(from: "11.9.0")),
    .remote(url: "https://github.com/airbnb/lottie-ios.git", requirement: .exact("4.4.0")),
    .remote(url: "https://github.com/scinfu/SwiftSoup.git", requirement: .exact("2.5.3")),
    .remote(url: "https://github.com/mozilla/glean-swift.git", requirement: .exact("61.2.0")),
    .remote(url: "https://github.com/snowplow/snowplow-ios-tracker.git", requirement: .upToNextMinor(from: "6.0.9")),
    .remote(url: "https://github.com/auth0/SimpleKeychain.git", requirement: .upToNextMajor(from: "1.3.0")),
    .remote(url: "https://github.com/auth0/JWTDecode.swift.git", requirement: .upToNextMajor(from: "3.3.0")),
    .remote(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", requirement: .upToNextMajor(from: "1.18.7")),
    .remote(url: "https://github.com/nalexn/ViewInspector.git", requirement: .upToNextMajor(from: "0.10.1")),
    .remote(url: "https://github.com/pointfreeco/xctest-dynamic-overlay.git", requirement: .upToNextMajor(from: "1.5.1")),
    .remote(url: "https://github.com/pointfreeco/swift-custom-dump.git", requirement: .upToNextMajor(from: "1.3.3")),
    .remote(url: "https://github.com/kif-framework/KIF.git", requirement: .exact("3.8.9")),
    .remote(url: "https://github.com/adjust/ios_sdk.git", requirement: .exact("4.37.0")),
    .remote(url: "https://github.com/SnapKit/SnapKit.git", requirement: .exact("5.7.0")),
    .remote(url: "https://github.com/nbhasin2/Fuzi.git", requirement: .branch("master")),
    .remote(url: "https://github.com/nbhasin2/GCDWebServer.git", requirement: .branch("master")),
    .remote(url: "https://github.com/getsentry/sentry-cocoa.git", requirement: .exact("8.36.0")),
    .remote(url: "https://github.com/onevcat/Kingfisher.git", requirement: .exact("7.12.0")),
    .remote(url: "https://github.com/apple/swift-certificates.git", requirement: .exact("1.2.0")),
    .remote(url: "https://github.com/mozilla-mobile/MappaMundi.git", requirement: .branch("master")),
    .remote(url: "https://github.com/ecosia/rust-components-swift.git", requirement: .branch("133.0.0_Glean_removed")),
]

// MARK: - Project

let project = Project(
    name: "Client",
    organizationName: "com.ecosia",
    options: .options(
        automaticSchemesOptions: .disabled,
        disableSynthesizedResourceAccessors: true
    ),
    packages: packages,
    settings: .settings(configurations: buildConfigurations),
    targets: [
        // MARK: - Client App
        .target(
            name: "Client",
            destinations: [.iPhone, .iPad],
            product: .app,
            bundleId: "$(MOZ_BUNDLE_ID)",
            infoPlist: .file(path: "Client/Info.plist"),
            sources: ["Client/**/*.swift"],
            resources: [
                "Client/Assets/**/*.{js,css,html,png,jpg,jpeg,pdf,otf,ttf}",
                "Client/Assets/**/*.xcassets",
                "Client/Frontend/**/*.{storyboard,xib,xcassets,strings,stringsdict}",
                "Client/*.lproj/**",
            ],
            dependencies: [
                .target(name: "Account"),
                .target(name: "Shared"),
                .target(name: "Storage"),
                .target(name: "Sync"),
                .target(name: "Ecosia", condition: .when([.ios])),
                .target(name: "RustMozillaAppServices", condition: .when([.ios])),
                .target(name: "ShareTo"),
                .target(name: "WidgetKitExtension"),
                .package(product: "Adjust"),
                .package(product: "BrazeKit"),
                .package(product: "BrazeUI"),
                .package(product: "Common"),
                .package(product: "ComponentLibrary"),
                .package(product: "Fuzi"),
                .package(product: "GCDWebServers"),
                .package(product: "Glean"),
                .package(product: "Kingfisher"),
                .package(product: "Lottie"),
                .package(product: "MenuKit"),
                .package(product: "Redux"),
                .package(product: "Sentry-Dynamic"),
                .package(product: "SiteImageView"),
                .package(product: "TabDataStore"),
                .package(product: "ToolbarKit"),
                .package(product: "WebEngine"),
                .package(product: "X509"),
                .sdk(name: "Accelerate", type: .framework),
                .sdk(name: "AdServices", type: .framework),
                .sdk(name: "AdSupport", type: .framework),
                .sdk(name: "AuthenticationServices", type: .framework),
                .sdk(name: "ImageIO", type: .framework),
                .sdk(name: "PassKit", type: .framework),
                .sdk(name: "SafariServices", type: .framework),
                .sdk(name: "libxml2.2", type: .library),
                .sdk(name: "libz", type: .library),
            ],
            settings: .settings(
                base: baseSettings,
                configurations: [
                    .debug(name: "Debug", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match Development com.ecosia.ecosiaapp"
                    ], xcconfig: "Client/Configuration/EcosiaDebug.xcconfig"),
                    .debug(name: "BetaDebug", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match Development com.ecosia.ecosiaapp.firefox"
                    ], xcconfig: "Client/Configuration/EcosiaBetaDebug.xcconfig"),
                    .debug(name: "Testing", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match Development com.ecosia.ecosiaapp.firefox"
                    ], xcconfig: "Client/Configuration/EcosiaTesting.xcconfig"),
                    .release(name: "Release", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match Development com.ecosia.ecosiaapp"
                    ], xcconfig: "Client/Configuration/Ecosia.xcconfig"),
                    .release(name: "Development_TestFlight", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match Development com.ecosia.ecosiaapp.firefox"
                    ], xcconfig: "Client/Configuration/Staging.xcconfig"),
                    .release(name: "Development_Firebase", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match Development com.ecosia.ecosiaapp.firefox"
                    ], xcconfig: "Client/Configuration/Staging.xcconfig"),
                ]
            )
        ),
        
        // MARK: - ShareTo Extension
        .target(
            name: "ShareTo",
            destinations: [.iPhone, .iPad],
            product: .appExtension,
            bundleId: "com.ecosia.ecosiaapp.ShareTo",
            infoPlist: .file(path: "Extensions/ShareTo/Info.plist"),
            sources: ["Extensions/ShareTo/**/*.swift"],
            resources: ["Extensions/ShareTo/**/*.{xcassets,strings,stringsdict}"],
            dependencies: [
                .target(name: "Shared"),
                .target(name: "Sync"),
                .package(product: "Common"),
                .package(product: "Fuzi"),
                .package(product: "GCDWebServers"),
                .package(product: "SiteImageView"),
                .package(product: "SnapKit"),
                .package(product: "TabDataStore"),
                .sdk(name: "ImageIO", type: .framework),
            ],
            settings: .settings(
                base: baseSettings.merging(["APPLICATION_EXTENSION_API_ONLY": "YES"], uniquingKeysWith: { _, new in new }),
                configurations: [
                    .debug(name: "Debug", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match Development com.ecosia.ecosiaapp.ShareTo"
                    ], xcconfig: "Client/Configuration/EcosiaDebug.ShareTo.xcconfig"),
                    .debug(name: "BetaDebug", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match Development com.ecosia.ecosiaapp.ShareTo"
                    ], xcconfig: "Client/Configuration/EcosiaBetaDebug.ShareTo.xcconfig"),
                    .debug(name: "Testing", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match Development com.ecosia.ecosiaapp.ShareTo"
                    ], xcconfig: "Client/Configuration/EcosiaTesting.ShareTo.xcconfig"),
                    .release(name: "Release", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match Development com.ecosia.ecosiaapp.ShareTo"
                    ], xcconfig: "Client/Configuration/Ecosia.ShareTo.xcconfig"),
                    .release(name: "Development_TestFlight", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match Development com.ecosia.ecosiaapp.ShareTo"
                    ], xcconfig: "Client/Configuration/EcosiaBeta.ShareTo.xcconfig"),
                    .release(name: "Development_Firebase", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match Development com.ecosia.ecosiaapp.ShareTo"
                    ], xcconfig: "Client/Configuration/EcosiaBeta.ShareTo.xcconfig"),
                ]
            )
        ),
        
        // MARK: - WidgetKitExtension
        .target(
            name: "WidgetKitExtension",
            destinations: [.iPhone, .iPad],
            product: .appExtension,
            bundleId: "com.ecosia.ecosiaapp.WidgetKit",
            infoPlist: .file(path: "WidgetKit/Info.plist"),
            sources: ["WidgetKit/**/*.swift"],
            resources: ["WidgetKit/**/*.{xcassets,strings,stringsdict,intentdefinition}"],
            dependencies: [
                .target(name: "Storage"),
                .package(product: "Common"),
                .package(product: "Fuzi"),
                .package(product: "GCDWebServers"),
                .package(product: "SiteImageView"),
                .package(product: "TabDataStore"),
                .sdk(name: "SwiftUI", type: .framework),
                .sdk(name: "WidgetKit", type: .framework),
            ],
            settings: .settings(
                base: baseSettings.merging(["APPLICATION_EXTENSION_API_ONLY": "YES"], uniquingKeysWith: { _, new in new }),
                configurations: [
                    .debug(name: "Debug", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match Development com.ecosia.ecosiaapp.WidgetKit"
                    ], xcconfig: "Client/Configuration/EcosiaDebug.WidgetKit.xcconfig"),
                    .debug(name: "BetaDebug", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match Development com.ecosia.ecosiaapp.WidgetKit"
                    ], xcconfig: "Client/Configuration/EcosiaBetaDebug.WidgetKit.xcconfig"),
                    .debug(name: "Testing", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match Development com.ecosia.ecosiaapp.WidgetKit"
                    ], xcconfig: "Client/Configuration/EcosiaTesting.WidgetKit.xcconfig"),
                    .release(name: "Release", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match Development com.ecosia.ecosiaapp.WidgetKit"
                    ], xcconfig: "Client/Configuration/Ecosia.WidgetKit.xcconfig"),
                    .release(name: "Development_TestFlight", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match Development com.ecosia.ecosiaapp.WidgetKit"
                    ], xcconfig: "Client/Configuration/EcosiaBeta.WidgetKit.xcconfig"),
                    .release(name: "Development_Firebase", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match Development com.ecosia.ecosiaapp.WidgetKit"
                    ], xcconfig: "Client/Configuration/EcosiaBeta.WidgetKit.xcconfig"),
                ]
            )
        ),
        
        // MARK: - Account Framework
        .target(
            name: "Account",
            destinations: .iOS,
            product: .staticLibrary,
            bundleId: "com.ecosia.framework.Account",
            infoPlist: .file(path: "Account/Info.plist"),
            sources: ["Account/**/*.swift"],
            dependencies: [
                .package(product: "Common"),
                .package(product: "Fuzi"),
                .package(product: "GCDWebServers"),
                .package(product: "SiteImageView"),
                .package(product: "TabDataStore"),
            ],
            settings: .settings(base: baseSettings)
        ),
        
        // MARK: - Storage Framework
        .target(
            name: "Storage",
            destinations: .iOS,
            product: .staticLibrary,
            bundleId: "com.ecosia.framework.Storage",
            infoPlist: .file(path: "Storage/Info.plist"),
            sources: ["Storage/**/*.swift"],
            resources: ["Storage/**/*.{xcdatamodeld,sql,html,js}"],
            dependencies: [
                .package(product: "Common"),
                .package(product: "Fuzi"),
                .package(product: "GCDWebServers"),
                .package(product: "SiteImageView"),
                .package(product: "TabDataStore"),
            ],
            settings: .settings(base: baseSettings)
        ),
        
        // MARK: - Shared Framework
        .target(
            name: "Shared",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.ecosia.framework.Shared",
            infoPlist: .default,
            sources: ["Shared/**/*.swift"],
            resources: ["Shared/**/*.{strings,stringsdict}"],
            dependencies: [
                .package(product: "Common"),
                .package(product: "Fuzi"),
                .package(product: "GCDWebServers"),
                .package(product: "SiteImageView"),
                .package(product: "TabDataStore"),
            ],
            settings: .settings(
                base: baseSettings.merging([
                    "DEFINES_MODULE": "YES",
                    "CLANG_ENABLE_MODULES": "YES"
                ], uniquingKeysWith: { _, new in new })
            )
        ),
        
        // MARK: - Sync Framework
        .target(
            name: "Sync",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.ecosia.framework.Sync",
            infoPlist: .file(path: "Sync/Info.plist"),
            sources: ["Sync/**/*.swift"],
            dependencies: [
                .target(name: "Account"),
                .target(name: "Storage"),
                .package(product: "Common"),
                .package(product: "Fuzi"),
                .package(product: "GCDWebServers"),
                .package(product: "SiteImageView"),
                .package(product: "TabDataStore"),
            ],
            settings: .settings(base: baseSettings)
        ),
        
        // MARK: - Ecosia Framework
        .target(
            name: "Ecosia",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.ecosia.framework.Ecosia",
            infoPlist: .file(path: "Ecosia/Info.plist"),
            sources: [
                "Ecosia/**/*.swift",
                "Ecosia/**/*.h",
            ],
            resources: [
                "Ecosia/L10N/**",
                "Ecosia/UI/**/*.{xcassets,lottie}",
                "Ecosia/markets.json",
                "Ecosia/Ecosia.docc/**",
            ],
            dependencies: [
                .package(product: "Auth0"),
                .package(product: "BrazeKit"),
                .package(product: "BrazeUI"),
                .package(product: "Common"),
                .package(product: "Lottie"),
                .package(product: "SwiftSoup"),
                .package(product: "SnowplowTracker")
            ],
            settings: .settings(
                base: baseSettings.merging([
                    "DEFINES_MODULE": "YES",
                    "CLANG_ENABLE_MODULES": "YES"
                ], uniquingKeysWith: { _, new in new })
            )
        ),
        
        // MARK: - RustMozillaAppServices Framework
        .target(
            name: "RustMozillaAppServices",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.ecosia.framework.RustMozillaAppServices",
            infoPlist: .file(path: "RustMozillaAppServices-Info.plist"),
            sources: ["RustFxA/**/*.swift"],
            dependencies: [
                .package(product: "MozillaAppServices"),
            ],
            settings: .settings(base: baseSettings)
        ),
        
        // MARK: - AccountTests
        .target(
            name: "AccountTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.ecosia.tests.Account",
            infoPlist: .default,
            sources: ["firefox-ios-tests/Tests/AccountTests/**/*.swift"],
            dependencies: [
                .target(name: "Account"),
                .package(product: "Common"),
                .package(product: "Fuzi"),
                .package(product: "GCDWebServers"),
                .package(product: "SiteImageView"),
                .package(product: "TabDataStore"),
            ],
            settings: .settings(base: baseSettings)
        ),
        
        // MARK: - ClientTests
        .target(
            name: "ClientTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.ecosia.tests.Client",
            infoPlist: .default,
            sources: ["firefox-ios-tests/Tests/ClientTests/**/*.swift"],
            dependencies: [
                .target(name: "Client"),
                .package(product: "Common"),
                .package(product: "Fuzi"),
                .package(product: "GCDWebServers"),
                .package(product: "SiteImageView"),
                .package(product: "TabDataStore"),
            ],
            settings: .settings(base: baseSettings)
        ),
        
        // MARK: - StoragePerfTests
        .target(
            name: "StoragePerfTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.ecosia.tests.StoragePerf",
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
            settings: .settings(base: baseSettings)
        ),
        
        // MARK: - StorageTests
        .target(
            name: "StorageTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.ecosia.tests.Storage",
            infoPlist: .default,
            sources: ["firefox-ios-tests/Tests/StorageTests/**/*.swift"],
            dependencies: [
                .target(name: "Storage"),
                .package(product: "Common"),
                .package(product: "Fuzi"),
                .package(product: "GCDWebServers"),
                .package(product: "SiteImageView"),
                .package(product: "TabDataStore"),
            ],
            settings: .settings(base: baseSettings)
        ),
        
        // MARK: - SharedTests
        .target(
            name: "SharedTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.ecosia.tests.Shared",
            infoPlist: .default,
            sources: ["firefox-ios-tests/Tests/SharedTests/**/*.swift"],
            settings: .settings(base: baseSettings)
        ),
        
        // MARK: - SyncTelemetryTests
        .target(
            name: "SyncTelemetryTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.ecosia.tests.SyncTelemetry",
            infoPlist: .default,
            sources: ["firefox-ios-tests/Tests/SyncTelemetryTests/**/*.swift"],
            dependencies: [
                .package(product: "Glean"),
            ],
            settings: .settings(base: baseSettings)
        ),
        
        // MARK: - SyncTests
        .target(
            name: "SyncTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.ecosia.tests.Sync",
            infoPlist: .default,
            sources: ["firefox-ios-tests/Tests/SyncTests/**/*.swift"],
            dependencies: [
                .target(name: "Sync"),
                .package(product: "Common"),
                .package(product: "Fuzi"),
                .package(product: "GCDWebServers"),
                .package(product: "SiteImageView"),
                .package(product: "TabDataStore"),
            ],
            settings: .settings(base: baseSettings)
        ),
        
        // MARK: - L10nSnapshotTests
        .target(
            name: "L10nSnapshotTests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "com.ecosia.tests.L10nSnapshot",
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
            settings: .settings(base: baseSettings)
        ),
        
        // MARK: - EcosiaSnapshotTests
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
            settings: .settings(base: baseSettings)
        ),
        
        // MARK: - EcosiaTests
        .target(
            name: "EcosiaTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.ecosia.tests.Ecosia",
            infoPlist: .default,
            sources: [
                "EcosiaTests/*.swift",
                "EcosiaTests/Mocks/**/*.swift",
                "EcosiaTests/UI/**/*.swift",
                "EcosiaTests/Core/**/*.swift",
                "EcosiaTests/IntegrationTests/**/*.swift",
            ],
            dependencies: [
                .target(name: "Ecosia"),
                .package(product: "Common"),
                .package(product: "Fuzi"),
                .package(product: "GCDWebServers"),
                .package(product: "SiteImageView"),
                .package(product: "SnowplowTracker"),
                .package(product: "TabDataStore"),
                .package(product: "ViewInspector"),
            ],
            settings: .settings(base: baseSettings)
        ),
    ],
    schemes: [
        .scheme(
            name: "Ecosia",
            buildAction: .buildAction(targets: ["Client"]),
            runAction: .runAction(
                executable: "Client",
                arguments: .arguments(environmentVariables: [
                    "OS_ACTIVITY_MODE": .environmentVariable(value: "${DEBUG_ACTIVITY_MODE}", isEnabled: true),
                    "DYLD_PRINT_STATISTICS": .environmentVariable(value: "1", isEnabled: true)
                ])
            )
        ),
        .scheme(
            name: "EcosiaBeta",
            buildAction: .buildAction(targets: ["Client"]),
            runAction: .runAction(
                executable: "Client",
                arguments: .arguments(environmentVariables: [
                    "OS_ACTIVITY_MODE": .environmentVariable(value: "${DEBUG_ACTIVITY_MODE}", isEnabled: true)
                ])
            )
        ),
        .scheme(
            name: "EcosiaSnapshotTests",
            buildAction: .buildAction(targets: ["EcosiaSnapshotTests"]),
            testAction: .targets(
                ["EcosiaSnapshotTests"],
                configuration: .debug
            ),
            runAction: .runAction(executable: "Client")
        ),
    ]
)
