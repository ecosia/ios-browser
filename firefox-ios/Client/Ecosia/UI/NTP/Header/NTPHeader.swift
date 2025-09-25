// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SwiftUI
import Common
import Ecosia

protocol NTPHeaderDelegate: AnyObject {
    func headerOpenAISearch()
}

/// NTP header cell containing multiple Ecosia-specific actions like AI search
@available(iOS 16.0, *)
final class NTPHeader: UICollectionViewCell, ReusableCell {

    // MARK: - Properties
    private var hostingController: UIHostingController<AnyView>?
    private var viewModel: NTPHeaderViewModel?

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Setup

    private func setup() {
        // Create a placeholder hosting controller - will be configured later
        let hostingController = UIHostingController(rootView: AnyView(EmptyView()))
        hostingController.view.backgroundColor = UIColor.clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(hostingController.view)
        self.hostingController = hostingController

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    // MARK: - Public Methods

    func configure(with viewModel: NTPHeaderViewModel,
                   windowUUID: WindowUUID) {
        self.viewModel = viewModel

        // Update the SwiftUI view with the new view model
        let swiftUIView = NTPHeaderView(
            viewModel: viewModel,
            windowUUID: windowUUID
        )

        hostingController?.rootView = AnyView(swiftUIView)
    }
}

// MARK: - SwiftUI Multi-Purpose Header View
@available(iOS 16.0, *)
struct NTPHeaderView: View {
    @ObservedObject var viewModel: NTPHeaderViewModel
    @ObservedObject private var authStateProvider = EcosiaAuthUIStateProvider.shared
    let windowUUID: WindowUUID
    // Use explicit SwiftUI.Environment to avoid ambiguity
    @SwiftUI.Environment(\.themeManager) var themeManager: any ThemeManager
    @SwiftUI.Environment(\.accessibilityReduceMotion) var reduceMotion: Bool
    @State private var showAccountImpactView = false

    var body: some View {
        HStack(spacing: .ecosia.space._1s) {
            Spacer()
            if AISearchMVPExperiment.isEnabled {
                EcosiaAISearchButton(
                    windowUUID: windowUUID,
                    onTap: handleAISearchTap
                )
            }
            ZStack(alignment: .topLeading) {
                EcosiaAccountNavButton(
                    seedCount: viewModel.seedCount,
                    avatarURL: viewModel.userAvatarURL,
                    enableAnimation: !reduceMotion,
                    windowUUID: windowUUID,
                    onTap: handleTap
                )

                if let increment = viewModel.balanceIncrement {
                    BalanceIncrementAnimationView(
                        increment: increment,
                        windowUUID: windowUUID
                    )
                    .offset(x: 20, y: -10)
                }
            }
        }
        .padding(.leading, .ecosia.space._m)
        .padding(.trailing, .ecosia.space._m)
        .sheet(isPresented: $showAccountImpactView) {
            EcosiaAccountImpactView(
                viewModel: EcosiaAccountImpactViewModel(
                    onLogin: {
                        viewModel.performLogin()
                    },
                    onDismiss: {
                        showAccountImpactView = false
                    }
                ),
                windowUUID: windowUUID
            )
            .padding(.horizontal, .ecosia.space._m)
            .dynamicHeightPresentationDetent()
        }
    }

    private func handleAISearchTap() {
        viewModel.openAISearch()
    }

    private func handleTap() {
        showAccountImpactView = true
        Analytics.shared.accountHeaderClicked()
    }
}

#if DEBUG
// MARK: - Preview
@available(iOS 16.0, *)
struct NTPHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Logged out state
            NTPHeaderView(
                viewModel: createMockViewModel(isLoggedIn: false, seedCount: 42),
                windowUUID: .XCTestDefaultUUID
            )
            .previewDisplayName("Logged Out")

            // Logged in state
            NTPHeaderView(
                viewModel: createMockViewModel(
                    isLoggedIn: true,
                    seedCount: 1247,
                    avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1?v=4")
                ),
                windowUUID: .XCTestDefaultUUID
            )
            .previewDisplayName("Logged In")

            // With balance increment animation
            NTPHeaderView(
                viewModel: createMockViewModelWithIncrement(seedCount: 856, increment: 3),
                windowUUID: .XCTestDefaultUUID
            )
            .previewDisplayName("With Balance Increment")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }

    private static func createMockViewModel(
        isLoggedIn: Bool = false,
        seedCount: Int = 42,
        avatarURL: URL? = nil
    ) -> NTPHeaderViewModel {
        let mockAuth = MockAuth(isLoggedIn: isLoggedIn, avatarURL: avatarURL)
        let mockAccountsProvider = MockAccountsProvider()
        let mockDelegate = MockNTPHeaderDelegate()

        return NTPHeaderViewModel(
            profile: Profile(localName: "test"),
            theme: LightTheme(),
            windowUUID: .XCTestDefaultUUID,
            accountsProvider: mockAccountsProvider,
            auth: mockAuth,
            delegate: mockDelegate
        )
    }

    private static func createMockViewModelWithIncrement(
        seedCount: Int = 100,
        increment: Int = 5
    ) -> NTPHeaderViewModel {
        let viewModel = createMockViewModel(isLoggedIn: true, seedCount: seedCount)
        // Simulate balance increment
        DispatchQueue.main.async {
            viewModel.updateSeedCount(seedCount)
            // Mock the increment animation
            // viewModel.balanceIncrement = increment
        }
        return viewModel
    }
}

// MARK: - Mock Objects for Preview
private class MockAuth: AuthInterface {
    let isLoggedIn: Bool
    let avatarURL: URL?

    init(isLoggedIn: Bool, avatarURL: URL? = nil) {
        self.isLoggedIn = isLoggedIn
        self.avatarURL = avatarURL
    }

    var accessToken: String? { isLoggedIn ? "mock-token" : nil }
    var userProfile: UserProfile? {
        isLoggedIn ? UserProfile(id: "1", name: "Test User", pictureURL: avatarURL) : nil
    }

    func login() {}
    func logout() {}
    func refreshToken() async throws {}
}

private class MockAccountsProvider: AccountsProviderProtocol {
    func registerVisit(accessToken: String) async throws -> AccountVisitResponse {
        return AccountVisitResponse(
            balance: AccountVisitResponse.Balance(
                amount: 100,
                updatedAt: ISO8601DateFormatter().string(from: Date()),
                isModified: true
            ),
            previousBalance: AccountVisitResponse.PreviousBalance(amount: 97)
        )
    }
}

private class MockNTPHeaderDelegate: NTPHeaderDelegate {
    func headerOpenAISearch() {}
}

private class MockSeedProgressManager: SeedProgressManagerProtocol {
    static var progressUpdatedNotification: Notification.Name { .init("Mock.SeedProgressUpdated") }
    static var levelUpNotification: Notification.Name { .init("Mock.SeedLevelUp") }

    static func loadTotalSeedsCollected() -> Int { 42 }
    static func loadCurrentLevel() -> Int { 1 }
    static func collectDailySeed() {}
    static func resetCounter() {}
}
#endif
