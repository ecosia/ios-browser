// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Combine
import Common

/// ViewModel for managing account avatar state and handling progress/level notifications
@available(iOS 16.0, *)
@MainActor
public final class EcosiaAccountAvatarViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var avatarURL: URL?
    @Published public var progress: Double
    @Published public var showSparkles = false
    
    // MARK: - Private Properties
    
    private var authStateObserver: NSObjectProtocol?
    private var userProfileObserver: NSObjectProtocol?
    private var progressObserver: NSObjectProtocol?
    private var levelUpObserver: NSObjectProtocol?
    
    // MARK: - Initialization
    
    public init(
        avatarURL: URL? = nil,
        progress: Double = 0.25
    ) {
        self.avatarURL = avatarURL
        self.progress = max(0.0, min(1.0, progress)) // Clamp between 0.0 and 1.0
        
        setupInitialState()
        setupObservers()
    }
    
    deinit {
        removeObservers()
    }
    
    // MARK: - Public Methods
    
    /// Manually update the avatar URL
    /// - Parameter url: The new avatar URL
    public func updateAvatarURL(_ url: URL?) {
        avatarURL = url
    }
    
    /// Manually update the progress
    /// - Parameter newProgress: The new progress value (0.0 to 1.0)
    public func updateProgress(_ newProgress: Double) {
        progress = max(0.0, min(1.0, newProgress))
    }
    
    /// Trigger sparkle animation manually
    /// - Parameter duration: Duration to show sparkles (default: 2.0 seconds)
    public func triggerSparkles(duration: TimeInterval = 2.0) {
        showSparkles = true
        
        Task {
            try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            showSparkles = false
        }
    }
    
    // MARK: - Private Methods
    
    private func setupInitialState() {
        // Set initial avatar URL if user is logged in
        if Auth.shared.isLoggedIn {
            avatarURL = Auth.shared.userProfile?.pictureURL
        }
    }
    
    private func setupObservers() {
        // Listen for auth state changes
        authStateObserver = NotificationCenter.default.addObserver(
            forName: .EcosiaAuthStateChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAuthStateChange()
        }
        
        // Listen for user profile updates (avatar changes)
        userProfileObserver = NotificationCenter.default.addObserver(
            forName: .EcosiaUserProfileUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleUserProfileUpdate()
        }
        
        // Listen for progress updates
        progressObserver = NotificationCenter.default.addObserver(
            forName: .EcosiaAccountProgressUpdated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleProgressUpdate(notification)
        }
        
        // Listen for level up events
        levelUpObserver = NotificationCenter.default.addObserver(
            forName: .EcosiaAccountLevelUp,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleLevelUp(notification)
        }
    }
    
    private func removeObservers() {
        [authStateObserver, userProfileObserver, progressObserver, levelUpObserver].forEach {
            if let observer = $0 {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
    
    private func handleAuthStateChange() {
        avatarURL = Auth.shared.isLoggedIn ? Auth.shared.userProfile?.pictureURL : nil
        
        // Reset to default progress if user logs out
        if !Auth.shared.isLoggedIn {
            progress = 0.25
        }
    }
    
    private func handleUserProfileUpdate() {
        avatarURL = Auth.shared.userProfile?.pictureURL
    }
    
    private func handleProgressUpdate(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let newProgress = userInfo[EcosiaAccountNotificationKeys.progress] as? Double else {
            return
        }
        
        updateProgress(newProgress)
    }
    
    private func handleLevelUp(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let newProgress = userInfo[EcosiaAccountNotificationKeys.newProgress] as? Double else {
            return
        }
        
        // Update progress and trigger sparkles
        updateProgress(newProgress)
        triggerSparkles()
    }
}

#if DEBUG
// MARK: - Preview Helper
@available(iOS 16.0, *)
extension EcosiaAccountAvatarViewModel {
    /// Creates a preview instance with sample data
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
