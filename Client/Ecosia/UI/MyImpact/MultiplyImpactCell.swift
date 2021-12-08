/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

final class MultiplyImpactCell: UICollectionViewCell, AutoSizingCell, Themeable {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private weak var stack: MyImpactStackView!
    private weak var outline: UIView!
    private var widthConstraint: NSLayoutConstraint!

    private func setup() {
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

        let stack = MyImpactStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        self.stack = stack

        stack.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16).isActive = true
        stack.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16).isActive = true
        stack.topAnchor.constraint(equalTo: contentView.topAnchor,constant: 18).isActive = true
        stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -18).isActive = true

        applyTheme()
    }

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

    private func hover() {
        outline.backgroundColor = isSelected || isHighlighted ? UIColor.theme.ecosia.hoverBackgroundColor : UIColor.theme.ecosia.highlightedBackground
    }

    func display(_ model: MyImpactStackViewModel, action: MyImpactStackViewModel.Action?) {
        stack.display(model, action: action)
        applyTheme()
    }

    func applyTheme() {
        stack.applyTheme()
        stack.subtitleLabel.textColor = UIColor.theme.ecosia.highContrastText

        outline.layer.borderWidth = ThemeManager.instance.current.isDark ? 0 : 1
        outline.backgroundColor = UIColor.theme.ecosia.highlightedBackground
        outline.layer.borderColor = UIColor.theme.ecosia.highlightedBorder.cgColor
    }

    func setWidth(_ width: CGFloat, insets: UIEdgeInsets) {
        let margin = max(max(16, insets.left), insets.right)
        widthConstraint.constant = width - 2 * margin
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
}
