/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core

final class MyImpactCell: UICollectionViewCell, NotificationThemeable {
    private(set) weak var howItWorksButton: UIControl!
    private weak var totalProgress: Progress!
    private weak var currentProgress: Progress!
    private weak var indicator: Indicator!
    private weak var outline: UIView!
    private weak var treesCount: UILabel!
    private weak var treesPlanted: UILabel!
    private weak var howItWorks: UILabel!
    private weak var searches: UILabel!
    private weak var searchesTrees: UILabel!
    private weak var friends: UILabel!
    private weak var friendsTrees: UILabel!
    private weak var treesIcon: UIImageView!
    private weak var howItWorksIcon: UIImageView!
    private weak var searchesIcon: UIImageView!
    private weak var searchesImpact: UIImageView!
    private weak var friendsIcon: UIImageView!
    private weak var friendsImpact: UIImageView!

    required init?(coder: NSCoder) { nil }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let outline = UIView()
        outline.layer.cornerRadius = 10
        outline.translatesAutoresizingMaskIntoConstraints = false
        self.outline = outline
        contentView.addSubview(outline)

        let howItWorksButton = UIControl()
        howItWorksButton.translatesAutoresizingMaskIntoConstraints = false
        outline.addSubview(howItWorksButton)
        self.howItWorksButton = howItWorksButton
        
        let progressSize = CGSize(width: 240, height: 150)
        let totalProgress = Progress(size: progressSize, lineWidth: 8)
        self.totalProgress = totalProgress
        howItWorksButton.addSubview(totalProgress)
        
        let currentProgress = Progress(size: progressSize, lineWidth: 8)
        self.currentProgress = currentProgress
        howItWorksButton.addSubview(currentProgress)
        
        let indicator = Indicator(size: progressSize)
        self.indicator = indicator
        howItWorksButton.addSubview(indicator)
        
        let treesIcon = UIImageView()
        treesIcon.translatesAutoresizingMaskIntoConstraints = false
        treesIcon.contentMode = .center
        treesIcon.clipsToBounds = true
        howItWorksButton.addSubview(treesIcon)
        self.treesIcon = treesIcon
        
        let treesCount = UILabel()
        treesCount.translatesAutoresizingMaskIntoConstraints = false
        treesCount.font = .preferredFont(forTextStyle: .title1).bold()
        treesCount.adjustsFontForContentSizeCategory = true
        self.treesCount = treesCount
        howItWorksButton.addSubview(treesCount)
        
        let treesPlanted = UILabel()
        treesPlanted.translatesAutoresizingMaskIntoConstraints = false
        treesPlanted.font = .preferredFont(forTextStyle: .body)
        treesPlanted.adjustsFontForContentSizeCategory = true
        self.treesPlanted = treesPlanted
        howItWorksButton.addSubview(treesPlanted)
        
        let howItWorks = UILabel()
        howItWorks.translatesAutoresizingMaskIntoConstraints = false
        howItWorks.font = .preferredFont(forTextStyle: .callout)
        howItWorks.adjustsFontForContentSizeCategory = true
        howItWorks.text = .localized(.howItWorks)
        self.howItWorks = howItWorks
        howItWorksButton.addSubview(howItWorks)
        
        let howItWorksIcon = UIImageView()
        howItWorksIcon.translatesAutoresizingMaskIntoConstraints = false
        howItWorksIcon.contentMode = .center
        howItWorksIcon.clipsToBounds = true
        howItWorksButton.addSubview(howItWorksIcon)
        self.howItWorksIcon = howItWorksIcon
        
        let searchesStackView = UIStackView()
        searchesStackView.translatesAutoresizingMaskIntoConstraints = false
        searchesStackView.axis = .horizontal
        searchesStackView.distribution = .fill
        searchesStackView.alignment = .center
        searchesStackView.spacing = 8.0

        let searchesIcon = UIImageView()
        searchesIcon.translatesAutoresizingMaskIntoConstraints = false
        searchesIcon.contentMode = .center
        searchesIcon.clipsToBounds = true
        searchesIcon.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        searchesIcon.setContentHuggingPriority(.defaultHigh, for: .vertical)
        self.searchesIcon = searchesIcon
                
