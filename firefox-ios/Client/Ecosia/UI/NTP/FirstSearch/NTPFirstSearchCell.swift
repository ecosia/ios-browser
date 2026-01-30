// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import SwiftUI

/// Cell displayed during the product tour's "First Search" state
final class NTPFirstSearchCell: UICollectionViewCell, ReusableCell, ThemeApplicable {

    struct UX {
        static let contentTopSpacing: CGFloat = 40 // Includes space for the icon
        static let contentSpacing: CGFloat = 8
        static let extraSuggestionsSpacing: CGFloat = 12
        static let cornerRadius: CGFloat = 12
        static let iconSize: CGFloat = 36
        static let iconCircleSize: CGFloat = 56
        static let closeButtonSize: CGFloat = 40
        static let closeButtonImageSize: CGFloat = 16
        static let closeButtonMargin: CGFloat = 8
        static let contentHorizontalPadding: CGFloat = 16
        static let contentBottomPadding: CGFloat = 24
    }

    // MARK: - Properties

    var onCloseButtonTapped: (() -> Void)?
    var onSearchSuggestionTapped: ((String) -> Void)?

    // MARK: - UI Components

    private lazy var containerView: UIView = .build { view in
        view.layer.cornerRadius = UX.cornerRadius
        view.clipsToBounds = false
    }

    private lazy var iconContainerView: UIView = .build { view in
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = UX.iconCircleSize / 2
    }

    private lazy var iconImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGreen
        imageView.accessibilityLabel = "Seedling icon"
        imageView.image = .init(named: "plantedSeedling")
    }

    private lazy var closeButton: UIButton = .build { button in
        let config = UIImage.SymbolConfiguration(pointSize: UX.closeButtonImageSize, weight: .medium)
        let image = UIImage(named: "close", in: .ecosia, with: config)
        button.setImage(image, for: .normal)
        button.tintColor = .systemGray
        button.accessibilityLabel = "Close"
        button.accessibilityHint = "Closes the search suggestions"
    }

    private lazy var contentStackView: UIStackView = .build { stack in
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = UX.contentSpacing
        stack.distribution = .fill
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.font = .preferredFont(forTextStyle: .callout).semibold()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
    }

    private lazy var descriptionLabel: UILabel = .build { label in
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
    }

    private lazy var suggestionsContainerView: UIView = .build { view in
        // Container view for SwiftUI flow layout
    }

    private var swiftUIHostingController: UIHostingController<SearchSuggestionFlowLayout>?
    private var currentTheme: Theme?
    private var currentSuggestions: [String] = []

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        setupActions()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
        setupActions()
    }

    // MARK: - Setup

    private func setupLayout() {
        contentView.addSubviews(containerView, iconContainerView)
        containerView.addSubviews(closeButton, contentStackView)
        iconContainerView.addSubviews(iconImageView)

        // Content setup
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(descriptionLabel)
        contentStackView.addArrangedSubview(suggestionsContainerView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UX.iconCircleSize/2),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // Icon container constraints (centered on top of container, slightly outside)
            iconContainerView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconContainerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: -UX.iconCircleSize/2),
            iconContainerView.widthAnchor.constraint(equalToConstant: UX.iconCircleSize),
            iconContainerView.heightAnchor.constraint(equalToConstant: UX.iconCircleSize),

            // Icon image constraints
            iconImageView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: UX.iconSize),
            iconImageView.heightAnchor.constraint(equalToConstant: UX.iconSize),

            // Close button constraints (top right)
            closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: UX.closeButtonMargin),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -UX.closeButtonMargin),
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonSize),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonSize),

            // Content stack constraints
            contentStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: UX.contentTopSpacing),
            contentStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: UX.contentHorizontalPadding),
            contentStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -UX.contentHorizontalPadding),
            contentStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -UX.contentBottomPadding),

            // Suggestions container width constraint
            suggestionsContainerView.widthAnchor.constraint(equalTo: contentStackView.widthAnchor)
        ])
    }

    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
    }

    @objc private func closeButtonTapped() {
        onCloseButtonTapped?()
    }

    private func setupSwiftUIFlowLayout() {
        // Remove existing hosting controller
        swiftUIHostingController?.view.removeFromSuperview()
        swiftUIHostingController?.removeFromParent()

        // Only setup if we have both suggestions and a theme
        guard !currentSuggestions.isEmpty, let theme = currentTheme else {
            return
        }

        // Create new SwiftUI view
        let availableWidth = suggestionsContainerView.bounds.width > 0
            ? suggestionsContainerView.bounds.width
            : UIScreen.main.bounds.width - (UX.contentHorizontalPadding * 2)

        let swiftUIView = SearchSuggestionFlowLayout(
            suggestions: currentSuggestions,
            onSuggestionTapped: { [weak self] suggestion in
                self?.onSearchSuggestionTapped?(suggestion)
            },
            theme: theme,
            availableWidth: availableWidth
        )

        // Create hosting controller
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.view.backgroundColor = .clear
        swiftUIHostingController = hostingController

        // Add to container with proper constraints
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        suggestionsContainerView.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: suggestionsContainerView.topAnchor, constant: UX.extraSuggestionsSpacing),
            hostingController.view.leadingAnchor.constraint(equalTo: suggestionsContainerView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: suggestionsContainerView.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: suggestionsContainerView.bottomAnchor)
        ])
    }

    private func updateSwiftUITheme() {
        // If we have a hosting controller, update its root view with the new theme
        guard let hostingController = swiftUIHostingController,
              let theme = currentTheme else { return }

        let availableWidth = suggestionsContainerView.bounds.width > 0 
            ? suggestionsContainerView.bounds.width 
            : UIScreen.main.bounds.width - (UX.contentHorizontalPadding * 2)
            
        let updatedView = SearchSuggestionFlowLayout(
            suggestions: currentSuggestions,
            onSuggestionTapped: { [weak self] suggestion in
                self?.onSearchSuggestionTapped?(suggestion)
            },
            theme: theme,
            availableWidth: availableWidth
        )

        hostingController.rootView = updatedView
    }

    // MARK: - Configuration

    func configure(title: String, description: String, suggestions: [String] = []) {
        titleLabel.text = title
        descriptionLabel.text = description

        // Store suggestions and set up SwiftUI layout if theme is available
        currentSuggestions = suggestions
        setupSwiftUIFlowLayout()
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        // Store the theme
        currentTheme = theme

        // Apply theme to UIKit components
        titleLabel.textColor = theme.colors.ecosia.textPrimary
        descriptionLabel.textColor = theme.colors.ecosia.textSecondary
        containerView.backgroundColor = theme.colors.ecosia.backgroundElevation1
        contentView.backgroundColor = .clear
        closeButton.tintColor = theme.colors.ecosia.buttonContentSecondary
        iconContainerView.backgroundColor = theme.colors.ecosia.backgroundElevation1

        // Update SwiftUI view with new theme (or set it up if not done yet)
        if swiftUIHostingController != nil {
            updateSwiftUITheme()
        } else {
            setupSwiftUIFlowLayout()
        }
    }
}
