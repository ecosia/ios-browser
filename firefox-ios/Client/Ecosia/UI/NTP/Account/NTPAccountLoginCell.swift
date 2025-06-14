// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SwiftUI
import Common
import Ecosia
import Redux

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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthDidLogin),
            name: .EcosiaAuthDidLoginWithSessionToken,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthDidLogout),
            name: .EcosiaAuthDidLogout,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthStateReady),
            name: .EcosiaAuthStateReady,
            object: nil
        )
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
            await Auth.shared.login()
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
