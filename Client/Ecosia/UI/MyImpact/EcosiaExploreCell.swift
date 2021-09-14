/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

protocol EcosiaExploreCellModel {
    var title: String { get }
    var image: String { get }
}

extension EcosiaHome.Section.Explore: EcosiaExploreCellModel {}

final class EcosiaExploreCell: UICollectionViewCell, Themeable, AutoSizingCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    var title: UILabel!
    var image: UIImageView!
    var outline: UIView!

    private weak var widthConstraint: NSLayoutConstraint!

    private func setup() {
        outline = UIView()
        contentView.addSubview(outline)
        outline.layer.cornerRadius = 10
        outline.translatesAutoresizingMaskIntoConstraints = false

        title = UILabel()
        contentView.addSubview(title)
        title.font = .preferredFont(forTextStyle: .subheadline)
        title.adjustsFontForContentSizeCategory = true
        title.textAlignment = .center
        title.numberOfLines = 0
        title.translatesAutoresizingMaskIntoConstraints = false
        title.allowsDefaultTighteningForTruncation = true

        image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(image)

        outline.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor, constant: 0).isActive = true
        outline.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor, constant: 0).isActive = true
        outline.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        outline.widthAnchor.constraint(equalTo: outline.heightAnchor, multiplier: 1).isActive = true

        let widthConstraint = outline.widthAnchor.constraint(equalToConstant: 100)
        widthConstraint.priority = .init(999)
        widthConstraint.isActive = true
        self.widthConstraint = widthConstraint

        title.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16).isActive = true
        title.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16).isActive = true
        title.topAnchor.constraint(equalTo: outline.bottomAnchor, constant: 8).isActive = true
        title.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8).isActive = true

        image.centerXAnchor.constraint(equalTo: outline.centerXAnchor).isActive = true
        image.centerYAnchor.constraint(equalTo: outline.centerYAnchor).isActive = true
        image.widthAnchor.constraint(equalToConstant: 100).isActive = true
        image.heightAnchor.constraint(equalToConstant: 100).isActive = true

        applyTheme()
    }

    func display(_ model: EcosiaExploreCellModel) {
        title.text = model.title
        image.image = UIImage(named: model.image)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        image.layer.masksToBounds = true
        image.layer.cornerRadius = image.bounds.size.width/2.0
    }

    override var isSelected: Bool {
        didSet {
            hover()
        }
    }

    override var isHighlighted: Bool {
        didSet {
            hover()
        }
    }

    private func hover() {
        outline.backgroundColor = isSelected || isHighlighted ? UIColor.theme.ecosia.hoverBackgroundColor : UIColor.theme.ecosia.highlightedBackground
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }

    private var horizontalItems: Int {
        var horizontalItems = traitCollection.userInterfaceIdiom == .pad ? 3 : 2

        let isLandscape = UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight
        if isLandscape && traitCollection.userInterfaceIdiom == .phone {
            horizontalItems = 4
        }
        return horizontalItems
    }

    func setWidth(_ width: CGFloat, insets: UIEdgeInsets) {
        let horizontalItems = CGFloat(self.horizontalItems)
        let margin: CGFloat = 16
        let left = max(margin, insets.left)
        let right = max(margin, insets.right)
        let width = floor((width - (horizontalItems - 1) * margin - left - right) / horizontalItems)
        widthConstraint.constant = width
    }

    func applyTheme() {
        title.textColor = UIColor.theme.ecosia.highContrastText
        outline.elevate()
    }
}
