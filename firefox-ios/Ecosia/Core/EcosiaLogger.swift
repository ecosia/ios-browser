// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import OSLog

// MARK: - Logger Extension

extension Logger {
    /// Using bundle identifier ensures a unique identifier for Ecosia logs
    private static var subsystem = "com.ecosia.app.logging"

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

// MARK: - EcosiaLogger Migration Helper

/// Temporary compatibility layer to help migration from old EcosiaLogger to direct OSLog usage
/// TODO: Replace all EcosiaLogger calls with direct Logger usage and remove this
@available(*, deprecated, message: "Use Logger.auth.info(), Logger.invisibleTabs.debug(), etc. directly instead")
public enum EcosiaLogger {
    
    public static func auth(_ message: String, level: LogLevel = .info) {
        switch level {
        case .debug: Logger.auth.debug("\(message, privacy: .public)")
        case .info: Logger.auth.info("\(message, privacy: .public)")
        case .warning: Logger.auth.notice("\(message, privacy: .public)")
        case .error: Logger.auth.error("\(message, privacy: .public)")
        }
    }
    
    public static func invisibleTabs(_ message: String, level: LogLevel = .info) {
        switch level {
        case .debug: Logger.invisibleTabs.debug("\(message, privacy: .public)")
        case .info: Logger.invisibleTabs.info("\(message, privacy: .public)")
        case .warning: Logger.invisibleTabs.notice("\(message, privacy: .public)")
        case .error: Logger.invisibleTabs.error("\(message, privacy: .public)")
        }
    }
    
    public static func tabAutoClose(_ message: String, level: LogLevel = .info) {
        switch level {
        case .debug: Logger.tabAutoClose.debug("\(message, privacy: .public)")
        case .info: Logger.tabAutoClose.info("\(message, privacy: .public)")
        case .warning: Logger.tabAutoClose.notice("\(message, privacy: .public)")
        case .error: Logger.tabAutoClose.error("\(message, privacy: .public)")
        }
    }
    
    public static func session(_ message: String, level: LogLevel = .info) {
        switch level {
        case .debug: Logger.session.debug("\(message, privacy: .public)")
        case .info: Logger.session.info("\(message, privacy: .public)")
        case .warning: Logger.session.notice("\(message, privacy: .public)")
        case .error: Logger.session.error("\(message, privacy: .public)")
        }
    }
    
    public static func cookies(_ message: String, level: LogLevel = .info) {
        switch level {
        case .debug: Logger.cookies.debug("\(message, privacy: .public)")
        case .info: Logger.cookies.info("\(message, privacy: .public)")
        case .warning: Logger.cookies.notice("\(message, privacy: .public)")
        case .error: Logger.cookies.error("\(message, privacy: .public)")
        }
    }
    
    public static func log(_ message: String, category: String = "General", level: LogLevel = .info) {
        switch level {
        case .debug: Logger.general.debug("\(message, privacy: .public)")
        case .info: Logger.general.info("\(message, privacy: .public)")
        case .warning: Logger.general.notice("\(message, privacy: .public)")
        case .error: Logger.general.error("\(message, privacy: .public)")
        }
    }
}

// MARK: - Log Level (Deprecated)

/// Legacy log level enum - use OSLog levels directly instead
@available(*, deprecated, message: "Use OSLog methods directly: logger.debug(), logger.info(), logger.notice(), logger.error()")
public enum LogLevel {
    case debug
    case info
    case warning
    case error
}
