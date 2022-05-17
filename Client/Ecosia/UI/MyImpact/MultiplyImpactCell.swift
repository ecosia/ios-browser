/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

final class MultiplyImpactCell: UICollectionViewCell, AutoSizingCell, Themeable {
    private(set) weak var widthConstraint: NSLayoutConstraint!
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

        outline.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        outline.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        outline.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4).isActive = true
        outline.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4).isActive = true

        let widthConstraint = outline.widthAnchor.constraint(equalToConstant: 100)
        widthConstraint.priority = .init(rawValue: 999)
        widthConstraint.isActive = true
        self.widthConstraint = widthConstraint

        applyTheme()
    }

    private func hover() {
        outline.backgroundColor = isSelected || isHighlighted ? UIColor.theme.ecosia.hoverBackgroundColor : UIColor.theme.ecosia.highlightedBackground
    }

    func applyTheme() {
        outline.layer.borderWidth = ThemeManager.instance.current.isDark ? 0 : 1
        outline.backgroundColor = UIColor.theme.ecosia.highlightedBackground
        outline.layer.borderColor = UIColor.theme.ecosia.highlightedBorder.cgColor
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
}
