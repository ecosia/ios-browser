// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Centralized logging utility for Ecosia-specific functionality
/// Available to both Ecosia framework and Client module code
public enum EcosiaLogger {
    
    /// Controls whether debug logging is enabled
    /// Only enabled for debug builds to avoid noise in production
    private static var debugLogging: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Logging Methods
    
    /// Logs authentication-related events
    /// - Parameters:
    ///   - message: The log message
    ///   - level: Log level (info, debug, warning, error)
    public static func auth(_ message: String, level: LogLevel = .info) {
        log(message, category: "🔐 Auth", level: level)
    }
    
    /// Logs invisible tab management events
    /// - Parameters:
    ///   - message: The log message
    ///   - level: Log level (info, debug, warning, error)
    public static func invisibleTabs(_ message: String, level: LogLevel = .info) {
        log(message, category: "👻 InvisibleTabs", level: level)
    }
    
    /// Logs tab auto-close management events
    /// - Parameters:
    ///   - message: The log message
    ///   - level: Log level (info, debug, warning, error)
    public static func tabAutoClose(_ message: String, level: LogLevel = .info) {
        log(message, category: "⏱️  TabAutoClose", level: level)
    }
    
    /// Logs session management events
    /// - Parameters:
    ///   - message: The log message
    ///   - level: Log level (info, debug, warning, error)
    public static func session(_ message: String, level: LogLevel = .info) {
        log(message, category: "🎫 Session", level: level)
    }
    
    /// Logs cookie injection and management events
    /// - Parameters:
    ///   - message: The log message
    ///   - level: Log level (info, debug, warning, error)
    public static func cookies(_ message: String, level: LogLevel = .info) {
        log(message, category: "🍪 Cookies", level: level)
    }
    
    /// Generic logging method for other Ecosia functionality
    /// - Parameters:
    ///   - message: The log message
    ///   - category: Log category/prefix
    ///   - level: Log level (info, debug, warning, error)
    public static func log(_ message: String, category: String = "🌳 Ecosia", level: LogLevel = .info) {
        // Only log if debug logging is enabled or if it's a warning/error
        guard debugLogging || level.shouldAlwaysLog else { return }
        
        let timestamp = DateFormatter.logTimestamp.string(from: Date())
        let levelIndicator = level.indicator
        print("Ecosia Logging: \(timestamp) \(levelIndicator) \(category) - \(message)")
    }
}

// MARK: - Log Level

/// Log levels for Ecosia logging
public enum LogLevel {
    case debug
    case info
    case warning
    case error
    
    /// Visual indicator for the log level
    var indicator: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
    
    /// Whether this log level should always be shown regardless of debug settings
    var shouldAlwaysLog: Bool {
        switch self {
        case .debug, .info: return false
        case .warning, .error: return true
        }
    }
}

// MARK: - Extensions

private extension DateFormatter {
    static let logTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
} 
