import ProjectDescription

/// Client app target and its settings.
public enum ClientTarget {
    private static let clientConfigurations: [Configuration] = [
        .debug(name: "Debug", settings: [
            "PROVISIONING_PROFILE_SPECIFIER": "match Development com.ecosia.ecosiaapp",
        ], xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaDebug.xcconfig"),
        .debug(name: "BetaDebug", settings: [
            "PROVISIONING_PROFILE_SPECIFIER": "match Development com.ecosia.ecosiaapp.firefox",
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "",
        ], xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaBetaDebug.xcconfig"),
        .debug(name: "Testing", settings: [
            "PROVISIONING_PROFILE_SPECIFIER": "match Development com.ecosia.ecosiaapp.firefox",
        ], xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaTesting.xcconfig"),
        .release(name: "Release", settings: [
            "CODE_SIGN_IDENTITY": "iPhone Distribution",
            "PROVISIONING_PROFILE_SPECIFIER": "match AppStore com.ecosia.ecosiaapp",
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS": ""
        ], xcconfig: "Client/Ecosia/BuildSettingsConfigurations/Ecosia.xcconfig"),
        .release(name: "Development_TestFlight", settings: [
            "CODE_SIGN_IDENTITY": "iPhone Distribution",
            "PROVISIONING_PROFILE_SPECIFIER": "match AppStore com.ecosia.ecosiaapp.firefox",
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS": ""
        ], xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaBeta.xcconfig"),
        .release(name: "Development_Firebase", settings: [
            "CODE_SIGN_IDENTITY": "iPhone Distribution",
            "PROVISIONING_PROFILE_SPECIFIER": "match AdHoc com.ecosia.ecosiaapp.firefox"
        ], xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaBeta.xcconfig"),
    ]

    public static func target() -> Target {
        .target(
            name: "Client",
            destinations: [.iPhone, .iPad],
            product: .app,
            bundleId: "$(MOZ_BUNDLE_ID)",
            infoPlist: .file(path: "Client/Info.plist"),
            sources: [
                .glob(
                    "Client/**/*.{swift,h,m}",
                    excluding: [
                        "Client/Assets/Search/get_supported_locales.swift",
                        "Client/Frontend/Browser/PrivateModeButton.swift",
                        "Client/Frontend/Browser/TranslationToastHandler.swift",
                        "Client/Frontend/Settings/Main/Support/StudiesToggleSetting.swift",
                        "Client/Frontend/Browser/Tabs/State/TabViewState.swift",
                        "Client/Frontend/Browser/MainMenu/Redux/MainMenuDetailState.swift",
                        "Extensions/NotificationService/**/*.swift"
                    ]
                ),
                "Client/Frontend/Settings/Main/General/**/*.swift",
                "Client/IntroScreenManager.swift",
                "Client/ProfilePrefsReader.swift",
                "Client/CrashTracker.swift",
                "Client/Generated/**/*.swift",
                "Providers/**/*.swift",
                "Account/*.swift",
                "RustFxA/**/*.swift",
                "TranslationsEngine.html",
                "WidgetKit/DownloadManager/DownloadLiveActivity.swift",
                "WidgetKit/OpenTabs/SimpleTab.swift",
                "Extensions/NotificationService/NotificationPayloads.swift"
            ],
            resources: [
                "Client/Assets/CC_Script/CC_Python_Update.py",
                "Client/Assets/CC_Script/Constants.ios.mjs",
                "Client/Assets/CC_Script/CreditCard.sys.mjs",
                "Client/Assets/CC_Script/CreditCardRuleset.sys.mjs",
                "Client/Assets/CC_Script/fathom.mjs",
                "Client/Assets/CC_Script/FieldScanner.sys.mjs",
                "Client/Assets/CC_Script/FormAutofill.ios.sys.mjs",
                "Client/Assets/CC_Script/FormAutofill.sys.mjs",
                "Client/Assets/CC_Script/FormAutofillChild.ios.sys.mjs",
                "Client/Assets/CC_Script/FormAutofillHandler.sys.mjs",
                "Client/Assets/CC_Script/FormAutofillHeuristics.sys.mjs",
                "Client/Assets/CC_Script/FormAutofillNameUtils.sys.mjs",
                "Client/Assets/CC_Script/FormAutofillSection.sys.mjs",
                "Client/Assets/CC_Script/FormAutofillUtils.sys.mjs",
                "Client/Assets/CC_Script/FormLikeFactory.sys.mjs",
                "Client/Assets/CC_Script/FormStateManager.sys.mjs",
                "Client/Assets/CC_Script/Helpers.ios.mjs",
                "Client/Assets/CC_Script/HeuristicsRegExp.sys.mjs",
                "Client/Assets/CC_Script/LabelUtils.sys.mjs",
                "Client/Assets/CC_Script/LoginManager.shared.sys.mjs",
                "Client/Assets/CC_Script/Overrides.ios.js",
                "Client/Assets/**/*.{css,html,png,jpg,jpeg,pdf,otf,ttf}",
                "Client/Assets/RemoteSettingsData/**/*.json",
                "Client/Assets/SpotlightHelper.js",
                "Client/MailSchemes.plist",
                .glob(pattern: "Client/Assets/**/*.xcassets", excluding: [
                    "Client/Assets/Images.xcassets/AppIcon.appiconset",
                    "Client/Assets/Images.xcassets/AppIcon_Beta.appiconset",
                    "Client/Assets/Images.xcassets/AppIcon_Developer.appiconset"
                ]),
                "Client/Ecosia/**/*.{xib,xcassets,strings,stringsdict}",
                .glob(pattern: "Client/*.lproj/**", excluding: ["Client/Extensions/**"]),
                "Shared/**/*.{strings, stringsdict}",
            ],
            scripts: BuildScripts.clientBuildScripts,
            dependencies: [
                .target(name: "ShareTo"),
                .target(name: "WidgetKitExtension"),
                .target(name: "Ecosia"),
                .target(name: "Account"),
                .target(name: "Storage"),
                .sdk(name: "Accelerate", type: .framework),
                .sdk(name: "AdServices", type: .framework, status: .optional),
                .sdk(name: "AdSupport", type: .framework),
                .sdk(name: "AuthenticationServices", type: .framework),
                .package(product: "Common"),
                .package(product: "ComponentLibrary"),
                .package(product: "Fuzi"),
                .package(product: "GCDWebServers"),
                .package(product: "Glean"),
                .sdk(name: "iAd", type: .framework),
                .sdk(name: "ImageIO", type: .framework),
                .package(product: "Kingfisher"),
                .target(name: "Localizations"),
                .package(product: "Lottie"),
                .package(product: "MenuKit"),
                .package(product: "OnboardingKit"),
                .sdk(name: "PassKit", type: .framework),
                .package(product: "Redux"),
                .target(name: "RustMozillaAppServices"),
                .sdk(name: "SafariServices", type: .framework),
                .package(product: "Sentry-Dynamic"),
                .package(product: "Shared"),
                .package(product: "SiteImageView"),
                .package(product: "SnapKit"),
                .package(product: "SummarizeKit"),
                .target(name: "Sync"),
                .package(product: "TabDataStore"),
                .package(product: "ToolbarKit"),
                .package(product: "UnifiedSearchKit"),
                .sdk(name: "xml2", type: .library),
                .sdk(name: "z", type: .library),
                .package(product: "X509"),
                .package(product: "Adjust"),
                .package(product: "BrazeKit"),
                .package(product: "BrazeUI"),
                .package(product: "SnowplowTracker"),
            ],
            settings: .settings(
                base: BuildConfigurations.baseSettings.merging([
                    "SKIP_INSTALL": "NO",
                    "SWIFT_OBJC_BRIDGING_HEADER": "$(PROJECT_DIR)/Client/Client-Bridging-Header.h",
                    "HEADER_SEARCH_PATHS": ["$(inherited)", "$(SRCROOT)", "$(SRCROOT)/Client", "$(SRCROOT)/Client/Utils"],
                    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                    "INFOPLIST_KEY_UILaunchStoryboardName": "EcosiaLaunchScreen"
                ], uniquingKeysWith: { _, new in new }),
                configurations: clientConfigurations
            )
        )
    }
}
