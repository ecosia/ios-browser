/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core

final class MyImpactCell: UICollectionViewCell {
    
    // MARK: - UX

    struct UX {
        
        enum Outline {
            static let cornerRadius: CGFloat = 10
        }
        
        enum SearchAndFriends {
            static let padding: CGFloat = 16
            static let topPadding: CGFloat = 12
            static let bottomPadding: CGFloat = 24
            static let stackViewSpacing: CGFloat = 8
            static let maximumNumberOfLines = 2
        }
        
        enum ProgressView {
            static let progressSize = CGSize(width: 240, height: 150)
            static let lineWidth: CGFloat = 8
            static let topAnchorOffset: CGFloat = 25
            static let treesIconTopAnchorOffset: CGFloat = 34
            static let treesCountBottomAnchorOffset: CGFloat = 2
        }
        
        enum HowItWorksView {
            static let buttonBottomAnchorOffset: CGFloat = 6
            static let centerXOffset: CGFloat = -8
            static let topAnchorOffset: CGFloat = 6
            static let iconLeftAnchorOffset: CGFloat = 4
        }
    }
    
    // MARK: - Properties
    
    private(set) weak var howItWorksButton: UIControl!
    private weak var totalProgress: Progress!
    private weak var currentProgress: Progress!
    private weak var indicator: Indicator!
    private weak var outline: UIView!
    private weak var treesCount: UILabel!
    private weak var treesPlanted: UILabel!
    private weak var howItWorks: UILabel!
    private weak var searchesLabel: UILabel!
    private weak var searchesTreesLabel: UILabel!
    private weak var friendsLabel: UILabel!
    private weak var friendsTreesLabel: UILabel!
    private weak var treesIcon: UIImageView!
    private weak var howItWorksIcon: UIImageView!
    private weak var searchesIcon: UIImageView!
    private weak var searchesImpactIcon: UIImageView!
    private weak var friendsIcon: UIImageView!
    private weak var friendsImpactIcon: UIImageView!
    private weak var searchAndYourFriendsImpactContainerView: UIView!
    
    // MARK: - Init

    required init?(coder: NSCoder) { nil }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupConstraints()
        applyTheme()
    }
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
}

extension MyImpactCell {
    
    // MARK: - View Setup

