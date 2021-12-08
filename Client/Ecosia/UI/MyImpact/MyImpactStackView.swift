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

    enum Action {
        case tap(text: String)
        case arrow(collapsed: Bool)
    }
}

class MyImpactStackView: UIStackView, Themeable {
    var model: MyImpactStackViewModel!
    var action: MyImpactStackViewModel.Action?

    private weak var topStack: UIStackView!
    private weak var titleLabel: UILabel!
    weak var subtitleLabel: UILabel!
    private weak var actionButton: UIButton!
    private weak var imageView: UIImageView!
    private weak var imageBackgroundView: UIView!
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
    }

    func display(_ model: MyImpactStackViewModel, action: MyImpactStackViewModel.Action? = nil) {
        self.model = model
        self.action = action
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

        if let action = action {
            display(action)
        } else {
            actionButton.isHidden = true
        }
        applyTheme()
    }

    func display(_ action: MyImpactStackViewModel.Action) {
        actionButton.isHidden = false

        switch action {
        case .tap(let text):
            actionButton.setTitle(text, for: .normal)
            actionButton.setImage(nil, for: .normal)
            actionButton.isUserInteractionEnabled = false
        case .arrow(let collapsed):
            actionButton.setTitle(nil, for: .normal)
            actionButton.isUserInteractionEnabled = true

            let image: UIImage = .init(themed: "impactDown")!
            actionButton.setImage(image, for: .normal)
            actionButton.imageView?.contentMode = .scaleAspectFit
            actionButton.transform = collapsed ? .identity : .init(rotationAngle: Double.pi - 0.00001)
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
        actionButton.setTitleColor(UIColor.theme.ecosia.primaryBrand, for: .normal)
        model.imageName.map { imageView.image = UIImage(themed: $0) }
    }

    @objc func actionTapped() {
        guard let action = action else { return }

        switch action {
        case .tap:
            break
        case .arrow:
            let selector = #selector(MyImpactStackViewModelResize.resizeStack)
            if let target = target(forAction: selector, withSender: self) as? UIResponder {
                target.perform(selector, with: self)
            }
        }
    }
}
