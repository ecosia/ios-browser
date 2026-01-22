import ProjectDescription

// MARK: - Build Configurations

private let buildConfigurations: [Configuration] = [
    .debug(name: "Debug", xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaDebug.xcconfig"),
    .debug(name: "BetaDebug", xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaBetaDebug.xcconfig"),
    .debug(name: "Testing", xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaTesting.xcconfig"),
    .release(name: "Release", xcconfig: "Client/Ecosia/BuildSettingsConfigurations/Ecosia.xcconfig"),
    .release(name: "Development_TestFlight", xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaBeta.xcconfig"),
    .release(name: "Development_Firebase", xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaBeta.xcconfig"),
]

// MARK: - Base Settings
// Note: Most settings are defined in xcconfig files (source of truth)
// Only minimal settings that can't be in xcconfig are defined here

private let baseSettings: SettingsDictionary = [
    "SWIFT_VERSION": "6.2",
    // Temporarily disabled during Firefox 147.2 upgrade - see TODO_SWIFT_CONCURRENCY.md
    "SWIFT_STRICT_CONCURRENCY": "minimal"
]

// MARK: - Swift Package Dependencies

private let packages: [Package] = [
    .local(path: "../BrowserKit"),
    .local(path: "../MozillaRustComponents"),
    .remote(url: "https://github.com/auth0/Auth0.swift.git", requirement: .upToNextMajor(from: "2.0.0")),
    .remote(url: "https://github.com/braze-inc/braze-swift-sdk.git", requirement: .upToNextMajor(from: "11.9.0")),
    .remote(url: "https://github.com/airbnb/lottie-ios.git", requirement: .exact("4.4.0")),
    .remote(url: "https://github.com/mozilla/glean-swift.git", requirement: .upToNextMinor(from: "66.3.0")),
    .remote(url: "https://github.com/snowplow/snowplow-ios-tracker.git", requirement: .upToNextMinor(from: "6.0.9")),
    .remote(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", requirement: .upToNextMajor(from: "1.18.7")),
    .remote(url: "https://github.com/nalexn/ViewInspector.git", requirement: .upToNextMajor(from: "0.10.1")),
    .remote(url: "https://github.com/kif-framework/KIF.git", requirement: .exact("3.8.9")),
    .remote(url: "https://github.com/adjust/ios_sdk.git", requirement: .exact("4.37.0")),
    .remote(url: "https://github.com/SnapKit/SnapKit.git", requirement: .exact("5.7.0")),
    .remote(url: "https://github.com/nbhasin2/Fuzi.git", requirement: .branch("master")),
    .remote(url: "https://github.com/nbhasin2/GCDWebServer.git", requirement: .branch("master")),
    .remote(url: "https://github.com/getsentry/sentry-cocoa.git", requirement: .exact("8.36.0")),
    .remote(url: "https://github.com/onevcat/Kingfisher.git", requirement: .exact("8.2.0")),
    .remote(url: "https://github.com/apple/swift-certificates.git", requirement: .exact("1.2.0")),
    .remote(url: "https://github.com/mozilla-mobile/MappaMundi.git", requirement: .branch("master")),
]

// MARK: - Build Scripts

/// SwiftLint - Lint modified Swift files
private let swiftlintScript: [TargetScript] = [
    .pre(
        script: """
        if [[ "$(uname -m)" == arm64 ]]; then
            export PATH="/opt/homebrew/bin:$PATH"
        fi

        MODIFIED_FILES=$(git diff --name-only --diff-filter=ACM | grep -e '\\.swift$')

        SWIFTLINT_ROOT="${SRCROOT}/.."

        if which swiftlint > /dev/null; then
            # Move to the location of the root Swiftlint config file in
            # order to use nested configurations
            cd ${SWIFTLINT_ROOT}

            swiftlint lint ${MODIFIED_FILES}
        else
            echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
        fi
        """,
        name: "Swiftlint",
        basedOnDependencyAnalysis: false
    )
]

/// Update Version - Read version from version.txt and update version.xcconfig
private let updateVersionScript: [TargetScript] = [
    .pre(
        script: """
        #!/bin/sh

        VERSION_FILE="${SRCROOT}/../version.txt"
        XCCONFIG_FILE="${SRCROOT}/Client/Configuration/version.xcconfig"

        # Read version from file
        if [ -f "$VERSION_FILE" ]; then
            FULL_VERSION=$(tr -d '[:space:]' < "$VERSION_FILE")
        else
            echo "Error: version.txt not found!"
            exit 1
        fi

        # Extract only numeric parts (e.g., "123.0" from "123.0b2")
        VERSION_NUMBER=$(echo "$FULL_VERSION" | sed -E 's/^([0-9]+(\\.[0-9]+)*).*/\\1/')

        # Update the xcconfig file with the version number
        echo "APP_VERSION = $VERSION_NUMBER" > "$XCCONFIG_FILE"

        echo "Updated Version.xcconfig with version: $VERSION_NUMBER"
        """,
        name: "Update Version",
        basedOnDependencyAnalysis: false
    )
]

/// Move Nested Frameworks - Flatten nested frameworks to avoid code signing issues
private let moveNestedFrameworksScript: [TargetScript] = [
    .post(
        script: """
        movedFrameworks=()
        cd "${CODESIGNING_FOLDER_PATH}/Frameworks/"
        for framework in *; do
            if [ -d "$framework" ]; then
                if [ -d "${framework}/Frameworks" ]; then
                    echo "Moving nested frameworks from ${framework}/Frameworks/ to ${PRODUCT_NAME}.app/Frameworks/"
        
                    cd "${framework}/Frameworks/"
                    for nestedFramework in *; do
                        echo "- nested: ${nestedFramework}"
                        movedFrameworks+=("${nestedFramework}")
                    done
                    cd ..
                    cd ..
        
                    cp -R "${framework}/Frameworks/" .
                    rm -rf "${framework}/Frameworks"
                fi
            fi
        done
        
        if [ "${CONFIGURATION}" == "Debug" ] & [ "${PLATFORM_NAME}" != "iphonesimulator" ] ; then
            for movedFramework in "${movedFrameworks[@]}"
            do
                codesign --force --deep --sign "${EXPANDED_CODE_SIGN_IDENTITY}" --preserve-metadata=identifier,entitlements --timestamp=none "${movedFramework}"
            done
        else
            echo "Info: CODESIGNING is only needed for Debug on device (will be re-signed anyway when archiving) "
        fi
        """,
        name: "Move Nested Frameworks",
        basedOnDependencyAnalysis: false
    )
]

/// Conditionally Add Optional Resources - Add settings bundle and debug files
private let addOptionalResourcesScript: [TargetScript] = [
    .post(
        script: """
        ## Add setting bundle to app bundle
        if [ "${INCLUDE_SETTINGS_BUNDLE}" = "YES" ]; then
            cp -r "${PROJECT_DIR}/${TARGET_NAME}/Application/Settings.bundle" "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app"
        fi

        ## copy debug files to app bundle
        if [ "$CONFIGURATION" = "Fennec" ]; then
            cp -R "${PROJECT_DIR}/${TARGET_NAME}/Assets/Debug/" "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/"
        fi
        """,
        name: "Conditionally Add Optional Resources",
        basedOnDependencyAnalysis: false
    )
]

/// Populate test-fixtures - Copy test fixtures to app bundle for testing
private let populateTestFixturesScript: [TargetScript] = [
    .post(
        script: """
        # Skip copying test-fixtures for any Firefox build configuration
        if [[ "$CONFIGURATION" == Firefox* ]]; then
          echo "Populate test-fixtures: skipping for $CONFIGURATION"
          exit 0
        fi

        fixtures="${SRCROOT}/../test-fixtures"
        [[ -e $fixtures ]] || exit 1

        outpath="${TARGET_BUILD_DIR}/Client.app"
        rsync -zvrt --update "$fixtures" "$outpath"
        """,
        name: "Populate test-fixtures script",
        basedOnDependencyAnalysis: false
    )
]

/// Strip Symbols - Strip debugging symbols from Firefox configuration builds
private let stripSymbolsScript: [TargetScript] = [
    .post(
        script: """
        #!/bin/bash
        set -e

        if [ "Firefox" = "${CONFIGURATION}" ]; then
          # Path to the app directory
          APP_DIR_PATH="${BUILT_PRODUCTS_DIR}/${EXECUTABLE_FOLDER_PATH}"
          # Strip main binary
          strip -rSTx "${APP_DIR_PATH}/${EXECUTABLE_NAME}"
          # Path to the Frameworks directory
          APP_FRAMEWORKS_DIR="${APP_DIR_PATH}/Frameworks"

          # Strip symbols from frameworks, if Frameworks/ exists at all
          # ... as long as the framework is NOT signed by Apple
          if [ -d "${APP_FRAMEWORKS_DIR}" ]
          then
            find "${APP_FRAMEWORKS_DIR}" -type f -perm +111 -maxdepth 2 -mindepth 2 -exec bash -c '
            codesign -v -R="anchor apple" "{}" &> /dev/null ||
            (
                echo "Stripping {}" &&
                if [ -w "{}" ]; then
                    strip -rSTx "{}"
                else
                    echo "Warning: No write permission for {}"
                fi
            )
            ' \\;
          fi

          # Path to the PlugIns directory
          APP_PLUGINS_DIR="${APP_DIR_PATH}/PlugIns"

          # Strip symbols from plugins, if PlugIns/ exists at all
          # ... as long as the plugin is NOT signed by Apple
          if [ -d "${APP_PLUGINS_DIR}" ]
          then
            find "${APP_PLUGINS_DIR}" -type f -perm +111 -maxdepth 2 -mindepth 2 -exec bash -c '
            codesign -v -R="anchor apple" "{}" &> /dev/null ||
            (
                echo "Stripping {}" &&
                if [ -w "{}" ]; then
                    strip -rSTx "{}"
                else
                    echo "Warning: No write permission for {}"
                fi
            )
            ' \\;
          fi
        fi
        """,
        name: "Strip Symbols",
        basedOnDependencyAnalysis: false
    )
]

/// Remove Frameworks - Clean up frameworks folder
private let removeFrameworksScript: [TargetScript] = [
    .post(
        script: """
        cd "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/"
        if [[ -d "Frameworks" ]]; then
            rm -fr Frameworks
        fi
        """,
        name: "Remove Frameworks",
        basedOnDependencyAnalysis: false
    )
]

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

        # Skip deletion during archive to avoid code signing issues
        if [ "${ACTION}" = "install" ]; then
            echo "[Ecosia/Tuist] Skipping MozillaRustComponents cleanup during archive install"
        else
            EMBEDDED_FW="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}/MozillaRustComponents.framework"
            if [ -d "${EMBEDDED_FW}" ]; then
                echo "[Ecosia/Tuist] Removing stale embedded MozillaRustComponents.framework"
                rm -rf "${EMBEDDED_FW}"
            fi
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

/// All Client target build scripts in execution order
private let clientBuildScripts: [TargetScript] = 
    swiftlintScript +
    updateVersionScript +
    // fixMozillaRustComponentsEmbeddingScript +
    moveNestedFrameworksScript +
    addOptionalResourcesScript +
    populateTestFixturesScript +
    stripSymbolsScript +
    removeFrameworksScript

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
                "Client/**/*.{swift, h, m}",
                "Providers/**/*.swift",
                "Extensions/**/*",
                "WidgetKit/**/*.swift",
                "Account/**/*.{plist, swift, h}",
                "RustFxA/**/*.swift",
                "TranslationsEngine.html"
            ],
            resources: [
                // Ecosia: Explicitly list CC_Script files (autofill, credit card, form handling)
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
                
                // Other Client/Assets files
                "Client/Assets/**/*.{css,html,png,jpg,jpeg,pdf,otf,ttf}",
                "Client/Assets/SpotlightHelper.js",
                
                // Ecosia: Exclude ALL Firefox AppIcons (we use Ecosia's from Client/Ecosia/UI/Ecosia.xcassets)
                .glob(pattern: "Client/Assets/**/*.xcassets", excluding: [
                    "Client/Assets/Images.xcassets/AppIcon.appiconset",
                    "Client/Assets/Images.xcassets/AppIcon_Beta.appiconset",
                    "Client/Assets/Images.xcassets/AppIcon_Developer.appiconset"
                ]),
                "Client/Frontend/**/*.{storyboard,xib,xcassets,strings,stringsdict}",
                "Client/Ecosia/**/*.{xib,xcassets,strings,stringsdict}",
                "Client/*.lproj/**",
            ],
            scripts: clientBuildScripts,
            dependencies: [
                // Target Dependencies (app extensions)
                .target(name: "ShareTo"),
                .target(name: "WidgetKitExtension"),
                // Temporarily disabled during Firefox 147.2 upgrade - provisioning profile issues
                // .target(name: "CredentialProvider"),
                // .target(name: "ActionExtension"),
                // .target(name: "NotificationService"),
                // .target(name: "Sticker"),
                .target(name: "Ecosia"),

                // Link Binary With Libraries
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
                
                // Ecosia-specific dependencies
                .package(product: "Adjust"),
                .package(product: "BrazeKit"),
                .package(product: "BrazeUI"),
                .package(product: "SnowplowTracker"),
            ],
            settings: .settings(
                base: baseSettings.merging([
                    "SKIP_INSTALL": "NO",
                    "SWIFT_OBJC_BRIDGING_HEADER": "$(PROJECT_DIR)/Client/Client-Bridging-Header.h",
                    "HEADER_SEARCH_PATHS": ["$(inherited)", "$(SRCROOT)", "$(SRCROOT)/Client", "$(SRCROOT)/Client/Utils"],
                    // Ecosia: Use custom AppIcon from Client/Ecosia/UI/Ecosia.xcassets
                    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon"
                ], uniquingKeysWith: { _, new in new }),
                configurations: [
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
                .package(product: "Shared"),
                .package(product: "Fuzi"),
                .package(product: "Common"),
                .package(product: "SnapKit"),
                .sdk(name: "ImageIO", type: .framework),
                .sdk(name: "RustMozillaAppServices", type: .framework),
                .sdk(name: "Localizations", type: .framework),
            ],
            settings: .settings(
                base: baseSettings.merging([
                    "SKIP_INSTALL": "NO",
                    "APPLICATION_EXTENSION_API_ONLY": "YES",
                    "OTHER_SWIFT_FLAGS": "$(inherited) -DMOZ_TARGET_SHARETO"
                ], uniquingKeysWith: { _, new in new }),
                configurations: [
                    .debug(name: "Debug", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match Development com.ecosia.ecosiaapp.ShareTo"
                    ], xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaDebug.ShareTo.xcconfig"),
                    .debug(name: "BetaDebug", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match Development com.ecosia.ecosiaapp.ShareTo"
                    ], xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaBetaDebug.ShareTo.xcconfig"),
                    .debug(name: "Testing", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match Development com.ecosia.ecosiaapp.ShareTo"
                    ], xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaTesting.ShareTo.xcconfig"),
                    .release(name: "Release", settings: [
                        "CODE_SIGN_IDENTITY": "iPhone Distribution",
                        "PROVISIONING_PROFILE_SPECIFIER": "match AppStore com.ecosia.ecosiaapp.ShareTo"
                    ], xcconfig: "Client/Ecosia/BuildSettingsConfigurations/Ecosia.ShareTo.xcconfig"),
                    .release(name: "Development_TestFlight", settings: [
                        "CODE_SIGN_IDENTITY": "iPhone Distribution",
                        "PROVISIONING_PROFILE_SPECIFIER": "match AppStore com.ecosia.ecosiaapp.firefox.ShareTo"
                    ], xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaBeta.ShareTo.xcconfig"),
                    .release(name: "Development_Firebase", settings: [
                        "CODE_SIGN_IDENTITY": "iPhone Distribution",
                        "PROVISIONING_PROFILE_SPECIFIER": "match AdHoc com.ecosia.ecosiaapp.firefox.ShareTo"
                    ], xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaBeta.ShareTo.xcconfig"),
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
                .package(product: "Common"),
                .package(product: "Fuzi"),
                .package(product: "GCDWebServers"),
                .package(product: "libStorage.a"),
                .sdk(name: "Localizations", type: .framework),
                .sdk(name: "RustMozillaAppServices", type: .framework),
                .package(product: "Shared"),
                .package(product: "SiteImageView"),
                .sdk(name: "SwiftUI", type: .framework),
                .package(product: "TabDataStore"),
                .sdk(name: "WidgetKit", type: .framework),
            ],
            settings: .settings(
                base: baseSettings.merging([
                    "SKIP_INSTALL": "NO",
                    "APPLICATION_EXTENSION_API_ONLY": "YES"
                ], uniquingKeysWith: { _, new in new }),
                configurations: [
                    .debug(name: "Debug", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match Development com.ecosia.ecosiaapp.WidgetKit"
                    ], xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaDebug.WidgetKit.xcconfig"),
                    .debug(name: "BetaDebug", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match Development com.ecosia.ecosiaapp.WidgetKit"
                    ], xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaBetaDebug.WidgetKit.xcconfig"),
                    .debug(name: "Testing", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match Development com.ecosia.ecosiaapp.WidgetKit"
                    ], xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaTesting.WidgetKit.xcconfig"),
                    .release(name: "Release", settings: [
                        "CODE_SIGN_IDENTITY": "iPhone Distribution",
                        "PROVISIONING_PROFILE_SPECIFIER": "match AppStore com.ecosia.ecosiaapp.WidgetKit"
                    ], xcconfig: "Client/Ecosia/BuildSettingsConfigurations/Ecosia.WidgetKit.xcconfig"),
                    .release(name: "Development_TestFlight", settings: [
                        "CODE_SIGN_IDENTITY": "iPhone Distribution",
                        "PROVISIONING_PROFILE_SPECIFIER": "match AppStore com.ecosia.ecosiaapp.firefox.WidgetKit"
                    ], xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaBeta.WidgetKit.xcconfig"),
                    .release(name: "Development_Firebase", settings: [
                        "CODE_SIGN_IDENTITY": "iPhone Distribution",
                        "PROVISIONING_PROFILE_SPECIFIER": "match AdHoc com.ecosia.ecosiaapp.firefox.WidgetKit"
                    ], xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaBeta.WidgetKit.xcconfig"),
                ]
            )
        ),
        // MARK: - CredentialProvider Extension
        // Temporarily disabled during Firefox 147.2 upgrade - provisioning profile issues
        // TODO: Re-enable after upgrade complete and provisioning profiles are set up
        /*
        .target(
            name: "CredentialProvider",
            destinations: [.iPhone, .iPad],
            product: .appExtension,
            bundleId: "$(MOZ_BUNDLE_ID).CredentialProvider",
            infoPlist: .file(path: "CredentialProvider/Info.plist"),
            sources: [
                "CredentialProvider/**/*.swift"
            ],
            resources: [
                "CredentialProvider/**/*.{xcassets,strings,stringsdict}"
            ],
            dependencies: [
                // Target Dependencies
                .target(name: "Shared"),
                .target(name: "Storage"),

                // Link Binary With Libraries
                .package(product: "Common"),
            ],
            settings: .settings(
                base: baseSettings.merging([
                    "APPLICATION_EXTENSION_API_ONLY": "YES"
                ], uniquingKeysWith: { _, new in new }),
                configurations: [
                    .debug(name: "Debug", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match Development $(MOZ_BUNDLE_ID).CredentialProvider"
                    ], xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaDebug.xcconfig"),
                    .debug(name: "BetaDebug", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match Development $(MOZ_BUNDLE_ID).CredentialProvider"
                    ], xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaBetaDebug.xcconfig"),
                    .debug(name: "Testing", settings: [
                        "PROVISIONING_PROFILE_SPECIFIER": "match Development $(MOZ_BUNDLE_ID).CredentialProvider"
                    ], xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaTesting.xcconfig"),
                    .release(name: "Release", settings: [
                        "CODE_SIGN_IDENTITY": "iPhone Distribution",
                        "PROVISIONING_PROFILE_SPECIFIER": "match AppStore $(MOZ_BUNDLE_ID).CredentialProvider"
                    ], xcconfig: "Client/Ecosia/BuildSettingsConfigurations/Ecosia.xcconfig"),
                    .release(name: "Development_TestFlight", settings: [
                        "CODE_SIGN_IDENTITY": "iPhone Distribution",
                        "PROVISIONING_PROFILE_SPECIFIER": "match AppStore $(MOZ_BUNDLE_ID).CredentialProvider"
                    ], xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaBeta.xcconfig"),
                    .release(name: "Development_Firebase", settings: [
                        "CODE_SIGN_IDENTITY": "iPhone Distribution",
                        "PROVISIONING_PROFILE_SPECIFIER": "match AdHoc $(MOZ_BUNDLE_ID).CredentialProvider"
                    ], xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaBeta.xcconfig"),
                ]
            )
        ),
        */

        // // MARK: - ActionExtension Extension
        // .target(
        //     name: "ActionExtension",
        //     destinations: [.iPhone, .iPad],
        //     product: .appExtension,
        //     bundleId: "$(MOZ_BUNDLE_ID).ShareTo.ActionExtension",
        //     infoPlist: .file(path: "Extensions/ActionExtension/Info.plist"),
        //     sources: [
        //         "Extensions/ActionExtension/**/*.swift"
        //     ],
        //     resources: [
        //         "Extensions/ActionExtension/**/*.{xcassets,strings}"
        //     ],
        //     dependencies: [
        //         // Target Dependencies
        //         .target(name: "Shared"),
        //         .target(name: "Storage"),

        //         // Link Binary With Libraries
        //         .package(product: "Common"),
        //     ],
        //     settings: .settings(
        //         base: baseSettings.merging([
        //             "APPLICATION_EXTENSION_API_ONLY": "YES"
        //         ], uniquingKeysWith: { _, new in new }),
        //         configurations: [
        //             .debug(name: "Debug", settings: [
        //                 "PROVISIONING_PROFILE_SPECIFIER": "match Development $(MOZ_BUNDLE_ID).ShareTo.ActionExtension"
        //             ], xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaDebug.xcconfig"),
        //             .debug(name: "BetaDebug", settings: [
        //                 "PROVISIONING_PROFILE_SPECIFIER": "match Development $(MOZ_BUNDLE_ID).ShareTo.ActionExtension"
        //             ], xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaBetaDebug.xcconfig"),
        //             .debug(name: "Testing", settings: [
        //                 "PROVISIONING_PROFILE_SPECIFIER": "match Development $(MOZ_BUNDLE_ID).ShareTo.ActionExtension"
        //             ], xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaTesting.xcconfig"),
        //             .release(name: "Release", settings: [
        //                 "CODE_SIGN_IDENTITY": "iPhone Distribution",
        //                 "PROVISIONING_PROFILE_SPECIFIER": "match AppStore $(MOZ_BUNDLE_ID).ShareTo.ActionExtension"
        //             ], xcconfig: "Client/Ecosia/BuildSettingsConfigurations/Ecosia.xcconfig"),
        //             .release(name: "Development_TestFlight", settings: [
        //                 "CODE_SIGN_IDENTITY": "iPhone Distribution",
        //                 "PROVISIONING_PROFILE_SPECIFIER": "match AppStore $(MOZ_BUNDLE_ID).ShareTo.ActionExtension"
        //             ], xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaBeta.xcconfig"),
        //             .release(name: "Development_Firebase", settings: [
        //                 "CODE_SIGN_IDENTITY": "iPhone Distribution",
        //                 "PROVISIONING_PROFILE_SPECIFIER": "match AdHoc $(MOZ_BUNDLE_ID).ShareTo.ActionExtension"
        //             ], xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaBeta.xcconfig"),
        //         ]
        //     )
        // ),

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
                .target(name: "RustMozillaAppServices"),
                .sdk(name: "GCDWebServers", type: .framework)
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
                .package(product: "Common"),
                .package(product: "GCDWebServers"),
                .package(product: "Kingfisher"),
                .sdk(name: "RustMozillaAppServices", type: .framework),
                .package(product: "Shared"),
                .package(product: "SiteImageView"),
            ],
            settings: .settings(base: baseSettings.merging([
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
                .package(product: "Common"),
                .package(product: "Fuzi"),
                .package(product: "libAccount.a"),
                .package(product: "libStorage.a"),
                .sdk(name: "Localizations", type: .framework),
                .sdk(name: "RustMozillaAppServices", type: .framework),
                .package(product: "Shared"),
                .package(product: "SiteImageView"),
            ],
            settings: .settings(base: baseSettings.merging([
                "APPLICATION_EXTENSION_API_ONLY": "YES",
                "DEFINES_MODULE": "YES",
                "GCC_TREAT_WARNINGS_AS_ERRORS": "NO",
                "GCC_WARN_INHIBIT_ALL_WARNINGS": "YES",
                "SWIFT_OBJC_BRIDGING_HEADER": "$SRCROOT/Sync/Sync-Bridging-Header.h"
            ], uniquingKeysWith: { _, new in new }))
        ),

        // MARK: - Localizations Framework
        .target(
            name: "Localizations",
            destinations: .iOS,
            product: .framework,
            bundleId: "org.mozilla.ios.Localizations",
            infoPlist: .file(path: "Shared/Supporting Files/Info.plist"),
            resources: ["Localizations/**/*.{strings,stringsdict}"],
            dependencies: [
                .package(product: "Common"),
                .package(product: "GCDWebServers"),
                .package(product: "Shared"),
                .package(product: "WebEngine")
            ],
            settings: .settings(base: baseSettings.merging([
                "DEFINES_MODULE": "YES",
                "GENERATE_INFOPLIST_FILE": "YES"
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
                    "SWIFT_EMIT_LOC_STRINGS": "YES",
                    "SWIFT_INSTALL_OBJC_HEADER": "NO"
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
                .package(product: "MozillaRustComponents"),
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
                .sdk(name: "RustMozillaAppServices", type: .framework),
                .package(product: "Shared"),

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
                .target(name: "RustMozillaAppServices"),
                .package(product: "Common"),
                .package(product: "Fuzi"),
                .package(product: "GCDWebServers"),
                .package(product: "Kingfisher"),
                .package(product: "SiteImageView"),
                .package(product: "TabDataStore"),
                .sdk(name: "z", type: .library),
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
