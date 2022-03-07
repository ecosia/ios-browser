/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class ThemedNavigationController: DismissableNavigationViewController {
    var presentingModalViewControllerDelegate: PresentingModalViewControllerDelegate?
    private weak var separator: UIView?
    
    @objc func done() {
        if let delegate = presentingModalViewControllerDelegate {
            delegate.dismissPresentedModalViewController(self, animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return topViewController?.preferredStatusBarStyle ?? ThemeManager.instance.statusBarStyle
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        modalPresentationStyle = .overFullScreen
        modalPresentationCapturesStatusBarAppearance = true
        
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        self.separator = separator
        navigationBar.addSubview(separator)
        
        separator.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor).isActive = true
        separator.leftAnchor.constraint(equalTo: navigationBar.leftAnchor).isActive = true
        separator.rightAnchor.constraint(equalTo: navigationBar.rightAnchor).isActive = true
        separator.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        
        applyTheme()
    }
}

extension ThemedNavigationController: Themeable {
    private func setupNavigationBarAppearance() {
        let standardAppearance = UINavigationBarAppearance()
            standardAppearance.configureWithOpaqueBackground()
            standardAppearance.backgroundColor = UIColor.theme.ecosia.barBackground
            standardAppearance.titleTextAttributes = [.foregroundColor: UIColor.theme.ecosia.highContrastText]
            standardAppearance.shadowImage = nil
            standardAppearance.shadowColor = nil
        navigationBar.standardAppearance = standardAppearance
        navigationBar.compactAppearance = standardAppearance
        navigationBar.scrollEdgeAppearance = standardAppearance
        
        // Ecosia
        navigationBar.prefersLargeTitles = true
        
        if #available(iOS 15.0, *) {
            navigationBar.compactScrollEdgeAppearance = standardAppearance
        }
        navigationBar.tintColor = UIColor.theme.general.controlTint
    }
    func applyTheme() {
        setupNavigationBarAppearance()
        setNeedsStatusBarAppearanceUpdate()
        viewControllers.forEach {
            ($0 as? Themeable)?.applyTheme()
        }

        navigationBar.setNeedsDisplay()
        setNeedsStatusBarAppearanceUpdate()
        navigationBar.tintColor = UIColor.theme.general.controlTint
        separator?.backgroundColor = UIColor.theme.tableView.separator
    }
}

protocol PresentingModalViewControllerDelegate: AnyObject {
    func dismissPresentedModalViewController(_ modalViewController: UIViewController, animated: Bool)
}

class ModalSettingsNavigationController: UINavigationController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
}
