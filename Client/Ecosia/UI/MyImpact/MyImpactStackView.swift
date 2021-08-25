/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

protocol MyImpactStackDelegate: AnyObject {
    func impactStackTitleAction(_ stack: MyImpactStackView)
    func impactStackTitleCallout(_ stack: MyImpactStackView)
}

struct MyImpactStackViewModel {
    let title: String
    let boldTitle: Bool
    let subtitle: String?
    let imageName: String

    var action: Action?

    enum Action {
        case tap(String), collapse(String, String, Bool)
    }

}

class MyImpactStackView: UIStackView, Themeable {
    var model: MyImpactStackViewModel!
    weak var delegate: MyImpactStackDelegate?

    private weak var topStack: UIStackView!
    private weak var titleLabel: UILabel!
    private weak var subtitleLabel: UILabel!
    private weak var actionButton: UIButton!
    private weak var imageView: UIImageView!
    private weak var callout: UIView!
    private weak var calloutStack: UIStackView!
    private weak var calloutLabel: UILabel!
    private weak var calloutButton: UIButton!

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

        addArrangedSubview(topStack)

        let imageBackground = UIView()
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageBackground.addSubview(imageView)
        self.imageView = imageView

        imageView.topAnchor.constraint(equalTo: imageBackground.topAnchor).isActive = true
        imageView.leftAnchor.constraint(equalTo: imageBackground.leftAnchor).isActive = true
        imageView.rightAnchor.constraint(equalTo: imageBackground.rightAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: imageBackground.bottomAnchor).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 32).isActive = true
        topStack.addArrangedSubview(imageBackground)

        let labelStack = UIStackView()
        labelStack.axis = .vertical
        labelStack.distribution = .fill
        labelStack.spacing = 2
        labelStack.distribution = .fill
        topStack.addArrangedSubview(labelStack)

        let titleLabel = UILabel()
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        labelStack.addArrangedSubview(titleLabel)
        self.titleLabel = titleLabel

        let subtitleLabel = UILabel()
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        subtitleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
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
        self.calloutStack = calloutStack

        calloutStack.topAnchor.constraint(equalTo: callout.topAnchor, constant: 12).isActive = true
        calloutStack.leftAnchor.constraint(equalTo: callout.leftAnchor, constant: 12).isActive = true
        calloutStack.rightAnchor.constraint(equalTo: callout.rightAnchor, constant: -12).isActive = true
        calloutStack.bottomAnchor.constraint(equalTo: callout.bottomAnchor, constant: -12).isActive = true

        let calloutLabel = UILabel()
        calloutLabel.font = .preferredFont(forTextStyle: .footnote)
        calloutLabel.adjustsFontForContentSizeCategory = true
        calloutLabel.numberOfLines = 0
        calloutStack.addArrangedSubview(calloutLabel)
        self.calloutLabel = calloutLabel

        let calloutButton = UIButton(type: .custom)
        calloutButton.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
        calloutButton.titleLabel?.adjustsFontForContentSizeCategory = true
        calloutButton.setContentHuggingPriority(.defaultHigh, for: .vertical)
        calloutButton.addTarget(self, action: #selector(calloutTapped), for: .primaryActionTriggered)
        calloutStack.addArrangedSubview(calloutButton)
        self.calloutButton = calloutButton
    }

    func display(_ model: MyImpactStackViewModel) {
        self.model = model
        titleLabel.text = model.title
        subtitleLabel.text = model.subtitle
        subtitleLabel.isHidden = model.subtitle == nil

        imageView.image = UIImage(themed: model.imageName)

        if let action = model.action {
            display(action)
        } else {
            actionButton.isHidden = true
        }
        applyTheme()
    }

    func display(_ action: MyImpactStackViewModel.Action) {
        actionButton.isHidden = false

        switch action {
        case .tap(let title):
            actionButton.setTitle(title, for: .normal)
            actionButton.setImage(nil, for: .normal)
        case .collapse(let description, let actionTitle, let collapsed):
            actionButton.setTitle(nil, for: .normal)

            let image: UIImage = collapsed ? .init(themed: "impactDown")! : .init(themed: "impactUp")!
            actionButton.setImage(image, for: .normal)
            actionButton.imageView?.contentMode = .scaleAspectFit

            calloutStack.isHidden = collapsed
            callout.isHidden = collapsed
            calloutButton.setTitle(actionTitle, for: .normal)
            calloutLabel.text = description
        }
    }

    func applyTheme() {
        guard let model = model else { return }

        let style: UIFont.TextStyle = model.boldTitle ? .headline : .subheadline
        titleLabel.font = .preferredFont(forTextStyle: style)
        titleLabel.textColor = UIColor.theme.ecosia.highContrastText
        subtitleLabel.textColor = UIColor.theme.ecosia.secondaryText
        callout.backgroundColor = UIColor.theme.ecosia.impactBackground
        calloutLabel.textColor = UIColor.theme.ecosia.highContrastText
        calloutButton.setTitleColor(UIColor.theme.ecosia.primaryBrand, for: .normal)
        actionButton.setTitleColor(UIColor.theme.ecosia.primaryBrand, for: .normal)
        imageView.image = UIImage(themed: model.imageName)
    }

    @objc func actionTapped() {
        guard let action = model.action else { return }

        switch action {
        case .tap:
            delegate?.impactStackTitleAction(self)
        case .collapse(let description, let title, let collapse):
            delegate?.impactStackTitleAction(self)
            self.model.action = .collapse(description, title, !collapse)
            display(self.model)
        }
    }

    @objc func calloutTapped() {
        delegate?.impactStackTitleCallout(self)
    }
}
