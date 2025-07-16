// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import OSLog

// MARK: - Logger Extension

extension Logger {
    /// Using bundle identifier ensures a unique identifier for Ecosia logs
    private static var subsystem = "org.mozilla.ios.Ecosia"

    /// Authentication-related logs (login, logout, credentials)
    static let auth = Logger(subsystem: subsystem, category: "auth")

    /// Invisible tab management logs
    static let invisibleTabs = Logger(subsystem: subsystem, category: "invisibleTabs")

    /// Tab auto-close management logs
    static let tabAutoClose = Logger(subsystem: subsystem, category: "tabAutoClose")

    /// Session management logs (tokens, SSO)
    static let session = Logger(subsystem: subsystem, category: "session")

    /// Cookie injection and management logs
    static let cookies = Logger(subsystem: subsystem, category: "cookies")

    /// General Ecosia functionality logs
    static let general = Logger(subsystem: subsystem, category: "general")
}

// MARK: - EcosiaLogger Compatibility Layer

/// Centralized logging utility for Ecosia-specific functionality using OSLog
/// Provides backward compatibility while leveraging modern OSLog structured logging
public enum EcosiaLogger {

    /// Logs authentication-related events
    /// - Parameters:
    ///   - message: The log message
    ///   - level: Log level (info, debug, warning, error)
    public static func auth(_ message: String, level: LogLevel = .info) {
        level.log(message, using: .auth)
    }

    /// Logs invisible tab management events
    /// - Parameters:
    ///   - message: The log message
    ///   - level: Log level (info, debug, warning, error)
    public static func invisibleTabs(_ message: String, level: LogLevel = .info) {
        level.log(message, using: .invisibleTabs)
    }

    /// Logs tab auto-close management events
    /// - Parameters:
    ///   - message: The log message
    ///   - level: Log level (info, debug, warning, error)
    public static func tabAutoClose(_ message: String, level: LogLevel = .info) {
        level.log(message, using: .tabAutoClose)
    }

    /// Logs session management events
    /// - Parameters:
    ///   - message: The log message
    ///   - level: Log level (info, debug, warning, error)
    public static func session(_ message: String, level: LogLevel = .info) {
        level.log(message, using: .session)
    }

    /// Logs cookie injection and management events
    /// - Parameters:
    ///   - message: The log message
    ///   - level: Log level (info, debug, warning, error)
    public static func cookies(_ message: String, level: LogLevel = .info) {
        level.log(message, using: .cookies)
    }

    /// Generic logging method for other Ecosia functionality
    /// - Parameters:
    ///   - message: The log message
    ///   - category: Log category/prefix (legacy parameter, not used with OSLog)
    ///   - level: Log level (info, debug, warning, error)
    public static func log(_ message: String, category: String = "General", level: LogLevel = .info) {
        level.log(message, using: .general)
    }
}

// MARK: - Log Level

/// Log levels for Ecosia logging mapped to OSLog levels
public enum LogLevel {
    case debug    // Maps to OSLog.debug
    case info     // Maps to OSLog.info
    case warning  // Maps to OSLog.notice
    case error    // Maps to OSLog.error

    /// Logs a message using the specified Logger at the appropriate OSLog level
    /// - Parameters:
    ///   - message: The message to log
    ///   - logger: The Logger instance to use
    func log(_ message: String, using logger: Logger) {
        switch self {
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
