import ProjectDescription

/// Returns the six Ecosia build configurations for an app extension, using extension-specific xcconfig and provisioning profiles.
/// Use this to avoid duplicating the same configuration pattern across ShareTo, WidgetKitExtension, etc.
///
/// - Parameter suffix: Extension identifier used in xcconfig filenames and profile specifiers (e.g. "ShareTo", "WidgetKit").
/// - Returns: Array of 6 configurations: Debug, BetaDebug, Testing, Release, Development_TestFlight, Development_Firebase.
public enum ExtensionConfigurations {
    private static let basePath = "Client/Ecosia/BuildSettingsConfigurations"

    public static func configurations(suffix: String) -> [Configuration] {
        let xcconfigSuffix = suffix.isEmpty ? "" : ".\(suffix)"
        return [
            .debug(
                name: "Debug",
                settings: ["PROVISIONING_PROFILE_SPECIFIER": "match Development com.ecosia.ecosiaapp.\(suffix)"],
                xcconfig: "\(basePath)/EcosiaDebug\(xcconfigSuffix).xcconfig"
            ),
            .debug(
                name: "BetaDebug",
                settings: ["PROVISIONING_PROFILE_SPECIFIER": "match Development com.ecosia.ecosiaapp.\(suffix)"],
                xcconfig: "\(basePath)/EcosiaBetaDebug\(xcconfigSuffix).xcconfig"
            ),
            .debug(
                name: "Testing",
                settings: ["PROVISIONING_PROFILE_SPECIFIER": "match Development com.ecosia.ecosiaapp.\(suffix)"],
                xcconfig: "\(basePath)/EcosiaTesting\(xcconfigSuffix).xcconfig"
            ),
            .release(
                name: "Release",
                settings: [
                    "CODE_SIGN_IDENTITY": "iPhone Distribution",
                    "PROVISIONING_PROFILE_SPECIFIER": "match AppStore com.ecosia.ecosiaapp.\(suffix)"
                ],
                xcconfig: "\(basePath)/Ecosia\(xcconfigSuffix).xcconfig"
            ),
            .release(
                name: "Development_TestFlight",
                settings: [
                    "CODE_SIGN_IDENTITY": "iPhone Distribution",
                    "PROVISIONING_PROFILE_SPECIFIER": "match AppStore com.ecosia.ecosiaapp.firefox.\(suffix)"
                ],
                xcconfig: "\(basePath)/EcosiaBeta\(xcconfigSuffix).xcconfig"
            ),
            .release(
                name: "Development_Firebase",
                settings: [
                    "CODE_SIGN_IDENTITY": "iPhone Distribution",
                    "PROVISIONING_PROFILE_SPECIFIER": "match AdHoc com.ecosia.ecosiaapp.firefox.\(suffix)"
                ],
                xcconfig: "\(basePath)/EcosiaBeta\(xcconfigSuffix).xcconfig"
            ),
        ]
    }
}
