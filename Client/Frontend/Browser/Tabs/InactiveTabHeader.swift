// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum ExpandButtonState {
    case up
    case down

    var image: UIImage? {
        switch self {
        case .up:
            return UIImage(systemName: "chevron.up")
        case .down:
            return UIImage(systemName: "chevron.down")
        }
    }
}

class InactiveTabHeader: UITableViewHeaderFooterView, NotificationThemeable, ReusableCell {
    var state: ExpandButtonState? {
        willSet(state) {
            moreButton.setImage(state?.image, for: .normal)
        }
    }

    lazy var titleLabel: UILabel = .build { titleLabel in
        titleLabel.text = self.title
        titleLabel.textColor = UIColor.theme.homePanel.activityStreamHeaderText
        titleLabel.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .headline, maxSize: 17)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.minimumScaleFactor = 0.6
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
    }

    lazy var moreButton: UIButton = .build { button in
        button.isHidden = true
        button.setImage(self.state?.image, for: .normal)
        button.contentHorizontalAlignment = .trailing
    }

    var title: String? {
        willSet(newTitle) {
            titleLabel.text = newTitle
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
        moreButton.setTitle(nil, for: .normal)
        moreButton.accessibilityIdentifier = nil
        titleLabel.text = nil
        moreButton.removeTarget(nil, action: nil, for: .allEvents)
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        contentView.addSubview(titleLabel)
        contentView.addSubview(moreButton)
        moreButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityIdentifier = AccessibilityIdentifiers.TabTray.inactiveTabHeader

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12, priority: .defaultHigh),
            titleLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: moreButton.leadingAnchor, constant: -16, priority: .defaultHigh),

            moreButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            moreButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -28),
        ])

        applyTheme()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme() {
        self.titleLabel.textColor = .theme.ecosia.primaryText
        moreButton.imageView?.tintColor = .theme.ecosia.decorativeIcon
    }
}