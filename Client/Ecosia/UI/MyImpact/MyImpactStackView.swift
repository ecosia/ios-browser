/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

@objc protocol MyImpactStackViewModelResize: AnyObject {
    @objc func resizeStack(sender: MyImpactStackView)
}

struct MyImpactStackViewModel {
    let title: String?
    let highlight: Bool
    let subtitle: String?
    let imageName: String?

    var callout: Callout?

    struct Callout {
        var action: Action
        var collapsed: Bool = true
    }

    enum Action {
        case tap(text: String)
        case collapse(text: String, button: String, selector: Selector)
    }
}

class MyImpactStackView: UIStackView, Themeable {
    var model: MyImpactStackViewModel!

    private weak var topStack: UIStackView!
    private weak var titleLabel: UILabel!
    weak var subtitleLabel: UILabel!
    private weak var actionButton: UIButton!
    private weak var imageView: UIImageView!
    private weak var imageBackgroundView: UIView!
    private weak var callout: UIView!
    private weak var calloutStack: UIStackView!
    private weak var calloutLabel: UILabel!
    private weak var calloutButton: UIButton!
    private weak var imageWidthConstraint: NSLayoutConstraint!
    private weak var imageHeightConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        axis = .vertical
        spacing = 8

        let topStack = UIStackView()
        topStack.spacing = 8
        topStack.axis = .horizontal
        topStack.alignment = .center
        topStack.translatesAutoresizingMaskIntoConstraints = false
        topStack.setContentCompressionResistancePriority(.required, for: .vertical)
        addArrangedSubview(topStack)

        let imageBackgroundView = UIView()
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageBackgroundView.addSubview(imageView)
        imageBackgroundView.setContentCompressionResistancePriority(.required, for: .vertical)
        self.imageBackgroundView = imageBackgroundView
        self.imageView = imageView

        imageView.leftAnchor.constraint(equalTo: imageBackgroundView.leftAnchor).isActive = true
        imageView.rightAnchor.constraint(equalTo: imageBackgroundView.rightAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: imageBackgroundView.centerYAnchor).isActive = true
        imageView.setContentCompressionResistancePriority(.required, for: .vertical)

