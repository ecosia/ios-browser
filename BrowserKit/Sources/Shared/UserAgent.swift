// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import WebKit
import UIKit

open class UserAgent {
    public static let uaBitSafari = "Safari/604.1"
    public static let uaBitMobile = "Mobile/15E148"
    public static let uaBitFx = "FxiOS/\(AppInfo.appVersion)"
    // Ecosia: Add Ecosia user agent info.
    public static let uaBitVersion = "Version/\(UIDeviceDetails.systemVersion)"
    public static var uaBitEcosia: String {
        return "(Ecosia ios@\(AppInfo.appVersion).\(AppInfo.buildNumber))"
    }
    public static var ecosiaDesktopUA: String {
        return "\(UserAgent.desktopUserAgent()) \(UserAgent.uaBitEcosia)"
    }
    public static let product = "Mozilla/5.0"
    public static let platform = "AppleWebKit/605.1.15"
    public static let platformDetails = "(KHTML, like Gecko)"

    private static let defaults = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier)!
    // Ecosia: Configure Ecosia domains from the app layer's URLProvider.
    private static let configuration = UserAgentConfiguration()
    public static func configureEcosiaDesktopUserAgentDomains(_ domains: [String]) {
        configuration.configureEcosiaDesktopUserAgentDomains(domains)
    }

    private static func clientUserAgent(prefix: String) -> String {
        let versionStr: String
        if AppInfo.buildNumber != "1" {
            versionStr = "\(AppInfo.appVersion)b\(AppInfo.buildNumber)"
        } else {
            versionStr = "dev"
        }
        return "\(prefix)/\(versionStr) (\(DeviceInfo.deviceModel()); iPhone OS \(UIDeviceDetails.systemVersion)) (\(AppInfo.displayName))"
    }

    public static var syncUserAgent: String {
        /* Ecosia: Use Ecosia UA prefix for sync requests.
        return clientUserAgent(prefix: "Firefox-iOS-Sync")
         */
        return clientUserAgent(prefix: "Ecosia-iOS-Sync")
    }

    public static var tokenServerClientUserAgent: String {
        /* Ecosia: Use Ecosia UA prefix for token server requests.
        return clientUserAgent(prefix: "Firefox-iOS-Token")
         */
        return clientUserAgent(prefix: "Ecosia-iOS-Token")
    }

    public static var fxaUserAgent: String {
        /* Ecosia: Use Ecosia UA prefix for account webviews.
        return clientUserAgent(prefix: "Firefox-iOS-FxA")
         */
        return clientUserAgent(prefix: "Ecosia-iOS-EcosiaA")
    }

    public static var defaultClientUserAgent: String {
        /* Ecosia: Use Ecosia UA prefix for generic client requests.
        return clientUserAgent(prefix: "Firefox-iOS")
         */
        return clientUserAgent(prefix: "Ecosia-iOS")
    }

    public static func isDesktop(ua: String) -> Bool {
        return ua.lowercased().contains("intel mac")
    }

    public static func desktopUserAgent() -> String {
        return UserAgentBuilder.defaultDesktopUserAgent().userAgent()
    }

    public static func mobileUserAgent() -> String {
        return UserAgentBuilder.defaultMobileUserAgent().userAgent()
    }

    public static func oppositeUserAgent(domain: String) -> String {
        let isDefaultUADesktop = UserAgent.isDesktop(ua: UserAgent.getUserAgent(domain: domain))
        if isDefaultUADesktop {
            return UserAgent.getUserAgent(domain: domain, platform: .Mobile)
        } else {
            return UserAgent.getUserAgent(domain: domain, platform: .Desktop)
        }
    }

    public static func getUserAgent(domain: String, platform: UserAgentPlatform) -> String {
        switch platform {
        case .Desktop:
            if configuration.containsEcosiaDesktopUserAgentDomain(domain) {
                return ecosiaDesktopUA
            }

            guard let customUA = CustomUserAgentConstant.customDesktopUAForDomain[domain] else {
                return desktopUserAgent()
            }
            return customUA
        case .Mobile:
            guard let customUA = CustomUserAgentConstant.customMobileUAForDomain[domain] else {
                return mobileUserAgent()
            }
            return customUA
        }
    }

    public static func getUserAgent(domain: String = "") -> String {
        // As of iOS 13 using a hidden webview method does not return the correct UA on
        // iPad (it returns mobile UA). We should consider that method no longer reliable.
        if UIDeviceDetails.userInterfaceIdiom == .pad {
            return getUserAgent(domain: domain, platform: .Desktop)
        } else {
            return getUserAgent(domain: domain, platform: .Mobile)
        }
    }
}

public enum UserAgentPlatform {
    case Desktop
    case Mobile
}

// Ecosia: Keeps URLProvider-derived domains out of BrowserKit's static upstream domain list.
private final class UserAgentConfiguration: @unchecked Sendable {
    private let lock = NSLock()
    private var ecosiaDesktopUserAgentDomains = Set<String>()

    func configureEcosiaDesktopUserAgentDomains(_ domains: [String]) {
        lock.lock()
        defer { lock.unlock() }

        ecosiaDesktopUserAgentDomains = Set(domains.map { $0.lowercased() })
    }

    func containsEcosiaDesktopUserAgentDomain(_ domain: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        return ecosiaDesktopUserAgentDomains.contains(domain.lowercased())
    }
}

