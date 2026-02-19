// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import Foundation

struct WallpaperSettingsHeaderViewModel {
    var theme: Theme
    // Ecosia: Made title optional to allow collections without headings
    var title: String?

    var subheading: String?

    var buttonTitle: String?
    var buttonA11yIdentifier: String?
    var buttonAction: (() -> Void)?
}

class WallpaperSettingsHeaderView: UICollectionReusableView, ReusableCell {
    private struct UX {
        static let stackViewSpacing: CGFloat = 4.0
        static let topBottomSpacing: CGFloat = 16.0
    }

    private var viewModel: WallpaperSettingsHeaderViewModel?

    // Views
    private lazy var contentStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.stackViewSpacing
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.headline.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
    }

    private lazy var subheadingLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
    }

    private lazy var learnMoreButton: LinkButton = .build { button in
        button.addTarget(self, action: #selector(self.buttonTapped), for: .touchUpInside)
    }

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Helper functions
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        subheadingLabel.text = nil
        learnMoreButton.setAttributedTitle(nil, for: .normal)

        // Ecosia: Remove all views from stack to handle optional title
        contentStackView.removeArrangedView(titleLabel)
        titleLabel.removeFromSuperview()
        contentStackView.removeArrangedView(subheadingLabel)
        subheadingLabel.removeFromSuperview()
        contentStackView.removeArrangedView(learnMoreButton)
        learnMoreButton.removeFromSuperview()
    }

    func configure(viewModel: WallpaperSettingsHeaderViewModel) {
        self.viewModel = viewModel

        // Ecosia: Only add title if it exists
        if let title = viewModel.title, !title.isEmpty {
            titleLabel.text = title
            contentStackView.addArrangedSubview(titleLabel)
        }

        // Ecosia: Only add description if it exists
        if let subheading = viewModel.subheading {
            subheadingLabel.text = subheading
            contentStackView.addArrangedSubview(subheadingLabel)
        }

        if let buttonTitle = viewModel.buttonTitle,
           let buttonA11y = viewModel.buttonA11yIdentifier,
           viewModel.buttonAction != nil {
            let learnMoreButtonViewModel = LinkButtonViewModel(
                title: buttonTitle,
                a11yIdentifier: buttonA11y,
                font: FXFontStyles.Regular.caption1.scaledFont(),
                contentInsets: .zero
            )
            learnMoreButton.configure(viewModel: learnMoreButtonViewModel)

            setButtonStyle(theme: viewModel.theme)

            contentStackView.addArrangedSubview(learnMoreButton)

            // needed so the button sizes correctly
            setNeedsLayout()
            layoutIfNeeded()
        }

        applyTheme(theme: viewModel.theme)
    }

    @objc
    func buttonTapped(_ sender: Any) {
        viewModel?.buttonAction?()
    }
}

// MARK: - Private
private extension WallpaperSettingsHeaderView {
    func setupView() {
        // Ecosia: Don't add titleLabel here - it's added conditionally in configure()
        addSubview(contentStackView)

        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: UX.topBottomSpacing),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.topBottomSpacing),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
}

// MARK: - Themable
extension WallpaperSettingsHeaderView: ThemeApplicable {
    func applyTheme(theme: Theme) {
        contentStackView.backgroundColor = theme.colors.layer5
        titleLabel.textColor = theme.colors.textPrimary
        subheadingLabel.textColor = theme.colors.textPrimary
        setButtonStyle(theme: theme)
    }

    private func setButtonStyle(theme: Theme) {
        let color = theme.colors.textPrimary
        learnMoreButton.setTitleColor(color, for: .normal)

        // in iOS 13 the title color set is not used for the attributed text color so we have to set it via attributes
        guard let buttonTitle = viewModel?.buttonTitle else { return }
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: FXFontStyles.Regular.body.scaledFont(),
            .foregroundColor: color,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]

        let attributeString = NSMutableAttributedString(string: buttonTitle,
                                                        attributes: labelAttributes)
        learnMoreButton.setAttributedTitle(attributeString, for: .normal)
    }
}
