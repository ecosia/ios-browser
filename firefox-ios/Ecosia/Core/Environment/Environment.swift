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
        /*
         * Why not xcconfig compilation flags (SWIFT_ACTIVE_COMPILATION_CONDITIONS / #if DEBUG)?
         * - Project configs had SWIFT_ACTIVE_COMPILATION_CONDITIONS = ""; blocking xcconfig inheritance
         * - Multiple BetaDebug configs with same name, Xcode uses wrong one
         * - EcosiaTesting.xcconfig works because it sets explicit value, not empty string
         *
         * Solution: Bundle ID detection is more reliable than build config inheritance. The one
         * exception is below: _isDebugAssertConfiguration() isn't a custom macro - it reflects
         * SWIFT_OPTIMIZATION_LEVEL (-Onone vs -O), which Xcode sets per-target automatically and
         * isn't subject to either of the failure modes above.
         */
        guard let bundleId = Bundle.main.bundleIdentifier else {
            return .production
        }

        switch bundleId {
        case "com.ecosia.ecosiaapp":
            // EcosiaDebug.xcconfig deliberately keeps this the same as production's bundle ID for
            // parity, so a genuine Debug build of it should hit staging instead - only a real
            // Release build of this bundle ID is actual production.
            return _isDebugAssertConfiguration() ? .staging : .production
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
