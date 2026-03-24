// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
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
        static let paddingInBetweenItems: CGFloat = 15
        static let verticalPadding: CGFloat = 20
        static let horizontalPadding: CGFloat = 24
        /* Ecosia: Larger image for Ecosia private browsing mascot
        static let imageSize = CGSize(width: 72, height: 72)
        */
        static let imageSize = CGSize(width: 120, height: 120)
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
        label.font = FXFontStyles.Regular.headline.scaledFont()
        label.text =  .PrivateBrowsingTitle
        label.textAlignment = .center
    }

    private let descriptionLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.footnote.scaledFont()
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
        /* Ecosia: Use Ecosia private browsing icon
        imageView.image = UIImage.templateImageNamed(StandardImageIdentifiers.Large.privateMode)
        */
        imageView.image = UIImage(named: "tigerIncognito")
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

    // Ecosia: Vertically centered private browsing placeholder
    private lazy var contentStack: UIStackView = .build { stack in
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = UX.paddingInBetweenItems
    }

    private func setupLayout() {
        /* Ecosia: Remove Learn More button and vertically center content
        configureLearnMoreButton()
        centeredView.addSubviews(iconImageView, titleLabel, descriptionLabel, learnMoreButton)
        containerView.addSubview(centeredView)
        scrollView.addSubview(containerView)
        addSubview(scrollView)
        */
        contentStack.addArrangedSubview(iconImageView)
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(descriptionLabel)
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor,
                                                  constant: UX.horizontalPadding),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                   constant: -UX.horizontalPadding),

            iconImageView.widthAnchor.constraint(equalToConstant: UX.imageSize.width),
            iconImageView.heightAnchor.constraint(equalToConstant: UX.imageSize.height),
        ])
    }

    func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer3
        titleLabel.textColor = theme.colors.textPrimary
        descriptionLabel.textColor = theme.colors.textPrimary
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
