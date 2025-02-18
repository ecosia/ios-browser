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
    private var loginButton = UIButton()

    // Task for managing login/logout async operations
    private var authTask: Task<Void, Never>?

    // Keeps track of login state using the Auth instance
    private var auth = Auth()

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
        setupLoginButton()
    }

    private func setupLoginButton() {
        updateLoginButtonTitle()
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.backgroundColor = .clear
        loginButton.addTarget(self, action: #selector(toggleAccountState), for: .touchUpInside)
        loginButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        loginButton.contentHorizontalAlignment = .trailing
        NSLayoutConstraint.activate([
            loginButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.insetMargin),
            loginButton.heightAnchor.constraint(equalToConstant: UX.containerHeight),
            loginButton.widthAnchor.constraint(equalToConstant: 100),
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
        if auth.isLoggedIn {
            await auth.logout()
        } else {
            await auth.login()
        }
        updateLoginButtonTitle()
    }

    private func updateLoginButtonTitle() {
        // Update button title and background color based on login state
        loginButton.setTitle(auth.isLoggedIn ? "Sign Out" : "Sign In", for: .normal)
    }

    // MARK: - Theming

    func applyTheme(theme: any Common.Theme) {
        loginButton.setTitleColor(auth.isLoggedIn ? .red : theme.colors.ecosia.buttonBackgroundPrimaryActive, for: .normal)
    }
}
