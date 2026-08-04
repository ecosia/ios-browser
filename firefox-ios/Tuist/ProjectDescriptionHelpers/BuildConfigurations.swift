import ProjectDescription

/// Ecosia build configurations and base settings.
/// Centralized so Project.swift stays lean and config changes are in one place.
public enum BuildConfigurations {
    public static let all: [Configuration] = [
        .debug(name: "Debug", xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaDebug.xcconfig"),
        .debug(name: "BetaDebug", xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaBetaDebug.xcconfig"),
        .debug(name: "Testing", xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaTesting.xcconfig"),
        .release(name: "Release", xcconfig: "Client/Ecosia/BuildSettingsConfigurations/Ecosia.xcconfig"),
        .release(name: "Development_TestFlight", xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaBeta.xcconfig"),
        .release(name: "Development_Firebase", xcconfig: "Client/Ecosia/BuildSettingsConfigurations/EcosiaBeta.xcconfig"),
    ]

    /// Most settings are in xcconfig files (source of truth). Only minimal settings that can't be in xcconfig are here.
    public static let baseSettings: SettingsDictionary = [
        "SWIFT_VERSION": "6.2",
        // Temporarily disabled during Firefox 147.2 upgrade - see TODO_SWIFT_CONCURRENCY.md
        "SWIFT_STRICT_CONCURRENCY": "minimal"
    ]

    /// Base settings for all test targets — disables code signing so tests run on simulators without provisioning profiles.
    public static let testBaseSettings: SettingsDictionary = baseSettings.merging([
        "CODE_SIGN_IDENTITY": "",
        "CODE_SIGNING_REQUIRED": "NO",
        "CODE_SIGNING_ALLOWED": "NO",
        // Explicit Module Builds drop public extension members on foreign (Foundation) types — e.g.
        // Shared's Date.now()/URL.displayURL — from XCTest bundles' link inputs, causing "undefined
        // symbol" at link time despite the symbol compiling fine. Disable for test targets only.
        "SWIFT_ENABLE_EXPLICIT_MODULES": "NO",
    ], uniquingKeysWith: { _, new in new })
}
