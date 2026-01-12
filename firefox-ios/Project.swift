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

// MARK: - Build Scripts

/// Workaround for Xcode validating `MozillaRustComponents.framework` (from SwiftPM) and failing
/// because the embedded framework is missing `Info.plist`.
///
/// We do two things on every build:
/// - Delete any previously embedded `MozillaRustComponents.framework` from the app bundle output,
///   forcing Xcode to re-embed it.
/// - Ensure the SwiftPM artifact slices contain an `Info.plist`, so the re-embedded framework
///   includes it and validation passes (clean + incremental builds).
private let fixMozillaRustComponentsEmbeddingScript: [TargetScript] = [
    .pre(
        script: """
        set -eu

        EMBEDDED_FW="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}/MozillaRustComponents.framework"
        if [ -d "${EMBEDDED_FW}" ]; then
            echo "[Ecosia/Tuist] Removing stale embedded MozillaRustComponents.framework"
            rm -rf "${EMBEDDED_FW}"
        fi

        DERIVED_DATA_DIR="$(dirname "$(dirname "${BUILD_DIR}")")"
        ARTIFACTS_DIR="${DERIVED_DATA_DIR}/SourcePackages/artifacts"
        TEMPLATE_PLIST="${SRCROOT}/Tuist/MozillaRustComponents-Info.plist"

        if [ ! -d "${ARTIFACTS_DIR}" ]; then
            echo "[Ecosia/Tuist] No SwiftPM artifacts dir at ${ARTIFACTS_DIR} (ok)"
            exit 0
        fi
        if [ ! -f "${TEMPLATE_PLIST}" ]; then
            echo "[Ecosia/Tuist] Missing template plist at ${TEMPLATE_PLIST}"
            exit 1
        fi

        FRAMEWORK_DIRS="$(find "${ARTIFACTS_DIR}" -type d -name "MozillaRustComponents.framework" 2>/dev/null || true)"
        if [ -z "${FRAMEWORK_DIRS}" ]; then
            echo "[Ecosia/Tuist] MozillaRustComponents.framework not found in artifacts (ok)"
            exit 0
        fi

        echo "${FRAMEWORK_DIRS}" | while IFS= read -r FRAMEWORK_DIR; do
            INFO_PLIST="${FRAMEWORK_DIR}/Info.plist"
            if [ -f "${INFO_PLIST}" ]; then
                continue
            fi
            echo "[Ecosia/Tuist] Adding Info.plist to artifact slice: ${FRAMEWORK_DIR}"
            cp "${TEMPLATE_PLIST}" "${INFO_PLIST}"
        done
        """,
        name: "Fix MozillaRustComponents embedding",
        basedOnDependencyAnalysis: false
    )
]

// MARK: - Targets

