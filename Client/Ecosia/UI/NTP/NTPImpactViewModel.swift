// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Core

class NTPImpactViewModel {
    struct UX {
        static let bottomSpacing: CGFloat = 12
    }

    private let personalCounter: PersonalCounter

    init(personalCounter: PersonalCounter) {
        self.personalCounter = personalCounter
    }

    var treesCellModel: NTPImpactCell.Model {
        .init(impact: User.shared.impact, searches: personalCounter.state!, trees: TreeCounter.shared.statistics.treesAt(.init()))
    }

    weak var cell: NTPImpactCell?

    func startCounter() {
        guard !UIAccessibility.isReduceMotionEnabled else {
            cell?.display(treesCellModel, animated: false)
            return
        }

        TreeCounter.shared.subscribe(self) { [weak self] count in
            guard let cell = self?.cell, let model = self?.treesCellModel else { return }
            cell.display(model, animated: true)
        }
    }

    func stopCounter() {
        TreeCounter.shared.unsubscribe(self)
    }
}

// MARK: HomeViewModelProtocol
extension NTPImpactViewModel: HomepageViewModelProtocol {

    var sectionType: HomepageSectionType {
        return .impact
    }

    var headerViewModel: LabelButtonHeaderViewModel {
        return .emptyHeader
    }

    func section(for traitCollection: UITraitCollection) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .estimated(200.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .estimated(200.0))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

        let section = NSCollectionLayoutSection(group: group)

        let insets = sectionType.sectionInsets(traitCollection)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: insets,
            bottom: UX.bottomSpacing,
            trailing: insets)

        // Adding a header if needed
        if NTPTooltip.highlight(for: User.shared, isInPromoTest: DefaultBrowserExperiment.isInPromoTest())?.text != nil {
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                    heightDimension: .absolute(1.0))
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top)
            section.boundarySupplementaryItems = [header]
        }
        return section
    }

    func numberOfItemsInSection() -> Int {
        return 1
    }

    var isEnabled: Bool {
        true
    }

    func refreshData(for traitCollection: UITraitCollection,
                     isPortrait: Bool = UIWindow.isPortrait,
                     device: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom) {}

}

extension NTPImpactViewModel: HomepageSectionHandler {

    func configure(_ cell: UICollectionViewCell, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = cell as? NTPImpactCell else { return UICollectionViewCell() }
        cell.display(treesCellModel, animated: false)
        self.cell = cell
        return cell
    }

    func didSelectItem(at indexPath: IndexPath, homePanelDelegate: HomePanelDelegate?, libraryPanelDelegate: LibraryPanelDelegate?) {
        homePanelDelegate?.homePanelDidRequestToOpenImpact()
    }
}