/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core

final class MyImpactCell: UICollectionViewCell, AutoSizingCell, Themeable {
    private(set) weak var howItWorksButton: UIControl!
    private weak var totalProgress: Progress!
    private weak var currentProgress: Progress!
    private weak var indicator: Indicator!
    private weak var widthConstraint: NSLayoutConstraint!
    private weak var outline: UIView!
    private weak var treesCount: UILabel!
    private weak var treesPlanted: UILabel!
    private weak var howItWorks: UILabel!
    private weak var searches: UILabel!
    private weak var searchesTrees: UILabel!
    private weak var friends: UILabel!
    private weak var friendsTrees: UILabel!
    
    required init?(coder: NSCoder) { nil }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let outline = UIView()
        outline.layer.cornerRadius = 10
        outline.translatesAutoresizingMaskIntoConstraints = false
        self.outline = outline
        contentView.addSubview(outline)

        let progressSize = CGSize(width: 240, height: 150)
        let totalProgress = Progress(size: progressSize, lineWidth: 8)
        self.totalProgress = totalProgress
        outline.addSubview(totalProgress)
        
        let currentProgress = Progress(size: progressSize, lineWidth: 8)
        self.currentProgress = currentProgress
        outline.addSubview(currentProgress)
        
        let indicator = Indicator(size: progressSize)
        self.indicator = indicator
        outline.addSubview(indicator)
        
        let treesIcon = UIImageView(image: .init(themed: "yourImpact"))
        treesIcon.translatesAutoresizingMaskIntoConstraints = false
        treesIcon.contentMode = .center
        treesIcon.clipsToBounds = true
        outline.addSubview(treesIcon)
        
        let treesCount = UILabel()
        treesCount.translatesAutoresizingMaskIntoConstraints = false
        treesCount.font = .preferredFont(forTextStyle: .title1).bold()
        treesCount.adjustsFontForContentSizeCategory = true
        self.treesCount = treesCount
        outline.addSubview(treesCount)
        
        let treesPlanted = UILabel()
        treesPlanted.translatesAutoresizingMaskIntoConstraints = false
        treesPlanted.font = .preferredFont(forTextStyle: .body)
        treesPlanted.adjustsFontForContentSizeCategory = true
        self.treesPlanted = treesPlanted
        outline.addSubview(treesPlanted)
        
        let howItWorksButton = UIControl()
        howItWorksButton.translatesAutoresizingMaskIntoConstraints = false
        outline.addSubview(howItWorksButton)
        self.howItWorksButton = howItWorksButton
        
        let howItWorks = UILabel()
        howItWorks.translatesAutoresizingMaskIntoConstraints = false
        howItWorks.font = .preferredFont(forTextStyle: .callout)
        howItWorks.adjustsFontForContentSizeCategory = true
        howItWorks.text = .localized(.howItWorks)
        self.howItWorks = howItWorks
        howItWorksButton.addSubview(howItWorks)
        
        let howItWorksIcon = UIImageView(image: .init(themed: "howItWorks"))
        howItWorksIcon.translatesAutoresizingMaskIntoConstraints = false
        howItWorksIcon.contentMode = .center
        howItWorksIcon.clipsToBounds = true
        howItWorksButton.addSubview(howItWorksIcon)
        
        let searchesIcon = UIImageView(image: .init(themed: "searches"))
        searchesIcon.translatesAutoresizingMaskIntoConstraints = false
        searchesIcon.contentMode = .center
        searchesIcon.clipsToBounds = true
        outline.addSubview(searchesIcon)
        
        let searches = UILabel()
        searches.translatesAutoresizingMaskIntoConstraints = false
        searches.font = .preferredFont(forTextStyle: .body)
        searches.adjustsFontForContentSizeCategory = true
        self.searches = searches
        outline.addSubview(searches)
        