        let searches = UILabel()
        searches.translatesAutoresizingMaskIntoConstraints = false
        searches.font = .preferredFont(forTextStyle: .body)
        searches.adjustsFontForContentSizeCategory = true
        searches.setContentHuggingPriority(.defaultLow, for: .horizontal)
        searches.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        self.searches = searches
        
        let searchesTrees = UILabel()
        searchesTrees.translatesAutoresizingMaskIntoConstraints = false
        searchesTrees.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .subheadline).pointSize, weight: .semibold)
        searchesTrees.adjustsFontForContentSizeCategory = true
        searchesTrees.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        searchesTrees.setContentHuggingPriority(.defaultHigh, for: .vertical)
        self.searchesTrees = searchesTrees
        
        let searchesImpact = UIImageView()
        searchesImpact.translatesAutoresizingMaskIntoConstraints = false
        searchesImpact.contentMode = .center
        searchesImpact.clipsToBounds = true
        searchesImpact.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        searchesImpact.setContentHuggingPriority(.defaultHigh, for: .vertical)
        self.searchesImpact = searchesImpact
        
        searchesStackView.addArrangedSubview(self.searchesIcon)
        searchesStackView.addArrangedSubview(self.searches)
        searchesStackView.addArrangedSubview(self.searchesTrees)
        searchesStackView.addArrangedSubview(self.searchesImpact)
        
        let friendsStackView = UIStackView()
        friendsStackView.translatesAutoresizingMaskIntoConstraints = false
        friendsStackView.axis = .horizontal
        friendsStackView.distribution = .fill
        friendsStackView.alignment = .center
        friendsStackView.spacing = 8.0
        friendsStackView.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let friendsIcon = UIImageView()
        friendsIcon.translatesAutoresizingMaskIntoConstraints = false
        friendsIcon.contentMode = .center
        friendsIcon.clipsToBounds = true
        friendsIcon.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        friendsIcon.setContentHuggingPriority(.defaultHigh, for: .vertical)
        self.friendsIcon = friendsIcon
        
        let friends = UILabel()
        friends.translatesAutoresizingMaskIntoConstraints = false
        friends.font = .preferredFont(forTextStyle: .body)
        friends.adjustsFontForContentSizeCategory = true
        friends.numberOfLines = 2
        self.friends = friends
        
        let friendsTrees = UILabel()
        friendsTrees.translatesAutoresizingMaskIntoConstraints = false
        friendsTrees.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .subheadline).pointSize, weight: .semibold)
        friendsTrees.adjustsFontForContentSizeCategory = true
        friendsTrees.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        friendsTrees.setContentHuggingPriority(.defaultHigh, for: .vertical)
        self.friendsTrees = friendsTrees
        
        let friendsImpact = UIImageView()
        friendsImpact.translatesAutoresizingMaskIntoConstraints = false
        friendsImpact.contentMode = .center
        friendsImpact.clipsToBounds = true
        friendsImpact.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        friendsImpact.setContentHuggingPriority(.defaultHigh, for: .vertical)
        self.friendsImpact = friendsImpact
        
        friendsStackView.addArrangedSubview(self.friendsIcon)
        friendsStackView.addArrangedSubview(self.friends)
        friendsStackView.addArrangedSubview(self.friendsTrees)
        friendsStackView.addArrangedSubview(self.friendsImpact)
        
        let searchAndFriendsStackView = UIStackView()
        searchAndFriendsStackView.translatesAutoresizingMaskIntoConstraints = false
        searchAndFriendsStackView.alignment = .fill
        searchAndFriendsStackView.axis = .vertical
        searchAndFriendsStackView.spacing = UIStackView.spacingUseDefault
        
        searchAndFriendsStackView.addArrangedSubview(searchesStackView)
        searchAndFriendsStackView.addArrangedSubview(friendsStackView)
        outline.addSubview(searchAndFriendsStackView)

        outline.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor).isActive = true
        outline.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor).isActive = true
        outline.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        outline.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        outline.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        
        totalProgress.topAnchor.constraint(equalTo: outline.topAnchor, constant: 25).isActive = true
        totalProgress.centerXAnchor.constraint(equalTo: outline.centerXAnchor).isActive = true
        
        currentProgress.centerYAnchor.constraint(equalTo: totalProgress.centerYAnchor).isActive = true
        currentProgress.centerXAnchor.constraint(equalTo: totalProgress.centerXAnchor).isActive = true
        
        indicator.centerYAnchor.constraint(equalTo: totalProgress.centerYAnchor).isActive = true
        indicator.centerXAnchor.constraint(equalTo: totalProgress.centerXAnchor).isActive = true

        treesIcon.topAnchor.constraint(equalTo: totalProgress.topAnchor, constant: 34).isActive = true
        treesIcon.centerXAnchor.constraint(equalTo: totalProgress.centerXAnchor).isActive = true
        
        treesCount.topAnchor.constraint(equalTo: treesIcon.bottomAnchor, constant: 2).isActive = true
        treesCount.centerXAnchor.constraint(equalTo: totalProgress.centerXAnchor).isActive = true
        
        treesPlanted.topAnchor.constraint(equalTo: treesCount.bottomAnchor).isActive = true
        treesPlanted.centerXAnchor.constraint(equalTo: totalProgress.centerXAnchor).isActive = true
        
        howItWorksButton.topAnchor.constraint(equalTo: outline.topAnchor).isActive = true
        howItWorksButton.leftAnchor.constraint(equalTo: outline.leftAnchor).isActive = true
        howItWorksButton.rightAnchor.constraint(equalTo: outline.rightAnchor).isActive = true
        howItWorksButton.bottomAnchor.constraint(equalTo: totalProgress.bottomAnchor, constant: 6).isActive = true
        
        howItWorks.centerXAnchor.constraint(equalTo: outline.centerXAnchor, constant: -8).isActive = true
        howItWorks.topAnchor.constraint(equalTo: treesPlanted.bottomAnchor, constant: 6).isActive = true
        
        howItWorksIcon.centerYAnchor.constraint(equalTo: howItWorks.centerYAnchor).isActive = true
        howItWorksIcon.leftAnchor.constraint(equalTo: howItWorks.rightAnchor, constant: 4).isActive = true

        searchAndFriendsStackView.leadingAnchor.constraint(equalTo: outline.leadingAnchor, constant: 16).isActive = true
        searchAndFriendsStackView.trailingAnchor.constraint(equalTo: outline.trailingAnchor, constant: -16).isActive = true
        searchAndFriendsStackView.topAnchor.constraint(equalTo: totalProgress.bottomAnchor, constant: 12).isActive = true
        searchAndFriendsStackView.bottomAnchor.constraint(equalTo: outline.bottomAnchor, constant: -24).isActive = true
                        
        applyTheme()
    }
    
    func update(personalCounter: Int, progress: Double) {
        currentProgress.value = progress
        indicator.value = progress
        
        if #available(iOS 15.0, *) {
            treesCount.text = User.shared.impact.formatted()
            searchesTrees.text = User.shared.searchImpact.formatted()
            friendsTrees.text = User.shared.referrals.impact.formatted()
        } else {
            treesCount.text = "\(User.shared.impact)"
            searchesTrees.text = "\(User.shared.searchImpact)"
            friendsTrees.text = "\(User.shared.referrals.impact)"
        }

        treesPlanted.text = .localizedPlural(.treesPlantedPlural, num: User.shared.impact)
        searches.text = .localizedPlural(.searches, num: personalCounter)
        friends.text = .localizedPlural(.friendInvitesPlural, num: User.shared.referrals.count)
    }
    
    func applyTheme() {
        outline.backgroundColor = .theme.ecosia.ntpCellBackground
        totalProgress.update(color: .theme.ecosia.treeCounterProgressTotal)
        currentProgress.update(color: .theme.ecosia.treeCounterProgressCurrent)
        indicator.update(fill: .theme.ecosia.treeCounterProgressCurrent, border: .theme.ecosia.treeCounterProgressBorder)
        treesCount.textColor = .theme.ecosia.primaryText
        treesPlanted.textColor = .theme.ecosia.primaryText
        howItWorks.textColor = .theme.ecosia.primaryButton
        searches.textColor = .theme.ecosia.primaryText
        searchesTrees.textColor = .theme.ecosia.primaryText
        friends.textColor = .theme.ecosia.primaryText
        friendsTrees.textColor = .theme.ecosia.primaryText

        treesIcon.image = .init(themed: "yourImpact")
        howItWorksIcon.image = .init(themed: "howItWorks")
        searchesIcon.image = .init(themed: "searches")
        searchesImpact.image = .init(themed: "yourImpact")
        friendsIcon.image = .init(themed: "friends")
        friendsImpact.image = .init(themed: "yourImpact")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
}
