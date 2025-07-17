// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Ecosia-specific logging levels following established patterns
public enum LogLevel {
    case debug
    case info
    case warning
    case error
}

/// Protocol for category-specific logging with default implementations
public protocol EcosiaLoggerCategory {
    static var prefix: String { get }
}

public extension EcosiaLoggerCategory {
    static func debug(_ message: String) {
        EcosiaLogger.debug("\(prefix) \(message)")
    }

    static func info(_ message: String) {
        EcosiaLogger.info("\(prefix) \(message)")
    }

    static func notice(_ message: String) {
        EcosiaLogger.warning("\(prefix) \(message)")
    }

    static func error(_ message: String) {
        EcosiaLogger.error("\(prefix) \(message)")
    }
}

/// Ecosia-specific logger that avoids conflicts with Firefox's logging system
public enum EcosiaLogger {

    static let prefix: String = "Ecosia Logger"

    /// Log a debug message
    public static func debug(_ message: String) {
        print("\(prefix): 🔍 [DEBUG] \(message)")
    }

    /// Log an info message  
    public static func info(_ message: String) {
        print("\(prefix): ℹ️ [INFO] \(message)")
    }

    /// Log a warning message
    public static func warning(_ message: String) {
        print("\(prefix): ⚠️ [WARNING] \(message)")
    }

    /// Log an error message
    public static func error(_ message: String) {
        print("\(prefix): ❌ [ERROR] \(message)")
    }

    /// Generic log method with level
    public static func log(_ message: String, level: LogLevel) {
        switch level {
        case .debug:
            debug(message)
        case .info:
            info(message)
        case .warning:
            warning(message)
        case .error:
            error(message)
        }
    }

    // Category-specific loggers
    public enum auth: EcosiaLoggerCategory {
        public static let prefix = "🔐 [AUTH]"
    }

    public enum invisibleTabs: EcosiaLoggerCategory {
        public static let prefix = "👻 [TABS]"
    }

    public enum tabAutoClose: EcosiaLoggerCategory {
        public static let prefix = "⏰ [AUTO-CLOSE]"
    }

    public enum session: EcosiaLoggerCategory {
        public static let prefix = "🎫 [SESSION]"
    }

    public enum cookies: EcosiaLoggerCategory {
        public static let prefix = "🍪 [COOKIES]"
    }

    public enum general: EcosiaLoggerCategory {
        public static let prefix = "🌱 [GENERAL]"
    }
}