struct CustomUserAgentConstant {
    private static let defaultMobileUA = UserAgentBuilder.defaultMobileUserAgent().userAgent()
    // Ecosia: Keep a Firefox mobile UA for domains that reject Ecosia's default UA.
    private static let defaultFirefoxMobileUA = UserAgentBuilder.defaultFirefoxMobileUserAgent().userAgent()
    /* Ecosia: Build Safari-only overrides from the Firefox mobile UA.
    private static let safariMobileUA = UserAgentBuilder.defaultMobileUserAgent().clone(extensions: "Version/18.6 \(UserAgent.uaBitMobile) \(UserAgent.uaBitSafari)")
     */
    private static let safariMobileUA = UserAgentBuilder.defaultFirefoxMobileUserAgent().clone(
        extensions: "Version/18.6 \(UserAgent.uaBitMobile) \(UserAgent.uaBitSafari)"
    )

    static let customMobileUAForDomain = [
        // Ecosia: PayPal expects the Firefox mobile UA.
        "paypal.com": defaultFirefoxMobileUA,
        // TODO: FXIOS-14371 [webcompat] rokuchannel blocking FXIOS "this browser isn't supported" (webcompat #126427)
        "roku.com": safariMobileUA,
        // TODO: FXIOS-13391 [webcompat] "connection error" only on FxiOS/* UA (bug 1983983)
        "tver.jp": safariMobileUA,
        // TODO: FXIOS-14398 [webcompat] ServiceNow rejects Mobile Safari version "null" (bug 1978984)
        "lta.go.jp": safariMobileUA,
        // TODO: FXIOS-13096 [webcompat] UA version parsed as "Safari 0" (webcompat #170304)
        "epic.com": safariMobileUA,
        "athenahealth.com": safariMobileUA,
        "ehealthontario.ca": safariMobileUA
    ]

    static let customDesktopUAForDomain = [
        // TODO: FXIOS-8027, FXIOS-11230, FXIOS-13891 PayPal buttons open blank tabs
        /* Ecosia: PayPal expects the Firefox mobile UA.
        "paypal.com": defaultMobileUA,
         */
        "paypal.com": defaultFirefoxMobileUA,
        // FXIOS-10251: Do not appear as desktop/Safari for firefox.com/pair
        "firefox.com": defaultMobileUA
    ]
}

public struct UserAgentBuilder {
    // User agent components
    fileprivate var product = ""
    fileprivate var systemInfo = ""
    fileprivate var platform = ""
    fileprivate var platformDetails = ""
    fileprivate var extensions = ""

    init(
        product: String,
        systemInfo: String,
        platform: String,
        platformDetails: String,
        extensions: String
    ) {
        self.product = product
        self.systemInfo = systemInfo
        self.platform = platform
        self.platformDetails = platformDetails
        self.extensions = extensions
    }

    public func userAgent() -> String {
        let userAgentItems = [product, systemInfo, platform, platformDetails, extensions]
        return removeEmptyComponentsAndJoin(uaItems: userAgentItems)
    }

    public func clone(
        product: String? = nil,
        systemInfo: String? = nil,
        platform: String? = nil,
        platformDetails: String? = nil,
        extensions: String? = nil
    ) -> String {
        let userAgentItems = [
            product ?? self.product,
            systemInfo ?? self.systemInfo,
            platform ?? self.platform,
            platformDetails ?? self.platformDetails,
            extensions ?? self.extensions
        ]
        return removeEmptyComponentsAndJoin(uaItems: userAgentItems)
    }

    /// Helper method to remove the empty components from user agent string that contain
    /// only whitespaces or are just empty
    private func removeEmptyComponentsAndJoin(uaItems: [String]) -> String {
        return uaItems.filter { !$0.isEmptyOrWhitespace() }.joined(separator: " ")
    }

    public static func defaultMobileUserAgent() -> UserAgentBuilder {
        /* Ecosia: Always return Ecosia's UA as the default mobile UA.
        return UserAgentBuilder(
            product: UserAgent.product,
            systemInfo: "(\(UIDeviceDetails.model); CPU iPhone OS 18_7 like Mac OS X)",
            platform: UserAgent.platform,
            platformDetails: UserAgent.platformDetails,
            extensions: "FxiOS/\(AppInfo.appVersion) \(UserAgent.uaBitMobile) \(UserAgent.uaBitSafari)")
         */
        return UserAgentBuilder.ecosiaMobileUserAgent()
    }

    public static func defaultFirefoxMobileUserAgent() -> UserAgentBuilder {
        return UserAgentBuilder(
            product: UserAgent.product,
            systemInfo: "(\(UIDeviceDetails.model); CPU iPhone OS 18_7 like Mac OS X)",
            platform: UserAgent.platform,
            platformDetails: UserAgent.platformDetails,
            extensions: "FxiOS/\(AppInfo.appVersion) \(UserAgent.uaBitMobile) \(UserAgent.uaBitSafari)")
    }

    public static func defaultDesktopUserAgent() -> UserAgentBuilder {
        return UserAgentBuilder(
            product: UserAgent.product,
            systemInfo: "(Macintosh; Intel Mac OS X 10_15_7)",
            platform: UserAgent.platform,
            platformDetails: UserAgent.platformDetails,
            extensions: "Version/18.6 Safari/605.1.15")
    }
}

// Ecosia: Ecosia mobile UA.
extension UserAgentBuilder {
    public static func ecosiaMobileUserAgent() -> UserAgentBuilder {
        let formattedSystemVersion = UIDeviceDetails.systemVersion.replacingOccurrences(of: ".", with: "_")

        return UserAgentBuilder(
            product: UserAgent.product,
            systemInfo: "(\(UIDeviceDetails.model); CPU iPhone OS \(formattedSystemVersion) like Mac OS X)",
            platform: UserAgent.platform,
            platformDetails: UserAgent.platformDetails,
            extensions: "\(UserAgent.uaBitVersion) \(UserAgent.uaBitMobile) \(UserAgent.uaBitSafari) \(UserAgent.uaBitEcosia)")
    }
}
