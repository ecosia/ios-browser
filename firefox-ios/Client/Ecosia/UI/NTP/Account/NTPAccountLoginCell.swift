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
        button.addTarget(self, action: #selector(fetchSessionToken), for: .touchUpInside)
        button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        button.contentHorizontalAlignment = .trailing
        return button
    }()
    // Task for managing login/logout async operations
    private var authTask: Task<Void, Never>?
    // Task for managing fetching the session token async operations
    private var sessionTokenTask: Task<Void, Never>?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    deinit {
        // Cancel any ongoing task when the cell is deallocated
        authTask?.cancel()
    }

    // MARK: - Setup

    private func setup() {
        contentView.addSubview(loginButton)
        contentView.addSubview(sessionTokenButton)
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
            loginButton.heightAnchor.constraint(equalToConstant: UX.containerHeight),
            loginButton.widthAnchor.constraint(equalToConstant: 100),
            sessionTokenButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 4),
            sessionTokenButton.trailingAnchor.constraint(equalTo: loginButton.trailingAnchor),
        ])
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
    }

    private func updateLoginButtonTitle() {
        loginButton.setTitle(Auth.shared.isLoggedIn ? "Sign Out" : "Sign In", for: .normal)
        guard let currentWindowUUID else { return }
        let themeManager: ThemeManager = AppContainer.shared.resolve()
        applyTheme(theme: themeManager.getCurrentTheme(for: currentWindowUUID))
    }

    private func updateSessionTokenButtonTitle() {
        let sessionTokenAuxiliaryText = ((Auth.shared.currentSessionToken?.prefix(10)) != nil) ? "Fetched session token: " : "Click to fetch session token (after login)"
        sessionTokenButton.setTitle("\(sessionTokenAuxiliaryText)\(Auth.shared.currentSessionToken?.prefix(10) ?? "")", for: .normal)
        guard let currentWindowUUID else { return }
        let themeManager: ThemeManager = AppContainer.shared.resolve()
        applyTheme(theme: themeManager.getCurrentTheme(for: currentWindowUUID))
    }

    @objc private func fetchSessionToken() {
        sessionTokenTask?.cancel()
        sessionTokenTask = Task {
            await Auth.shared.fetchSessionToken()
            updateSessionTokenButtonTitle()
        }
    }

    // MARK: - Theming

    func applyTheme(theme: Theme) {
        loginButton.setTitleColor(Auth.shared.isLoggedIn ? .red : theme.colors.ecosia.buttonBackgroundPrimaryActive, for: .normal)
        sessionTokenButton.setTitleColor(Auth.shared.isLoggedIn ? theme.colors.ecosia.buttonBackgroundPrimaryActive : .red, for: .normal)
    }
}
