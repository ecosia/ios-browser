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
    
    private let backgroundCard: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = UX.cornerRadius
        return view
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "xmark"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.addTarget(NTPOnboardingCardCell.self, action: #selector(closeAction), for: .touchUpInside)
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.text = OnboardingCardNTPExperiment.title
        label.numberOfLines = 0
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.text = OnboardingCardNTPExperiment.description
        label.numberOfLines = 0
        return label
    }()
    
    private let showOnboardingButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(OnboardingCardNTPExperiment.buttonTitle, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
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
        contentView.addSubview(backgroundCard)
        backgroundCard.addSubview(closeButton)
        
        let vStack = UIStackView()
        vStack.translatesAutoresizingMaskIntoConstraints = false
        vStack.axis = .vertical
        vStack.alignment = .leading
        vStack.addArrangedSubview(titleLabel)
        vStack.addArrangedSubview(descriptionLabel)
        vStack.addArrangedSubview(closeButton)
        backgroundCard.addSubview(vStack)
        
        NSLayoutConstraint.activate([
            backgroundCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundCard.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonWidthHeight),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonWidthHeight),
            closeButton.trailingAnchor.constraint(equalTo: backgroundCard.trailingAnchor),
            closeButton.topAnchor.constraint(equalTo: backgroundCard.topAnchor),
            
            vStack.topAnchor.constraint(equalTo: backgroundCard.bottomAnchor, constant: UX.insetMargin),
            vStack.leadingAnchor.constraint(equalTo: backgroundCard.leadingAnchor, constant: UX.insetMargin),
            vStack.trailingAnchor.constraint(equalTo: backgroundCard.trailingAnchor, constant: -UX.insetMargin),
            vStack.bottomAnchor.constraint(equalTo: backgroundCard.bottomAnchor, constant: -UX.insetMargin),
        ])
        
        applyTheme()
        listenForThemeChange(contentView)
    }
    
    @objc func applyTheme() {
        backgroundCard.backgroundColor = .legacyTheme.ecosia.primaryBackground
        titleLabel.backgroundColor = .legacyTheme.ecosia.primaryText
        descriptionLabel.textColor = .legacyTheme.ecosia.secondaryText
        closeButton.tintColor = .legacyTheme.ecosia.primaryButtonActive
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let targetSize = CGSize(width: layoutAttributes.frame.width, height: 0)
        layoutAttributes.frame.size = contentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        return layoutAttributes
    }
    
    @objc private func closeAction() {
        delegate?.onboardingCardDismiss()
    }
}
