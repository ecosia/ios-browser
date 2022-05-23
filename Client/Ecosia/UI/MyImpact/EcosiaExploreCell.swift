/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SwiftUI

final class EcosiaExploreCell: UICollectionViewCell, Themeable, AutoSizingCell {
    private(set) weak var widthConstraint: NSLayoutConstraint!
    private weak var title: UILabel!
    private weak var image: UIImageView!
    private weak var indicator: UIImageView!
    private weak var outline: UIView!
    
    required init?(coder: NSCoder) { super.init(coder: coder) }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let outline = UIView()
        contentView.addSubview(outline)
        outline.layer.cornerRadius = 10
        outline.translatesAutoresizingMaskIntoConstraints = false
        self.outline = outline

        let title = UILabel()
        title.font = .preferredFont(forTextStyle: .body)
        title.adjustsFontForContentSizeCategory = true
        title.textAlignment = .center
        title.numberOfLines = 0
        title.translatesAutoresizingMaskIntoConstraints = false
        title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        outline.addSubview(title)
        self.title = title

        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.translatesAutoresizingMaskIntoConstraints = false
        image.clipsToBounds = true
        image.contentMode = .center
        outline.addSubview(image)
        self.image = image

        outline.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        outline.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        outline.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        outline.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true

        image.centerXAnchor.constraint(equalTo: outline.leftAnchor, constant: 38).isActive = true
        image.centerYAnchor.constraint(equalTo: outline.centerYAnchor).isActive = true
        
        title.centerYAnchor.constraint(equalTo: outline.centerYAnchor).isActive = true
        title.leftAnchor.constraint(equalTo: outline.leftAnchor, constant: 72).isActive = true
        title.rightAnchor.constraint(lessThanOrEqualTo: indicator.leftAnchor, constant: -5).isActive = true
        
        indicator.centerYAnchor.constraint(equalTo: outline.centerYAnchor).isActive = true
        indicator.rightAnchor.constraint(equalTo: outline.rightAnchor, constant: -20).isActive = true
        
        widthConstraint = outline.widthAnchor.constraint(equalToConstant: 100)
        widthConstraint.priority = .init(999)
        widthConstraint.isActive = true

        applyTheme()
    }

    func display(_ model: EcosiaHome.Section.Explore) {
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
        outline.backgroundColor = isSelected || isHighlighted ? .theme.ecosia.hoverBackgroundColor : .theme.ecosia.ntpCellBackground
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }

    func applyTheme() {
        title.textColor = UIColor.theme.ecosia.highContrastText
        outline.elevate()
    }
}
