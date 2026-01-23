// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

/// Cell displayed during the product tour's "First Search" state
final class NTPFirstSearchCell: UICollectionViewCell, ReusableCell, ThemeApplicable {

    struct UX {
        static let headerPadding: CGFloat = 16
        static let labelSpacing: CGFloat = 12
        static let suggestionSpacing: CGFloat = 8
        static let cornerRadius: CGFloat = 12
        static let titleFontSize: CGFloat = 22
        static let descriptionFontSize: CGFloat = 16
        static let iconSize: CGFloat = 40
        static let iconCircleSize: CGFloat = 60
        static let closeButtonSize: CGFloat = 24
        static let suggestionCornerRadius: CGFloat = 20
        static let suggestionPadding: CGFloat = 6 // Further reduced to make buttons fit
        static let contentTopPadding: CGFloat = 25 // Further reduced to bring title/description into view
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
    }

    private lazy var closeButton: UIButton = .build { button in
        let config = UIImage.SymbolConfiguration(pointSize: UX.closeButtonSize, weight: .medium)
        let image = UIImage(systemName: "xmark", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .systemGray
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
        // Container view for custom layout of suggestion buttons
    }

    private var suggestionButtons: [UIButton] = []

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

    private func createSearchSuggestionButton(text: String) -> UIButton {
        let button = UIButton(type: .system)

        var config = UIButton.Configuration.plain()
        config.title = text
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .preferredFont(forTextStyle: .subheadline)
            return outgoing
        }

        if let searchIcon = UIImage(named: "searchUrl") {
            config.image = searchIcon
            config.imagePlacement = .trailing // Icon on the right
            config.imagePadding = 4
        }

        config.contentInsets = NSDirectionalEdgeInsets(
            top: UX.suggestionPadding,
            leading: UX.suggestionPadding,
            bottom: UX.suggestionPadding,
            trailing: UX.suggestionPadding
        )

        config.background.backgroundColor = .clear
        config.background.strokeWidth = 1
        config.background.strokeColor = UIColor.systemGray4
        config.background.cornerRadius = UX.suggestionCornerRadius

        button.configuration = config
        button.configurationUpdateHandler = { button in
            button.configuration?.background.backgroundColor = .clear
        }

        button.addTarget(self, action: #selector(searchSuggestionTapped(_:)), for: .touchUpInside)

        return button
    }

    private func layoutSuggestionButtons(_ buttons: [UIButton]) {
        suggestionsContainerView.subviews.forEach { $0.removeFromSuperview() }
        suggestionButtons = buttons

        guard !buttons.isEmpty else {
            updateContainerHeight(0)
            return
        }

        buttons.forEach { button in
            button.translatesAutoresizingMaskIntoConstraints = true
            suggestionsContainerView.addSubview(button)
        }

        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if suggestionsContainerView.bounds.width > 0 {
            layoutSuggestionButtonsFlow()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.layoutSuggestionButtonsFlow()
            }
        }
    }

    private func layoutSuggestionButtonsFlow() {
        guard !suggestionButtons.isEmpty else { return }

        let containerWidth = suggestionsContainerView.bounds.width
        guard containerWidth > 0 else { return }

        let spacing = UX.suggestionSpacing

        // First pass: group buttons into rows
        var rows: [[UIButton]] = []
        var currentRow: [UIButton] = []
        var currentRowWidth: CGFloat = 0

        for button in suggestionButtons {
            let buttonSize = button.intrinsicContentSize
            let buttonWidth = buttonSize.width

            // Check if button fits in current row
            let requiredWidth = currentRowWidth + buttonWidth + (currentRow.isEmpty ? 0 : spacing)

            if requiredWidth <= containerWidth || currentRow.isEmpty {
                // Button fits in current row
                currentRow.append(button)
                currentRowWidth = requiredWidth
            } else {
                // Start new row
                if !currentRow.isEmpty {
                    rows.append(currentRow)
                }
                currentRow = [button]
                currentRowWidth = buttonWidth
            }
        }

        // Add last row
        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        // Second pass: position buttons with centered rows
        var currentY: CGFloat = 0
        let buttonHeight: CGFloat = suggestionButtons.first?.intrinsicContentSize.height ?? 44

        for (_, row) in rows.enumerated() {
            // Calculate total width of this row
            let totalRowWidth = row.enumerated().reduce(0) { total, buttonData in
                let (index, button) = buttonData
                let buttonWidth = button.intrinsicContentSize.width
                let buttonSpacing = index == 0 ? 0 : spacing
                return total + buttonWidth + buttonSpacing
            }

            // Center the row
            let startX = max(0, (containerWidth - totalRowWidth) / 2)
            var currentX = startX

            // Position buttons in this row
            for (index, button) in row.enumerated() {
                let buttonSize = button.intrinsicContentSize

                button.frame = CGRect(
                    x: currentX,
                    y: currentY,
                    width: buttonSize.width,
                    height: buttonSize.height
                )

                // Update X position for next button
                currentX += buttonSize.width
                if index < row.count - 1 {
                    currentX += spacing
                }
            }

            // Move to next row
            currentY += buttonHeight + spacing
        }

        // Update container height (remove the extra spacing from the last row)
        let totalHeight = max(0, currentY - spacing)
        updateContainerHeight(totalHeight)
    }

    private var heightConstraint: NSLayoutConstraint?

    private func updateContainerHeight(_ height: CGFloat) {
        // Remove existing height constraint if it exists
        if let existingConstraint = heightConstraint {
            existingConstraint.isActive = false
            suggestionsContainerView.removeConstraint(existingConstraint)
        }

        // Add new height constraint
        heightConstraint = suggestionsContainerView.heightAnchor.constraint(equalToConstant: height)
        heightConstraint?.isActive = true
    }

    @objc private func searchSuggestionTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal) else { return }
        onSearchSuggestionTapped?(title)
    }

    // MARK: - Configuration

    func configure(title: String, description: String, suggestions: [String] = [], iconImage: UIImage? = nil) {
        titleLabel.text = title
        descriptionLabel.text = description
        iconImageView.image = iconImage ?? UIImage(named: "plantedSeedling")

        // Create suggestion buttons
        let buttons = suggestions.map { createSearchSuggestionButton(text: $0) }

        // Layout buttons in flowing rows
        layoutSuggestionButtons(buttons)
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        titleLabel.textColor = theme.colors.textPrimary
        descriptionLabel.textColor = theme.colors.textSecondary
        containerView.backgroundColor = theme.colors.layer2
        contentView.backgroundColor = theme.colors.layer1
        closeButton.tintColor = theme.colors.iconSecondary
        iconContainerView.backgroundColor = theme.colors.layer2
        suggestionsContainerView.subviews.compactMap { $0 as? UIButton }.forEach { button in
            button.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.foregroundColor = theme.colors.textPrimary
                return outgoing
            }
            button.configuration?.background.backgroundColor = .clear
            button.configuration?.background.strokeColor = theme.colors.borderPrimary
            button.tintColor = theme.colors.iconSecondary
        }
    }
}
