/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

final class MultiplyImpactCell: UICollectionViewCell, AutoSizingCell, Themeable {
    private(set) weak var widthConstraint: NSLayoutConstraint!
    private weak var title: UILabel!
    private weak var subtitle: UILabel!
    private weak var outline: UIView!

    override var isSelected: Bool {
        didSet {
            hover()
        }
    }

    override var isHighlighted: Bool {
        didSet {
            hover()
        }
    }
    
    required init?(coder: NSCoder) { super.init(coder: coder) }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let outline = UIView()
        contentView.addSubview(outline)
        outline.layer.cornerRadius = 8
        outline.translatesAutoresizingMaskIntoConstraints = false
        self.outline = outline
        
        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.font = .preferredFont(forTextStyle: .body)
        title.adjustsFontForContentSizeCategory = true
        title.numberOfLines = 0
        title.text = .localized(.getATreeWithEveryFriend)
        self.title = title
        outline.addSubview(title)
        
        let subtitle = UILabel()
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.font = .preferredFont(forTextStyle: .callout)
        subtitle.adjustsFontForContentSizeCategory = true
        subtitle.text = .localized(.inviteFriends)
        self.subtitle = subtitle
        outline.addSubview(subtitle)
        
        let icon = UIImageView(image: .init(named: "groupYourImpact"))
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .center
        icon.clipsToBounds = true
        outline.addSubview(icon)

        outline.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        outline.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        outline.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4).isActive = true
        outline.bottomAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 12).isActive = true

        title.leftAnchor.constraint(equalTo: outline.leftAnchor, constant: 16).isActive = true
        title.topAnchor.constraint(equalTo: outline.topAnchor, constant: 12).isActive = true
        title.widthAnchor.constraint(lessThanOrEqualToConstant: 220).isActive = true
        
        subtitle.leftAnchor.constraint(equalTo: outline.leftAnchor, constant: 16).isActive = true
        subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8).isActive = true
        
        icon.rightAnchor.constraint(equalTo: outline.rightAnchor, constant: -16).isActive = true
        icon.centerYAnchor.constraint(equalTo: outline.centerYAnchor).isActive = true
        
        let widthConstraint = outline.widthAnchor.constraint(equalToConstant: 100)
        widthConstraint.priority = .init(rawValue: 999)
        widthConstraint.isActive = true
        self.widthConstraint = widthConstraint
        
        applyTheme()
    }

    private func hover() {
        outline.backgroundColor = isSelected || isHighlighted ? .theme.ecosia.hoverBackgroundColor : .theme.ecosia.ecosiaHomeCellBackground
    }

    func applyTheme() {
        outline.backgroundColor = .theme.ecosia.ecosiaHomeCellBackground
        title.textColor = .theme.ecosia.primaryText
        subtitle.textColor = .theme.ecosia.primaryButton
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
}
