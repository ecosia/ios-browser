// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Combine
import Common

/// Centralized, reactive authentication state provider for consistent UI state across all components
/// This eliminates the need for individual components to manage their own auth state observers
public final class EcosiaAuthStateProvider: ObservableObject {

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

    // MARK: - Private Properties

    private var authStateObserver: NSObjectProtocol?
    private var userProfileObserver: NSObjectProtocol?
    private let accountsProvider: AccountsProviderProtocol
    private static var seedProgressManagerType: SeedProgressManagerProtocol.Type = UserDefaultsSeedProgressManager.self

    // MARK: - Singleton

    /// Shared instance for app-wide auth state
    public static let shared = EcosiaAuthStateProvider()

    private init(accountsProvider: AccountsProviderProtocol = AccountsProvider(useMockData: true)) {
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
    public var levelDisplayText: String {
        let level = AccountSeedLevelSystem.currentLevel(for: seedCount)
        let levelName = level.localizedName
        return "\(String.localized(.level)) \(level.level) - \(levelName)"
    }

    /// Computed property for level progress (0.0 to 1.0)
    public var levelProgress: Double {
        if isLoggedIn {
            return AccountSeedLevelSystem.progressToNextLevel(for: seedCount)
        } else {
            return 0.25 // Default progress for guest users
        }
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
            // Initialize from Auth.shared
            await updateFromAuthShared()

            // Initialize seed count based on auth state
            if Auth.shared.isLoggedIn {
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

    private func updateFromAuthShared() async {
        await MainActor.run {
            isLoggedIn = Auth.shared.isLoggedIn
            userProfile = Auth.shared.userProfile
            avatarURL = userProfile?.pictureURL
            username = userProfile?.name
        }
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

    private func handleUserProfileUpdate() async {
        await MainActor.run {
            if isLoggedIn {
                userProfile = Auth.shared.userProfile
                username = userProfile?.name
                avatarURL = userProfile?.pictureURL
            }
        }
    }

    // MARK: - Seed Count Management

    private func registerVisitIfNeeded() {
        Task {
            do {
                guard let accessToken = Auth.shared.accessToken, !accessToken.isEmpty else {
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

    private func updateBalance(_ response: AccountVisitResponse) async {
        let newSeedCount = response.balance.amount

        await MainActor.run {
            if let increment = response.balanceIncrement {
                EcosiaLogger.accounts.info("Balance updated with animation: \(seedCount) → \(newSeedCount) (+\(increment))")
                animateBalanceChange(from: seedCount, to: newSeedCount, increment: increment)
            } else {
                EcosiaLogger.accounts.info("Balance updated without animation: \(seedCount) → \(newSeedCount)")
                seedCount = newSeedCount
            }
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

    private func resetToLocalSeedCollection() async {
        EcosiaLogger.accounts.info("Resetting to local seed collection system")
        Self.seedProgressManagerType.resetCounter()

        await MainActor.run {
            seedCount = Self.seedProgressManagerType.loadTotalSeedsCollected()
        }
    }

    private func handleLocalSeedCollection() async {
        EcosiaLogger.accounts.info("Handling local seed collection for logged-out user")
        Self.seedProgressManagerType.collectDailySeed()
        let newSeedCount = Self.seedProgressManagerType.loadTotalSeedsCollected()

        await MainActor.run {
            if newSeedCount > seedCount {
                let increment = newSeedCount - seedCount
                animateBalanceChange(from: seedCount, to: newSeedCount, increment: increment)
            } else {
                seedCount = newSeedCount
            }
        }
    }
}
