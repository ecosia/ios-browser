// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Core
import Common

protocol NTPOnboardingCardCellDelegate: AnyObject {
    func onboardingCardClick()
    func onboardingCardDismiss()
}

final class NTPOnboardingCardCellViewModel {
    weak var delegate: NTPOnboardingCardCellDelegate?
    var theme: Theme
    
    init(delegate: NTPOnboardingCardCellDelegate? = nil, theme: Theme) {
        self.delegate = delegate
        self.theme = theme
    }
}

extension NTPOnboardingCardCellViewModel: HomepageViewModelProtocol {
    func setTheme(theme: Theme) {
        self.theme = theme
    }

    var sectionType: HomepageSectionType {
        return .onboardingCard
    }

    var headerViewModel: LabelButtonHeaderViewModel {
        return .emptyHeader
    }

    func section(for traitCollection: UITraitCollection, size: CGSize) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .estimated(128)) // TODO: Make cell automatically size it's height
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

        let section = NSCollectionLayoutSection(group: group)

        section.contentInsets = sectionType.sectionInsets(traitCollection, bottomSpacing: 8)

        return section
    }

    func numberOfItemsInSection() -> Int {
        return 1
    }

    var isEnabled: Bool {
//        OnboardingCardNTPExperiment.shouldShowCard
        true // TODO: Why is there a `UICollectionViewCompositionalLayout` whenever this is false?
    }
}

extension NTPOnboardingCardCellViewModel: HomepageSectionHandler {

    func configure(_ cell: UICollectionViewCell, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = cell as? NTPOnboardingCardCell else { return UICollectionViewCell() }
        cell.delegate = delegate
        return cell
    }

    func didSelectItem(at indexPath: IndexPath, homePanelDelegate: HomePanelDelegate?, libraryPanelDelegate: LibraryPanelDelegate?) {}
}
