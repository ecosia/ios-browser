import ProjectDescription

/// Framework and static library targets: Account, Storage, Sync, Localizations, Ecosia, RustMozillaAppServices.
public enum FrameworkTargets {

    public static func all() -> [Target] {
        [
            account(),
            storage(),
            sync(),
            localizations(),
            ecosia(),
            rustMozillaAppServices(),
        ]
    }

    static func account() -> Target {
        .target(
            name: "Account",
            destinations: .iOS,
            product: .staticLibrary,
            bundleId: "org.mozilla.ios.Account",
            infoPlist: .file(path: "Account/Info.plist"),
            sources: [
                "Account/Info.plist",
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
                .package(product: "Common"),
                .package(product: "GCDWebServers"),
                .sdk(name: "RustMozillaAppServices", type: .framework),
                .package(product: "Shared"),
                .target(name: "Storage"),
            ],
            settings: .settings(base: BuildConfigurations.baseSettings.merging([
                "ALWAYS_SEARCH_USER_PATHS": "YES",
                "DEFINES_MODULE": "YES",
                "HEADER_SEARCH_PATHS": [
                    "$(inherited)",
                    "$(SRCROOT)",
                    "$(SDKROOT)/usr/include/libxml2",
                    "ThirdParty/Apple",
                    "ThirdParty/ecec/include/**",
                    "FxA/FxA/include"
                ],
                "LIBRARY_SEARCH_PATHS": [
                    "$(inherited)",
                    "$(PROJECT_DIR)/FxA/FxA/lib"
                ],
                "SWIFT_OBJC_BRIDGING_HEADER": "$SRCROOT/Account/Account-Bridging-Header.h"
            ], uniquingKeysWith: { _, new in new }))
        )
    }

    static func storage() -> Target {
        .target(
            name: "Storage",
            destinations: .iOS,
            product: .staticLibrary,
            bundleId: "org.mozilla.ios.Storage",
            infoPlist: .file(path: "Storage/Info.plist"),
            sources: [
                "Storage/**/*.swift",
                "Shared/FSUtils.h",
                "Shared/FSUtils.m"
            ],
            resources: ["Storage/**/*.{xcdatamodeld,sql,html,js}"],
            dependencies: [
                .package(product: "Common"),
                .package(product: "GCDWebServers"),
                .package(product: "Kingfisher"),
                .target(name: "Localizations"),
                .sdk(name: "RustMozillaAppServices", type: .framework),
                .package(product: "Shared"),
                .package(product: "SiteImageView"),
            ],
            settings: .settings(base: BuildConfigurations.baseSettings.merging([
                "DEFINES_MODULE": "YES",
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
        )
    }

    static func sync() -> Target {
        .target(
            name: "Sync",
            destinations: .iOS,
            product: .framework,
            bundleId: "org.mozilla.ios.Sync",
            infoPlist: .file(path: "Sync/Info.plist"),
            sources: ["Sync/**/*.swift"],
            dependencies: [
                .target(name: "Account"),
                .package(product: "Common"),
                .package(product: "Fuzi"),
                .target(name: "Storage"),
                .target(name: "Localizations"),
                .sdk(name: "RustMozillaAppServices", type: .framework),
                .package(product: "Shared"),
                .package(product: "SiteImageView"),
            ],
            settings: .settings(base: BuildConfigurations.baseSettings.merging([
                "APPLICATION_EXTENSION_API_ONLY": "YES",
                "DEFINES_MODULE": "YES",
                "GCC_TREAT_WARNINGS_AS_ERRORS": "NO",
                "GCC_WARN_INHIBIT_ALL_WARNINGS": "YES",
                "SWIFT_OBJC_BRIDGING_HEADER": "$SRCROOT/Sync/Sync-Bridging-Header.h"
            ], uniquingKeysWith: { _, new in new }))
        )
    }

    static func localizations() -> Target {
        .target(
            name: "Localizations",
            destinations: .iOS,
            product: .framework,
            bundleId: "org.mozilla.ios.Localizations",
            infoPlist: .file(path: "Shared/Supporting Files/Info.plist"),
            sources: [
                "Shared/Strings.swift",
                "Shared/DeviceInfo+defaultClientName.swift",
                "Shared/Date+relativeTimeString.swift"
            ],
            resources: ["Localizations/**/*.{strings,stringsdict}"],
            dependencies: [
                .package(product: "Common"),
                .package(product: "GCDWebServers"),
                .package(product: "Shared"),
                .package(product: "WebEngine")
            ],
            settings: .settings(base: BuildConfigurations.baseSettings.merging([
                "DEFINES_MODULE": "YES",
                "GENERATE_INFOPLIST_FILE": "YES"
            ], uniquingKeysWith: { _, new in new }))
        )
    }

    static func ecosia() -> Target {
        .target(
            name: "Ecosia",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.ecosia.framework.Ecosia",
            infoPlist: .file(path: "Ecosia/Info.plist"),
            sources: [
                "Ecosia/**/*.{h,swift}",
                "Ecosia/**/*.h"
            ],
            resources: [
                "Ecosia/L10N/**/*.{strings,stringsdict}",
                "Ecosia/UI/**/*.{xcassets,lottie}",
                "Ecosia/markets.json",
                "Ecosia/Ecosia.docc/**",
            ],
            dependencies: [
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
                base: BuildConfigurations.baseSettings.merging([
                    "DEFINES_MODULE": "YES",
                    "CLANG_ENABLE_MODULES": "YES",
                    "SWIFT_EMIT_LOC_STRINGS": "YES",
                    "SWIFT_INSTALL_OBJC_HEADER": "NO"
                ], uniquingKeysWith: { _, new in new })
            )
        )
    }

    static func rustMozillaAppServices() -> Target {
        .target(
            name: "RustMozillaAppServices",
            destinations: .iOS,
            product: .framework,
            bundleId: "org.mozilla.ios.RustMozillaAppServices",
            infoPlist: .file(path: "RustMozillaAppServices-Info.plist"),
            sources: ["Tuist/RustMozillaAppServices.swift"],
            dependencies: [
                .package(product: "MozillaRustComponents"),
            ],
            settings: .settings(base: BuildConfigurations.baseSettings.merging([
                "APPLICATION_EXTENSION_API_ONLY": "YES",
                "DEFINES_MODULE": "YES",
                "GCC_WARN_INHIBIT_ALL_WARNINGS": "YES"
            ], uniquingKeysWith: { _, new in new }))
        )
    }
}
