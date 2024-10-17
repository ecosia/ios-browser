/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SwiftUI
import Core
import Common

final class NTPAccountLoginCell: UICollectionViewCell, Themeable, ReusableCell {

    // MARK: - UX Constants
    private enum UX {
        static let containerWidthHeight: CGFloat = 48
        static let insetMargin: CGFloat = 16
    }
    
    // MARK: - Properties
    private var loginButton: UIButton = UIButton()
    
    // Keeps track of login state
    private var isLoggedIn: Bool { Auth.isLoggedIn }
        
    // MARK: - Themeable Properties
    var themeManager: ThemeManager { AppContainer.shared.resolve() }
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        listenForLevelUpNotification()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }


    // MARK: - Setup

    private func setup() {
        contentView.addSubview(loginButton)
        setupLoginButton()
        applyTheme()
        listenForThemeChange(contentView)
    }

    private func setupLoginButton() {
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.backgroundColor = .clear
        loginButton.addTarget(self, action: #selector(toggleAccountState), for: .touchUpInside)
        loginButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        loginButton.titleLabel?.adjustsFontSizeToFitWidth = true
        loginButton.titleLabel?.adjustsFontForContentSizeCategory = true
        loginButton.contentHorizontalAlignment = .trailing
        NSLayoutConstraint.activate([
            loginButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.insetMargin),
            loginButton.heightAnchor.constraint(equalToConstant: 30),
            loginButton.widthAnchor.constraint(equalToConstant: 100),
        ])
        updateLoginButton()
    }
    
    // MARK: - Observer

    private func listenForLevelUpNotification() {
        NotificationCenter.default.addObserver(forName: Auth.loggedInNotification, object: nil, queue: .main) { [weak self] _ in
            self?.updateLoginButton()
        }
        
        NotificationCenter.default.addObserver(forName: Auth.loggedOutNotification, object: nil, queue: .main) { [weak self] _ in
            self?.updateLoginButton()
        }
    }

    // MARK: - Action

    @objc private func toggleAccountState() {
        Task {
            await performAuthAction()
        }
    }
    
    @MainActor
    private func performAuthAction() async {
        if isLoggedIn {
            await Auth.logout()
        } else {
            await Auth.login()
        }
    }

    private func updateLoginButton() {
        // Update button title and background color based on login state
        loginButton.setTitle(Auth.isLoggedIn ? "Sign Out" : "Sign In", for: .normal)
        updateButtonTheme()
    }
    
    // MARK: - Theming
    @objc func applyTheme() {
        updateButtonTheme()
    }
    
    func updateButtonTheme() {
        loginButton.setTitleColor(isLoggedIn ?
            .red : .legacyTheme.ecosia.primaryButtonActive, for: .normal)
    }
}
