import ProjectDescription

/// Ecosia schemes.
///
/// Test targets and skipped tests are declared inline so Tuist resolves
/// identifiers at generation time — no manually-maintained .xctestplan
/// with fragile UUIDs needed.
public enum EcosiaSchemes {

    // MARK: - Shared test targets

    /// Test targets shared by Ecosia & EcosiaBeta schemes.
    private static let unitTestTargets: [TestableTarget] = [
        "EcosiaTests",
        "ClientTests",
        "SyncTests",
        "StorageTests",
        "SharedTests",
        "SyncTelemetryTests",
    ]

    /// Tests to skip across all unit-test schemes.
    ///
    /// Format: `"ClassName/methodName()"` for a single test,
    ///         `"ClassName"` for an entire test class.
    /// These are written into the xcscheme's `<SkippedTests>` section.
    private static let skippedTests: [String] = [
        // EcosiaTests
        "AppDelegateFeatureManagementIntegrationTests/testStateAfterDidBecomeActive_expectesSameModel_AfterDidFinishLaunchingWithOptions()",

        // ClientTests
        "ContentBlockerTests/testCompileListsNotInStore_callsCompletionHandlerSuccessfully()",
        "GeneralizedImageFetcherTests/testBadStatusCode()",
        "GeneralizedImageFetcherTests/testErrorResponse()",
        "GeneralizedImageFetcherTests/testNilData()",
        "GleanPlumbMessageManagerTests/testManagerOnMessagePressed_withMalformedURL()",
        "IntroScreenManagerTests/testHasSeenIntroScreen_shouldNotShowIt()",
        "ShortcutRouteTests",
        "SyncContentSettingsViewControllerTests",

        // StorageTests
        "TestBrowserDB/testMovesDB()",
    ]

    // MARK: - Schemes

    public static let all: [Scheme] = [
        .scheme(
            name: "Ecosia",
            buildAction: .buildAction(targets: ["Client"]),
            testAction: .targets(
                unitTestTargets,
                configuration: "Testing",
                attachDebugger: false,
                skippedTests: skippedTests
            ),
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
            testAction: .targets(
                unitTestTargets,
                configuration: "Testing",
                attachDebugger: false,
                skippedTests: skippedTests
            ),
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
}