let allTargets: [Target] = [
        // MARK: - Client App
        .target(
            name: "Client",
            destinations: [.iPhone, .iPad],
            product: .app,
            bundleId: "$(MOZ_BUNDLE_ID)",
            infoPlist: .file(path: "Client/Info.plist"),
            sources: [
                .glob("Client/**/*.swift", excluding: [
                    "Client/Assets/Search/get_supported_locales.swift",
                    "Client/Frontend/Browser/FaviconManager.swift",
                    "Client/Frontend/Browser/TranslationToastHandler.swift",
                    "Client/Frontend/Login/LoginViewController.swift",
                    "Client/Frontend/Strings.swift",
                    // Ecosia: Exclude original Firefox files that are replaced by Ecosia versions
                    "Client/Frontend/Home/HomepageSectionType.swift",
                    "Client/Frontend/Home/TopSites/Cell/TopSiteItemCell.swift",
                    "Client/Ecosia/UI/NTP/DefaultBrowser.swift",
                    // Ecosia: Exclude Ecosia override files that are not currently used
                    "Client/Frontend/Widgets/EcosiaTabTrayButtonExtensions.swift",
                    // Ecosia: Exclude outdated color definitions (use Ecosia framework version)
                    "Client/Ecosia/UI/Theme/EcosiaColor.swift",
                    // Exclude new Redux tab management files not yet integrated
                    "Client/Frontend/Browser/Tabs/Action/TabManagerAction.swift",
                    "Client/Frontend/Browser/Tabs/State/TabViewState.swift",
                    // Exclude only PocketViewModel from old Pocket (unused, new one might exist elsewhere)
                    "Client/Frontend/Home/Pocket/PocketViewModel.swift",
                    // Exclude features not yet integrated (Bookmarks, MessageCard, and JumpBackInViewModel)
                    "Client/Frontend/Home/Bookmarks/**",
                    "Client/Frontend/Home/JumpBackIn/JumpBackInViewModel.swift",
                    "Client/Frontend/Home/MessageCard/**",
                    // Exclude unused AppDelegate extension
                    "Client/Application/AppDelegate+PushNotifications.swift"
                ]),
                "Providers/**/*.swift",
                "Extensions/NotificationService/NotificationPayloads.swift",
                "WidgetKit/OpenTabs/SimpleTab.swift",
                "Account/FxAPushMessageHandler.swift",
                "RustFxA/FirefoxAccountSignInViewController.swift",
                "RustFxA/FxAEntryPoint.swift",
                "RustFxA/FxALaunchParams.swift",
                "RustFxA/FxASignInViewParameters.swift",
                "RustFxA/FxAWebViewController.swift",
                "RustFxA/FxAWebViewModel.swift",
                "RustFxA/FxAWebViewTelemetry.swift",
                "Client/**/*.m",
                "Client/**/*.h"
            ],
            resources: [
                "Client/Assets/**/*.{js,css,html,png,jpg,jpeg,pdf,otf,ttf}",
                "Client/Assets/**/*.xcassets",
                .folderReference(path: "Client/Assets/Search/SearchPlugins"),
                "Client/Frontend/**/*.{storyboard,xib,xcassets,strings,stringsdict}",
                "Client/Ecosia/**/*.{xib,xcassets,strings,stringsdict}",
                "Client/*.lproj/**",
                "../ContentBlockingLists/*.json",
            ],
            scripts: fixMozillaRustComponentsEmbeddingScript,
            dependencies: [
                // Target Dependencies
                .target(name: "Sync"),
                .target(name: "Shared"),
                .target(name: "ShareTo"),
                .target(name: "WidgetKitExtension"),
                .target(name: "Ecosia"),
                .target(name: "RustMozillaAppServices"),

                // Link Binary With Libraries
                .package(product: "MozillaAppServices"),
                .package(product: "BrazeUI"),
                .package(product: "BrazeKit"),
                .package(product: "Common"),
                .sdk(name: "AdServices", type: .framework, status: .optional),
                .sdk(name: "iAd", type: .framework),
                .package(product: "ComponentLibrary"),
                .package(product: "SiteImageView"),
                .sdk(name: "SafariServices", type: .framework),
                .sdk(name: "Accelerate", type: .framework),
                .sdk(name: "AuthenticationServices", type: .framework),
                .sdk(name: "xml2", type: .library),
                .package(product: "ToolbarKit"),
                .sdk(name: "z", type: .library),
                .sdk(name: "AdSupport", type: .framework),
                .package(product: "Sentry-Dynamic"),
                .package(product: "Kingfisher"),
                .package(product: "MenuKit"),
                .package(product: "Lottie"),
                .package(product: "Fuzi"),
                .package(product: "Adjust"),
                .sdk(name: "ImageIO", type: .framework),
                .package(product: "Glean"),
                .package(product: "X509"),
                .package(product: "GCDWebServers"),
                .package(product: "TabDataStore"),
                .package(product: "Redux"),
                .package(product: "SnowplowTracker"),
                .sdk(name: "PassKit", type: .framework),
                .package(product: "SnapKit"),
            ],
            settings: .settings(
                base: baseSettings.merging([
                    "SWIFT_OBJC_BRIDGING_HEADER": "$(PROJECT_DIR)/Client/Client-Bridging-Header.h",
                    "HEADER_SEARCH_PATHS": ["$(inherited)", "$(SRCROOT)", "$(SRCROOT)/Client", "$(SRCROOT)/Client/Utils"]
                ], uniquingKeysWith: { _, new in new }),
                configurations: [
                    .debug(name: "Debug", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match Development com.ecosia.ecosiaapp",
                    ], xcconfig: "Client/Configuration/EcosiaDebug.xcconfig"),
                    .debug(name: "BetaDebug", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match Development com.ecosia.ecosiaapp.firefox",
                        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "",
                    ], xcconfig: "Client/Configuration/EcosiaBetaDebug.xcconfig"),
                    .debug(name: "Testing", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match Development com.ecosia.ecosiaapp.firefox",
                    ], xcconfig: "Client/Configuration/EcosiaTesting.xcconfig"),
                    .release(name: "Release", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match AppStore com.ecosia.ecosiaapp",
                        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": ""
                    ], xcconfig: "Client/Configuration/Ecosia.xcconfig"),
                    .release(name: "Development_TestFlight", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match AppStore com.ecosia.ecosiaapp.firefox",
                        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": ""
                    ], xcconfig: "Client/Configuration/Staging.xcconfig"),
                    .release(name: "Development_Firebase", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match AdHoc com.ecosia.ecosiaapp.firefox"
                    ], xcconfig: "Client/Configuration/Staging.xcconfig"),
                ]
            )
        ),

        // MARK: - ShareTo Extension
        .target(
            name: "ShareTo",
            destinations: [.iPhone, .iPad],
            product: .appExtension,
            bundleId: "$(MOZ_BUNDLE_ID).ShareTo",
            infoPlist: .file(path: "Extensions/ShareTo/Info.plist"),
            sources: [
                "Extensions/ShareTo/**/*.swift",
                "Providers/Profile.swift",
                "Providers/RustErrors.swift",
                "Providers/RustSyncManager.swift",
                "Providers/SyncDisplayState.swift",
                "Providers/LoginRecordExtension.swift",
                "Push/Autopush.swift",
                "Push/PushConfiguration.swift",
                "Client/Frontend/Extensions/DevicePickerViewController.swift",
                "Client/Frontend/DevicePickerTableViewCell.swift",
                "Client/Frontend/DevicePickerTableViewHeaderCell.swift",
                "Client/Frontend/HostingTableViewCell.swift",
                "Client/Frontend/InstructionsView.swift",
                "Client/Frontend/HelpView.swift",
                "Client/Frontend/Share/SendToDeviceHelper.swift",
                "Client/Application/AccessibilityIdentifiers.swift",
                "Client/Frontend/Browser/Event Queue/EventQueue.swift",
                "Client/Frontend/Browser/Event Queue/AppEvent.swift",
                "Client/Frontend/Browser/URIFixup.swift",
                "Client/Frontend/Browser/SearchEngines/DefaultSearchEngineProvider.swift",
                "Client/Frontend/Browser/SearchEngines/OpenSearchEngine.swift",
                "Client/Frontend/Browser/SearchEngines/OpenSearchParser.swift",
                "Client/Frontend/Browser/DefaultSearchPrefs.swift",
                "Client/Frontend/Browser/String+Punycode.swift",
                "Client/Extensions/Locale+possibilitiesForLanguageIdentifier.swift",
                "Client/Frontend/Theme/LegacyThemeManager/LegacyTheme.swift",
                "Client/Frontend/Theme/LegacyThemeManager/photon-colors.swift",
                "Client/Utils/DispatchQueueHelper.swift",
                "Client/Application/UIConstants.swift",
                "Client/ImageIdentifiers.swift",
                "Client/Extensions/AnyHashable.swift",
                "Client/Ecosia/UI/Theme/EcosiaThemeManager.swift",
                "Client/Ecosia/UI/Theme/EcosiaLightTheme.swift",
                "Client/Ecosia/UI/Theme/EcosiaDarkTheme.swift"
            ],
            resources: ["Extensions/ShareTo/**/*.{xcassets,strings,stringsdict}"],
            dependencies: [
                // Target Dependencies
                .target(name: "Shared"),
                .target(name: "Sync"),
                .target(name: "Storage"),

                // Link Binary With Libraries
                .package(product: "Fuzi"),
                .target(name: "RustMozillaAppServices"),
                .package(product: "SnapKit"),
                .package(product: "Common"),
                .sdk(name: "ImageIO", type: .framework),
                .package(product: "MozillaAppServices"),
                .package(product: "SiteImageView"),
                .package(product: "GCDWebServers"),
                .package(product: "Kingfisher"),
            ],
            settings: .settings(
                base: baseSettings.merging([
                    "APPLICATION_EXTENSION_API_ONLY": "YES",
                    "OTHER_SWIFT_FLAGS": "$(inherited) -DMOZ_TARGET_SHARETO"
                ], uniquingKeysWith: { _, new in new }),
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
                        "PROVISIONING_PROFILE_SPECIFIER": "match AppStore com.ecosia.ecosiaapp.ShareTo"
                    ], xcconfig: "Client/Configuration/Ecosia.ShareTo.xcconfig"),
                    .release(name: "Development_TestFlight", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match AppStore com.ecosia.ecosiaapp.firefox.ShareTo"
                    ], xcconfig: "Client/Configuration/EcosiaBeta.ShareTo.xcconfig"),
                    .release(name: "Development_Firebase", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match AdHoc com.ecosia.ecosiaapp.firefox.ShareTo"
                    ], xcconfig: "Client/Configuration/EcosiaBeta.ShareTo.xcconfig"),
                ]
            )
        ),

        // MARK: - WidgetKitExtension
        .target(
            name: "WidgetKitExtension",
            destinations: [.iPhone, .iPad],
            product: .appExtension,
            bundleId: "$(MOZ_BUNDLE_ID).WidgetKit",
            infoPlist: .file(path: "WidgetKit/Info.plist"),
            sources: [
                "WidgetKit/**/*.swift",
                "WidgetKit/**/*.intentdefinition",
                "Client/TabManagement/Legacy/LegacyTabDataRetriever.swift",
                "Client/TabManagement/Legacy/LegacyTabFileManager.swift",
                "Client/TabManagement/Legacy/LegacyTabGroupData.swift",
                "Client/TabManagement/Legacy/LegacySavedTab.swift",
                "Client/Frontend/Browser/PrivilegedRequest.swift",
                "Client/ImageIdentifiers.swift",
                "Client/Frontend/InternalSchemeHandler/InternalSchemeHandler.swift",
                "Client/Frontend/Theme/LegacyThemeManager/photon-colors.swift",
                "Client/Ecosia/UI/Theme/EcosiaThemeManager.swift",
                "Client/Ecosia/UI/Theme/EcosiaLightTheme.swift",
                "Client/Ecosia/UI/Theme/EcosiaDarkTheme.swift",
                "Client/Utils/DispatchQueueHelper.swift",
                "Shared/TimeConstants.swift",
                "Shared/AppInfo.swift"
            ],
            resources: [
                "WidgetKit/**/*.{xcassets,strings,stringsdict}",
                "PrivacyInfo.xcprivacy"
            ],
            dependencies: [
                // Target Dependencies
                .target(name: "Shared"),

                // Link Binary With Libraries
                .target(name: "Storage"),
                .target(name: "RustMozillaAppServices"),
                .package(product: "Fuzi"),
                .package(product: "GCDWebServers"),
                .package(product: "Common"),
                .package(product: "TabDataStore"),
                .sdk(name: "WidgetKit", type: .framework),
                .package(product: "SiteImageView"),
                .sdk(name: "SwiftUI", type: .framework),
                .package(product: "MozillaAppServices"),
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
                        "PROVISIONING_PROFILE_SPECIFIER": "match AppStore com.ecosia.ecosiaapp.WidgetKit"
                    ], xcconfig: "Client/Configuration/Ecosia.WidgetKit.xcconfig"),
                    .release(name: "Development_TestFlight", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match AppStore com.ecosia.ecosiaapp.firefox.WidgetKit"
                    ], xcconfig: "Client/Configuration/EcosiaBeta.WidgetKit.xcconfig"),
                    .release(name: "Development_Firebase", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match AdHoc com.ecosia.ecosiaapp.firefox.WidgetKit"
                    ], xcconfig: "Client/Configuration/EcosiaBeta.WidgetKit.xcconfig"),
                ]
            )
        ),

        // MARK: - Account Framework
        .target(
            name: "Account",
            destinations: .iOS,
            product: .staticLibrary,
            bundleId: "org.mozilla.ios.Account",
            infoPlist: .file(path: "Account/Info.plist"),
            sources: [
                "RustFxA/Avatar.swift",
                "RustFxA/PushNotificationSetup.swift",
                "RustFxA/RustFirefoxAccounts.swift",
                "Client/GeneralizedImageFetcher.swift",
                "Client/ImageIdentifiers.swift",
                "Push/Autopush.swift",
                "Push/PushConfiguration.swift",
                "Client/Telemetry/ReferringPage.swift"
            ],
            dependencies: [
                // Target Dependencies
                .target(name: "Storage"),
                .target(name: "Shared"),

                // Link Binary With Libraries
                .package(product: "GCDWebServers"),
            ],
            settings: .settings(base: baseSettings.merging([
                "ALWAYS_SEARCH_USER_PATHS": "YES",
                "DEFINES_MODULE": "YES",
                "HEADER_SEARCH_PATHS": [
                    "$(inherited)",
                    "$(SRCROOT)",
                    "$(SDKROOT)/usr/include/libxml2",
                    "ThirdParty/ecec/include/**",
                    "FxA/FxA/include"
                ],
                "LIBRARY_SEARCH_PATHS": [
                    "$(inherited)",
                    "$(PROJECT_DIR)/FxA/FxA/lib"
                ],
                "SWIFT_OBJC_BRIDGING_HEADER": "$SRCROOT/Account/Account-Bridging-Header.h"
            ], uniquingKeysWith: { _, new in new }))
        ),

        // MARK: - Storage Framework
        .target(
            name: "Storage",
            destinations: .iOS,
            product: .staticLibrary,
            bundleId: "org.mozilla.ios.Storage",
            infoPlist: .file(path: "Storage/Info.plist"),
            sources: ["Storage/**/*.swift"],
            resources: ["Storage/**/*.{xcdatamodeld,sql,html,js}"],
            dependencies: [
                // Target Dependencies
                .target(name: "Shared"),
                .target(name: "Ecosia"),

                // Link Binary With Libraries
                .package(product: "SiteImageView"),
                .package(product: "GCDWebServers"),
                .package(product: "Common"),
                .package(product: "Kingfisher"),
            ],
            settings: .settings(base: baseSettings.merging([
                "DEFINES_MODULE": "YES",
                "SKIP_INSTALL": "YES",
                "VALIDATE_WORKSPACE": "YES",
                "HEADER_SEARCH_PATHS": [
                    "$(inherited)",
                    "$(SRCROOT)/Shared",
                    "$(SRCROOT)/Client",
                    "$(SRCROOT)/Client/Frontend/Reader/Resources",
                    "$(SRCROOT)/ThirdParty/Apple",
                    "$(SRCROOT)/Account",
                    "$(SRCROOT)/Storage"
                ],
                "SWIFT_OBJC_BRIDGING_HEADER": "$SRCROOT/Storage/Storage-Bridging-Header.h"
            ], uniquingKeysWith: { _, new in new }))
        ),

        // MARK: - Shared Framework
        .target(
            name: "Shared",
            destinations: .iOS,
            product: .framework,
            bundleId: "org.mozilla.ios.Shared",
            infoPlist: .file(path: "Shared/Supporting Files/Info.plist"),
            sources: [
                "Shared/**/*.swift",
                "Shared/**/*.m",
                "Client/Frontend/Strings.swift",
                "ThirdParty/Deferred/Deferred/*.swift",
                "ThirdParty/Reachability.swift",
                "ThirdParty/Result/*.swift"
            ],
            resources: ["Shared/**/*.{strings,stringsdict}"],
            dependencies: [
                // Target Dependencies
                .target(name: "Ecosia"),
                .target(name: "RustMozillaAppServices"),

                // Link Binary With Libraries
                .package(product: "WebEngine"),
                .package(product: "GCDWebServers"),
                .package(product: "Common"),
                .package(product: "MozillaAppServices"),
            ],
            settings: .settings(
                base: baseSettings.merging([
                    "APPLICATION_EXTENSION_API_ONLY": "YES",
                    "DEFINES_MODULE": "YES",
                    "CLANG_ENABLE_MODULES": "YES",
                    "GCC_TREAT_WARNINGS_AS_ERRORS": "NO",
                    "GCC_WARN_INHIBIT_ALL_WARNINGS": "YES",
                    "SWIFT_OBJC_BRIDGING_HEADER": "$SRCROOT/Shared/Shared-Bridging-Header.h"
                ], uniquingKeysWith: { _, new in new })
            )
        ),

        // MARK: - Sync Framework
        .target(
            name: "Sync",
            destinations: .iOS,
            product: .framework,
            bundleId: "org.mozilla.ios.Sync",
            infoPlist: .file(path: "Sync/Info.plist"),
            sources: ["Sync/**/*.swift"],
            dependencies: [
                // Target Dependencies
                .target(name: "Account"),
                .target(name: "Shared"),
                .target(name: "RustMozillaAppServices"),

                // Link Binary With Libraries
                .package(product: "Fuzi"),
                .package(product: "SiteImageView"),
                .target(name: "Storage"),
                .package(product: "Common"),
                .package(product: "MozillaAppServices"),
            ],
            settings: .settings(base: baseSettings.merging([
                "APPLICATION_EXTENSION_API_ONLY": "YES",
                "DEFINES_MODULE": "YES",
                "GCC_TREAT_WARNINGS_AS_ERRORS": "NO",
                "GCC_WARN_INHIBIT_ALL_WARNINGS": "YES",
                "SWIFT_OBJC_BRIDGING_HEADER": "$SRCROOT/Sync/Sync-Bridging-Header.h"
            ], uniquingKeysWith: { _, new in new }))
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
                "Ecosia/L10N/**/*.{strings,stringsdict}",
                "Ecosia/UI/**/*.{xcassets,lottie}",
                "Ecosia/markets.json",
                "Ecosia/Ecosia.docc/**",
            ],
            dependencies: [
                // Link Binary With Libraries
                .package(product: "SnowplowTracker"),
                .package(product: "BrazeKit"),
                .package(product: "BrazeUI"),
                .package(product: "Common"),
                .package(product: "SwiftSoup"),
                .package(product: "Auth0"),
                .package(product: "Lottie"),
                .sdk(name: "Foundation", type: .framework),
                .sdk(name: "UIKit", type: .framework),
                .sdk(name: "SwiftUI", type: .framework)
            ],
            settings: .settings(
                base: baseSettings.merging([
                    "DEFINES_MODULE": "YES",
                    "CLANG_ENABLE_MODULES": "YES",
                    "SKIP_INSTALL": "YES",
                    "SWIFT_EMIT_LOC_STRINGS": "YES",
                    "SWIFT_INSTALL_OBJC_HEADER": "NO",
                    "SWIFT_VERSION": "5.0"
                ], uniquingKeysWith: { _, new in new })
            )
        ),

        // MARK: - RustMozillaAppServices Framework
        // Ecosia: Wrapper framework to re-export MozillaAppServices and avoid direct linking
        // from multiple targets (which would embed MozillaRustComponents multiple times)
        .target(
            name: "RustMozillaAppServices",
            destinations: .iOS,
            product: .framework,
            bundleId: "org.mozilla.ios.RustMozillaAppServices",
            infoPlist: .file(path: "RustMozillaAppServices-Info.plist"),
            sources: ["Tuist/RustMozillaAppServices.swift"],
            dependencies: [
                // Link Binary With Libraries
                .package(product: "MozillaAppServices"),
            ],
            settings: .settings(base: baseSettings.merging([
                "APPLICATION_EXTENSION_API_ONLY": "YES",
                "DEFINES_MODULE": "YES",
                "GCC_WARN_INHIBIT_ALL_WARNINGS": "YES"
            ], uniquingKeysWith: { _, new in new }))
        ),

        // MARK: - AccountTests
        .target(
            name: "AccountTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "org.mozilla.ios.AccountTests",
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
            settings: .settings(base: baseSettings.merging([
                "SWIFT_OBJC_BRIDGING_HEADER": "$SRCROOT/Account/Account-Bridging-Header.h"
            ], uniquingKeysWith: { _, new in new }))
        ),

        // MARK: - ClientTests
        .target(
            name: "ClientTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "org.mozilla.ios.ClientTests",
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
            settings: .settings(base: baseSettings)
        ),

        // MARK: - StorageTests
        .target(
            name: "StorageTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "org.mozilla.ios.StorageTests",
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
            settings: .settings(base: baseSettings.merging([
                "SWIFT_OBJC_BRIDGING_HEADER": "$SRCROOT/Storage/Storage-Bridging-Header.h"
            ], uniquingKeysWith: { _, new in new }))
        ),

        // MARK: - SharedTests
        .target(
            name: "SharedTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "org.mozilla.ios.SharedTests",
            infoPlist: .default,
            sources: ["firefox-ios-tests/Tests/SharedTests/**/*.swift"],
            settings: .settings(base: baseSettings.merging([
                "SWIFT_OBJC_BRIDGING_HEADER": "$SRCROOT/Shared/Shared-Bridging-Header.h"
            ], uniquingKeysWith: { _, new in new }))
        ),

        // MARK: - SyncTelemetryTests
        .target(
            name: "SyncTelemetryTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "org.mozilla.ios.SyncTelemetryTests",
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
            bundleId: "org.mozilla.ios.SyncTests",
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
            settings: .settings(base: baseSettings.merging([
                "SWIFT_OBJC_BRIDGING_HEADER": "$SRCROOT/firefox-ios-tests/Tests/SyncTests/SyncTests-Bridging-Header.h"
            ], uniquingKeysWith: { _, new in new }))
        ),

        // MARK: - L10nSnapshotTests
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
]

// MARK: - Schemes

let allSchemes: [Scheme] = [
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
                configuration: "BetaDebug",
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
    targets: allTargets,
    schemes: allSchemes
)