        let searchesTrees = UILabel()
        searchesTrees.translatesAutoresizingMaskIntoConstraints = false
        searchesTrees.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .subheadline).pointSize, weight: .semibold)
        searchesTrees.adjustsFontForContentSizeCategory = true
        self.searchesTrees = searchesTrees
        outline.addSubview(searchesTrees)
        
        let searchesImpact = UIImageView(image: .init(themed: "yourImpact"))
        searchesImpact.translatesAutoresizingMaskIntoConstraints = false
        searchesImpact.contentMode = .center
        searchesImpact.clipsToBounds = true
        outline.addSubview(searchesImpact)
        
        let friendsIcon = UIImageView(image: .init(themed: "friends"))
        friendsIcon.translatesAutoresizingMaskIntoConstraints = false
        friendsIcon.contentMode = .center
        friendsIcon.clipsToBounds = true
        outline.addSubview(friendsIcon)
        
        let friends = UILabel()
        friends.translatesAutoresizingMaskIntoConstraints = false
        friends.font = .preferredFont(forTextStyle: .body)
        friends.adjustsFontForContentSizeCategory = true
        self.friends = friends
        outline.addSubview(friends)
        
        let friendsTrees = UILabel()
        friendsTrees.translatesAutoresizingMaskIntoConstraints = false
        friendsTrees.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .subheadline).pointSize, weight: .semibold)
        friendsTrees.adjustsFontForContentSizeCategory = true
        self.friendsTrees = friendsTrees
        outline.addSubview(friendsTrees)
        
        let friendsImpact = UIImageView(image: .init(themed: "yourImpact"))
        friendsImpact.translatesAutoresizingMaskIntoConstraints = false
        friendsImpact.contentMode = .center
        friendsImpact.clipsToBounds = true
        outline.addSubview(friendsImpact)

        outline.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        outline.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        outline.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12).isActive = true
        outline.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4).isActive = true

        let widthConstraint = outline.widthAnchor.constraint(equalToConstant: 100)
        widthConstraint.priority = .defaultHigh
        widthConstraint.isActive = true
        self.widthConstraint = widthConstraint
        
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
        
        howItWorksButton.topAnchor.constraint(equalTo: treesPlanted.bottomAnchor).isActive = true
        howItWorksButton.centerXAnchor.constraint(equalTo: totalProgress.centerXAnchor).isActive = true
        howItWorksButton.bottomAnchor.constraint(equalTo: howItWorks.bottomAnchor, constant: 6).isActive = true
        howItWorksButton.rightAnchor.constraint(equalTo: howItWorksIcon.rightAnchor).isActive = true
        
        howItWorks.leftAnchor.constraint(equalTo: howItWorksButton.leftAnchor).isActive = true
        howItWorks.topAnchor.constraint(equalTo: howItWorksButton.topAnchor, constant: 6).isActive = true
        
        howItWorksIcon.centerYAnchor.constraint(equalTo: howItWorks.centerYAnchor).isActive = true
        howItWorksIcon.leftAnchor.constraint(equalTo: howItWorks.rightAnchor, constant: 4).isActive = true
        
        searchesIcon.leftAnchor.constraint(equalTo: outline.leftAnchor, constant: 16).isActive = true
        searchesIcon.bottomAnchor.constraint(equalTo: friendsIcon.topAnchor, constant: -10).isActive = true
        
        searches.leftAnchor.constraint(equalTo: searchesIcon.rightAnchor, constant: 10).isActive = true
        searches.centerYAnchor.constraint(equalTo: searchesIcon.centerYAnchor).isActive = true
        
        searchesTrees.rightAnchor.constraint(equalTo: searchesImpact.leftAnchor, constant: -7).isActive = true
        searchesTrees.centerYAnchor.constraint(equalTo: searchesIcon.centerYAnchor).isActive = true
        
        searchesImpact.rightAnchor.constraint(equalTo: outline.rightAnchor, constant: -19).isActive = true
        searchesImpact.centerYAnchor.constraint(equalTo: searchesIcon.centerYAnchor).isActive = true
        
        friendsIcon.leftAnchor.constraint(equalTo: outline.leftAnchor, constant: 16).isActive = true
        friendsIcon.bottomAnchor.constraint(equalTo: outline.bottomAnchor, constant: -24).isActive = true
        
        friends.leftAnchor.constraint(equalTo: friendsIcon.rightAnchor, constant: 10).isActive = true
        friends.centerYAnchor.constraint(equalTo: friendsIcon.centerYAnchor).isActive = true
        
        friendsTrees.rightAnchor.constraint(equalTo: friendsImpact.leftAnchor, constant: -7).isActive = true
        friendsTrees.centerYAnchor.constraint(equalTo: friendsIcon.centerYAnchor).isActive = true
        
        friendsImpact.rightAnchor.constraint(equalTo: outline.rightAnchor, constant: -19).isActive = true
        friendsImpact.centerYAnchor.constraint(equalTo: friendsIcon.centerYAnchor).isActive = true
        
        applyTheme()
    }
    
    func update(personalCounter: Int) {
        let progress = .init(personalCounter % 45) / 45.0
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

    func setWidth(_ width: CGFloat, insets: UIEdgeInsets) {
        let margin = max(max(16, insets.left), insets.right)
        widthConstraint.constant = width - 2 * margin
    }
    
    func applyTheme() {
        outline.backgroundColor = .theme.ecosia.ecosiaHomeCellBackground
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
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
}
