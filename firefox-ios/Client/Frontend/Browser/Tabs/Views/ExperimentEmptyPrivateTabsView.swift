// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Ecosia
import UIKit
import Foundation
import Shared
import ComponentLibrary

@MainActor
protocol EmptyPrivateTabView: UIView, ThemeApplicable, InsetUpdatable {
    var needsSafeArea: Bool { get }
    var delegate: EmptyPrivateTabsViewDelegate? { get set }
}

// View we display when there are no private tabs created
class ExperimentEmptyPrivateTabsView: UIView,
                                      EmptyPrivateTabView {
    struct UX {
        /* Ecosia: Spacings mirror PrivateMessageCardCell.UX so the icon stays at the
           same screen position during the tab-tray → private-NTP transition.
        static let paddingInBetweenItems: CGFloat = 15
        static let verticalPadding: CGFloat = 20
        */
        static let iconToTitleSpacing: CGFloat = 16     // PrivateMessageCardCell.UX.contentStackViewSpacing
        static let titleToBodySpacing: CGFloat = 8      // PrivateMessageCardCell.UX.titleBodySpacing
        static let bodyToSpacerSpacing: CGFloat = 24    // PrivateMessageCardCell.UX.bodyButtonSpacing
        // Approximate height of the link button in PrivateMessageCardCell so the
        // content block's center of mass (and therefore icon Y) is identical.
        static let linkButtonSpacerHeight: CGFloat = 44
        // Compensates for the tab tray header pushing self.centerY lower than
        // view.safeAreaLayoutGuide.centerY in PrivateHomepageViewController.
        static let verticalCenterOffset: CGFloat = 30
        static let horizontalPadding: CGFloat = 24
        /* Ecosia: Match incognito NTP icon size (64pt)
        static let imageSize = CGSize(width: 72, height: 72)
        */
        static let imageSize = CGSize(width: 64, height: 64)
    }

    // MARK: - Properties

    var needsSafeArea: Bool { true }
    weak var delegate: EmptyPrivateTabsViewDelegate?

    // UI
    private let scrollView: UIScrollView = .build { scrollview in
        scrollview.backgroundColor = .clear
    }

    private lazy var containerView: UIView = .build { _ in }
    private lazy var centeredView: UIView = .build { _ in }

    private let titleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        /* Ecosia: Use Ecosia design system fonts to match incognito NTP
        label.font = FXFontStyles.Regular.headline.scaledFont()
         */
        label.font = .ecosia(size: .ecosia.font._3l)
        label.text =  .PrivateBrowsingTitle
        label.textAlignment = .center
    }

    private let descriptionLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        /* Ecosia: Use Ecosia design system fonts to match incognito NTP
        label.font = FXFontStyles.Regular.footnote.scaledFont()
         */
        label.font = .ecosia(size: .ecosia.font._2l)
        label.textAlignment = .center
        label.numberOfLines = 0
        /* Ecosia: Use Ecosia private browsing description
        label.text = .TabsTray.TabTrayPrivateBrowsingDescription
        */
        label.text = .localized(.privateEmpty)
    }

    /* Ecosia: Remove Learn More button
    private lazy var learnMoreButton: SecondaryRoundedButton = .build { button in
        let viewModel = SecondaryRoundedButtonViewModel(
            title: .PrivateBrowsingLearnMore,
            a11yIdentifier: AccessibilityIdentifiers.TabTray.learnMoreButton
        )
        button.configure(viewModel: viewModel)
        button.addTarget(self, action: #selector(self.didTapLearnMore), for: .touchUpInside)
    }
    */

    private let iconImageView: UIImageView = .build { imageView in
        /* Ecosia: Use new incognito icon from Ecosia asset catalog
        imageView.image = UIImage.templateImageNamed(StandardImageIdentifiers.Large.privateMode)
        */
        imageView.image = UIImage(named: "incognito", in: .ecosia, with: nil)?
            .withRenderingMode(.alwaysTemplate)
        imageView.contentMode = .scaleAspectFit
    }

    // MARK: - Inits

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /* Ecosia: Remove Learn More button
    private func configureLearnMoreButton() {
        learnMoreButton.addTarget(self, action: #selector(self.didTapLearnMore), for: .touchUpInside)
    }
    */

    // Ecosia: Vertically centered private browsing placeholder, spacings mirror PrivateMessageCardCell
    private lazy var contentStack: UIStackView = .build { stack in
        stack.axis = .vertical
        stack.alignment = .center
    }

    // Transparent spacer that occupies the same height as the link button in
    // PrivateMessageCardCell, keeping the icon at the same Y during the transition.
    private let linkButtonSpacer: UIView = .build { view in
        view.backgroundColor = .clear
    }

    private func setupLayout() {
        /* Ecosia: Remove Learn More button and vertically center content
        configureLearnMoreButton()
        centeredView.addSubviews(iconImageView, titleLabel, descriptionLabel, learnMoreButton)
        containerView.addSubview(centeredView)
        scrollView.addSubview(containerView)
        addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor,
                                                constant: UX.horizontalPadding),
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor,
                                            constant: UX.verticalPadding),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                 constant: -UX.horizontalPadding),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor,
                                               constant: -UX.verticalPadding),

            scrollView.frameLayoutGuide.widthAnchor.constraint(equalTo: containerView.widthAnchor),

            scrollView.contentLayoutGuide.topAnchor.constraint(equalTo: containerView.topAnchor),
            scrollView.contentLayoutGuide.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            centeredView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: UX.verticalPadding),
            centeredView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            centeredView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            centeredView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            iconImageView.topAnchor.constraint(equalTo: centeredView.topAnchor,
                                               constant: UX.paddingInBetweenItems),
            iconImageView.centerXAnchor.constraint(equalTo: centeredView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: UX.imageSize.width),
            iconImageView.heightAnchor.constraint(equalToConstant: UX.imageSize.height),

            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor,
                                            constant: UX.paddingInBetweenItems),
            titleLabel.leadingAnchor.constraint(equalTo: centeredView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: centeredView.trailingAnchor),

            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor,
                                                  constant: UX.paddingInBetweenItems),
            descriptionLabel.leadingAnchor.constraint(equalTo: centeredView.leadingAnchor,
                                                      constant: UX.horizontalPadding),
            descriptionLabel.trailingAnchor.constraint(equalTo: centeredView.trailingAnchor,
                                                       constant: -UX.horizontalPadding),

            learnMoreButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor,
                                                 constant: UX.paddingInBetweenItems),
            learnMoreButton.leadingAnchor.constraint(greaterThanOrEqualTo: centeredView.leadingAnchor),
            learnMoreButton.trailingAnchor.constraint(lessThanOrEqualTo: centeredView.trailingAnchor),
            learnMoreButton.centerXAnchor.constraint(equalTo: centeredView.centerXAnchor),
            learnMoreButton.bottomAnchor.constraint(equalTo: centeredView.bottomAnchor,
                                                    constant: -UX.paddingInBetweenItems),
        ])
        */
        // Mirror PrivateMessageCardCell spacing exactly so the icon doesn't jump during transition
        contentStack.addArrangedSubview(iconImageView)
        contentStack.setCustomSpacing(UX.iconToTitleSpacing, after: iconImageView)
        contentStack.addArrangedSubview(titleLabel)
        contentStack.setCustomSpacing(UX.titleToBodySpacing, after: titleLabel)
        contentStack.addArrangedSubview(descriptionLabel)
        contentStack.setCustomSpacing(UX.bodyToSpacerSpacing, after: descriptionLabel)
        contentStack.addArrangedSubview(linkButtonSpacer)
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -UX.verticalCenterOffset),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor,
                                                  constant: UX.horizontalPadding),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                   constant: -UX.horizontalPadding),

            iconImageView.widthAnchor.constraint(equalToConstant: UX.imageSize.width),
            iconImageView.heightAnchor.constraint(equalToConstant: UX.imageSize.height),

            linkButtonSpacer.heightAnchor.constraint(equalToConstant: UX.linkButtonSpacerHeight),
        ])
    }

    func applyTheme(theme: Theme) {
        /* Ecosia: Use Ecosia incognito design tokens
        backgroundColor = theme.colors.layer3
        titleLabel.textColor = theme.colors.textPrimary
        descriptionLabel.textColor = theme.colors.textPrimary
         */
        backgroundColor = theme.colors.ecosia.backgroundNeutralTertiary
        let contentColor = theme.colors.ecosia.buttonContentPrimary
        titleLabel.textColor = contentColor
        descriptionLabel.textColor = contentColor
        iconImageView.tintColor = contentColor
        /* Ecosia: Remove Learn More button theming
        learnMoreButton.applyTheme(theme: theme)
        iconImageView.tintColor = theme.colors.iconDisabled
        */
    }

    /* Ecosia: Remove Learn More button action
    @objc
    private func didTapLearnMore() {
        guard let url = SupportUtils.URLForTopic("private-browsing-ios") else { return }
        let request = URLRequest(url: url)
        delegate?.didTapLearnMore(urlRequest: request)
    }
    */

    // MARK: - InsetUpdatable

    func updateInsets(top: CGFloat, bottom: CGFloat) {
        scrollView.contentInset.top = top
        scrollView.contentInset.bottom = bottom
    }
}
