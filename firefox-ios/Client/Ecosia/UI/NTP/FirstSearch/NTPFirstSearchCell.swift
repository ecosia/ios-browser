// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import SwiftUI

/// Cell displayed during the product tour's "First Search" state
final class NTPFirstSearchCell: UICollectionViewCell, ReusableCell, ThemeApplicable {

    struct UX {
        static let headerPadding: CGFloat = 16
        static let labelSpacing: CGFloat = 12
        static let cornerRadius: CGFloat = 12
        static let iconSize: CGFloat = 40
        static let iconCircleSize: CGFloat = 60
        static let closeButtonSize: CGFloat = 24
        static let contentTopPadding: CGFloat = 25
    }

    // MARK: - Properties

    var onCloseButtonTapped: (() -> Void)?
    var onSearchSuggestionTapped: ((String) -> Void)?

    // MARK: - UI Components

    private lazy var containerView: UIView = .build { view in
        view.layer.cornerRadius = UX.cornerRadius
        view.clipsToBounds = false // Changed to false to allow icon to extend outside
    }

    private lazy var iconContainerView: UIView = .build { view in
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = UX.iconCircleSize / 2
        // Removed shadow properties to blend with container
    }

    private lazy var iconImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGreen
        imageView.accessibilityLabel = "Search icon"
    }

    private lazy var closeButton: UIButton = .build { button in
        let config = UIImage.SymbolConfiguration(pointSize: UX.closeButtonSize, weight: .medium)
        let image = UIImage(systemName: "xmark", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .systemGray
        button.accessibilityLabel = "Close"
        button.accessibilityHint = "Closes the search suggestions"
    }

    private lazy var contentStackView: UIStackView = .build { stack in
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = UX.labelSpacing
        stack.distribution = .fill
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.font = .preferredFont(forTextStyle: .title2)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
    }

    private lazy var descriptionLabel: UILabel = .build { label in
        label.font = .preferredFont(forTextStyle: .body)
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
            closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: UX.headerPadding),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -UX.headerPadding),
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonSize),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonSize),

            // Content stack constraints
            contentStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: UX.contentTopPadding),
            contentStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: UX.headerPadding),
            contentStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -UX.headerPadding),
            contentStackView.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -UX.headerPadding),

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
        let swiftUIView = SearchSuggestionFlowLayout(
            suggestions: currentSuggestions,
            onSuggestionTapped: { [weak self] suggestion in
                self?.onSearchSuggestionTapped?(suggestion)
            },
            theme: theme
        )

        // Create hosting controller
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.view.backgroundColor = .clear
        swiftUIHostingController = hostingController

        // Add to container with proper constraints
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        suggestionsContainerView.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: suggestionsContainerView.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: suggestionsContainerView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: suggestionsContainerView.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: suggestionsContainerView.bottomAnchor)
        ])
    }

    private func updateSwiftUITheme() {
        // If we have a hosting controller, update its root view with the new theme
        guard let hostingController = swiftUIHostingController,
              let theme = currentTheme else { return }

        let updatedView = SearchSuggestionFlowLayout(
            suggestions: currentSuggestions,
            onSuggestionTapped: { [weak self] suggestion in
                self?.onSearchSuggestionTapped?(suggestion)
            },
            theme: theme
        )

        hostingController.rootView = updatedView
    }

    // MARK: - Configuration

    func configure(title: String, description: String, suggestions: [String] = [], iconImage: UIImage? = nil) {
        titleLabel.text = title
        descriptionLabel.text = description
        iconImageView.image = iconImage ?? UIImage(named: "plantedSeedling")

        // Store suggestions and set up SwiftUI layout if theme is available
        currentSuggestions = suggestions
        setupSwiftUIFlowLayout()
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        // Store the theme
        currentTheme = theme

        // Apply theme to UIKit components
        titleLabel.textColor = theme.colors.textPrimary
        descriptionLabel.textColor = theme.colors.textSecondary
        containerView.backgroundColor = theme.colors.layer2
        contentView.backgroundColor = theme.colors.layer1
        closeButton.tintColor = theme.colors.iconSecondary
        iconContainerView.backgroundColor = theme.colors.layer2

        // Update SwiftUI view with new theme (or set it up if not done yet)
        if swiftUIHostingController != nil {
            updateSwiftUITheme()
        } else {
            setupSwiftUIFlowLayout()
        }
    }
}
