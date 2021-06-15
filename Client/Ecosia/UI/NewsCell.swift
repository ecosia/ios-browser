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
    private weak var image: UIImageView!
    private weak var title: UILabel!
    private weak var date: UILabel!
    private weak var topBorder: UIView!
    private weak var bottomBorder: UIView!
    private weak var bottomLeft: NSLayoutConstraint!

    required init?(coder: NSCoder) { nil }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

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
        title.numberOfLines = 4
        title.lineBreakMode = .byTruncatingTail
        title.font = .preferredFont(forTextStyle: .subheadline)
        contentView.addSubview(title)
        self.title = title
        
        let date = UILabel()
        date.translatesAutoresizingMaskIntoConstraints = false
        date.font = .preferredFont(forTextStyle: .subheadline)
        date.numberOfLines = 1
        date.textAlignment = .left
        date.setContentCompressionResistancePriority(.required, for: .vertical)
        contentView.addSubview(date)
        self.date = date
        
        placeholder.topAnchor.constraint(equalTo: image.topAnchor).isActive = true
        placeholder.bottomAnchor.constraint(equalTo: image.bottomAnchor).isActive = true
        placeholder.leftAnchor.constraint(equalTo: image.leftAnchor).isActive = true
        placeholder.rightAnchor.constraint(equalTo: image.rightAnchor).isActive = true
        
        image.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        image.widthAnchor.constraint(equalToConstant: 96).isActive = true
        image.heightAnchor.constraint(equalTo: image.widthAnchor).isActive = true
        
        title.leftAnchor.constraint(equalTo: image.rightAnchor, constant: 15).isActive = true
        title.topAnchor.constraint(equalTo: image.topAnchor, constant: 3).isActive = true
        title.bottomAnchor.constraint(lessThanOrEqualTo: date.topAnchor, constant: 0).isActive = true

        date.leftAnchor.constraint(equalTo: title.leftAnchor).isActive = true
        date.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16).isActive = true

        bottom.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        bottom.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        bottom.heightAnchor.constraint(equalToConstant: 1).isActive = true

        top.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        top.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        top.topAnchor.constraint(equalTo: topAnchor).isActive = true
        top.heightAnchor.constraint(equalToConstant: 1).isActive = true

        image.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: 16).isActive = true
        title.rightAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.rightAnchor, constant: -16).isActive = true
        date.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -16).isActive = true
        let bottomLeft = bottom.leftAnchor.constraint(equalTo: leftAnchor, constant: 16)
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
        button.setTitleColor(UIColor.theme.ecosia.primaryButton, for: .normal)
        button.setTitleColor(UIColor.Photon.Grey50, for: .highlighted)
        button.titleLabel?.font = .preferredFont(forTextStyle: .body)
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
        moreButton.setTitleColor(UIColor.theme.ecosia.primaryButton, for: .normal)
        moreButton.setTitleColor(UIColor.Photon.Grey50, for: .highlighted)
    }
}

class NewsHeader: UICollectionReusableView, Themeable {
    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.theme.ecosia.highContrastText
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        return titleLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        addSubview(titleLabel)

        titleLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
        titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.trailingAnchor, constant: -16).isActive = true
        titleLabel.topAnchor.constraint(greaterThanOrEqualTo: topAnchor).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16).isActive = true
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
    }

    func applyTheme() {
        titleLabel.textColor = UIColor.theme.ecosia.highContrastText
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
}
