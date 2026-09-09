// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public enum Environment: Equatable, Sendable {
    case production
    case staging
    case debug
}

extension Environment {

    public static var current: Environment {
        // EcosiaDebug.xcconfig sets ECOSIA_ENVIRONMENT_OVERRIDE=staging so the "Ecosia" debug
        // scheme hits staging (ecosia-staging.xyz, login.ecosia-staging.xyz) for local testing,
        // without changing MOZ_BUNDLE_ID away from production's - it deliberately keeps that
        // bundle ID for parity with production (see EcosiaDebug.xcconfig), and reusing the
        // staging bundle ID here would collide with the "Ecosia Beta" scheme when both are
        // installed on the same device/simulator. Every other scheme leaves this key unset, so
        // it falls through to the bundle ID detection below unchanged.
        if let override = EnvironmentFetcher.valueFromMainBundleOrProcessInfo(forKey: "ECOSIA_ENVIRONMENT_OVERRIDE") {
            switch override {
            case "staging":
                return .staging
            case "production":
                return .production
            case "debug":
                return .debug
            default:
                break
            }
        }

        /*
         * Why not xcconfig compilation flags?
         * - Project configs had SWIFT_ACTIVE_COMPILATION_CONDITIONS = ""; blocking xcconfig inheritance
         * - Multiple BetaDebug configs with same name, Xcode uses wrong one
         * - EcosiaTesting.xcconfig works because it sets explicit value, not empty string
         *
         * Solution: Bundle ID detection is more reliable than build config inheritance
         */
        guard let bundleId = Bundle.main.bundleIdentifier else {
            return .production
        }

        switch bundleId {
        case "com.ecosia.ecosiaapp":
            return .production
        case "com.ecosia.ecosiaapp.firefox":
            return .staging
        default:
            return .debug
        }
    }
}

extension Environment {

    public var urlProvider: URLProvider {
        switch self {
        case .production:
            return .production
        case .staging:
            return .staging
        case .debug:
            return .debug
        }
    }
}

extension Environment {

    /// Sentry environment tag for this build.
    /// Threaded into BrowserKit's `CrashManager` via `BrowserKitInformation.environmentName`.
    public var sentryTag: String {
        switch self {
        case .production:
            return "production"
        case .staging:
            return "staging"
        case .debug:
            return "debug"
        }
    }
}
