/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SnapKit

// MARK: - Section Header View
public struct FirefoxHomeHeaderViewUX {
    static let Insets: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? FirefoxHomeUX.SectionInsetsForIpad + FirefoxHomeUX.MinimumInsets : FirefoxHomeUX.MinimumInsets
    static let TitleTopInset: CGFloat = 5
    static let sectionHeaderSize: CGFloat = 20
}

enum ASHeaderViewType {
    case otherGroupTabs
    case normal
}

class ASHeaderView: UICollectionReusableView {
    static let verticalInsets: CGFloat = 4
    var sectionType: ASHeaderViewType = .normal

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = self.title
        titleLabel.textColor = UIColor.theme.homePanel.activityStreamHeaderText
        titleLabel.font = UIFont.systemFont(ofSize: FirefoxHomeHeaderViewUX.sectionHeaderSize, weight: .bold)
        titleLabel.minimumScaleFactor = 0.6
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        return titleLabel
    }()

    lazy var moreButton: UIButton = {
        let button = UIButton()
        button.isHidden = true
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
        button.contentHorizontalAlignment = .right
        button.setTitleColor(UIColor.theme.homePanel.activityStreamHeaderButton, for: .normal)
        button.setTitleColor(UIColor.Photon.Grey50, for: .highlighted)
        return button
    }()

    var title: String? {
        willSet(newTitle) {
            titleLabel.text = newTitle
        }
    }

    var titleInsets: CGFloat {
        get {
            return max((bounds.size.width - 520) / 2.0, FirefoxHomeUX.MinimumInsets)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        moreButton.isHidden = true
        moreButton.setTitle(nil, for: .normal)
        moreButton.accessibilityIdentifier = nil;
        titleLabel.text = nil
        moreButton.removeTarget(nil, action: nil, for: .allEvents)
        titleLabel.textColor = UIColor.theme.homePanel.activityStreamHeaderText
        moreButton.setTitleColor(UIColor.theme.homePanel.activityStreamHeaderButton, for: .normal)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        addSubview(moreButton)
        moreButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-6)
            make.trailing.equalTo(self.safeArea.trailing).inset(titleInsets)
        }
        moreButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(self.safeArea.leading).inset(titleInsets)
            make.trailing.equalTo(moreButton.snp.leading).inset(-FirefoxHomeHeaderViewUX.TitleTopInset)
            make.bottom.equalToSuperview().offset(-10)
        }
    }

    func remakeConstraint(type: ASHeaderViewType) {
        let inset = type == .otherGroupTabs ? 15 : titleInsets
        titleLabel.snp.updateConstraints { update in
            update.leading.equalTo(self.safeArea.leading).inset(inset)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
