// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

/// Cell displayed during the product tour's "First Search" state
final class NTPFirstSearchCell: UICollectionViewCell, ReusableCell, ThemeApplicable {

    struct UX {
        static let containerPadding: CGFloat = 20
        static let labelSpacing: CGFloat = 16
        static let cornerRadius: CGFloat = 12
        static let titleFontSize: CGFloat = 22
        static let descriptionFontSize: CGFloat = 16
    }

    // MARK: - UI Components

    private lazy var containerView: UIView = .build { view in
        view.layer.cornerRadius = UX.cornerRadius
        view.clipsToBounds = true
    }

    private lazy var stackView: UIStackView = .build { stack in
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

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
    }

    // MARK: - Setup

    private func setupLayout() {
        contentView.addSubviews(containerView)
        containerView.addSubviews(stackView)

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(descriptionLabel)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UX.containerPadding),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.containerPadding),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.containerPadding),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -UX.containerPadding),

            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: UX.containerPadding),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: UX.containerPadding),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -UX.containerPadding),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -UX.containerPadding)
        ])
    }

    // MARK: - Configuration

    func configure(title: String, description: String) {
        titleLabel.text = title
        descriptionLabel.text = description
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        titleLabel.textColor = theme.colors.textPrimary
        descriptionLabel.textColor = theme.colors.textSecondary
        containerView.backgroundColor = theme.colors.layer2
        contentView.backgroundColor = theme.colors.layer1
    }
}
