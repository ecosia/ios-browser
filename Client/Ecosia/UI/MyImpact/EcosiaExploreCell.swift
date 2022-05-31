/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

final class EcosiaExploreCell: UICollectionViewCell, Themeable {
    private(set) weak var learnMore: UIButton!
    private weak var title: UILabel!
    private weak var subtitle: UILabel!
    private weak var image: UIImageView!
    private weak var indicator: UIImageView!
    private weak var outline: UIView!
    private weak var divider: UIView!
    private weak var disclosure: UIView!
    
    var model: EcosiaHome.Section.Explore? {
        didSet {
            guard let model = model, model != oldValue else { return }
            title.text = model.title
            image.image = UIImage(named: model.image)
            outline.layer.maskedCorners = model.maskedCorners
            subtitle.text = model.title
            divider.isHidden = model == .faq
        }
    }
    
    var expandedHeight: CGFloat {
        disclosure.frame.maxY + (model == .faq ? 16 : 0)
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
    
    required init?(coder: NSCoder) { super.init(coder: coder) }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let outline = UIView()
        outline.layer.cornerRadius = 10
        outline.translatesAutoresizingMaskIntoConstraints = false
        outline.clipsToBounds = true
        contentView.addSubview(outline)
        self.outline = outline

        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.translatesAutoresizingMaskIntoConstraints = false
        image.clipsToBounds = true
        image.contentMode = .center
        outline.addSubview(image)
        self.image = image
        
        let title = UILabel()
        title.font = .preferredFont(forTextStyle: .body)
        title.adjustsFontForContentSizeCategory = true
        title.numberOfLines = 0
        title.translatesAutoresizingMaskIntoConstraints = false
        title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        outline.addSubview(title)
        self.title = title

        let indicator = UIImageView(image: .init(named: "chevronDown"))
        indicator.contentMode = .scaleAspectFit
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.clipsToBounds = true
        indicator.contentMode = .center
        outline.addSubview(indicator)
        self.indicator = indicator
        
        let disclosure = UIView()
        disclosure.translatesAutoresizingMaskIntoConstraints = false
        disclosure.layer.cornerRadius = 10
        outline.addSubview(disclosure)
        self.disclosure = disclosure
        
        let subtitle = UILabel()
        subtitle.font = .preferredFont(forTextStyle: .callout)
        subtitle.adjustsFontForContentSizeCategory = true
        subtitle.numberOfLines = 0
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        disclosure.addSubview(subtitle)
        self.subtitle = subtitle
        
        let learnMore = UIButton()
        learnMore.translatesAutoresizingMaskIntoConstraints = false
        learnMore.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        learnMore.titleLabel?.adjustsFontForContentSizeCategory = true
        disclosure.addSubview(learnMore)
        self.learnMore = learnMore
        
        if #available(iOS 15.0, *) {
            var configuration = UIButton.Configuration.filled()
            configuration.cornerStyle = .capsule
            configuration.baseBackgroundColor = .white
            configuration.baseForegroundColor = .init(white: 0.1, alpha: 1)
            configuration.title = .localized(.learnMore)
            learnMore.configuration = configuration
        } else {
            learnMore.layer.cornerRadius = 20
            learnMore.titleEdgeInsets = .init(top: 0, left: 16, bottom: 0, right: 16)
            learnMore.backgroundColor = .white
            learnMore.setTitleColor(.init(white: 0.1, alpha: 1), for: .normal)
            learnMore.setTitle(.localized(.learnMore), for: [])
        }
        
        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.isUserInteractionEnabled = false
        outline.addSubview(divider)
        self.divider = divider
        
        outline.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        outline.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        outline.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        outline.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true

        image.centerXAnchor.constraint(equalTo: outline.leftAnchor, constant: 38).isActive = true
        image.centerYAnchor.constraint(equalTo: outline.topAnchor, constant: EcosiaHome.Section.explore.height / 2).isActive = true
        
        title.centerYAnchor.constraint(equalTo: image.centerYAnchor).isActive = true
        title.leftAnchor.constraint(equalTo: outline.leftAnchor, constant: 72).isActive = true
        title.rightAnchor.constraint(lessThanOrEqualTo: indicator.leftAnchor, constant: -5).isActive = true
        
        indicator.centerYAnchor.constraint(equalTo: image.centerYAnchor).isActive = true
        indicator.rightAnchor.constraint(equalTo: outline.rightAnchor, constant: -16).isActive = true
        
        disclosure.topAnchor.constraint(equalTo: outline.topAnchor, constant: EcosiaHome.Section.explore.height).isActive = true
        disclosure.leftAnchor.constraint(equalTo: outline.leftAnchor, constant: 16).isActive = true
        disclosure.rightAnchor.constraint(equalTo: outline.rightAnchor, constant: -16).isActive = true
        disclosure.bottomAnchor.constraint(equalTo: learnMore.bottomAnchor, constant: 14).isActive = true
        
        subtitle.topAnchor.constraint(equalTo: disclosure.topAnchor, constant: 12).isActive = true
        subtitle.leftAnchor.constraint(equalTo: disclosure.leftAnchor, constant: 12).isActive = true
        subtitle.rightAnchor.constraint(lessThanOrEqualTo: disclosure.rightAnchor, constant: -12).isActive = true
        
        learnMore.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 10).isActive = true
        learnMore.leftAnchor.constraint(equalTo: subtitle.leftAnchor).isActive = true
        learnMore.heightAnchor.constraint(greaterThanOrEqualToConstant: 40).isActive = true
        
        divider.leftAnchor.constraint(equalTo: outline.leftAnchor, constant: 16).isActive = true
        divider.rightAnchor.constraint(equalTo: outline.rightAnchor, constant: -16).isActive = true
        divider.bottomAnchor.constraint(equalTo: outline.bottomAnchor).isActive = true
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true

        applyTheme()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        divider?.isHidden = model == .faq || frame.height > EcosiaHome.Section.explore.height
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }

    func applyTheme() {
        outline.backgroundColor = .theme.ecosia.ntpCellBackground
        title.textColor = .theme.ecosia.primaryText
        indicator.tintColor = .theme.ecosia.secondaryText
        divider.backgroundColor = .theme.ecosia.border
        disclosure.backgroundColor = .theme.ecosia.quarternaryBackground
        subtitle.textColor = .theme.ecosia.primaryTextInverted
    }
    
    private func hover() {
        outline.backgroundColor = isSelected || isHighlighted ? .theme.ecosia.hoverBackgroundColor : .theme.ecosia.ntpCellBackground
    }
}
