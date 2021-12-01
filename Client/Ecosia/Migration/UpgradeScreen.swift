/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
import UIKit
import Core

final class UpgradeScreen: UIViewController {
    required init?(coder: NSCoder) { nil }
    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overCurrentContext
        modalTransitionStyle = .crossDissolve
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.theme.ecosia.welcomeScreenBackground
        
        let base = UIView()
        base.translatesAutoresizingMaskIntoConstraints = false
        base.clipsToBounds = true
        base.backgroundColor = UIColor.theme.ecosia.primaryBackground
        base.layer.cornerRadius = 8
        view.addSubview(base)
        
        let icon = UIImageView(image: UIImage(named: "ecosiaIllustrationSingleTree"))
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.clipsToBounds = true
        icon.contentMode = .center
        base.addSubview(icon)
        
        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.textAlignment = .center
        title.text = .localized(.welcomeToTheNewEcosia)
        title.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .title3).pointSize, weight: .bold)
        title.numberOfLines = 0
        title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        title.textColor = UIColor.theme.ecosia.cardText
        view.addSubview(title)
        
        let subtitle = UILabel()
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.textAlignment = .center
        subtitle.text = .localized(.weHaveDoneSome)
        subtitle.font = .preferredFont(forTextStyle: .footnote)
        subtitle.numberOfLines = 0
        subtitle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        subtitle.textColor = UIColor.theme.ecosia.cardText
        view.addSubview(subtitle)
        
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.Photon.Blue50
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.setTitle(.localized(.takeALook), for: [])
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .callout).pointSize, weight: .medium)
        button.addTarget(self, action: #selector(takeALook), for: .touchUpInside)
        view.addSubview(button)
        
        base.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: 16).isActive = true
        base.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        base.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        base.leftAnchor.constraint(greaterThanOrEqualTo: view.leftAnchor, constant: 16).isActive = true
        base.rightAnchor.constraint(lessThanOrEqualTo: view.rightAnchor, constant: -16).isActive = true
        base.widthAnchor.constraint(lessThanOrEqualToConstant: 360).isActive = true
        
        let width = base.widthAnchor.constraint(equalToConstant: 360)
        width.priority = .defaultLow
        width.isActive = true
        
        icon.topAnchor.constraint(equalTo: base.topAnchor, constant: 24).isActive = true
        icon.centerXAnchor.constraint(equalTo: base.centerXAnchor).isActive = true
        
        title.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        title.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 24).isActive = true
        title.leftAnchor.constraint(greaterThanOrEqualTo: base.leftAnchor, constant: 16).isActive = true
        title.rightAnchor.constraint(lessThanOrEqualTo: base.rightAnchor, constant: -16).isActive = true
        
        subtitle.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8).isActive = true
        subtitle.leftAnchor.constraint(greaterThanOrEqualTo: base.leftAnchor, constant: 16).isActive = true
        subtitle.rightAnchor.constraint(lessThanOrEqualTo: base.rightAnchor, constant: -16).isActive = true
        
        button.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 24).isActive = true
        button.leftAnchor.constraint(equalTo: base.leftAnchor, constant: 16).isActive = true
        button.rightAnchor.constraint(equalTo: base.rightAnchor, constant: -16).isActive = true
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
    }
    
    @objc private func takeALook() {
        User.shared.hideWelcomeScreen()
        dismiss(animated: true)
    }
}
