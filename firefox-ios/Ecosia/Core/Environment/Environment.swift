// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public enum Environment: Equatable {
    case production
    case staging
    case debug
}

extension Environment {

    public static var current: Environment {
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
    
    // Alternative: Bundle ID based detection
    public static var currentFromBundleId: Environment {
        guard let bundleId = Bundle.main.bundleIdentifier else {
            return .debug
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

    // Alternative: Environment variable based detection
    public static var currentFromEnvironmentVariable: Environment {
        if let envVar = ProcessInfo.processInfo.environment["ECOSIA_ENVIRONMENT"] {
            switch envVar.lowercased() {
            case "production":
                return .production
            case "staging", "beta":
                return .staging
            default:
                return .debug
            }
        }
        return .debug
    }

    // Alternative: Info.plist based detection
    public static var currentFromInfoPlist: Environment {
        guard let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let envString = plist["EcosiaEnvironment"] as? String else {
            return .debug
        }
        
        switch envString.lowercased() {
        case "production":
            return .production
        case "staging", "beta":
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
