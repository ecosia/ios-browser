// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension MyImpactCell {

    // MARK: - Outline and Progress View components

    func makeOutline() -> UIView {
        let outline = UIView()
        outline.layer.cornerRadius = UX.Outline.cornerRadius
        outline.translatesAutoresizingMaskIntoConstraints = false
        return outline
    }
    
    func makeHowItWorksButton() -> UIControl {
        let howItWorksButton = UIControl()
        howItWorksButton.translatesAutoresizingMaskIntoConstraints = false
        return howItWorksButton
    }
    
    func makeProgressView() -> Progress {
        Progress(size: UX.ProgressView.progressSize, lineWidth: UX.ProgressView.lineWidth)
    }
    
    func makeIndicatorView() -> Indicator {
        Indicator(size: UX.ProgressView.progressSize)
    }
    
    func makeTreesIcon() -> UIImageView {
        let treesIcon = UIImageView()
        treesIcon.translatesAutoresizingMaskIntoConstraints = false
        treesIcon.contentMode = .center
        treesIcon.clipsToBounds = true
        return treesIcon
    }
    
    func makeTreesCountLabel() -> UILabel {
        let treesCount = UILabel()
        treesCount.translatesAutoresizingMaskIntoConstraints = false
        treesCount.font = .preferredFont(forTextStyle: .title1).bold()
        treesCount.adjustsFontForContentSizeCategory = true
        return treesCount
    }
    
    func makeTreesPlantedLabel() -> UILabel {
        let treesPlanted = UILabel()
        treesPlanted.translatesAutoresizingMaskIntoConstraints = false
        treesPlanted.font = .preferredFont(forTextStyle: .body)
        treesPlanted.adjustsFontForContentSizeCategory = true
        return treesPlanted
    }
    
    func makeHowItWorksLabel() -> UILabel {
        let howItWorks = UILabel()
        howItWorks.translatesAutoresizingMaskIntoConstraints = false
        howItWorks.font = .preferredFont(forTextStyle: .callout)
        howItWorks.adjustsFontForContentSizeCategory = true
        howItWorks.text = .localized(.howItWorks)
        return howItWorks
    }
    
    func makeHowItWorksIcon() -> UIImageView {
        let howItWorksIcon = UIImageView()
        howItWorksIcon.translatesAutoresizingMaskIntoConstraints = false
        howItWorksIcon.contentMode = .center
        howItWorksIcon.clipsToBounds = true
        return howItWorksIcon
    }    
}


extension MyImpactCell {
    
    // MARK: - Search section container view and components
    
    func makeYourSearchesContainerStackView() -> UIStackView {
        let searchesStackView = UIStackView()
        searchesStackView.translatesAutoresizingMaskIntoConstraints = false
        searchesStackView.axis = .horizontal
        searchesStackView.distribution = .fill
        searchesStackView.alignment = .center
        searchesStackView.spacing = UX.SearchAndFriends.stackViewSpacing
        return searchesStackView
    }
    
    func makeYourSearchesIcon() -> UIImageView {
        let searchesIcon = UIImageView()
        searchesIcon.translatesAutoresizingMaskIntoConstraints = false
        searchesIcon.contentMode = .center
        searchesIcon.clipsToBounds = true
        searchesIcon.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        searchesIcon.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return searchesIcon
    }
    
    func makeYourSearchesLabel() -> UILabel {
        let searches = UILabel()
        searches.translatesAutoresizingMaskIntoConstraints = false
        searches.font = .preferredFont(forTextStyle: .body)
        searches.adjustsFontForContentSizeCategory = true
        searches.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return searches
    }
    
    func makeSearchesTreesLabel() -> UILabel {
        let searchesTrees = UILabel()
        searchesTrees.translatesAutoresizingMaskIntoConstraints = false
        searchesTrees.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .subheadline).pointSize, weight: .semibold)
        searchesTrees.adjustsFontForContentSizeCategory = true
        searchesTrees.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        searchesTrees.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return searchesTrees
    }
    
    func makeSearchesImpactIcon() -> UIImageView {
        let searchesImpact = UIImageView()
        searchesImpact.translatesAutoresizingMaskIntoConstraints = false
        searchesImpact.contentMode = .center
        searchesImpact.clipsToBounds = true
        searchesImpact.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        searchesImpact.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return searchesImpact
    }
}

extension MyImpactCell {
    
    // MARK: - Friends section container view and components

    func makeFriendsImpactContainerStackView() -> UIStackView {
        let friendsImpactContainerStackView = UIStackView()
        friendsImpactContainerStackView.translatesAutoresizingMaskIntoConstraints = false
        friendsImpactContainerStackView.axis = .horizontal
        friendsImpactContainerStackView.distribution = .fill
        friendsImpactContainerStackView.alignment = .center
        friendsImpactContainerStackView.spacing = UX.SearchAndFriends.stackViewSpacing
        return friendsImpactContainerStackView
    }
    
    func makeFriendsIcon() -> UIImageView {
        let friendsIcon = UIImageView()
        friendsIcon.translatesAutoresizingMaskIntoConstraints = false
        friendsIcon.contentMode = .center
        friendsIcon.clipsToBounds = true
        friendsIcon.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        friendsIcon.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return friendsIcon
    }
    
    func makeFriendsLabel() -> UILabel {
        let friends = UILabel()
        friends.translatesAutoresizingMaskIntoConstraints = false
        friends.font = .preferredFont(forTextStyle: .body)
        friends.adjustsFontForContentSizeCategory = true
        friends.numberOfLines = UX.SearchAndFriends.maximumNumberOfLines
        friends.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return friends
    }
    
    func makeFriendsTreesLabel() -> UILabel {
        let friendsTrees = UILabel()
        friendsTrees.translatesAutoresizingMaskIntoConstraints = false
        friendsTrees.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .subheadline).pointSize, weight: .semibold)
        friendsTrees.adjustsFontForContentSizeCategory = true
        friendsTrees.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        friendsTrees.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return friendsTrees
    }
    
    func makeFriendsImpactIcon() -> UIImageView {
        let friendsImpact = UIImageView()
        friendsImpact.translatesAutoresizingMaskIntoConstraints = false
        friendsImpact.contentMode = .center
        friendsImpact.clipsToBounds = true
        friendsImpact.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        friendsImpact.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return friendsImpact
    }
}

extension MyImpactCell {
    
    // MARK: - Friends and Friends container view
    
    func makeSearchAndYourFriendsImpactContainerStackView() -> UIStackView {
        let searchAndFriendsStackView = UIStackView()
        searchAndFriendsStackView.translatesAutoresizingMaskIntoConstraints = false
        searchAndFriendsStackView.alignment = .fill
        searchAndFriendsStackView.axis = .vertical
        searchAndFriendsStackView.spacing = UIStackView.spacingUseDefault
        return searchAndFriendsStackView
    }
}
