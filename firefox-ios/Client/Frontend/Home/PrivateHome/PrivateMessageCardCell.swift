// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import ComponentLibrary
import Ecosia
import UIKit

// UI element used to describe details about private browsing on the private firefox homepage
class PrivateMessageCardCell: UIView, ThemeApplicable {
    typealias a11y = AccessibilityIdentifiers.PrivateMode.Homepage
    var privateBrowsingLinkTapped: (() -> Void)?

    struct PrivateMessageCard: Hashable {
        let title: String
        let body: String
        let link: String
    }

    /* Ecosia: Redesign private message card to match Ecosia incognito design
    enum UX {
        static let contentStackViewSpacing: CGFloat = 8
        static let contentStackPadding: CGFloat = 16
        static let actionButtonInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    }

    private lazy var cardContainer: ShadowCardView = .build()

    private lazy var mainView: UIView = .build()
     */
    enum UX {
        static let contentStackViewSpacing: CGFloat = 16
        static let contentStackPadding: CGFloat = 24
        static let iconSize: CGFloat = 64
        static let titleBodySpacing: CGFloat = 8
        static let bodyButtonSpacing: CGFloat = 24
        static let buttonHorizontalPadding: CGFloat = 20
        static let buttonVerticalPadding: CGFloat = 12
        static let buttonIconSize: CGFloat = 16
        static let buttonIconSpacing: CGFloat = 6
    }

    private lazy var contentStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.alignment = .center // Ecosia: Incognito NTP design
        stackView.spacing = UX.contentStackViewSpacing
    }

    // Ecosia: Incognito icon graphic
    private lazy var iconImageView: UIImageView = .build { imageView in
        imageView.image = UIImage(named: "incognito", in: .ecosia, with: nil)?
            .withRenderingMode(.alwaysTemplate)
        imageView.contentMode = .scaleAspectFit
    }

    private lazy var headerLabel: UILabel = .build { label in
        /* Ecosia: Use Ecosia design system title3 at size 25
        label.font = FXFontStyles.Regular.headline.scaledFont()
         */
        label.font = .ecosia(size: 25)
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center // Ecosia: Incognito NTP design
        label.accessibilityIdentifier = a11y.title
        label.accessibilityTraits.insert(.header)
    }

    private lazy var bodyLabel: UILabel = .build { label in
        /* Ecosia: Use Ecosia design system body at size 20
        label.font = FXFontStyles.Regular.body.scaledFont()
         */
        label.font = .ecosia(size: 20)
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center // Ecosia: Incognito NTP design
        label.accessibilityIdentifier = a11y.body
    }

    /* Ecosia: Replace inline link label with a pill-shaped link button
    private lazy var linkLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = a11y.link
        label.accessibilityTraits.insert(.link)
        label.isUserInteractionEnabled = true
    }
     */
    private lazy var linkButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(
            top: UX.buttonVerticalPadding,
            leading: UX.buttonHorizontalPadding,
            bottom: UX.buttonVerticalPadding,
            trailing: UX.buttonHorizontalPadding
        )
        config.imagePlacement = .trailing
        config.imagePadding = UX.buttonIconSpacing
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: UX.buttonIconSize, weight: .regular)
        config.image = UIImage(systemName: "arrow.up.right.square", withConfiguration: symbolConfig)
        config.titleLineBreakMode = .byTruncatingTail
        button.configuration = config
        button.titleLabel?.font = .ecosia(size: 20)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.7
        button.layer.cornerRadius = 22
        button.layer.borderWidth = 1
        button.layer.masksToBounds = true
        button.accessibilityIdentifier = a11y.link
        button.accessibilityTraits.insert(.link)
        button.addTarget(self, action: #selector(linkTapped), for: .touchUpInside)
        return button
    }()

    /* Ecosia: Link tap is now handled by linkButton's target/action
    @objc
    func linkTapped(_ sender: UITapGestureRecognizer) {
        privateBrowsingLinkTapped?()
    }
     */
    @objc
    private func linkTapped() {
        privateBrowsingLinkTapped?()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with item: PrivateMessageCard, and theme: Theme) {
        headerLabel.text = item.title
        bodyLabel.text = item.body
        /* Ecosia: Configure link button with the link text instead of underlined label
        linkLabel.attributedText = getUnderlineText(for: item.link)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.linkTapped(_:)))
        linkLabel.addGestureRecognizer(tapGesture)

        let cardModel = ShadowCardViewModel(view: mainView, a11yId: a11y.card)
        cardContainer.configure(cardModel)
         */
        linkButton.setTitle(item.link, for: .normal)
        applyTheme(theme: theme)
    }

    func applyTheme(theme: Theme) {
        /* Ecosia: Drop ShadowCardView and apply Ecosia incognito theming directly
        cardContainer.applyTheme(theme: theme)
         */
        let contentColor = theme.colors.ecosia.buttonContentPrimary
        headerLabel.textColor = contentColor
        bodyLabel.textColor = contentColor
        linkButton.setTitleColor(contentColor, for: .normal)
        linkButton.tintColor = contentColor
        linkButton.layer.borderColor = contentColor.cgColor
        iconImageView.tintColor = contentColor
    }

    private func setupLayout() {
        /* Ecosia: Replace card-based layout with centered icon + text + pill button
        addSubviews(cardContainer, mainView)
        mainView.addSubview(contentStackView)
        contentStackView.addArrangedSubview(headerLabel)
        contentStackView.addArrangedSubview(bodyLabel)
        contentStackView.addArrangedSubview(linkLabel)

        NSLayoutConstraint.activate([
            cardContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardContainer.topAnchor.constraint(equalTo: topAnchor),
            cardContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: cardContainer.topAnchor,
                                                  constant: UX.contentStackPadding),
            contentStackView.bottomAnchor.constraint(equalTo: cardContainer.bottomAnchor,
                                                     constant: -UX.contentStackPadding),
            contentStackView.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor,
                                                      constant: UX.contentStackPadding),
            contentStackView.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor,
                                                       constant: -UX.contentStackPadding),
        ])
         */
        addSubview(contentStackView)
        contentStackView.addArrangedSubview(iconImageView)
        contentStackView.setCustomSpacing(UX.contentStackViewSpacing, after: iconImageView)
        contentStackView.addArrangedSubview(headerLabel)
        contentStackView.setCustomSpacing(UX.titleBodySpacing, after: headerLabel)
        contentStackView.addArrangedSubview(bodyLabel)
        contentStackView.setCustomSpacing(UX.bodyButtonSpacing, after: bodyLabel)
        contentStackView.addArrangedSubview(linkButton)

        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: UX.contentStackPadding),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.contentStackPadding),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.contentStackPadding),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.contentStackPadding),

            iconImageView.widthAnchor.constraint(equalToConstant: UX.iconSize),
            iconImageView.heightAnchor.constraint(equalToConstant: UX.iconSize),
        ])
    }

    /* Ecosia: Underlined text helper no longer needed (link is rendered as a pill button)
    private func getUnderlineText(for text: String) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        return NSMutableAttributedString(string: text, attributes: attributes)
    }
     */
}