    private func setupView() {
        
        let outline = makeOutline()
        contentView.addSubview(outline)
        self.outline = outline
        
        let howItWorksButton = makeHowItWorksButton()
        outline.addSubview(howItWorksButton)
        self.howItWorksButton = howItWorksButton
        
        let totalProgress = makeProgressView()
        howItWorksButton.addSubview(totalProgress)
        self.totalProgress = totalProgress
        
        let currentProgress = makeProgressView()
        howItWorksButton.addSubview(currentProgress)
        self.currentProgress = currentProgress
        
        let indicator = makeIndicatorView()
        howItWorksButton.addSubview(indicator)
        self.indicator = indicator
        
        let treesIcon = makeTreesIcon()
        howItWorksButton.addSubview(treesIcon)
        self.treesIcon = treesIcon
        
        let treesCount = makeTreesCountLabel()
        howItWorksButton.addSubview(treesCount)
        self.treesCount = treesCount
        
        let treesPlanted = makeTreesPlantedLabel()
        howItWorksButton.addSubview(treesPlanted)
        self.treesPlanted = treesPlanted
        
        let howItWorks = makeHowItWorksLabel()
        howItWorksButton.addSubview(howItWorks)
        self.howItWorks = howItWorks
        
        let howItWorksIcon = makeHowItWorksIcon()
        howItWorksButton.addSubview(howItWorksIcon)
        self.howItWorksIcon = howItWorksIcon
        
        let searchesStackView = makeYourSearchesContainerStackView()
        
        let searchesIcon = makeYourSearchesIcon()
        self.searchesIcon = searchesIcon
        
        let searchesLabel = makeYourSearchesLabel()
        self.searchesLabel = searchesLabel
        
        let searchesTreesLabel = makeSearchesTreesLabel()
        self.searchesTreesLabel = searchesTreesLabel

        let searchesImpactIcon = makeSearchesImpactIcon()
        self.searchesImpactIcon = searchesImpactIcon
        
        searchesStackView.addArrangedSubview(searchesIcon)
        searchesStackView.addArrangedSubview(searchesLabel)
        searchesStackView.addArrangedSubview(searchesTreesLabel)
        searchesStackView.addArrangedSubview(searchesImpactIcon)
                
        let friendsStackView = makeFriendsImpactContainerStackView()
        
        let friendsIcon = makeFriendsIcon()
        self.friendsIcon = friendsIcon
        
        let friendsLabel = makeFriendsLabel()
        self.friendsLabel = friendsLabel
        
        let friendsTreesLabel = makeFriendsTreesLabel()
        self.friendsTreesLabel = friendsTreesLabel
        
        let friendsImpactIcon = makeFriendsImpactIcon()
        self.friendsImpactIcon = friendsImpactIcon
        
        friendsStackView.addArrangedSubview(friendsIcon)
        friendsStackView.addArrangedSubview(friendsLabel)
        friendsStackView.addArrangedSubview(friendsTreesLabel)
        friendsStackView.addArrangedSubview(friendsImpactIcon)
        
        let searchAndYourFriendsImpactContainerView = makeSearchAndYourFriendsImpactContainerStackView()
        searchAndYourFriendsImpactContainerView.addArrangedSubview(searchesStackView)
        searchAndYourFriendsImpactContainerView.addArrangedSubview(friendsStackView)
        outline.addSubview(searchAndYourFriendsImpactContainerView)
        self.searchAndYourFriendsImpactContainerView = searchAndYourFriendsImpactContainerView
    }
}

extension MyImpactCell {
    
    // MARK: - View update helper

    func update(personalCounter: Int, progress: Double) {
        currentProgress.value = progress
        indicator.value = progress
        
        if #available(iOS 15.0, *) {
            treesCount.text = User.shared.impact.formatted()
            searchesTreesLabel.text = User.shared.searchImpact.formatted()
            friendsTreesLabel.text = User.shared.referrals.impact.formatted()
        } else {
            treesCount.text = "\(User.shared.impact)"
            searchesTreesLabel.text = "\(User.shared.searchImpact)"
            friendsTreesLabel.text = "\(User.shared.referrals.impact)"
        }
        
        treesPlanted.text = .localizedPlural(.treesPlantedPlural, num: User.shared.impact)
        searchesLabel.text = .localizedPlural(.searches, num: personalCounter)
        friendsLabel.text = .localizedPlural(.friendInvitesPlural, num: User.shared.referrals.count)
    }
    
}

extension MyImpactCell: NotificationThemeable {
    
    // MARK: - Theme

    func applyTheme() {
        outline.backgroundColor = .theme.ecosia.ntpCellBackground
        totalProgress.update(color: .theme.ecosia.treeCounterProgressTotal)
        currentProgress.update(color: .theme.ecosia.treeCounterProgressCurrent)
        indicator.update(fill: .theme.ecosia.treeCounterProgressCurrent, border: .theme.ecosia.treeCounterProgressBorder)
        treesCount.textColor = .theme.ecosia.primaryText
        treesPlanted.textColor = .theme.ecosia.primaryText
        howItWorks.textColor = .theme.ecosia.primaryButton
        searchesLabel.textColor = .theme.ecosia.primaryText
        searchesTreesLabel.textColor = .theme.ecosia.primaryText
        friendsLabel.textColor = .theme.ecosia.primaryText
        friendsTreesLabel.textColor = .theme.ecosia.primaryText
        
        treesIcon.image = .init(themed: "yourImpact")
        howItWorksIcon.image = .init(themed: "howItWorks")
        searchesIcon.image = .init(themed: "searches")
        searchesImpactIcon.image = .init(themed: "yourImpact")
        friendsIcon.image = .init(themed: "friends")
        friendsImpactIcon.image = .init(themed: "yourImpact")
    }
}

