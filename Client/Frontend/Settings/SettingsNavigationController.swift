// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared

class ThemedNavigationController: DismissableNavigationViewController, Themeable {
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol

    init(themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(rootViewController: UIViewController,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(rootViewController: rootViewController)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return topViewController?.preferredStatusBarStyle ?? LegacyThemeManager.instance.statusBarStyle
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        modalPresentationStyle = .overFullScreen
        modalPresentationCapturesStatusBarAppearance = true
        applyTheme()
        listenForThemeChange(view)
    }

    private func setupNavigationBarAppearance(theme: Theme) {
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithDefaultBackground()
        standardAppearance.backgroundColor = theme.colors.layer1
        // Ecosia: Define `largeTitleTextAttributes` as done for ThemedDefaultNavigationController utilized in Widgets
        standardAppearance.largeTitleTextAttributes = [.foregroundColor: theme.colors.textPrimary]
        standardAppearance.titleTextAttributes = [.foregroundColor: theme.colors.textPrimary]

        // Ecosia: Update navigationBar properties
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        standardAppearance.shadowImage = .init()
        standardAppearance.shadowColor = nil
        navigationBar.prefersLargeTitles = true

        navigationBar.standardAppearance = standardAppearance
        navigationBar.compactAppearance = standardAppearance
        navigationBar.scrollEdgeAppearance = standardAppearance
        navigationBar.compactScrollEdgeAppearance = standardAppearance
        navigationBar.tintColor = theme.colors.actionPrimary
    }

    func applyTheme() {
        setupNavigationBarAppearance(theme: themeManager.currentTheme)
        setNeedsStatusBarAppearanceUpdate()
    }
}

class ModalSettingsNavigationController: UINavigationController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
}
