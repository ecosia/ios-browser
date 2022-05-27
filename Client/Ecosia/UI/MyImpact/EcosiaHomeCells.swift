/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

final class MoreButtonCell: UICollectionViewCell, AutoSizingCell {
    lazy var moreButton: UIButton = {
        let button = UIButton()
        button.setImage(.init(named: "news"), for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .body)
        button.titleLabel?.adjustsFontForContentSizeCategory = true

        button.contentEdgeInsets.right = 16
        button.contentEdgeInsets.left = 16
        button.imageEdgeInsets.left = -8

        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1

        return button
    }()

    private(set) weak var widthConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)

        container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        container.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true

        let widthConstraint = container.widthAnchor.constraint(equalToConstant: 300)
        widthConstraint.priority = .defaultHigh
        widthConstraint.isActive = true
        self.widthConstraint = widthConstraint

        contentView.addSubview(moreButton)
        moreButton.translatesAutoresizingMaskIntoConstraints = false
        moreButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16).isActive = true
        moreButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20).isActive = true
        moreButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 8).isActive = true
        moreButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 32).isActive = true

        applyTheme()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme() {
        moreButton.tintColor = .theme.ecosia.primaryText
        moreButton.imageView?.tintColor = .theme.ecosia.primaryText
        moreButton.setTitleColor(.theme.ecosia.primaryText, for: .normal)
        moreButton.setTitleColor(.theme.ecosia.secondaryText, for: .highlighted)
        moreButton.setTitleColor(.theme.ecosia.secondaryText, for: .selected)
        moreButton.backgroundColor = .theme.ecosia.moreNewsButton
        moreButton.layer.borderColor = UIColor.theme.ecosia.primaryText.cgColor
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
}

final class HeaderCell: UICollectionViewCell, AutoSizingCell ,Themeable {
    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.theme.ecosia.highContrastText
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        return titleLabel
    }()

    private(set) weak var widthConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        contentView.addSubview(titleLabel)

        let top = titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 32)
        top.priority = .init(999)
        top.isActive = true

        titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16).isActive = true

        let widthConstraint = titleLabel.widthAnchor.constraint(equalToConstant: 100)
        widthConstraint.priority = .defaultHigh
        widthConstraint.isActive = true
        self.widthConstraint = widthConstraint
    }

    func applyTheme() {
        titleLabel.textColor = UIColor.theme.ecosia.highContrastText
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
}
