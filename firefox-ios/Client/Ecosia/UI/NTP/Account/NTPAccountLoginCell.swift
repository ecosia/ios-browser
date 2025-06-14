// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SwiftUI
import Common
import Ecosia

final class NTPAccountLoginCell: UICollectionViewCell, ThemeApplicable, ReusableCell {

    // MARK: - UX Constants
    private enum UX {
        static let containerHeight: CGFloat = 48
        static let insetMargin: CGFloat = 16
    }

    // MARK: - Properties
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
    private lazy var sessionTokenButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(getSessionTransferToken), for: .touchUpInside)
        button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        button.contentHorizontalAlignment = .trailing
        return button
    }()
    // User avatar image view
    private lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 16 // Half of 32x32 for circular shape
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
        // Listen for auth state changes
        setupNotificationObservers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
        // Listen for auth state changes
        setupNotificationObservers()
    }

    deinit {
        // Cancel any ongoing task when the cell is deallocated
        authTask?.cancel()
        // Remove notification observers
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setup() {
        contentView.addSubview(loginButton)
        contentView.addSubview(sessionTokenButton)
        contentView.addSubview(avatarImageView)
        setupConstraints()
        updateLoginButtonTitle()
        updateSessionTokenButtonTitle()
    }

    private func setupConstraints() {
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.backgroundColor = .clear
        loginButton.addTarget(self, action: #selector(toggleAccountState), for: .touchUpInside)
        loginButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        loginButton.contentHorizontalAlignment = .trailing
        NSLayoutConstraint.activate([
            loginButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.insetMargin),
            loginButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            loginButton.heightAnchor.constraint(equalToConstant: UX.containerHeight),
            loginButton.widthAnchor.constraint(equalToConstant: 100),
            sessionTokenButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 4),
            sessionTokenButton.trailingAnchor.constraint(equalTo: loginButton.trailingAnchor),

            // Avatar positioned to the left of the sign out button
            avatarImageView.trailingAnchor.constraint(equalTo: loginButton.leadingAnchor, constant: -8),
            avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 32),
            avatarImageView.heightAnchor.constraint(equalToConstant: 32),
        ])
    }

    // Setup notification observers for auth state changes
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthDidLogin),
            name: Notification.Name("EcosiaAuthDidLoginWithSessionToken"),
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthDidLogout),
            name: Notification.Name("EcosiaAuthDidLogout"),
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthStateReady),
            name: Notification.Name("EcosiaAuthStateReady"),
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
        loginButton.setTitle(Auth.shared.isLoggedIn ? "Sign Out" : "Sign In", for: .normal)

        // Update avatar visibility and load avatar if logged in
        updateAvatarDisplay()

        guard let currentWindowUUID else { return }
        let themeManager: ThemeManager = AppContainer.shared.resolve()
        applyTheme(theme: themeManager.getCurrentTheme(for: currentWindowUUID))
    }

    // Update avatar display based on login state
    private func updateAvatarDisplay() {
        if Auth.shared.isLoggedIn {
            avatarImageView.isHidden = false
            loadUserAvatar()
        } else {
            avatarImageView.isHidden = true
            avatarImageView.image = nil
        }
    }

    // Load user avatar from profile
    private func loadUserAvatar() {
        guard let pictureURL = Auth.shared.userProfile?.picture,
              let url = URL(string: pictureURL) else {
            // Show default avatar if no picture URL
            avatarImageView.image = UIImage(systemName: "person.circle.fill")
            return
        }

        // Load avatar image asynchronously
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
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
        loginButton.setTitleColor(Auth.shared.isLoggedIn ? .red : theme.colors.ecosia.buttonBackgroundPrimaryActive, for: .normal)
        sessionTokenButton.setTitleColor(Auth.shared.isLoggedIn ? theme.colors.ecosia.buttonBackgroundPrimaryActive : .red, for: .normal)
    }
}
