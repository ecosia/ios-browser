/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Core
import UIKit

final class NewsCell: UICollectionViewCell, Themeable {
    struct Positions: OptionSet {
        static let top = Positions(rawValue: 1)
        static let bottom = Positions(rawValue: 1 << 1)
        let rawValue: Int8

        static func derive(row: Int, items: Int) -> Positions {
            var pos = Positions()
            if row == 0 { pos.insert(.top) }
            if row == items - 1 { pos.insert(.bottom) }
            return pos
        }
    }

    private var imageUrl: URL?
    private weak var container: UIView!
    private weak var image: UIImageView!
    private weak var title: UILabel!
    private weak var date: UILabel!
    private weak var topBorder: UIView!
    private weak var bottomBorder: UIView!
    private weak var bottomLeft: NSLayoutConstraint!
    weak var widthConstraint: NSLayoutConstraint!

    required init?(coder: NSCoder) { nil }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)

        container.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        container.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        container.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true

        let widthConstraint = container.widthAnchor.constraint(equalToConstant: 100)
        widthConstraint.priority = .init(999)
        widthConstraint.isActive = true
        self.widthConstraint = widthConstraint

        let top = UIView()
        top.translatesAutoresizingMaskIntoConstraints = false
        top.isUserInteractionEnabled = false
        contentView.addSubview(top)
        self.topBorder = top

        let bottom = UIView()
        bottom.translatesAutoresizingMaskIntoConstraints = false
        bottom.isUserInteractionEnabled = false
        contentView.addSubview(bottom)
        self.bottomBorder = bottom
        
        let placeholder = UIImageView()
        placeholder.translatesAutoresizingMaskIntoConstraints = false
        placeholder.contentMode = .scaleAspectFill
        placeholder.clipsToBounds = true
        placeholder.image = UIImage(named: "image_placeholder")!
        placeholder.layer.cornerRadius = 5
        contentView.addSubview(placeholder)
        
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.alpha = 0
        image.layer.cornerRadius = 5
        contentView.addSubview(image)
        self.image = image
        
        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.numberOfLines = 0
        title.lineBreakMode = .byTruncatingTail
        title.font = .preferredFont(forTextStyle: .subheadline)
        title.setContentHuggingPriority(.defaultHigh, for: .vertical)
        title.adjustsFontForContentSizeCategory = true
        contentView.addSubview(title)
        self.title = title
        
        let date = UILabel()
        date.translatesAutoresizingMaskIntoConstraints = false
        date.font = .preferredFont(forTextStyle: .subheadline)
        date.adjustsFontForContentSizeCategory = true
        date.numberOfLines = 1
        date.textAlignment = .left
        date.setContentCompressionResistancePriority(.required, for: .vertical)
        date.setContentHuggingPriority(.defaultHigh, for: .vertical)

        contentView.addSubview(date)
        self.date = date
        
        placeholder.topAnchor.constraint(equalTo: image.topAnchor).isActive = true
        placeholder.bottomAnchor.constraint(equalTo: image.bottomAnchor).isActive = true
        placeholder.leftAnchor.constraint(equalTo: image.leftAnchor).isActive = true
        placeholder.rightAnchor.constraint(equalTo: image.rightAnchor).isActive = true
        
        image.leftAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leftAnchor, constant: 16).isActive = true
        image.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        image.widthAnchor.constraint(equalToConstant: 96).isActive = true
        image.heightAnchor.constraint(equalTo: image.widthAnchor).isActive = true
        image.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 16).isActive = true
        image.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -16).isActive = true

        title.leftAnchor.constraint(equalTo: image.rightAnchor, constant: 15).isActive = true
        title.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16).isActive = true
        title.bottomAnchor.constraint(lessThanOrEqualTo: date.topAnchor, constant: 0).isActive = true

        let squeeze = title.bottomAnchor.constraint(equalTo: date.topAnchor, constant: 0)
        squeeze.priority = .init(700)
        squeeze.isActive = true

        date.leftAnchor.constraint(equalTo: title.leftAnchor).isActive = true
        date.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16).isActive = true

        bottom.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        bottom.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        bottom.heightAnchor.constraint(equalToConstant: 1).isActive = true

        top.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        top.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        top.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        top.heightAnchor.constraint(equalToConstant: 1).isActive = true

        title.rightAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.rightAnchor, constant: -16).isActive = true
        date.rightAnchor.constraint(equalTo: title.rightAnchor).isActive = true
        let bottomLeft = bottom.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16)
        bottomLeft.priority = .defaultHigh
        bottomLeft.isActive = true
        self.bottomLeft = bottomLeft
        applyTheme()
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
    
    func configure(_ item: NewsModel, images: Images, positions: Positions) {
        imageUrl = item.imageUrl
        image.image = nil
        title.text = item.text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        
        if #available(iOS 13.0, *) {
            date.text = RelativeDateTimeFormatter().localizedString(for: item.publishDate, relativeTo: .init())
        } else {
            let count = Calendar.current.dateComponents([.day], from: item.publishDate, to: .init()).day!
            date.text = count == 0 ? .localized(.today) : .init(format: .localized(.daysAgo), "\(count)")
        }
        
        images.load(self, url: item.imageUrl) { [weak self] in
            guard self?.imageUrl == $0.url else { return }
            self?.updateImage($0.data)
        }

        topBorder.isHidden = !positions.contains(.top)
        bottomLeft.constant = positions.contains(.bottom) ? 0 : 16
        bottomBorder.setNeedsLayout()
    }
    
    private func updateImage(_ data: Data) {
        image.image = UIImage(data: data)
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: { [weak self] in
            self?.image.alpha = 1
        })
    }
    
    private func hover() {
        backgroundColor = isSelected || isHighlighted ? UIColor.theme.ecosia.hoverBackgroundColor : UIColor.theme.ecosia.highlightedBackground
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }

    func applyTheme() {
        backgroundColor = UIColor.theme.ecosia.highlightedBackground
        bottomBorder?.backgroundColor = UIColor.theme.ecosia.underlineGrey
        topBorder?.backgroundColor = UIColor.theme.ecosia.underlineGrey
        title?.textColor = UIColor.theme.ecosia.highContrastText
        date?.textColor = UIColor.theme.ecosia.secondaryText
    }
}

final class NewsButtonCell: UICollectionReusableView {
    lazy var moreButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(UIColor.theme.ecosia.primaryBrand, for: .normal)
        button.setTitleColor(UIColor.Photon.Grey50, for: .highlighted)
        button.titleLabel?.font = .preferredFont(forTextStyle: .body)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(moreButton)

        moreButton.translatesAutoresizingMaskIntoConstraints = false
        moreButton.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        moreButton.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        moreButton.topAnchor.constraint(equalTo: topAnchor).isActive = true
        moreButton.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        moreButton.setTitleColor(UIColor.theme.ecosia.primaryBrand, for: .normal)
        moreButton.setTitleColor(UIColor.Photon.Grey50, for: .highlighted)
    }
}

class NewsHeaderCell: UICollectionViewCell, Themeable {
    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.theme.ecosia.highContrastText
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        return titleLabel
    }()

    weak var widthConstraint: NSLayoutConstraint!

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
