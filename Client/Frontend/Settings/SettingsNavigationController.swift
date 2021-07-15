/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class ThemedNavigationController: UINavigationController {
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
        return ThemeManager.instance.statusBarStyle
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        modalPresentationStyle = .formSheet
        modalPresentationCapturesStatusBarAppearance = true
        
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        self.separator = separator
        navigationBar.addSubview(separator)
        
        separator.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor).isActive = true
        separator.leftAnchor.constraint(equalTo: navigationBar.leftAnchor).isActive = true
        separator.rightAnchor.constraint(equalTo: navigationBar.rightAnchor).isActive = true
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        applyTheme()
    }
}

extension ThemedNavigationController: Themeable {
    func applyTheme() {
        navigationBar.barTintColor = UIColor.theme.ecosia.barBackground
        navigationBar.isTranslucent = false
        navigationBar.tintColor = UIColor.theme.general.controlTint
        navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.theme.ecosia.highContrastText]
        navigationBar.shadowImage = nil
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        setNeedsStatusBarAppearanceUpdate()
        viewControllers.forEach {
            ($0 as? Themeable)?.applyTheme()
        }
        separator?.backgroundColor = UIColor.theme.ecosia.barSeparator
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