        let imageWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: 32)
        imageWidthConstraint.priority = .defaultHigh
        imageWidthConstraint.isActive = true
        self.imageWidthConstraint = imageWidthConstraint

        let imageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: 32)
        imageHeightConstraint.priority = .defaultHigh
        imageHeightConstraint.isActive = true
        self.imageHeightConstraint = imageHeightConstraint

        topStack.addArrangedSubview(imageBackgroundView)

        let labelStack = UIStackView()
        labelStack.axis = .vertical
        labelStack.distribution = .fillEqually
        labelStack.spacing = 2
        labelStack.setContentCompressionResistancePriority(.required, for: .vertical)
        topStack.addArrangedSubview(labelStack)

        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        labelStack.addArrangedSubview(titleLabel)
        self.titleLabel = titleLabel

        let subtitleLabel = UILabel()
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        subtitleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        subtitleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        subtitleLabel.numberOfLines = 0
        labelStack.addArrangedSubview(subtitleLabel)
        self.subtitleLabel = subtitleLabel

        let actionButton = UIButton(type: .custom)
        actionButton.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        actionButton.titleLabel?.adjustsFontForContentSizeCategory = true
        actionButton.setContentHuggingPriority(.required, for: .horizontal)
        actionButton.setContentHuggingPriority(.defaultLow, for: .vertical)
        actionButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        actionButton.addTarget(self, action: #selector(actionTapped), for: .primaryActionTriggered)
        topStack.addArrangedSubview(actionButton)
        self.actionButton = actionButton

        let callout = UIView()
        callout.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        addArrangedSubview(callout)
        callout.isHidden = true
        callout.layer.cornerRadius = 8
        self.callout = callout

        let calloutStack = UIStackView()
        calloutStack.translatesAutoresizingMaskIntoConstraints = false
        calloutStack.axis = .vertical
        calloutStack.alignment = .leading
        calloutStack.spacing = 8
        callout.addSubview(calloutStack)
        calloutStack.isHidden = true
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
        calloutLabel.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        calloutLabel.lineBreakMode = .byClipping
        calloutStack.addArrangedSubview(calloutLabel)
        self.calloutLabel = calloutLabel

        let calloutButton = UIButton(type: .custom)
        calloutButton.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
        calloutButton.titleLabel?.adjustsFontForContentSizeCategory = true
        calloutButton.setContentHuggingPriority(.defaultHigh, for: .vertical)
        calloutButton.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        calloutButton.addTarget(self, action: #selector(calloutTapped), for: .primaryActionTriggered)
        calloutStack.addArrangedSubview(calloutButton)
        self.calloutButton = calloutButton
    }

    func display(_ model: MyImpactStackViewModel) {
        self.model = model
        titleLabel.text = model.title
        titleLabel.isHidden = model.title == nil
        subtitleLabel.text = model.subtitle
        subtitleLabel.isHidden = model.subtitle == nil

        if let imageName = model.imageName {
            imageView.isHidden = false
            imageBackgroundView.isHidden = false
            imageView.image = UIImage(themed: imageName)
        } else {
            imageView.isHidden = true
            imageBackgroundView.isHidden = true
        }

        if let callout = model.callout {
            display(callout)
        } else {
            actionButton.isHidden = true
        }
        applyTheme()
    }

    func display(_ callout: MyImpactStackViewModel.Callout) {
        actionButton.isHidden = false

        switch callout.action {
        case .tap(let text):
            actionButton.setTitle(text, for: .normal)
            actionButton.setImage(nil, for: .normal)
            actionButton.isUserInteractionEnabled = false
        case .collapse(let text, let button, _):
            actionButton.setTitle(nil, for: .normal)
            actionButton.isUserInteractionEnabled = true

            let collapsed = callout.collapsed != false
            let image: UIImage = .init(themed: "impactDown")!
            actionButton.setImage(image, for: .normal)
            actionButton.imageView?.contentMode = .scaleAspectFit
            actionButton.transform = collapsed ? .identity : .init(rotationAngle: Double.pi - 0.00001)
            calloutStack.isHidden = collapsed
            self.callout.isHidden = collapsed
            calloutButton.setTitle(button, for: .normal)
            calloutLabel.text = text
        }
    }

    func applyTheme() {
        guard let model = model else { return }

        let style: UIFont.TextStyle = model.highlight ? .headline : .body
        titleLabel.font = UIFont.preferredFont(forTextStyle: style)
        imageWidthConstraint.constant = model.highlight ? 74 : 32
        imageHeightConstraint.constant = model.highlight ? 52 : 32

        titleLabel.textColor = UIColor.theme.ecosia.highContrastText
        subtitleLabel.textColor = UIColor.theme.ecosia.secondaryText
        callout.backgroundColor = UIColor.theme.ecosia.impactBackground
        calloutLabel.textColor = UIColor.theme.ecosia.highContrastText
        calloutButton.setTitleColor(UIColor.theme.ecosia.primaryBrand, for: .normal)
        actionButton.setTitleColor(UIColor.theme.ecosia.primaryBrand, for: .normal)
        model.imageName.map { imageView.image = UIImage(themed: $0) }
    }

    @objc func actionTapped() {
        guard let callout = model.callout else { return }

        switch callout.action {
        case .tap:
            break
        case .collapse:
            let selector = #selector(MyImpactStackViewModelResize.resizeStack)
            if let target = target(forAction: selector, withSender: self) as? UIResponder {
                target.perform(selector, with: self)
            }
        }
    }

    @objc func calloutTapped() {
        guard let callout = model.callout else { return }

        if case .collapse(_, _, let selector) = callout.action {
            if let target = target(forAction: selector, withSender: self) as? UIResponder {
                target.perform(selector)
            }
        }
    }
}
