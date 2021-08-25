/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

struct MyImpcactCellModel {
    var top: MyImpactStackViewModel
    var middle: MyImpactStackViewModel
    var bottom: MyImpactStackViewModel
}

protocol MyImpactCellDelegate: AnyObject {
    func impactCellTriggerAction(_ action: MyImpactStackViewModel.Action)
}

final class MyImpactCell: UICollectionViewCell, Themeable {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    weak var widthConstraint: NSLayoutConstraint!
    weak var container: UIStackView!
    weak var topStack: MyImpactStackView!
    weak var middleStack: MyImpactStackView!
    weak var bottomStack: MyImpactStackView!
    weak var outline: UIView!
    weak var separator: UIView!

    private (set) var model: MyImpcactCellModel?
    weak var delegate: MyImpactCellDelegate?

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
        outline.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        outline.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true

        let widthConstraint = outline.widthAnchor.constraint(equalToConstant: 100)
        widthConstraint.priority = .defaultHigh
        widthConstraint.isActive = true
        self.widthConstraint = widthConstraint

        container.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16).isActive = true
        container.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16).isActive = true
        container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20).isActive = true
        container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20).isActive = true

        let topStack = MyImpactStackView()
        topStack.delegate = self
        container.addArrangedSubview(topStack)
        self.topStack = topStack

        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = UIColor.theme.ecosia.barSeparator
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        container.addArrangedSubview(separator)
        self.separator = separator

        let middleStack = MyImpactStackView()
        middleStack.delegate = self
        container.addArrangedSubview(middleStack)
        self.middleStack = middleStack

        let bottomStack = MyImpactStackView()
        bottomStack.delegate = self
        container.addArrangedSubview(bottomStack)
        self.bottomStack = bottomStack

        applyTheme()
    }

    func display(_ model: MyImpcactCellModel) {
        self.model = model

        topStack.display(model.top)
        middleStack.display(model.middle)
        bottomStack.display(model.bottom)
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

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
}

extension MyImpactCell: MyImpactStackDelegate {
    func impactStackTitleAction(_ stack: MyImpactStackView) {
        guard let action = stack.model.action else { return }
        delegate?.impactCellTriggerAction(action)
    }

    func impactStackTitleCallout(_ stack: MyImpactStackView) {
        guard let action = stack.model.action else { return }
        delegate?.impactCellTriggerAction(action)
    }
}
