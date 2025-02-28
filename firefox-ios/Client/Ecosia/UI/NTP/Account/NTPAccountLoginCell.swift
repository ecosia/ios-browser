/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SwiftUI
import Common
import Ecosia

final class NTPAccountLoginCell: UICollectionViewCell, ThemeApplicable, ReusableCell {

    // MARK: - UX Constants
    private enum UX {
        static let containerWidthHeight: CGFloat = 48
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
        button.setTitle("Fetch session token", for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        button.contentHorizontalAlignment = .trailing
        return button
    }()
    // Task for managing login/logout async operations
    private var authTask: Task<Void, Never>?
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
        updateLoginButton()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            loginButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.insetMargin),
            loginButton.heightAnchor.constraint(equalToConstant: 30),
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

    @objc private func fetchSessionToken() {
        sessionTokenTask?.cancel()
        sessionTokenTask = Task {
            await Auth.shared.fetchSessionToken()
        }
    }

    @MainActor
    private func performAuthAction() async {
        if Auth.shared.isLoggedIn {
            await Auth.shared.logout()
        } else {
            await Auth.shared.login()
        }
        updateLoginButton()
    }

    private func updateLoginButton() {
        // Update button title and background color based on login state
        loginButton.setTitle(Auth.shared.isLoggedIn ? "Sign Out" : "Sign In", for: .normal)
    }

    // MARK: - Theming

    func applyTheme(theme: any Common.Theme) {
        loginButton.setTitleColor(Auth.shared.isLoggedIn ? .red : theme.colors.ecosia.buttonBackgroundPrimaryActive, for: .normal)
        sessionTokenButton.setTitleColor(Auth.shared.isLoggedIn ? theme.colors.ecosia.buttonBackgroundPrimaryActive : .red, for: .normal)
    }
}
