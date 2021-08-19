/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

protocol MyImpactStackDelegate: AnyObject {
    func impactStackTitleAction(_ stack: MyImpactStackView)
}

struct MyImpactStackViewModel {
    let title: String
    let boldTitle: Bool
    let subtitle: String?
    let imageName: String

    let action: Action?

    enum Action {
        case tap(String), collapse(String, String)
    }

}

class MyImpactStackView: UIStackView, Themeable {
    var model: MyImpactStackViewModel!
    weak var delegate: MyImpactStackDelegate?

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

        let titleLabel = UILabel()
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        labelStack.addArrangedSubview(titleLabel)
        self.titleLabel = titleLabel

        let subtitleLabel = UILabel()
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        labelStack.addArrangedSubview(subtitleLabel)
        self.subtitleLabel = subtitleLabel

        let actionButton = UIButton(type: .custom)
        actionButton.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        actionButton.setContentHuggingPriority(.required, for: .horizontal)
        actionButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        actionButton.addTarget(self, action: #selector(actionTapped), for: .primaryActionTriggered)
        addArrangedSubview(actionButton)
        self.actionButton = actionButton
    }

    func display(_ model: MyImpactStackViewModel) {
        self.model = model
        titleLabel.text = model.title
        subtitleLabel.text = model.subtitle
        subtitleLabel.isHidden = model.subtitle == nil

        imageView.image = UIImage(themed: model.imageName)

        if let action = model.action {
            actionButton.isHidden = false

            switch action {
            case .tap(let title):
                actionButton.setTitle(title, for: .normal)
                actionButton.setImage(nil, for: .normal)
            case .collapse(let description, let actionTitle):
                actionButton.setTitle(nil, for: .normal)
                actionButton.setImage(.init(themed: "impactDown"), for: .normal)
                actionButton.imageView?.contentMode = .scaleAspectFit
            }
        } else {
            actionButton.isHidden = true
        }
        applyTheme()
    }

    func applyTheme() {
        guard let model = model else { return }

        let style: UIFont.TextStyle = model.boldTitle ? .headline : .subheadline
        titleLabel.font = .preferredFont(forTextStyle: style)
        titleLabel.textColor = UIColor.theme.ecosia.highContrastText
        subtitleLabel.textColor = UIColor.theme.ecosia.secondaryText
        actionButton.setTitleColor(UIColor.theme.ecosia.primaryBrand, for: .normal)
        imageView.image = UIImage(themed: model.imageName)
    }

    @objc func actionTapped() {
        delegate?.impactStackTitleAction(self)
    }
}
