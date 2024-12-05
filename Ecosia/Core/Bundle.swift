import Foundation

extension Bundle {
    public static let version = marketing + "." + bundle
    private static let marketing = main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "4.0.20"
    private static let bundle = main.infoDictionary?["CFBundleVersion"] as? String ?? "840"
}
