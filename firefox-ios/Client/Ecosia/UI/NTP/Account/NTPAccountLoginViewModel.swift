// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import SwiftUI
import UIKit
import Ecosia

final class NTPAccountLoginViewModel: ObservableObject {
    struct UX {
        static let topInset: CGFloat = 24
    }

    // MARK: - Published Properties
    @Published var seedCount: Int = 1
    @Published var isLoggedIn: Bool = false
    @Published var userAvatarURL: URL?
    @Published var balanceIncrement: Int?

    // MARK: - Private Properties
    private let profile: Profile
    private(set) var auth: EcosiaAuth
    private let windowUUID: WindowUUID
    private var authStateObserver: NSObjectProtocol?
    private var userProfileObserver: NSObjectProtocol?
    weak var delegate: NTPSeedCounterDelegate?
    var onTapAction: ((UIButton) -> Void)?
    var theme: Theme
    private let accountsProvider: AccountsProvider

    // MARK: - Initialization
    init(profile: Profile,
         theme: Theme,
         auth: EcosiaAuth,
         windowUUID: WindowUUID,
         accountsProvider: AccountsProvider = AccountsProvider()) {
        self.profile = profile
        self.auth = auth
        self.theme = theme
        self.windowUUID = windowUUID
        self.accountsProvider = accountsProvider

        // Initialize auth state
        updateAuthState()

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

    func updateSeedCount(_ count: Int) {
        seedCount = count
    }

    func performLogin() {
        auth.login()
    }

    func performLogout() {
        showCustomLogoutConfirmation()
    }
    
    private func showCustomLogoutConfirmation() {
        guard let topViewController = getTopMostViewController() else {
            // Fallback to direct logout if we can't get the view controller
            auth.logout()
            return
        }
        
        let alertController = UIAlertController(
            title: "Sign Out",
            message: "Are you sure you want to sign out of your Ecosia account?",
            preferredStyle: .alert
        )
        
        alertController.addAction(
            UIAlertAction(title: "Cancel", style: .cancel) { _ in
                // User cancelled - do nothing
                EcosiaLogger.auth.info("User cancelled logout from custom dialog")
            }
        )
        
        alertController.addAction(
            UIAlertAction(title: "Sign Out", style: .destructive) { [weak self] _ in
                // User confirmed - proceed with logout
                EcosiaLogger.auth.info("User confirmed logout from custom dialog")
                self?.auth.logout()
            }
        )
        
        topViewController.present(alertController, animated: true)
    }
    
    private func getTopMostViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }),
              let rootViewController = window.rootViewController else {
            return nil
        }
        
        return findTopMostViewController(from: rootViewController)
    }
    
    private func findTopMostViewController(from viewController: UIViewController) -> UIViewController {
        if let presentedVC = viewController.presentedViewController {
            return findTopMostViewController(from: presentedVC)
        }
        
        if let navigationController = viewController as? UINavigationController,
           let topVC = navigationController.topViewController {
            return findTopMostViewController(from: topVC)
        }
        
        if let tabBarController = viewController as? UITabBarController,
           let selectedVC = tabBarController.selectedViewController {
            return findTopMostViewController(from: selectedVC)
        }
        
        return viewController
    }

    func registerVisitIfNeeded() {
        Task {
            do {
                // Step 2: Get access token after refresh
                guard let accessToken = auth.accessToken, !accessToken.isEmpty else {
                    EcosiaLogger.accounts.debug("No access token available - user not logged in")
                    return
                }
                
                // Step 3: Make API call (or use mock for testing)
                EcosiaLogger.accounts.info("Registering user visit for balance update")
                let response = try await getMockOrRealResponse(accessToken: accessToken)
                await updateBalance(response)
                
            } catch {
                EcosiaLogger.accounts.debug("Could not register visit: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - API Response (Mock for Testing)
    
    private func getMockOrRealResponse(accessToken: String) async throws -> AccountBalanceResponse {
        // TODO: Switch between mock and real API for testing
        let useMockData = true // Set to false for real API calls
        
        if useMockData {
            EcosiaLogger.accounts.info("Using mock response for testing")
            return createMockResponse()
        } else {
            return try await accountsProvider.registerVisit(accessToken: accessToken)
        }
    }
    
    private func createMockResponse() -> AccountBalanceResponse {
        let currentBalance = seedCount
        let increment = Int.random(in: 1...3) // Random increment for testing
        
        return AccountBalanceResponse(
            balance: AccountBalanceResponse.Balance(
                amount: currentBalance + increment,
                updatedAt: ISO8601DateFormatter().string(from: Date()),
                isModified: true
            ),
            previousBalance: AccountBalanceResponse.PreviousBalance(
                amount: currentBalance
            )
        )
    }

    // MARK: - Auth State Synchronization



    @MainActor
    private func updateBalance(_ response: AccountBalanceResponse) {
        let newSeedCount = response.balance.amount

        if let increment = response.balanceIncrement {
            EcosiaLogger.accounts.info("Balance updated with animation: \(seedCount) → \(newSeedCount) (+\(increment))")
            animateBalanceChange(from: seedCount, to: newSeedCount, increment: increment)
        } else {
            EcosiaLogger.accounts.info("Balance updated without animation: \(seedCount) → \(newSeedCount)")
            seedCount = newSeedCount
        }
    }

    @MainActor
    private func animateBalanceChange(from oldValue: Int, to newValue: Int, increment: Int) {
        seedCount = newValue
        balanceIncrement = increment

        // Clear the increment after animation duration
        Task {
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            balanceIncrement = nil
        }
    }

    // MARK: - Private Methods

    private func updateAuthState() {
        isLoggedIn = auth.isLoggedIn
        updateUserAvatar()
    }

    private func updateUserAvatar() {
        userAvatarURL = auth.userProfile?.pictureURL
    }

    private func setupAuthStateMonitoring() {
        // Listen for auth state changes
        authStateObserver = NotificationCenter.default.addObserver(
            forName: .EcosiaAuthStateChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            DispatchQueue.main.async {
                self?.updateAuthState()

                // Register visit when user logs in (same simple flow)
                if let actionType = notification.userInfo?["actionType"] as? EcosiaAuthActionType,
                   actionType == .userLoggedIn {
                    EcosiaLogger.accounts.info("User logged in - registering visit")
                    self?.registerVisitIfNeeded()
                }
            }
        }

        // Listen for user profile updates
        userProfileObserver = NotificationCenter.default.addObserver(
            forName: .EcosiaUserProfileUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateUserAvatar()
            }
        }
    }


}

// MARK: HomeViewModelProtocol
extension NTPAccountLoginViewModel: HomepageViewModelProtocol, FeatureFlaggable {
    var sectionType: HomepageSectionType {
        return .accountLogin
    }

    var headerViewModel: LabelButtonHeaderViewModel {
        return .emptyHeader
    }

    func section(for traitCollection: UITraitCollection, size: CGSize) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                              heightDimension: .estimated(64))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .estimated(64))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

        let section = NSCollectionLayoutSection(group: group)

        section.contentInsets = NSDirectionalEdgeInsets(
            top: UX.topInset,
            leading: 0,
            bottom: 0,
            trailing: 0)

        return section
    }

    func numberOfItemsInSection() -> Int {
        return 1
    }

    var isEnabled: Bool {
        true
    }

    func setTheme(theme: Theme) {
        self.theme = theme
    }
}

extension NTPAccountLoginViewModel: HomepageSectionHandler {

    func configure(_ cell: UICollectionViewCell, at indexPath: IndexPath) -> UICollectionViewCell {
        if #available(iOS 16.0, *) {
            guard let accountLoginCell = cell as? NTPAccountLoginCell else { return cell }
            accountLoginCell.configure(with: self, windowUUID: windowUUID)
            return accountLoginCell
        }
        return cell
    }
}
