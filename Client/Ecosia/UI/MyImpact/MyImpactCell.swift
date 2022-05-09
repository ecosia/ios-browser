/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

struct MyImpactCellModel {
    var top: MyImpactStackViewModel?
    var middle: MyImpactStackViewModel?
    var bottom: MyImpactStackViewModel?
    var callout: Callout

    struct Callout {
        var text: String
        var button: String
        var selector: Selector
        var collapsed: Bool
    }
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
    var container: UIStackView!
    var topStack: MyImpactStackView!
    var topContainer: UIView!
    var calloutContainerConstraint: NSLayoutConstraint!
    var calloutSeparatorConstraint: NSLayoutConstraint!
    weak var middleStack: MyImpactStackView!
    weak var bottomStack: MyImpactStackView!
    weak var outline: UIView!
    weak var separator: UIView!

    var callout: UIView!
    var calloutStack: UIStackView!
    var calloutLabel: UILabel!
    var calloutButton: UIButton!

    private (set) var model: MyImpactCellModel?

    private func setup() {
        let outline = UIView()
        contentView.addSubview(outline)
        outline.layer.cornerRadius = 10
        outline.translatesAutoresizingMaskIntoConstraints = false
        self.outline = outline

        let container = UIStackView()
        container.distribution = .fill
        container.axis = .vertical
        container.spacing = 20
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

        let topContainer = UIView()
        topContainer.translatesAutoresizingMaskIntoConstraints = false

        let topStack = MyImpactStackView()
        topStack.setContentHuggingPriority(.required, for: .vertical)
        topStack.translatesAutoresizingMaskIntoConstraints = false
        topContainer.addSubview(topStack)
        self.topStack = topStack

        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        topContainer.addSubview(separator)

        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        separator.topAnchor.constraint(equalTo: topStack.bottomAnchor, constant: 12).isActive = true
        separator.rightAnchor.constraint(equalTo: topContainer.rightAnchor).isActive = true
        separator.leftAnchor.constraint(equalTo: topContainer.leftAnchor).isActive = true
        self.separator = separator

        let callout = UIView()
        callout.translatesAutoresizingMaskIntoConstraints = false
        callout.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        topContainer.addSubview(callout)
        callout.layer.cornerRadius = 8
        self.callout = callout

        let calloutStack = UIStackView()
        calloutStack.translatesAutoresizingMaskIntoConstraints = false
        calloutStack.axis = .vertical
        calloutStack.alignment = .leading
        calloutStack.spacing = 8
        callout.addSubview(calloutStack)
        calloutStack.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        self.calloutStack = calloutStack

        calloutStack.topAnchor.constraint(equalTo: callout.topAnchor, constant: 12).isActive = true
        calloutStack.leftAnchor.constraint(equalTo: callout.leftAnchor, constant: 12).isActive = true
        calloutStack.rightAnchor.constraint(equalTo: callout.rightAnchor, constant: -12).isActive = true
        calloutStack.bottomAnchor.constraint(equalTo: callout.bottomAnchor, constant: -12).isActive = true

        let calloutLabel = UILabel()
        calloutLabel.font = .preferredFont(forTextStyle: .footnote)
        calloutLabel.adjustsFontForContentSizeCategory = true
        calloutLabel.numberOfLines = 0
        calloutLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        calloutLabel.lineBreakMode = .byClipping
        calloutStack.addArrangedSubview(calloutLabel)
        self.calloutLabel = calloutLabel

        let calloutButton = UIButton(type: .custom)
        calloutButton.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
        calloutButton.titleLabel?.adjustsFontForContentSizeCategory = true
        calloutButton.setContentHuggingPriority(.defaultHigh, for: .vertical)
        calloutButton.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        calloutButton.addTarget(self, action: #selector(calloutTapped), for: .primaryActionTriggered)
        calloutStack.addArrangedSubview(calloutButton)
        self.calloutButton = calloutButton

        topContainer.topAnchor.constraint(equalTo: topStack.topAnchor).isActive = true
        topContainer.leftAnchor.constraint(equalTo: topStack.leftAnchor).isActive = true
        topContainer.rightAnchor.constraint(equalTo: topStack.rightAnchor).isActive = true

        let calloutSeparatorConstraint = topStack.bottomAnchor.constraint(equalTo: separator.bottomAnchor, constant: 12)
        calloutSeparatorConstraint.priority = .init(999)
        calloutSeparatorConstraint.isActive = true
        self.calloutSeparatorConstraint = calloutSeparatorConstraint

        callout.topAnchor.constraint(equalTo: separator.bottomAnchor).isActive = true
        callout.leftAnchor.constraint(equalTo: topContainer.leftAnchor).isActive = true
        callout.rightAnchor.constraint(equalTo: topContainer.rightAnchor).isActive = true

        let calloutBottom = callout.bottomAnchor.constraint(equalTo: topContainer.bottomAnchor)
        calloutBottom.priority = .defaultHigh
        calloutBottom.isActive = true
        self.calloutContainerConstraint = calloutBottom

        container.addArrangedSubview(topContainer)
        self.topContainer = topContainer

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
            topStack.display(top, action: .arrow(collapsed: model.callout.collapsed))
        } else {
            topStack.isHidden = true
        }

        if let middle = model.middle {
            middleStack.isHidden = false
            middleStack.display(middle)
        } else {
            middleStack.isHidden = true
        }

        if let bottom = model.bottom {
            bottomStack.isHidden = false
            bottomStack.display(bottom)
        } else {
            bottomStack.isHidden = true
        }

        calloutButton.setTitle(model.callout.button, for: .normal)
        calloutLabel.text = model.callout.text

        if model.callout.collapsed {
            calloutSeparatorConstraint.priority = .defaultHigh
            calloutContainerConstraint.isActive = false
            callout.alpha = 0
            separator.alpha = 1
        } else {
            calloutSeparatorConstraint.priority = .defaultLow
            calloutContainerConstraint.isActive = true
            callout.alpha =  1
            separator.alpha = 0
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

        outline.backgroundColor = UIColor.theme.ecosia.ecosiaHomeCelBackground
        separator.backgroundColor = UIColor.theme.ecosia.barSeparator

        callout.backgroundColor = UIColor.theme.ecosia.impactBackground
        calloutLabel.textColor = UIColor.theme.ecosia.highContrastText
        calloutButton.setTitleColor(UIColor.theme.ecosia.primaryBrand, for: .normal)
    }

    func setWidth(_ width: CGFloat, insets: UIEdgeInsets) {
        let margin = max(max(16, insets.left), insets.right)
        widthConstraint.constant = width - 2 * margin
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }

    @objc func calloutTapped() {
        guard let selector = model?.callout.selector else { return }

        if let target = target(forAction: selector, withSender: self) as? UIResponder {
            target.perform(selector)
        }
    }
}
