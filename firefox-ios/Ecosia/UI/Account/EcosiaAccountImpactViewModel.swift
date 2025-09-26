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
    private let onDismissAction: () -> Void
    private var previousSeedCount: Int = 0
    
    // MARK: - Initialization
    public init(
        isLoggedIn: Bool,
        username: String? = nil,
        currentLevel: String? = nil,
        avatarURL: URL? = nil,
        seedCount: Int = 0,
        onLogin: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.isLoggedIn = isLoggedIn
        self.username = username
        self.currentLevel = currentLevel
        self.avatarURL = avatarURL
        self.seedCount = seedCount
        self.previousSeedCount = seedCount
        self.onLoginAction = onLogin
        self.onDismissAction = onDismiss
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
        
    /// The level text to display - always shows the level based on seed count
    public var levelDisplayText: String {
        let level = AccountSeedLevelSystem.currentLevel(for: seedCount)
        let levelName = String.localized(.init(rawValue: level.nameKey) ?? .ecocurious)
        return "\(String.localized(.level)) \(level.level) - \(levelName)"
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
