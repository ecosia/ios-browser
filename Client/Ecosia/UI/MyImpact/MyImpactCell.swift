/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

struct MyImpactCellModel {
    var top: MyImpactStackViewModel?
    var middle: MyImpactStackViewModel?
    var bottom: MyImpactStackViewModel?
}

final class MyImpactCell: UICollectionViewCell, AutoSizingCell, Themeable {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private weak var widthConstraint: NSLayoutConstraint!
    weak var container: UIStackView!
    weak var topStack: MyImpactStackView!
    weak var middleStack: MyImpactStackView!
    weak var bottomStack: MyImpactStackView!
    weak var outline: UIView!
    weak var separator: UIView!

    private (set) var model: MyImpactCellModel?

    private func setup() {
        let outline = UIView()
        contentView.addSubview(outline)
        outline.layer.cornerRadius = 8
        outline.translatesAutoresizingMaskIntoConstraints = false
        self.outline = outline

        let container = UIStackView()
        container.distribution = .fill
        container.axis = .vertical
        container.spacing = 12
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        self.container = container

        outline.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        outline.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        outline.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12).isActive = true
        outline.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4).isActive = true

        let widthConstraint = outline.widthAnchor.constraint(equalToConstant: 100)
        widthConstraint.priority = .defaultHigh
        widthConstraint.isActive = true
        self.widthConstraint = widthConstraint

        container.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16).isActive = true
        container.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16).isActive = true
        container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 30).isActive = true
        container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20).isActive = true

        let topStack = MyImpactStackView()
        container.addArrangedSubview(topStack)
        self.topStack = topStack

        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = UIColor.theme.ecosia.barSeparator
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        container.addArrangedSubview(separator)
        self.separator = separator

        let middleStack = MyImpactStackView()
        container.addArrangedSubview(middleStack)
        self.middleStack = middleStack

        let bottomStack = MyImpactStackView()
        container.addArrangedSubview(bottomStack)
        self.bottomStack = bottomStack

        applyTheme()
    }

    func display(_ model: MyImpactCellModel) {
        self.model = model

        if let top = model.top {
            topStack.isHidden = false
            topStack.display(top)
        } else {
            topStack.isHidden = true
        }

        if let middle = model.middle {
            middleStack.isHidden = false
            separator.isHidden = false
            middleStack.display(middle)
        } else {
            middleStack.isHidden = true
            separator.isHidden = true
        }

        if let bottom = model.bottom {
            bottomStack.isHidden = false
            bottomStack.display(bottom)
        } else {
            bottomStack.isHidden = true
        }
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

    func applyTheme() {
        [topStack, middleStack, bottomStack].forEach({ $0?.applyTheme() })
        outline.elevate()
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
