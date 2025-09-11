// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import SwiftUI
import Ecosia

final class NTPHeaderViewModel: ObservableObject {
    struct UX {
        static let topInset: CGFloat = 24
    }

    // MARK: - Properties
    internal weak var delegate: NTPHeaderDelegate?
    internal var theme: Theme
    private let windowUUID: WindowUUID
    private let profile: Profile
    private(set) var auth: EcosiaAuth
    private var authStateObserver: NSObjectProtocol?
    private var userProfileObserver: NSObjectProtocol?
    var onTapAction: ((UIButton) -> Void)?
    private let accountsProvider: AccountsProvider

    @Published var seedCount: Int = 1
    @Published var isLoggedIn: Bool = false
    @Published var userAvatarURL: URL?
    @Published var balanceIncrement: Int?

    // MARK: - Initialization
    init(profile: Profile,
         theme: Theme,
         windowUUID: WindowUUID,
         accountsProvider: AccountsProvider = AccountsProvider(),
         auth: EcosiaAuth,
         delegate: NTPHeaderDelegate? = nil) {
        self.profile = profile
        self.theme = theme
        self.windowUUID = windowUUID
        self.accountsProvider = accountsProvider
        self.auth = auth
        self.delegate = delegate

        // Initialize auth state
        updateAuthState()

        // Set up auth state monitoring
        setupAuthStateMonitoring()

        // Initialize seed count based on auth state
        initializeSeedCount()
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

    func openAISearch() {
        delegate?.headerOpenAISearch()
        Analytics.shared.aiSearchNTPButtonTapped()
    }

    func updateSeedCount(_ count: Int) {
        seedCount = count
    }

    func performLogin() {
        auth.login()
    }

    func performLogout() {
        EcosiaLogger.auth.info("Performing immediate logout without confirmation")
        auth.logout()

        // Reset to local seed collection system
        Task { @MainActor in
            resetToLocalSeedCollection()
        }
    }
}

extension NTPHeaderViewModel {

    func registerVisitIfNeeded() {
        Task {
            do {
                // Step 2: Get access token after refresh
                guard let accessToken = auth.accessToken, !accessToken.isEmpty else {
                    EcosiaLogger.accounts.debug("No access token available - user not logged in")

                    // Use local seed collection when not logged in
                    await handleLocalSeedCollection()
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
        let useMockData = false // Set to false for real API calls

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

    // MARK: - Local Seed Collection

    private func initializeSeedCount() {
        if auth.isLoggedIn {
            EcosiaLogger.accounts.info("User logged in at startup - will load from backend")
            registerVisitIfNeeded()
        } else {
            EcosiaLogger.accounts.info("User logged out at startup - using local seed collection")
            seedCount = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()
        }
    }

    @MainActor
    private func resetToLocalSeedCollection() {
        EcosiaLogger.accounts.info("Resetting to local seed collection system")
        UserDefaultsSeedProgressManager.resetCounter()
        seedCount = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()
    }

    @MainActor
    private func handleLocalSeedCollection() {
        EcosiaLogger.accounts.info("Handling local seed collection for logged-out user")
        UserDefaultsSeedProgressManager.collectDailySeed()
        let newSeedCount = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()

        if newSeedCount > seedCount {
            let increment = newSeedCount - seedCount
            animateBalanceChange(from: seedCount, to: newSeedCount, increment: increment)
        } else {
            seedCount = newSeedCount
        }
    }
}

// MARK: HomeViewModelProtocol
extension NTPHeaderViewModel: HomepageViewModelProtocol, FeatureFlaggable {
    var sectionType: HomepageSectionType {
        return .header
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
        return true
        AISearchMVPExperiment.isEnabled
    }

    func setTheme(theme: Theme) {
        self.theme = theme
    }

    func refreshData(for traitCollection: UITraitCollection, size: CGSize, isPortrait: Bool, device: UIUserInterfaceIdiom) {
        // No data refresh needed for multi-purpose header
    }
}

extension NTPHeaderViewModel: HomepageSectionHandler {

    func configure(_ cell: UICollectionViewCell, at indexPath: IndexPath) -> UICollectionViewCell {
        if #available(iOS 16.0, *) {
            guard let headerCell = cell as? NTPHeader else { return cell }
            headerCell.configure(with: self, windowUUID: windowUUID)
            return headerCell
        }
        return cell
    }

    func didSelectItem(at indexPath: IndexPath, homePanelDelegate: HomePanelDelegate?, libraryPanelDelegate: LibraryPanelDelegate?) {
        // This cell handles its own button actions, no cell selection needed
    }
}
