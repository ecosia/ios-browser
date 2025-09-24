// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Combine
import Common

@available(iOS 16.0, *)
@MainActor
public final class EcosiaAccountAvatarViewModel: ObservableObject {

    @Published public var avatarURL: URL?
    @Published public var progress: Double
    @Published public var showSparkles = false

    private var authStateObserver: NSObjectProtocol?
    private var userProfileObserver: NSObjectProtocol?
    private var progressObserver: NSObjectProtocol?
    private var levelUpObserver: NSObjectProtocol?

    private struct UX {
        static let defaultProgress: Double = 0.25
        static let levelUpDuration: TimeInterval = 2.0
    }

    public init(
        avatarURL: URL? = nil,
        progress: Double = 0.25
    ) {
        self.avatarURL = avatarURL
        self.progress = max(0.0, min(1.0, progress))

        setupInitialState()
        setupObservers()
    }

    deinit {
        [authStateObserver, userProfileObserver, progressObserver, levelUpObserver].forEach {
            if let observer = $0 {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }

    public func updateAvatarURL(_ url: URL?) {
        avatarURL = url
    }

    public func updateProgress(_ newProgress: Double) {
        let clampedProgress = max(0.0, min(1.0, newProgress))
        progress = clampedProgress
        // Note: Level up is now handled by backend via EcosiaAccountLevelUp notification
    }

    public func levelUp() {
        progress = 1.0
        triggerSparkles(duration: UX.levelUpDuration)
        
        Task {
            try await Task.sleep(for: .seconds(UX.levelUpDuration))
            progress = 0.0
        }
    }

    public func triggerSparkles(duration: TimeInterval = 4.0) {
        showSparkles = true

        Task {
            try await Task.sleep(for: .seconds(duration))
            showSparkles = false
        }
    }
    
    /// Updates avatar progress based on AccountBalanceResponse
    /// This method should be called when balance data is received from the backend
    public func updateFromBalanceResponse(_ response: AccountBalanceResponse) {
        // Backend should provide level progress information in future API response
        // For now, this is a placeholder for when that data becomes available
        
        // Example of how it might work when backend provides level progress:
        // if let levelProgress = response.levelProgress {
        //     updateProgress(levelProgress)
        // }
        
        // The backend will handle level up logic and send EcosiaAccountLevelUp notification
        // when a user levels up, rather than calculating it client-side
    }

    private func setupInitialState() {
        if Auth.shared.isLoggedIn {
            avatarURL = Auth.shared.userProfile?.pictureURL
        }
    }

    private func setupObservers() {
        authStateObserver = NotificationCenter.default.addObserver(
            forName: .EcosiaAuthStateChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAuthStateChange()
        }

        userProfileObserver = NotificationCenter.default.addObserver(
            forName: .EcosiaUserProfileUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleUserProfileUpdate()
        }

        progressObserver = NotificationCenter.default.addObserver(
            forName: .EcosiaAccountProgressUpdated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleProgressUpdate(notification)
        }

        levelUpObserver = NotificationCenter.default.addObserver(
            forName: .EcosiaAccountLevelUp,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleLevelUp(notification)
        }
    }

    nonisolated private func handleAuthStateChange() {
        let newAvatarURL = Auth.shared.isLoggedIn ? Auth.shared.userProfile?.pictureURL : nil
        let shouldResetProgress = !Auth.shared.isLoggedIn

        Task { @MainActor in
            avatarURL = newAvatarURL
            if shouldResetProgress {
                progress = UX.defaultProgress
            }
        }
    }

    nonisolated private func handleUserProfileUpdate() {
        let newAvatarURL = Auth.shared.userProfile?.pictureURL

        Task { @MainActor in
            avatarURL = newAvatarURL
        }
    }

    nonisolated private func handleProgressUpdate(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let newProgress = userInfo[EcosiaAccountNotificationKeys.progress] as? Double else {
            return
        }

        Task { @MainActor in
            updateProgress(newProgress)
        }
    }

    nonisolated private func handleLevelUp(_ notification: Notification) {
        Task { @MainActor in
            levelUp()
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
extension EcosiaAccountAvatarViewModel {
    static func preview(
        avatarURL: URL? = URL(string: "https://avatars.githubusercontent.com/u/1?v=4"),
        progress: Double = 0.75,
        showSparkles: Bool = false
    ) -> EcosiaAccountAvatarViewModel {
        let viewModel = EcosiaAccountAvatarViewModel(
            avatarURL: avatarURL,
            progress: progress
        )

        if showSparkles {
            viewModel.showSparkles = true
        }

        return viewModel
    }
}
#endif
