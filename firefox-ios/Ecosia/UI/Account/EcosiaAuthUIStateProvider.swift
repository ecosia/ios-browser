// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Combine
import Common

/// Centralized, reactive authentication state provider for consistent UI state across all components
/// This eliminates the need for individual components to manage their own auth state observers
public final class EcosiaAuthUIStateProvider: ObservableObject {

    // MARK: - Published Properties

    /// Current authentication status
    @Published public private(set) var isLoggedIn: Bool = false

    /// Current user profile information
    @Published public private(set) var userProfile: UserProfile?

    /// Current seed count (server-based for logged in users, local for guests)
    @Published public private(set) var seedCount: Int = 1

    /// Current user avatar URL
    @Published public private(set) var avatarURL: URL?

    /// Current username for display
    @Published public private(set) var username: String?

    /// Balance increment for animations (temporary state)
    @Published public private(set) var balanceIncrement: Int?

    /// Current level number (from API for logged-in users, 1 for logged-out)
    @Published private var currentLevelNumber: Int = 1

    /// Current progress towards next level (from API for logged-in users, default 0.25 for initial state)
    @Published private var currentProgress: Double = 0.25

    // MARK: - Private Properties

    private var authStateObserver: NSObjectProtocol?
    private var userProfileObserver: NSObjectProtocol?
    private let accountsProvider: AccountsProviderProtocol
    private static var seedProgressManagerType: SeedProgressManagerProtocol.Type = UserDefaultsSeedProgressManager.self

    // MARK: - Singleton

    /// Shared instance for app-wide auth state
    public static let shared = EcosiaAuthUIStateProvider()

    private init(accountsProvider: AccountsProviderProtocol = AccountsProvider()) {
        self.accountsProvider = accountsProvider
        setupAuthStateMonitoring()
        initializeState()
    }

    deinit {
        if let observer = authStateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = userProfileObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Public Interface

    /// Computed property for user display text
    public var userDisplayText: String {
        username ?? String.localized(.guestUser)
    }

    /// Computed property for level display text
    /// Returns level number and name for logged-in users, empty string for logged-out users
    public var levelDisplayText: String {
        let levelNumber = currentLevelNumber
        let levelName = GrowthPointsLevelSystem.levelName(for: levelNumber)
        return "\(String.localized(.level)) \(levelNumber) - \(levelName)"
    }

    /// Computed property for level progress (0.0 to 1.0)
    /// Returns progress from API for logged-in users, 0.25 default for initial/logged-out state
    public var levelProgress: Double {
        guard isLoggedIn else {
            return 0.25 // Default progress for logged-out users
        }
        return currentProgress
    }

    // MARK: - Private Methods

    private func setupAuthStateMonitoring() {
        // Listen for auth state changes
        authStateObserver = NotificationCenter.default.addObserver(
            forName: .EcosiaAuthStateChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task {
                await self?.handleAuthStateChange(notification)
            }
        }

        // Listen for user profile updates
        userProfileObserver = NotificationCenter.default.addObserver(
            forName: .EcosiaUserProfileUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.handleUserProfileUpdate()
            }
        }
    }

    private func initializeState() {
        Task {
            // Initialize from EcosiaAuthenticationService.shared
            await updateFromAuthShared()

            // Initialize seed count based on auth state
            if EcosiaAuthenticationService.shared.isLoggedIn {
                EcosiaLogger.accounts.info("User logged in at startup - will load from backend")
                registerVisitIfNeeded()
            } else {
                EcosiaLogger.accounts.info("User logged out at startup - using local seed collection")
                await MainActor.run {
                    seedCount = Self.seedProgressManagerType.loadTotalSeedsCollected()
                }
            }
        }
    }

    @MainActor
    private func updateFromAuthShared() {
        isLoggedIn = EcosiaAuthenticationService.shared.isLoggedIn
        userProfile = EcosiaAuthenticationService.shared.userProfile
        avatarURL = userProfile?.pictureURL
        username = userProfile?.name
    }

    private func handleAuthStateChange(_ notification: Notification) async {
        // Update UI properties on main actor
        await updateFromAuthShared()

        // Handle specific auth actions (business logic can be nonisolated)
        if let actionType = notification.userInfo?["actionType"] as? EcosiaAuthActionType {
            switch actionType {
            case .userLoggedIn:
                EcosiaLogger.accounts.info("User logged in - registering visit")
                registerVisitIfNeeded()
            case .userLoggedOut:
                EcosiaLogger.accounts.info("User logged out - resetting to local seed collection")
                await resetToLocalSeedCollection()
            case .authStateLoaded:
                break // State already updated above
            }
        }
    }

    @MainActor
    private func handleUserProfileUpdate() {
        if isLoggedIn {
            userProfile = EcosiaAuthenticationService.shared.userProfile
            username = userProfile?.name
            avatarURL = userProfile?.pictureURL
        }
    }

    // MARK: - Seed Count Management

    private func registerVisitIfNeeded() {
        Task {
            do {
                guard let accessToken = EcosiaAuthenticationService.shared.accessToken, !accessToken.isEmpty else {
                    EcosiaLogger.accounts.debug("No access token available - user not logged in")
                    await handleLocalSeedCollection()
                    return
                }

                EcosiaLogger.accounts.info("Registering user visit for balance update")
                let response = try await accountsProvider.registerVisit(accessToken: accessToken)
                await updateBalance(response)
            } catch {
                EcosiaLogger.accounts.debug("Could not register visit: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    private func updateBalance(_ response: AccountVisitResponse) {
        let newSeedCount = response.seeds.totalAmount
        let newLevelNumber = response.growthPoints.level.number
        let newProgress = response.progressToNextLevel

        // Update level and progress from API
        currentLevelNumber = newLevelNumber
        currentProgress = newProgress

        if let increment = response.seedsIncrement {
            EcosiaLogger.accounts.info("Balance updated with animation: \(seedCount) → \(newSeedCount) (+\(increment)), level=\(newLevelNumber), progress=\(newProgress)")
            animateBalanceChange(from: seedCount, to: newSeedCount, increment: increment)
        } else {
            EcosiaLogger.accounts.info("Balance updated without animation: \(seedCount) → \(newSeedCount), level=\(newLevelNumber), progress=\(newProgress)")
            seedCount = newSeedCount
        }
    }

    @MainActor
    private func animateBalanceChange(from oldValue: Int, to newValue: Int, increment: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.balanceIncrement = increment

            withAnimation(.easeIn(duration: 0.3)) {
                self.seedCount = newValue
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.linear(duration: 0.57)) {
                    self.balanceIncrement = nil
                }
            }
        }
    }

    @MainActor
    private func resetToLocalSeedCollection() {
        EcosiaLogger.accounts.info("Resetting to local seed collection system")
        Self.seedProgressManagerType.resetCounter()

        seedCount = Self.seedProgressManagerType.loadTotalSeedsCollected()
        // Clear level data when logging out
        currentLevelNumber = 1
        currentProgress = 0.25 // Reset to default progress
    }

    @MainActor
    private func handleLocalSeedCollection() {
        EcosiaLogger.accounts.info("Handling local seed collection for logged-out user")
        Self.seedProgressManagerType.collectDailySeed()
        let newSeedCount = Self.seedProgressManagerType.loadTotalSeedsCollected()

        if newSeedCount > seedCount {
            let increment = newSeedCount - seedCount
            animateBalanceChange(from: seedCount, to: newSeedCount, increment: increment)
        } else {
            seedCount = newSeedCount
        }
    }
}
