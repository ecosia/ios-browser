// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Core

protocol NTPImpactCellDelegate: AnyObject {
    func impactCellButtonAction(info: ClimateImpactInfo)
}

class NTPImpactCellViewModel {
    weak var delegate: NTPImpactCellDelegate?
    var infoItemSections: [[ClimateImpactInfo]] {
        var firstSection: [ClimateImpactInfo] = [
            .invites(value: User.shared.referrals.count)
        ]
        if !Unleash.isEnabled(.incentiveRestrictedSearch) {
            firstSection.insert(.personalCounter(value: User.shared.impact,
                                                 // TODO: Use PersonalCounter
                                                 searches: User.shared.treeCount),
                                at: 0)
        }
        let secondSection: [ClimateImpactInfo] = [
            .totalTrees(value: TreeCounter.shared.treesAt(.init())),
            .totalInvested(value: 123456789101112) // TODO: Fetch dynamically
        ]
        return [firstSection, secondSection]
    }

    private var cells = [Int:NTPImpactCell]()
    func refreshCells() {
        // TODO: Refresh only relevant content
        cells.forEach { (index, cell) in
            cell.refresh(items: infoItemSections[index])
        }
    }

    func startCounter() {
        guard !UIAccessibility.isReduceMotionEnabled else {
            refreshCells()
            return
        }

        TreeCounter.shared.subscribe(self) { [weak self] _ in
            self?.refreshCells()
        }
    }

    func stopCounter() {
        TreeCounter.shared.unsubscribe(self)
    }
}

// MARK: HomeViewModelProtocol
extension NTPImpactCellViewModel: HomepageViewModelProtocol {

    var sectionType: HomepageSectionType {
        .impact
    }

    var headerViewModel: LabelButtonHeaderViewModel {
        .init(title: .localized(.climateImpact), isButtonHidden: true)
    }

    func section(for traitCollection: UITraitCollection) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                              heightDimension: .estimated(192))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .estimated(192))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

        let section = NSCollectionLayoutSection(group: group)

        section.contentInsets = sectionType.sectionInsets(traitCollection)
        
        if NTPTooltip.highlight(for: User.shared, isInPromoTest: DefaultBrowserExperiment.isInPromoTest()) != nil {
            section.boundarySupplementaryItems = [
                .init(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                        heightDimension: .absolute(1)),
                      elementKind: UICollectionView.elementKindSectionHeader,
                      alignment: .top)
            ]
        } else {
            section.boundarySupplementaryItems = [
                .init(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                        heightDimension: .estimated(100)),
                      elementKind: UICollectionView.elementKindSectionHeader,
                      alignment: .top)
            ]
        }
        
        return section
    }

    func numberOfItemsInSection() -> Int {
        return infoItemSections.count
    }

    var isEnabled: Bool {
        User.shared.showClimateImpact
    }
}

extension NTPImpactCellViewModel: HomepageSectionHandler {

    func configure(_ cell: UICollectionViewCell, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = cell as? NTPImpactCell else { return UICollectionViewCell() }
        let items = infoItemSections[indexPath.row]
        cell.configure(items: items, addBottomDivider: indexPath.row == (infoItemSections.count - 1))
        cell.delegate = delegate
        cells[indexPath.row] = cell
        return cell
    }
}