extension MyImpactCell {
    
    // MARK: - Constraint helper
    
    private func setupConstraints() {
        
        outline.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor).isActive = true
        outline.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor).isActive = true
        outline.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        outline.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        outline.widthAnchor.constraint(equalToConstant: frame.width).isActive = true
        
        totalProgress.topAnchor.constraint(equalTo: outline.topAnchor, constant: UX.ProgressView.topAnchorOffset).isActive = true
        totalProgress.centerXAnchor.constraint(equalTo: outline.centerXAnchor).isActive = true
        
        currentProgress.centerYAnchor.constraint(equalTo: totalProgress.centerYAnchor).isActive = true
        currentProgress.centerXAnchor.constraint(equalTo: totalProgress.centerXAnchor).isActive = true
        
        indicator.centerYAnchor.constraint(equalTo: totalProgress.centerYAnchor).isActive = true
        indicator.centerXAnchor.constraint(equalTo: totalProgress.centerXAnchor).isActive = true
        
        treesIcon.topAnchor.constraint(equalTo: totalProgress.topAnchor, constant: UX.ProgressView.treesIconTopAnchorOffset).isActive = true
        treesIcon.centerXAnchor.constraint(equalTo: totalProgress.centerXAnchor).isActive = true
        
        treesCount.topAnchor.constraint(equalTo: treesIcon.bottomAnchor, constant: UX.ProgressView.treesCountBottomAnchorOffset).isActive = true
        treesCount.centerXAnchor.constraint(equalTo: totalProgress.centerXAnchor).isActive = true
        
        treesPlanted.topAnchor.constraint(equalTo: treesCount.bottomAnchor).isActive = true
        treesPlanted.centerXAnchor.constraint(equalTo: totalProgress.centerXAnchor).isActive = true
        
        howItWorksButton.topAnchor.constraint(equalTo: outline.topAnchor).isActive = true
        howItWorksButton.leftAnchor.constraint(equalTo: outline.leftAnchor).isActive = true
        howItWorksButton.rightAnchor.constraint(equalTo: outline.rightAnchor).isActive = true
        howItWorksButton.bottomAnchor.constraint(equalTo: totalProgress.bottomAnchor, constant: UX.HowItWorksView.buttonBottomAnchorOffset).isActive = true
        
        howItWorks.centerXAnchor.constraint(equalTo: outline.centerXAnchor, constant: UX.HowItWorksView.centerXOffset).isActive = true
        howItWorks.topAnchor.constraint(equalTo: treesPlanted.bottomAnchor, constant: UX.HowItWorksView.topAnchorOffset).isActive = true
        
        howItWorksIcon.centerYAnchor.constraint(equalTo: howItWorks.centerYAnchor).isActive = true
        howItWorksIcon.leftAnchor.constraint(equalTo: howItWorks.rightAnchor, constant: UX.HowItWorksView.iconLeftAnchorOffset).isActive = true
        
        searchAndYourFriendsImpactContainerView.leadingAnchor.constraint(equalTo: outline.leadingAnchor, constant: UX.SearchAndFriends.padding).isActive = true
        searchAndYourFriendsImpactContainerView.trailingAnchor.constraint(equalTo: outline.trailingAnchor, constant: -UX.SearchAndFriends.padding).isActive = true
        searchAndYourFriendsImpactContainerView.topAnchor.constraint(equalTo: totalProgress.bottomAnchor, constant: UX.SearchAndFriends.topPadding).isActive = true
        searchAndYourFriendsImpactContainerView.bottomAnchor.constraint(equalTo: outline.bottomAnchor, constant: -UX.SearchAndFriends.bottomPadding).isActive = true

    }
    
}
