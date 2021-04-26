/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
import UIKit
import Core

final class WelcomeScreen: UIViewController {
    required init?(coder: NSCoder) { nil }
    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overCurrentContext
        modalTransitionStyle = .crossDissolve
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.Photon.Grey70.withAlphaComponent(0.4)
        
        let base = UIView()
        base.translatesAutoresizingMaskIntoConstraints = false
        base.clipsToBounds = true
        base.backgroundColor = UIColor.theme.ecosia.primaryBackground
        base.layer.cornerRadius = 8
        view.addSubview(base)
        
        base.heightAnchor.constraint(equalToConstant: 300).isActive = true
        base.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        base.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        base.leftAnchor.constraint(greaterThanOrEqualTo: view.leftAnchor, constant: 16).isActive = true
        base.rightAnchor.constraint(lessThanOrEqualTo: view.rightAnchor, constant: -16).isActive = true
        base.widthAnchor.constraint(lessThanOrEqualToConstant: 360).isActive = true
        
        let width = base.widthAnchor.constraint(equalToConstant: 360)
        width.priority = .defaultLow
        width.isActive = true
    }
}
