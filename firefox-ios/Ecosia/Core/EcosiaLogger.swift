// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import OSLog

/// Centralized logging utility for Ecosia-specific functionality using OSLog
/// Available to both Ecosia framework and Client module code
public enum EcosiaLogger {

    // MARK: - OSLog Loggers

    /// Main subsystem identifier for Ecosia logs
    private static let subsystem = "org.mozilla.ios.Ecosia"

    /// Authentication-related logger
    private static let authLogger = Logger(subsystem: subsystem, category: "Auth")

    /// Invisible tab management logger
    private static let invisibleTabsLogger = Logger(subsystem: subsystem, category: "InvisibleTabs")

    /// Tab auto-close management logger
    private static let tabAutoCloseLogger = Logger(subsystem: subsystem, category: "TabAutoClose")

    /// Session management logger
    private static let sessionLogger = Logger(subsystem: subsystem, category: "Session")

    /// Cookie injection and management logger
    private static let cookiesLogger = Logger(subsystem: subsystem, category: "Cookies")

    /// Generic Ecosia functionality logger
    private static let generalLogger = Logger(subsystem: subsystem, category: "General")

    // MARK: - Logging Methods

    /// Logs authentication-related events
    /// - Parameters:
    ///   - message: The log message
    ///   - level: Log level (info, debug, warning, error)
    public static func auth(_ message: String, level: LogLevel = .info) {
        log(message: message, logger: authLogger, level: level)
    }

    /// Logs invisible tab management events
    /// - Parameters:
    ///   - message: The log message
    ///   - level: Log level (info, debug, warning, error)
    public static func invisibleTabs(_ message: String, level: LogLevel = .info) {
        log(message: message, logger: invisibleTabsLogger, level: level)
    }

    /// Logs tab auto-close management events
    /// - Parameters:
    ///   - message: The log message
    ///   - level: Log level (info, debug, warning, error)
    public static func tabAutoClose(_ message: String, level: LogLevel = .info) {
        log(message: message, logger: tabAutoCloseLogger, level: level)
    }

    /// Logs session management events
    /// - Parameters:
    ///   - message: The log message
    ///   - level: Log level (info, debug, warning, error)
    public static func session(_ message: String, level: LogLevel = .info) {
        log(message: message, logger: sessionLogger, level: level)
    }

    /// Logs cookie injection and management events
    /// - Parameters:
    ///   - message: The log message
    ///   - level: Log level (info, debug, warning, error)
    public static func cookies(_ message: String, level: LogLevel = .info) {
        log(message: message, logger: cookiesLogger, level: level)
    }

    /// Generic logging method for other Ecosia functionality
    /// - Parameters:
    ///   - message: The log message
    ///   - category: Log category/prefix (legacy parameter, not used with OSLog)
    ///   - level: Log level (info, debug, warning, error)
    public static func log(_ message: String, category: String = "General", level: LogLevel = .info) {
        log(message: message, logger: generalLogger, level: level)
    }

    // MARK: - Private Implementation

    /// Internal logging method that maps to OSLog levels
    /// - Parameters:
    ///   - message: The log message
    ///   - logger: The OSLog Logger instance to use
    ///   - level: The log level
    private static func log(message: String, logger: Logger, level: LogLevel) {
        switch level {
        case .debug:
            logger.debug("\(message, privacy: .public)")
        case .info:
            logger.info("\(message, privacy: .public)")
        case .warning:
            logger.notice("\(message, privacy: .public)")
        case .error:
            logger.error("\(message, privacy: .public)")
        }
    }
}

// MARK: - Log Level

/// Log levels for Ecosia logging mapped to OSLog levels
public enum LogLevel {
    case debug    // Maps to OSLog.debug
    case info     // Maps to OSLog.info
    case warning  // Maps to OSLog.notice
    case error    // Maps to OSLog.error

    /// Visual indicator for the log level (legacy support)
    var indicator: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }

    /// Whether this log level should always be shown (legacy support)
    var shouldAlwaysLog: Bool {
        switch self {
        case .debug, .info: return false
        case .warning, .error: return true
        }
    }
}
