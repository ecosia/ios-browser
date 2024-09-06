// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Core
import Common

final class NTPOnboardingCardCell: UICollectionViewCell, Themeable, ReusableCell {
    
    private enum UX {
        static let cornerRadius: CGFloat = 10
        static let closeButtonWidthHeight: CGFloat = 24
        static let insetMargin: CGFloat = 16
    }
    
    private let backgroundStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.layer.cornerRadius = UX.cornerRadius
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = .init(top: UX.insetMargin, leading: UX.insetMargin, bottom: UX.insetMargin, trailing: UX.insetMargin)
        return stackView
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "xmark"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = OnboardingCardNTPExperiment.title
        label.numberOfLines = 0
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = OnboardingCardNTPExperiment.description
        label.numberOfLines = 0
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()
    
    private let showOnboardingButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(OnboardingCardNTPExperiment.buttonTitle, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        button.addTarget(self, action: #selector(showOnboarding), for: .touchUpInside)
        button.setContentHuggingPriority(.required, for: .vertical)
        button.setContentCompressionResistancePriority(.required, for: .vertical)
        return button
    }()
    
    var delegate: NTPOnboardingCardCellDelegate?
    
    // MARK: - Themeable Properties
    
    var themeManager: ThemeManager { AppContainer.shared.resolve() }
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        contentView.addSubview(backgroundStackView)
        contentView.addSubview(closeButton)
        
        backgroundStackView.addArrangedSubview(titleLabel)
        backgroundStackView.addArrangedSubview(descriptionLabel)
        backgroundStackView.addArrangedSubview(showOnboardingButton)
        
        NSLayoutConstraint.activate([
            backgroundStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            backgroundStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonWidthHeight),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonWidthHeight),
            closeButton.trailingAnchor.constraint(equalTo: backgroundStackView.trailingAnchor),
            closeButton.topAnchor.constraint(equalTo: backgroundStackView.topAnchor),
        ])
        
        applyTheme()
        listenForThemeChange(contentView)
    }
    
    @objc func applyTheme() {
        backgroundStackView.backgroundColor = .legacyTheme.ecosia.secondaryBackground
        closeButton.tintColor = .legacyTheme.ecosia.decorativeIcon
        titleLabel.textColor = .legacyTheme.ecosia.primaryText
        descriptionLabel.textColor = .legacyTheme.ecosia.secondaryText
        showOnboardingButton.setTitleColor(.legacyTheme.ecosia.primaryButtonActive, for: .normal)
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let targetSize = CGSize(width: layoutAttributes.frame.width, height: 0)
        layoutAttributes.frame.size = contentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        return layoutAttributes
    }
    
    @objc private func closeAction() {
        delegate?.onboardingCardDismiss()
    }
    
    @objc private func showOnboarding() {
        delegate?.showOnboarding()
    }
}
