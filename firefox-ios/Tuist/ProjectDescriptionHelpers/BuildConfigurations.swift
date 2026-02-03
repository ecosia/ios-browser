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
}
