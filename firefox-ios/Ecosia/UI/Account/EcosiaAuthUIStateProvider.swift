// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Combine

/// Centralized, reactive identity/profile state provider for consistent UI state across all
/// components. Seed/level/progress impact state lives in `ImpactManager` instead - a sibling,
/// not a child of this type - so callers who only care about who's logged in don't pull in
/// impact-tracking machinery, and vice versa.
@MainActor
public class EcosiaAuthUIStateProvider: ObservableObject {

    /// Auth0 gives us back a Gravatar URL when no profile picture URL is provided from a resource (e.g. Sign In with Apple)
    /// We want to strip it, therefore we track the URL
    private let gravatarURL = URL(string: "https://s.gravatar.com/avatar/")

    // MARK: - Published Properties

    /// Current authentication status
    @Published public private(set) var isLoggedIn: Bool = false

    /// Current user profile information
    @Published public private(set) var userProfile: UserProfile?

    /// Current user avatar URL
    @Published public private(set) var avatarURL: URL?

    /// Current username for display
    @Published public private(set) var username: String?

    // MARK: - Private Properties

    private var userProfileObserver: NSObjectProtocol?
    /// Normalizing the avatar to match Web's Product behaviour.
    /// Our Auth Provider (Auth0) sends us a Gravatar URL when no profile image is retrieved from a user
    /// (e.g. Apple Sign In). As of now, we replace it with our tree-image in `EcosiaAvatar` by not setting any URL
    private var normalizedAvatarURL: URL? {
        guard userProfile?.pictureURL?.baseDomain != gravatarURL?.baseDomain else { return nil }
        return userProfile?.pictureURL
    }

    // MARK: - Singleton

    /// Shared instance for app-wide auth state
    nonisolated(unsafe) public static let shared: EcosiaAuthUIStateProvider = {
        MainActor.assumeIsolated {
            EcosiaAuthUIStateProvider()
        }
    }()

    public init() {
        // Initialize state synchronously to prevent flickering
        self.isLoggedIn = EcosiaAuthenticationService.shared.isLoggedIn
        self.userProfile = EcosiaAuthenticationService.shared.userProfile
        self.avatarURL = normalizedAvatarURL
        self.username = userProfile?.name

        setupAuthStateMonitoring()
    }

    deinit {
        MainActor.assumeIsolated {
            if let observer = userProfileObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }

    // MARK: - Public Interface

    /// Computed property for user display text
    public var userDisplayText: String {
        username ?? String.localized(.guestUser)
    }

    // MARK: - Private Methods

    private func setupAuthStateMonitoring() {
        // Listen for user profile updates (these carry login-state changes too - see
        // handleUserProfileUpdate). Impact-related auth-state side effects (registering a visit,
        // resetting local seed collection) live in ImpactManager, which listens independently.
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

    @MainActor
    private func handleUserProfileUpdate() {
        isLoggedIn = EcosiaAuthenticationService.shared.isLoggedIn
        userProfile = EcosiaAuthenticationService.shared.userProfile
        username = userProfile?.name
        avatarURL = normalizedAvatarURL
    }
}
