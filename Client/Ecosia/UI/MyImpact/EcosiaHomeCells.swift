/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

final class MoreButtonCell: UICollectionViewCell, AutoSizingCell {
    lazy var moreButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(UIColor.theme.ecosia.primaryBrand, for: .normal)
        button.setTitleColor(UIColor.Photon.Grey50, for: .highlighted)
        button.titleLabel?.font = .preferredFont(forTextStyle: .body)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        return button
    }()

    private weak var widthConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(moreButton)

        moreButton.translatesAutoresizingMaskIntoConstraints = false
        moreButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        moreButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        moreButton.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        moreButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true

        let widthConstraint = moreButton.widthAnchor.constraint(equalToConstant: 100)
        widthConstraint.priority = .defaultHigh
        widthConstraint.isActive = true
        self.widthConstraint = widthConstraint
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        moreButton.setTitleColor(UIColor.theme.ecosia.primaryBrand, for: .normal)
        moreButton.setTitleColor(UIColor.Photon.Grey50, for: .highlighted)
    }

    func setWidth(_ width: CGFloat, insets: UIEdgeInsets) {
        widthConstraint.constant = width
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

   private  weak var widthConstraint: NSLayoutConstraint!

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

    func setWidth(_ width: CGFloat, insets: UIEdgeInsets) {
        let margin = max(max(16, insets.left), insets.right)
        widthConstraint.constant = width - 2 * margin
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
}
