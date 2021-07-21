/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core

final class LogoCell: UICollectionViewCell, Themeable {

    private weak var logo: UIImageView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setup() {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal

        let logo = UIImageView(image: UIImage(themed: "ecosiaLogo"))
        logo.translatesAutoresizingMaskIntoConstraints = false
        logo.clipsToBounds = true
        logo.contentMode = .scaleAspectFit
        contentView.addSubview(logo)
        self.logo = logo

        logo.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16).isActive = true
        logo.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        logo.heightAnchor.constraint(equalTo: logo.widthAnchor, multiplier: 0.71).isActive = true
        logo.widthAnchor.constraint(lessThanOrEqualToConstant: 95).isActive = true
        logo.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.33).isActive = true
        let logoWidth = logo.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.33)
        logoWidth.priority = .defaultHigh
        logoWidth.isActive = true
    }

    func applyTheme() {
        logo.image = UIImage(themed: "ecosiaLogo")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
}
