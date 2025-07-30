// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SwiftUI
import Common
import Ecosia
import Redux

// MARK: - SwiftUI Account Login Cell View
@available(iOS 16.0, *)
struct NTPAccountLoginCellView: View {
    @ObservedObject var viewModel: NTPAccountLoginViewModel
    let windowUUID: WindowUUID
    
    // Use explicit SwiftUI.Environment to avoid ambiguity
    @SwiftUI.Environment(\.themeManager) var themeManager: any ThemeManager
    @SwiftUI.Environment(\.accessibilityReduceMotion) var reduceMotion: Bool
    
    private enum UX {
        static let seedIconSize: CGFloat = 24
        static let avatarSize: CGFloat = 32
        static let spacing: CGFloat = 12
        static let cornerRadius: CGFloat = 8
    }
    
    var body: some View {
        Button(action: handleTap) {
            HStack(spacing: UX.spacing) {
                // Seed icon
                Image("seed")
                    .resizable()
                    .frame(width: UX.seedIconSize, height: UX.seedIconSize)
                    .foregroundColor(Color(themeManager.getCurrentTheme(for: windowUUID).colors.iconPrimary))
                
                // Animated seed count
                Text("\(viewModel.seedCount)")
                    .font(.headline)
                    .foregroundColor(Color(themeManager.getCurrentTheme(for: windowUUID).colors.textPrimary))
                    .contentTransition(.numericText())
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: viewModel.seedCount)
                
                Spacer()
                
                // Avatar placeholder
                Circle()
                    .fill(Color(themeManager.getCurrentTheme(for: windowUUID).colors.iconSecondary))
                    .frame(width: UX.avatarSize, height: UX.avatarSize)
                    .overlay(
                        Image("avatar")
                            .resizable()
                            .scaledToFit()
                            .padding(6)
                            .foregroundColor(Color(themeManager.getCurrentTheme(for: windowUUID).colors.iconPrimary))
                    )
            }
            .padding()
            .background(Color(themeManager.getCurrentTheme(for: windowUUID).colors.layer1))
            .cornerRadius(UX.cornerRadius)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func handleTap() {
        if viewModel.isLoggedIn {
            viewModel.auth.logout()
        } else {
            viewModel.auth.login()
        }
    }
    
    private func applyTheme() {
        // Theme is already applied through environment
    }
}

// MARK: - Mock BrowserViewController for initialization
private class MockBrowserViewController: BrowserViewController {
    init() {
        super.init(
            profile: AppContainer.shared.resolve(),
            tabManager: AppContainer.shared.resolve(),
            themeManager: AppContainer.shared.resolve(),
            notificationCenter: NotificationCenter.default,
            ratingPromptManager: AppContainer.shared.resolve(),
            downloadQueue: AppContainer.shared.resolve(),
            logger: DefaultLogger.shared,
            appAuthenticator: AppAuthenticator()
        )
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UIKit Wrapper for Collection View Cell
@available(iOS 16.0, *)
final class NTPAccountLoginCell: UICollectionViewCell, ThemeApplicable, ReusableCell {
    
    // MARK: - UX Constants
    private enum UX {
        static let containerHeight: CGFloat = 64
        static let insetMargin: CGFloat = 16
        static let avatarSize: CGFloat = 32
        static let stackSpacing: CGFloat = 4
    }
    
    // MARK: - Properties
    private var hostingController: UIHostingController<NTPAccountLoginCellView>?
    private var viewModel: NTPAccountLoginViewModel?
    
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
        // Create a simple placeholder view - will be replaced by configure method
        // We'll create a minimal placeholder that doesn't require complex initialization
        let swiftUIView = NTPAccountLoginCellView(
            viewModel: NTPAccountLoginViewModel(
                profile: AppContainer.shared.resolve(),
                theme: LightTheme(),
                auth: EcosiaAuth(browserViewController: MockBrowserViewController()),
                windowUUID: .XCTestDefaultUUID
            ),
            windowUUID: .XCTestDefaultUUID
        )
        let hostingController = UIHostingController(rootView: swiftUIView)
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
    
    func configure(with viewModel: NTPAccountLoginViewModel, windowUUID: WindowUUID) {
        self.viewModel = viewModel
        
        // Update the SwiftUI view with the new view model
        let swiftUIView = NTPAccountLoginCellView(
            viewModel: viewModel,
            windowUUID: windowUUID
        )
        
        hostingController?.rootView = swiftUIView
    }
    
    func updateSeedCount(_ count: Int) {
        viewModel?.updateSeedCount(count)
    }
    
    // MARK: - Theming
    func applyTheme(theme: Theme) {
        // Theme is handled by the SwiftUI view
    }
}

// MARK: - Legacy UIKit Implementation (keeping for reference)
/*
final class NTPAccountLoginCell: UICollectionViewCell, ThemeApplicable, ReusableCell {

    // MARK: - UX Constants
    private enum UX {
        static let containerHeight: CGFloat = 64
        static let insetMargin: CGFloat = 16
        static let avatarSize: CGFloat = 32
        static let stackSpacing: CGFloat = 4
    }

    // MARK: - Properties
    private lazy var containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .trailing
        stackView.spacing = UX.stackSpacing
        stackView.distribution = .fill
        return stackView
    }()

    private lazy var loginButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(toggleAccountState), for: .touchUpInside)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.contentHorizontalAlignment = .trailing
        return button
    }()

    private lazy var sessionTokenButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(getSessionTransferToken), for: .touchUpInside)
        button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        button.contentHorizontalAlignment = .trailing
        button.isHidden = true // Hidden by default as requested
        return button
    }()

    // User avatar image view - positioned on top of the button when visible
    private lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = UX.avatarSize / 2 // Circular shape
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .systemGray5
        imageView.isHidden = true // Hidden by default
        return imageView
    }()

    // Task for managing login/logout async operations
    private var authTask: Task<Void, Never>?
    // Task for managing fetching the session token async operations
    private var sessionTokenTask: Task<Void, Never>?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        setupNotificationObservers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
        setupNotificationObservers()
    }

    deinit {
        // Cancel any ongoing task when the cell is deallocated
        authTask?.cancel()
        sessionTokenTask?.cancel()
        // Remove notification observers
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setup() {
        contentView.addSubview(containerStackView)

        // Add buttons to stack view
        containerStackView.addArrangedSubview(avatarImageView)
        containerStackView.addArrangedSubview(loginButton)
        containerStackView.addArrangedSubview(sessionTokenButton)

        setupConstraints()
        updateLoginButtonTitle()
        updateSessionTokenButtonTitle()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container stack view constraints
            containerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.insetMargin),
            containerStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            containerStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: UX.avatarSize),
            avatarImageView.heightAnchor.constraint(equalToConstant: UX.avatarSize)
        ])
    }

    // Setup notification observers for auth state changes
    private func setupNotificationObservers() {

    }

    // Handle auth login notification
    @objc private func handleAuthDidLogin() {
        DispatchQueue.main.async { [weak self] in
            self?.updateLoginButtonTitle()
            self?.updateSessionTokenButtonTitle()
        }
    }

    // Handle auth logout notification
    @objc private func handleAuthDidLogout() {
        DispatchQueue.main.async { [weak self] in
            self?.updateLoginButtonTitle()
            self?.updateSessionTokenButtonTitle()
        }
    }

    // Handle auth state ready notification to fix initial state inconsistency
    @objc private func handleAuthStateReady() {
        DispatchQueue.main.async { [weak self] in
            print("📱 NTPAccountLoginCell: Auth state ready, updating UI")
            self?.updateLoginButtonTitle()
            self?.updateSessionTokenButtonTitle()
        }
    }

    // MARK: - Action

    @objc private func toggleAccountState() {
        // Cancel any existing task before starting a new one
        authTask?.cancel()
        authTask = Task {
            await performAuthAction()
        }
    }

    @MainActor
    private func performAuthAction() async {
        if Auth.shared.isLoggedIn {
            await Auth.shared.logout()
        } else {
            // Ecosia: Use delayed completion for seamless UX - Auth0 popup stays visible during session transfer
            await Auth.shared.login(withDelayedCompletion: true)
        }
        updateLoginButtonTitle()
        updateSessionTokenButtonTitle() // Update session token display after auth action
    }

    private func updateLoginButtonTitle() {
        // Use Redux state if available, otherwise fall back to Auth.shared
        let isLoggedIn = getCurrentAuthState()
        loginButton.setTitle(isLoggedIn ? "Sign Out" : "Sign In", for: .normal)

        // Update avatar visibility and load avatar if logged in
        updateAvatarDisplay()

        guard let currentWindowUUID else { return }
        let themeManager: ThemeManager = AppContainer.shared.resolve()
        applyTheme(theme: themeManager.getCurrentTheme(for: currentWindowUUID))
    }

    // Get current auth state from Redux if available, otherwise from Auth.shared
    private func getCurrentAuthState() -> Bool {
        if let windowUUID = currentWindowUUID,
           let browserState = store.state.screenState(BrowserViewControllerState.self, for: .browserViewController, window: windowUUID),
           browserState.authStateLoaded {
            return browserState.isUserLoggedIn
        }
        return Auth.shared.isLoggedIn
    }

    // Update avatar display based on login state
    private func updateAvatarDisplay() {
        let isLoggedIn = getCurrentAuthState()

        // Animate avatar visibility changes for smooth UX
        UIView.animate(withDuration: 0.3, animations: {
            if isLoggedIn {
                self.avatarImageView.isHidden = false
                self.avatarImageView.alpha = 1.0
                self.loadUserAvatar()
            } else {
                self.avatarImageView.alpha = 0.0
            }
        }) { _ in
            if !isLoggedIn {
                self.avatarImageView.isHidden = true
                self.avatarImageView.image = nil
            }
        }
    }

    // Load user avatar from profile
    private func loadUserAvatar() {
        // Ensure avatar is visible and set initial alpha
        avatarImageView.alpha = 1.0

        guard let pictureURL = Auth.shared.userProfile?.picture,
              let url = URL(string: pictureURL) else {
            // Show default avatar if no picture URL
            avatarImageView.image = UIImage(systemName: "person.circle.fill")
            return
        }

        // Load avatar image asynchronously
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else {
                // Fallback to default avatar on load failure
                DispatchQueue.main.async {
                    self?.avatarImageView.image = UIImage(systemName: "person.circle.fill")
                }
                return
            }
            DispatchQueue.main.async {
                self?.avatarImageView.image = image
            }
        }.resume()
    }

    private func updateSessionTokenButtonTitle() {
        let sessionTokenAuxiliaryText = ((Auth.shared.currentSessionToken?.prefix(10)) != nil) ? "Fetched session token: " : "Click to fetch session token (after login)"
        sessionTokenButton.setTitle("\(sessionTokenAuxiliaryText)\(Auth.shared.currentSessionToken?.prefix(10) ?? "")", for: .normal)
        guard let currentWindowUUID else { return }
        let themeManager: ThemeManager = AppContainer.shared.resolve()
        applyTheme(theme: themeManager.getCurrentTheme(for: currentWindowUUID))
    }

    @objc private func getSessionTransferToken() {
        sessionTokenTask?.cancel()
        sessionTokenTask = Task {
            await Auth.shared.getSessionTransferToken()
            updateSessionTokenButtonTitle()
        }
    }

    // MARK: - Theming

    func applyTheme(theme: Theme) {
        let isLoggedIn = getCurrentAuthState()
        loginButton.setTitleColor(isLoggedIn ? .red : theme.colors.ecosia.buttonBackgroundPrimaryActive, for: .normal)
        sessionTokenButton.setTitleColor(isLoggedIn ? theme.colors.ecosia.buttonBackgroundPrimaryActive : .red, for: .normal)
    }
}
*/

#if DEBUG
// MARK: - Preview
// Preview code removed due to compilation issues with Profile and ThemeManager initialization
#endif
