import ProjectDescription

/// Build script phases used by Client and extension targets.
/// Order and content match Firefox's Xcode build phases for consistency.
public enum BuildScripts {

    // MARK: - Scripts used by Client target (in execution order)

    /// All Client target build scripts in execution order.
    public static let clientBuildScripts: [TargetScript] =
        updateVersionScript +
        swiftlintScript +
        populateTestFixturesScript +
        gleanSDKGeneratorScript +
        nimbusFeatureManifestScript +
        addOptionalResourcesScript +
        moveNestedFrameworksScript +
        stripSymbolsScript

    /// Used by app extensions (ShareTo, WidgetKitExtension) to remove Frameworks folder.
    public static let removeFrameworkScriptFromExtensionTargets: [TargetScript] = extensionRemoveFrameworksScript

    // MARK: - Individual scripts (private, composed above)

    private static let updateVersionScript: [TargetScript] = [
        .pre(
            script: """
            #!/bin/sh

            VERSION_FILE="${SRCROOT}/../version.txt"
            XCCONFIG_FILE="${SRCROOT}/Client/Configuration/version.xcconfig"

            if [ -f "$VERSION_FILE" ]; then
                FULL_VERSION=$(tr -d '[:space:]' < "$VERSION_FILE")
            else
                echo "Error: version.txt not found!"
                exit 1
            fi

            VERSION_NUMBER=$(echo "$FULL_VERSION" | sed -E 's/^([0-9]+(\\.[0-9]+)*).*/\\1/')
            echo "APP_VERSION = $VERSION_NUMBER" > "$XCCONFIG_FILE"
            echo "Updated Version.xcconfig with version: $VERSION_NUMBER"
            """,
            name: "Update Version",
            basedOnDependencyAnalysis: false
        )
    ]

    private static let swiftlintScript: [TargetScript] = [
        .pre(
            script: """
            if [[ "$(uname -m)" == arm64 ]]; then
                export PATH="/opt/homebrew/bin:$PATH"
            fi

            MODIFIED_FILES=$(git diff --name-only --diff-filter=ACM | grep -e '\\.swift$')
            SWIFTLINT_ROOT="${SRCROOT}/.."

            if which swiftlint > /dev/null; then
                cd ${SWIFTLINT_ROOT}
            else
                echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
            fi
            """,
            name: "Swiftlint",
            basedOnDependencyAnalysis: false
        )
    ]

    private static let nimbusFeatureManifestScript: [TargetScript] = [
        .pre(
            script: """
            #!/bin/sh
            if [ "$ACTION" != "indexbuild" ]; then
                /usr/bin/env -i HOME=$HOME PROJECT=$PROJECT CONFIGURATION=$CONFIGURATION SOURCE_ROOT=$SOURCE_ROOT bash "$SOURCE_ROOT/bin/nimbus-fml.sh" --verbose
            fi
            """,
            name: "Nimbus Feature Manifest Generator Script",
            inputPaths: ["$(SOURCE_ROOT)/nimbus.fml.yaml"],
            outputPaths: [
                "$(SRCROOT)/Client/Generated/FxNimbus.swift",
                "$(SRCROOT)/Client/Generated/FxNimbusMessaging.swift"
            ],
            basedOnDependencyAnalysis: false
        )
    ]

    private static let moveNestedFrameworksScript: [TargetScript] = [
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
                for movedFramework in "${movedFrameworks[@]}"; do
                    codesign --force --deep --sign "${EXPANDED_CODE_SIGN_IDENTITY}" --preserve-metadata=identifier,entitlements --timestamp=none "${movedFramework}"
                done
            else
                echo "Info: CODESIGNING is only needed for Debug on device (will be re-signed anyway when archiving)"
            fi
            """,
            name: "Move Nested Frameworks",
            basedOnDependencyAnalysis: false
        )
    ]

    private static let addOptionalResourcesScript: [TargetScript] = [
        .post(
            script: """
            if [ "${INCLUDE_SETTINGS_BUNDLE}" = "YES" ]; then
                cp -r "${PROJECT_DIR}/${TARGET_NAME}/Application/Settings.bundle" "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app"
            fi
            if [ "$CONFIGURATION" = "Fennec" ]; then
                cp -R "${PROJECT_DIR}/${TARGET_NAME}/Assets/Debug/" "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/"
            fi
            """,
            name: "Conditionally Add Optional Resources",
            basedOnDependencyAnalysis: false
        )
    ]

    private static let populateTestFixturesScript: [TargetScript] = [
        .post(
            script: """
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

    private static let gleanSDKGeneratorScript: [TargetScript] = [
        .pre(
            script: """
            OUTPUT_DIR="${SRCROOT}/Client/Generated/Metrics/"
            rm -f "${SRCROOT}/Client/Generated/Metrics/Metrics.swift"
            bash $PWD/bin/sdk_generator.sh -g Glean -o $OUTPUT_DIR
            """,
            name: "Glean SDK Generator Script",
            inputPaths: [
                "$(SRCROOT)/Client/Glean/pings.yaml",
                "$(SRCROOT)/Client/Glean/tags.yaml"
            ],
            inputFileListPaths: ["$(SRCROOT)/Client/Glean/gleanProbes.xcfilelist"],
            outputPaths: ["$(SRCROOT)/Client/Generated/Metrics/Metrics.swift"],
            basedOnDependencyAnalysis: false
        )
    ]

    private static let stripSymbolsScript: [TargetScript] = [
        .post(
            script: """
            #!/bin/bash
            set -e
            if [ "Firefox" = "${CONFIGURATION}" ]; then
              APP_DIR_PATH="${BUILT_PRODUCTS_DIR}/${EXECUTABLE_FOLDER_PATH}"
              strip -rSTx "${APP_DIR_PATH}/${EXECUTABLE_NAME}"
              APP_FRAMEWORKS_DIR="${APP_DIR_PATH}/Frameworks"
              if [ -d "${APP_FRAMEWORKS_DIR}" ]; then
                find "${APP_FRAMEWORKS_DIR}" -type f -perm +111 -maxdepth 2 -mindepth 2 -exec bash -c '
                codesign -v -R="anchor apple" "{}" &> /dev/null ||
                ( echo "Stripping {}" && if [ -w "{}" ]; then strip -rSTx "{}"; else echo "Warning: No write permission for {}"; fi )
                ' \\;
              fi
              APP_PLUGINS_DIR="${APP_DIR_PATH}/PlugIns"
              if [ -d "${APP_PLUGINS_DIR}" ]; then
                find "${APP_PLUGINS_DIR}" -type f -perm +111 -maxdepth 2 -mindepth 2 -exec bash -c '
                codesign -v -R="anchor apple" "{}" &> /dev/null ||
                ( echo "Stripping {}" && if [ -w "{}" ]; then strip -rSTx "{}"; else echo "Warning: No write permission for {}"; fi )
                ' \\;
              fi
            fi
            """,
            name: "Strip Symbols",
            basedOnDependencyAnalysis: false
        )
    ]

    private static let extensionRemoveFrameworksScript: [TargetScript] = [
        .post(
            script: """
            cd "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/"
            if [[ -d "Frameworks" ]]; then
                rm -fr Frameworks
            fi
            """,
            name: "Remove Framework from Extension Targets",
            basedOnDependencyAnalysis: false
        )
    ]
}
