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
        static let textSpacing: CGFloat = 4
        static let buttonAdditionalSpacing: CGFloat = 8
        static let imageHeight: CGFloat = 48
    }
    
    private let mainContainerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.layer.cornerRadius = UX.cornerRadius
        stackView.axis = .horizontal
        stackView.alignment = .leading
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = .init(top: UX.insetMargin, 
                                                   leading: UX.insetMargin,
                                                   bottom: UX.insetMargin,
                                                   trailing: UX.insetMargin)
        stackView.spacing = UX.textSpacing
        return stackView
    }()
    
    private let labelsAndCloseButtonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = UX.textSpacing
        return stackView
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "xmark"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        button.setContentHuggingPriority(.required, for: .horizontal)
        return button
    }()
    
    private lazy var imageView: UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.contentMode = .scaleAspectFit
        return image
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = OnboardingCardNTPExperiment.title
        label.font = .preferredFont(forTextStyle: .subheadline).bold()
        label.adjustsFontForContentSizeCategory = true
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = OnboardingCardNTPExperiment.description
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        return label
    }()
    
    private let showOnboardingButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(OnboardingCardNTPExperiment.buttonTitle, for: .normal)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.addTarget(self, action: #selector(showOnboarding), for: .touchUpInside)
        button.setInsets(forContentPadding: .init(top: UX.buttonAdditionalSpacing, left: 0, bottom: 0, right: 0), imageTitlePadding: 0)
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
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        contentView.addSubview(mainContainerStackView)
        
        let titleAndCloseButtonStackView = UIStackView()
        titleAndCloseButtonStackView.axis = .horizontal
        titleAndCloseButtonStackView.spacing = UX.insetMargin
        titleAndCloseButtonStackView.addArrangedSubview(titleLabel)
        titleAndCloseButtonStackView.addArrangedSubview(closeButton)
        
        labelsAndCloseButtonStackView.addArrangedSubview(titleAndCloseButtonStackView)
        labelsAndCloseButtonStackView.addArrangedSubview(descriptionLabel)
        labelsAndCloseButtonStackView.addArrangedSubview(showOnboardingButton)
        
        mainContainerStackView.addArrangedSubview(imageView)
        mainContainerStackView.addArrangedSubview(labelsAndCloseButtonStackView)
        
        NSLayoutConstraint.activate([
            mainContainerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mainContainerStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            mainContainerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mainContainerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            titleAndCloseButtonStackView.widthAnchor.constraint(equalTo: labelsAndCloseButtonStackView.widthAnchor, constant: -UX.insetMargin*2),
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonWidthHeight),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonWidthHeight),
            closeButton.trailingAnchor.constraint(equalTo: labelsAndCloseButtonStackView.trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: UX.imageHeight),
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor),
        ])
        
        applyTheme()
        listenForThemeChange(contentView)
    }
    
    @objc func applyTheme() {
        mainContainerStackView.backgroundColor = .legacyTheme.ecosia.secondaryBackground
        closeButton.tintColor = .legacyTheme.ecosia.decorativeIcon
        titleLabel.textColor = .legacyTheme.ecosia.primaryText
        descriptionLabel.textColor = .legacyTheme.ecosia.secondaryText
        showOnboardingButton.setTitleColor(.legacyTheme.ecosia.primaryButton, for: .normal)
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
        delegate?.onboardingCardClick()
    }
}
