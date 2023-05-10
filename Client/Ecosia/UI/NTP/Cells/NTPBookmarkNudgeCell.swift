// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Core

final class NTPBookmarkNudgeCell: UICollectionViewCell, NotificationThemeable, ReusableCell {
    
    private enum UX {
        static let insetMargin: CGFloat = 16
        static let badgeHeight: CGFloat = 20
    }
    
    private let backgroundCard: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .theme.ecosia.primaryBackground
        view.layer.cornerRadius = 8
        return view
    }()
    
    private let badge: NTPBookmarkNudgeCellBadge = {
        let view = NTPBookmarkNudgeCellBadge()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "xmark"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.tintColor = .theme.ecosia.primaryText
        button.imageEdgeInsets = UIEdgeInsets(equalInset: 10)
        return button
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.text = "You can now import bookmarks from other browsers to Ecosia."
        label.text = .localized(.bookmarksNtpNudgeCardDescription)
        label.numberOfLines = 0
        return label
    }()
    
    private let openBookmarksButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 15
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.theme.ecosia.primaryText.cgColor
        button.setTitle(.localized(.bookmarksNtpNudgeCardButtonTitle), for: .normal)
        button.setTitleColor(.theme.ecosia.primaryText, for: .normal)
        button.titleLabel?.font = UIFontMetrics(forTextStyle: .callout).scaledFont(for: .systemFont(ofSize: 16))
        button.contentEdgeInsets = UIEdgeInsets(horizontal: 12)
        return button
    }()
     
    private let icon: UIImageView = {
        let imageView = UIImageView(image: .init(named: "bookmarkImportExport"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    var openBookmarksHandler: (() -> Void)?
    var closeHandler: (() -> Void)?
    
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
        backgroundCard.addSubview(badge)
        backgroundCard.addSubview(closeButton)
        backgroundCard.addSubview(descriptionLabel)
        backgroundCard.addSubview(openBookmarksButton)
        backgroundCard.addSubview(icon)
        
        NSLayoutConstraint.activate([
            backgroundCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundCard.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            badge.heightAnchor.constraint(equalToConstant: UX.badgeHeight).priority(.required),
            badge.topAnchor.constraint(equalTo: backgroundCard.topAnchor, constant: UX.insetMargin),
            badge.leadingAnchor.constraint(equalTo: backgroundCard.leadingAnchor, constant: UX.insetMargin),
            
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            closeButton.trailingAnchor.constraint(equalTo: backgroundCard.trailingAnchor),
            closeButton.topAnchor.constraint(equalTo: backgroundCard.topAnchor),
            
            descriptionLabel.topAnchor.constraint(equalTo: badge.bottomAnchor, constant: UX.insetMargin / 2),
            descriptionLabel.leadingAnchor.constraint(equalTo: backgroundCard.leadingAnchor, constant: UX.insetMargin),
            descriptionLabel.trailingAnchor.constraint(equalTo: icon.leadingAnchor, constant: -UX.insetMargin),
            
            openBookmarksButton.heightAnchor.constraint(equalToConstant: 32).priority(.required),
            openBookmarksButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: UX.insetMargin),
            openBookmarksButton.leadingAnchor.constraint(equalTo: backgroundCard.leadingAnchor, constant: UX.insetMargin),
            openBookmarksButton.bottomAnchor.constraint(equalTo: backgroundCard.bottomAnchor, constant: -UX.insetMargin),
            
            icon.trailingAnchor.constraint(equalTo: backgroundCard.trailingAnchor, constant: -UX.insetMargin),
            icon.bottomAnchor.constraint(equalTo: openBookmarksButton.bottomAnchor, constant: 0),
            icon.widthAnchor.constraint(equalToConstant: 64).priority(.required),
            icon.heightAnchor.constraint(equalToConstant: 64).priority(.required),
            
            backgroundCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        openBookmarksButton.addTarget(self, action: #selector(handleOpenBookmarks), for: .touchUpInside)
    }
    
    func applyTheme() {}
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
            let targetSize = CGSize(width: layoutAttributes.frame.width, height: 0)
            layoutAttributes.frame.size = contentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
            return layoutAttributes
    }
    
    @objc private func handleOpenBookmarks() {
        openBookmarksHandler?()
    }
    
    @objc private func handleClose() {
        closeHandler?()
    }
}

private class NTPBookmarkNudgeCellBadge: UIView {
    
    private enum UX {
        static let labelInsetX: CGFloat = 8
        static let labelInsetY: CGFloat = 2.5
    }

    init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        isUserInteractionEnabled = false
        
        let badgeLabel = UILabel()
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.font = .preferredFont(forTextStyle: .footnote).bold()
        badgeLabel.adjustsFontForContentSizeCategory = true
        badgeLabel.text = .localized(.new)
        addSubview(badgeLabel)

        let size = badgeLabel.sizeThatFits(.init(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude))
        let height = size.height + 5
        frame.size = .init(width: size.width + 16, height: height)
        backgroundColor = .theme.ecosia.primaryBrand
        badgeLabel.textColor = .theme.ecosia.primaryTextInverted
        layer.cornerRadius = 10
        
        NSLayoutConstraint.activate([
            badgeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.labelInsetX),
            badgeLabel.topAnchor.constraint(equalTo: topAnchor, constant: UX.labelInsetY),
            badgeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.labelInsetX),
            badgeLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.labelInsetY)
        ])
    }
}
