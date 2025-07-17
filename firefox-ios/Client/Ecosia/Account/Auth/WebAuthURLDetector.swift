// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Ecosia

/// Detects Ecosia authentication URLs from web navigation and triggers native auth flows
/// Single responsibility: Monitor web URLs and coordinate with EcosiaAuth
final class WebAuthURLDetector {
    
    // MARK: - Properties
    
    private weak var authManager: EcosiaAuth?
    private let urlProvider: URLProvider
    
    // URL patterns for authentication detection
    private let signInPaths = ["/accounts/sign-up", "/login", "/signin", "/auth/login"]
    private let signOutPaths = ["/accounts/sign-out", "/logout", "/signout", "/auth/logout"]
    
    // MARK: - Initialization
    
    /// Initializes the WebAuthURLDetector
    /// - Parameters:
    ///   - authManager: The EcosiaAuth instance to trigger auth flows
    ///   - urlProvider: URL provider for environment detection
    init(authManager: EcosiaAuth, urlProvider: URLProvider = Environment.current.urlProvider) {
        self.authManager = authManager
        self.urlProvider = urlProvider
        
        setupNotificationObserver()
        EcosiaLogger.auth.info("WebAuthURLDetector initialized")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        EcosiaLogger.auth.debug("WebAuthURLDetector deallocated")
    }
    
    // MARK: - Setup
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLocationChange),
            name: .OnLocationChange,
            object: nil
        )
    }
    
    // MARK: - URL Detection
    
    @objc private func handleLocationChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let url = userInfo["url"] as? URL else {
            return
        }
        
        detectAndHandleAuthURL(url)
    }
    
    /// Detects authentication URLs and triggers appropriate native flows
    /// - Parameter url: The URL to analyze
    func detectAndHandleAuthURL(_ url: URL) {
        guard url.isEcosia() else { return }
        
        if isSignInURL(url) {
            handleSignInDetection(url)
        } else if isSignOutURL(url) {
            handleSignOutDetection(url)
        }
    }
        
    private func isSignInURL(_ url: URL) -> Bool {
        let path = url.path.lowercased()
        return signInPaths.contains { path.contains($0) }
    }
    
    private func isSignOutURL(_ url: URL) -> Bool {
        let path = url.path.lowercased()
        return signOutPaths.contains { path.contains($0) }
    }
    
    // MARK: - Authentication Flow Triggers
    
    private func handleSignInDetection(_ url: URL) {
        guard let authManager = authManager else {
            EcosiaLogger.auth.notice("No auth manager available for sign-in detection")
            return
        }
        
        // Only trigger if user is not already logged in
        guard !authManager.isLoggedIn else {
            EcosiaLogger.auth.debug("User already logged in, skipping sign-in detection for: \(url)")
            return
        }
        
        EcosiaLogger.auth.info("🔐 [WEB-AUTH] Sign-in URL detected: \(url)")
        EcosiaLogger.auth.info("🔐 [WEB-AUTH] Triggering native authentication flow")
        
        // Trigger native authentication
        authManager.login()
            .onNativeAuthCompleted {
                EcosiaLogger.auth.info("🔐 [WEB-AUTH] Native authentication completed from web sign-in detection")
            }
            .onAuthFlowCompleted { success in
                if success {
                    EcosiaLogger.auth.info("🔐 [WEB-AUTH] Complete authentication flow successful from web detection")
                } else {
                    EcosiaLogger.auth.notice("🔐 [WEB-AUTH] Authentication flow completed with issues from web detection")
                }
            }
            .onError { error in
                EcosiaLogger.auth.error("🔐 [WEB-AUTH] Authentication failed from web detection: \(error)")
            }
    }
    
    private func handleSignOutDetection(_ url: URL) {
        guard let authManager = authManager else {
            EcosiaLogger.auth.notice("No auth manager available for sign-out detection")
            return
        }
        
        // Only trigger if user is currently logged in
        guard authManager.isLoggedIn else {
            EcosiaLogger.auth.debug("User not logged in, skipping sign-out detection for: \(url)")
            return
        }
        
        EcosiaLogger.auth.info("🔐 [WEB-AUTH] Sign-out URL detected: \(url)")
        EcosiaLogger.auth.info("🔐 [WEB-AUTH] Triggering native logout flow")
        
        // Trigger native logout
        authManager.logout()
            .onNativeAuthCompleted {
                EcosiaLogger.auth.info("🔐 [WEB-AUTH] Native logout completed from web sign-out detection")
            }
            .onAuthFlowCompleted { success in
                if success {
                    EcosiaLogger.auth.info("🔐 [WEB-AUTH] Complete logout flow successful from web detection")
                } else {
                    EcosiaLogger.auth.notice("🔐 [WEB-AUTH] Logout flow completed with issues from web detection")
                }
            }
            .onError { error in
                EcosiaLogger.auth.error("🔐 [WEB-AUTH] Logout failed from web detection: \(error)")
            }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let OnLocationChange = Notification.Name("OnLocationChange")
} 
