// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// ViewModel for the EcosiaAccountImpactView that manages user account state and actions
@available(iOS 16.0, *)
@MainActor
public class EcosiaAccountImpactViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published public var isLoggedIn: Bool
    @Published public var username: String?
    @Published public var currentLevel: String?
    @Published public var avatarURL: URL?
    @Published public var seedCount: Int
    @Published public var isLoading: Bool = false
    @Published public var shouldShowLevelUpAnimation: Bool = false

    // MARK: - Private Properties
    private let onLoginAction: () -> Void
    private let onLogoutAction: (() -> Void)?
    private let onDismissAction: () -> Void
    private var previousSeedCount: Int = 0
    private var authStateObserver: NSObjectProtocol?
    private var userProfileObserver: NSObjectProtocol?

    // MARK: - Initialization
    public init(
        isLoggedIn: Bool,
        username: String? = nil,
        currentLevel: String? = nil,
        avatarURL: URL? = nil,
        seedCount: Int = 0,
        onLogin: @escaping () -> Void,
        onLogout: (() -> Void)? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.isLoggedIn = isLoggedIn
        self.username = username
        self.currentLevel = currentLevel
        self.avatarURL = avatarURL
        self.seedCount = seedCount
        self.previousSeedCount = seedCount
        self.onLoginAction = onLogin
        self.onLogoutAction = onLogout
        self.onDismissAction = onDismiss
        
        // Set up auth state monitoring
        setupAuthStateMonitoring()
    }
    
    deinit {
        // Remove notification observers
        if let observer = authStateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = userProfileObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Public Methods

    /// Handles the main CTA button tap (login for guests, or custom action for logged-in users)
    public func handleMainCTATap() {
        Analytics.shared.accountImpactSignUpClicked()

        if isLoggedIn {
            // For logged-in users, this could be a different action
            // For now, we'll just dismiss
            handleDismiss()
        } else {
            handleLogin()
        }
    }

    /// Handles the login action
    public func handleLogin() {
        isLoading = true
        onLoginAction()
        // Note: The loading state will be updated when the parent view updates the auth state
    }

    /// Handles dismissing the view
    public func handleDismiss() {
        Analytics.shared.accountImpactCloseClicked()
        onDismissAction()
    }

    /// Resets the level up animation state
    public func resetLevelUpAnimation() {
        shouldShowLevelUpAnimation = false
    }

    /// Handles the "Learn more about seeds" link tap
    public func handleLearnMoreTap() {
        Analytics.shared.accountImpactCardCtaClicked()
    }

    /// Handles the logout action
    public func handleLogout() async {
        if let onLogoutAction = onLogoutAction {
            // Use the provided logout callback for proper web session clearing
            onLogoutAction()
        } else {
            // Fallback to direct Auth.shared.logout() if no callback provided
            do {
                try await Auth.shared.logout()
                // Update state to logged out immediately with reset values
                updateState(
                    isLoggedIn: false,
                    username: nil,
                    currentLevel: nil,
                    avatarURL: nil,
                    seedCount: 1
                )
            } catch {
                EcosiaLogger.auth.error("Failed to logout: \(error)")
                // Handle logout error if needed
            }
        }
    }

    /// Updates the view model state
    public func updateState(
        isLoggedIn: Bool,
        username: String? = nil,
        currentLevel: String? = nil,
        avatarURL: URL? = nil,
        seedCount: Int = 0
    ) {
        // Check for level up before updating seed count
        if seedCount > self.seedCount {
            let levelUpResult = AccountSeedLevelSystem.checkLevelUp(from: self.seedCount, to: seedCount)
            self.shouldShowLevelUpAnimation = levelUpResult != nil
        }

        self.isLoggedIn = isLoggedIn
        self.username = username
        self.currentLevel = currentLevel
        self.avatarURL = avatarURL
        self.previousSeedCount = self.seedCount
        self.seedCount = seedCount
        self.isLoading = false
    }
    
    // MARK: - Auth State Monitoring
    
    private func setupAuthStateMonitoring() {
        // Listen for auth state changes
        authStateObserver = NotificationCenter.default.addObserver(
            forName: .EcosiaAuthStateChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAuthStateChange(notification)
        }
        
        // Listen for user profile updates
        userProfileObserver = NotificationCenter.default.addObserver(
            forName: .EcosiaUserProfileUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleUserProfileUpdate()
        }
    }
    
    private func handleAuthStateChange(_ notification: Notification) {
        // Update auth state from the global Auth singleton
        let newIsLoggedIn = Auth.shared.isLoggedIn
        let newUsername = Auth.shared.userProfile?.name
        let newAvatarURL = Auth.shared.userProfile?.pictureURL
        
        // Only update if state actually changed to avoid unnecessary UI updates
        if newIsLoggedIn != isLoggedIn {
            updateState(
                isLoggedIn: newIsLoggedIn,
                username: newUsername,
                currentLevel: newIsLoggedIn ? currentLevel : nil,
                avatarURL: newAvatarURL,
                seedCount: newIsLoggedIn ? seedCount : 1 // Reset to 1 for guest users
            )
        }
    }
    
    private func handleUserProfileUpdate() {
        if isLoggedIn {
            username = Auth.shared.userProfile?.name
            avatarURL = Auth.shared.userProfile?.pictureURL
        }
    }
}

// MARK: - Computed Properties
@available(iOS 16.0, *)
extension EcosiaAccountImpactViewModel {

    /// The text to display for the user section
    public var userDisplayText: String {
        username ?? String.localized(.guestUser)
    }

    /// The text for the main CTA button
    public var mainCTAText: String {
        String.localized(.signUp)
    }

    /// The level text to display - shows level for logged in users, ecocurious for guests
    public var levelDisplayText: String {
        if isLoggedIn {
            let level = AccountSeedLevelSystem.currentLevel(for: seedCount)
            let levelName = level.localizedName
            return "\(String.localized(.level)) \(level.level) - \(levelName)"
        } else {
            return "\(String.localized(.level)) 1 - \(String.localized(.ecocurious))"
        }
    }

    /// Progress for the avatar (0.0 to 1.0)
    public var levelProgress: Double {
        if isLoggedIn {
            return AccountSeedLevelSystem.progressToNextLevel(for: seedCount)
        } else {
            return 0.25 // Default progress for guest users
        }
    }
}
