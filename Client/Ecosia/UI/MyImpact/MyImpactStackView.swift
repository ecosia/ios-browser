/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

protocol MyImpactStackDelegate: AnyObject {
    func impactStackTitleAction(_ stack: MyImpactStackView)
}

struct MyImpactStackViewModel {
    let title: String
    let titleAction: Bool
    let boldTitle: Bool
    let subtitle: String?
    let imageName: String
    let actionName: String?
}

class MyImpactStackView: UIStackView, Themeable {
    var model: MyImpactStackViewModel!
    weak var delegate: MyImpactStackDelegate?

    private weak var titleLabel: UILabel!
    private weak var titleButton: UIButton!
    private weak var subtitleLabel: UILabel!
    private weak var actionLabel: UILabel!
    private weak var imageView: UIImageView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        axis = .horizontal
        spacing = 8

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
        addArrangedSubview(imageBackground)

        let labelStack = UIStackView()
        labelStack.axis = .vertical
        labelStack.distribution = .fill
        labelStack.spacing = 2
        labelStack.distribution = .fill
        addArrangedSubview(labelStack)

        let headlineStack = UIStackView()
        headlineStack.axis = .horizontal
        headlineStack.spacing = 8
        labelStack.addArrangedSubview(headlineStack)

        let titleLabel = UILabel()
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        headlineStack.addArrangedSubview(titleLabel)
        self.titleLabel = titleLabel

        let titleButton = UIButton(type: .infoLight)
        headlineStack.addArrangedSubview(titleButton)
        titleButton.addTarget(self, action: #selector(titleActionTapped), for: .primaryActionTriggered)
        self.titleButton = titleButton

        let emptyView = UIView()
        emptyView.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        headlineStack.addArrangedSubview(emptyView)

        let subtitleLabel = UILabel()
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        labelStack.addArrangedSubview(subtitleLabel)
        self.subtitleLabel = subtitleLabel

        let actionLabel = UILabel()
        actionLabel.font = .preferredFont(forTextStyle: .subheadline)
        actionLabel.setContentHuggingPriority(.required, for: .horizontal)
        addArrangedSubview(actionLabel)
        self.actionLabel = actionLabel
    }

    func display(_ model: MyImpactStackViewModel) {
        self.model = model
        titleLabel.text = model.title
        subtitleLabel.text = model.subtitle
        subtitleLabel.isHidden = model.subtitle == nil

        imageView.image = UIImage(themed: model.imageName)
        actionLabel.text = model.actionName
        actionLabel.isHidden = model.actionName == nil
        titleButton.isHidden = !model.titleAction

        applyTheme()
    }

    func applyTheme() {
        guard let model = model else { return }

        let style: UIFont.TextStyle = model.boldTitle ? .headline : .subheadline
        titleLabel.font = .preferredFont(forTextStyle: style)
        titleLabel.textColor = UIColor.theme.ecosia.highContrastText
        subtitleLabel.textColor = UIColor.theme.ecosia.secondaryText
        actionLabel.textColor = UIColor.theme.ecosia.primaryBrand
        imageView.image = UIImage(themed: model.imageName)
    }

    @objc func titleActionTapped() {
        delegate?.impactStackTitleAction(self)
    }
}
