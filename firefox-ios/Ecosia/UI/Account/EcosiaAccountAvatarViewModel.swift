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
    @Published public var currentLevel: AccountSeedLevel
    @Published public var seedCount: Int = 0

    private var authStateObserver: NSObjectProtocol?
    private var userProfileObserver: NSObjectProtocol?
    private var progressObserver: NSObjectProtocol?
    private var levelUpObserver: NSObjectProtocol?
    private var previousSeedCount: Int = 0

    private struct UX {
        static let defaultProgress: Double = 0.25
        static let levelUpDuration: TimeInterval = 2.0
    }

    public init(
        avatarURL: URL? = nil,
        progress: Double = 0.25,
        seedCount: Int = 0
    ) {
        self.avatarURL = avatarURL
        self.progress = max(0.0, min(1.0, progress))
        self.seedCount = seedCount
        self.previousSeedCount = seedCount
        self.currentLevel = AccountSeedLevelSystem.currentLevel(for: seedCount)

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
        }

#if DEBUG
    /// Manual level up for testing/previews only
    public func levelUp() {
        progress = 1.0
        triggerSparkles(duration: UX.levelUpDuration)

        Task {
            try await Task.sleep(for: .seconds(UX.levelUpDuration))
            progress = 0.0
        }
    }
#endif

    public func triggerSparkles(duration: TimeInterval = 4.0) {
        showSparkles = true

        Task {
            try await Task.sleep(for: .seconds(duration))
            showSparkles = false
        }
    }

    /// Updates avatar progress based on AccountVisitResponse
    public func updateFromBalanceResponse(_ response: AccountVisitResponse) {
        let newSeedCount = response.balance.amount
        updateSeedCount(newSeedCount)

        EcosiaLogger.accounts.info("Avatar received balance update: \(response.balance.amount), isModified: \(response.balance.isModified)")
    }

    /// Updates seed count and handles level progression
    public func updateSeedCount(_ newSeedCount: Int) {
        previousSeedCount = seedCount
        seedCount = newSeedCount

        let newLevel = AccountSeedLevelSystem.currentLevel(for: seedCount)
        let newProgress = AccountSeedLevelSystem.progressToNextLevel(for: seedCount)

        if let leveledUp = AccountSeedLevelSystem.checkLevelUp(from: previousSeedCount, to: seedCount) {
            currentLevel = leveledUp
            progress = newProgress

            triggerLevelUpAnimation()

            EcosiaLogger.accounts.info("User leveled up to \(leveledUp.level): \(leveledUp.localizedName)")
        } else {
            currentLevel = newLevel
            progress = newProgress
        }
    }

    private func triggerLevelUpAnimation() {
        progress = 1.0
        triggerSparkles(duration: UX.levelUpDuration)

        Task {
            try await Task.sleep(for: .seconds(UX.levelUpDuration))
            let actualProgress = AccountSeedLevelSystem.progressToNextLevel(for: seedCount)
            progress = actualProgress
        }
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
