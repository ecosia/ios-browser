/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

final class WelcomeTourGreen: UIView, NotificationThemeable {
    private weak var searchLabel: UILabel!

    init() {
        super.init(frame: .zero)
        setup()
        updateAccessibilitySettings()
        applyTheme()
    }

    required init?(coder: NSCoder) {  nil }

    func setup() {
        let iPadOffset: CGFloat = traitCollection.userInterfaceIdiom == .pad ? 60 : 0
        
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.distribution = .fill
        stack.alignment = .center
        stack.spacing = 24 + iPadOffset
        addSubview(stack)
        
        stack.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        stack.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -50 - iPadOffset).isActive = true

        let topImage = UIImageView(image: .init(named: "tourSearch-alternative"))
        topImage.translatesAutoresizingMaskIntoConstraints = false
        topImage.isAccessibilityElement = false
        stack.addArrangedSubview(topImage)

        let searchLabel = UILabel()
        searchLabel.translatesAutoresizingMaskIntoConstraints = false
        searchLabel.text = .localized(.sustainableShoes)
        searchLabel.font = .systemFont(ofSize: 12)
        searchLabel.numberOfLines = 1
        searchLabel.textAlignment = .left
        searchLabel.isAccessibilityElement = false
        topImage.addSubview(searchLabel)
        self.searchLabel = searchLabel

        searchLabel.leadingAnchor.constraint(equalTo: topImage.leadingAnchor, constant: 55).isActive = true
        searchLabel.topAnchor.constraint(equalTo: topImage.topAnchor, constant: 37).isActive = true
        searchLabel.trailingAnchor.constraint(equalTo: topImage.trailingAnchor, constant: -40).isActive = true
        searchLabel.transform = .init(rotationAngle: Double.pi / -33)

        let bottomImage = UIImageView(image: .init(named: "tourGreen"))
        bottomImage.translatesAutoresizingMaskIntoConstraints = false
        bottomImage.isAccessibilityElement = false
        stack.addArrangedSubview(bottomImage)

        // upscale images for iPad
        if traitCollection.userInterfaceIdiom == .pad {
            bottomImage.transform = bottomImage.transform.scaledBy(x: 1.5, y: 1.5)
            topImage.transform = topImage.transform.scaledBy(x: 1.5, y: 1.5)
        }
    }

    func applyTheme() {
        searchLabel.textColor = .theme.ecosia.primaryText
    }
    
    func updateAccessibilitySettings() {
        isAccessibilityElement = false
        shouldGroupAccessibilityChildren = true
    }
}
