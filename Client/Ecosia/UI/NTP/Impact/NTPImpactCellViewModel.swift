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
        var firstSection: [ClimateImpactInfo] = [invitesInfo]
        if !Unleash.isEnabled(.incentiveRestrictedSearch) {
            firstSection.insert(personalCounterInfo,
                                at: 0)
        }
        let secondSection: [ClimateImpactInfo] = [totalTreesInfo, totalInvestedInfo]
        return [firstSection, secondSection]
    }
    var invitesInfo: ClimateImpactInfo {
        .invites(value: User.shared.referrals.count)
    }
    var personalCounterInfo: ClimateImpactInfo {
        .personalCounter(value: User.shared.impact,
                         searches: personalCounter.state ?? User.shared.treeCount)
    }
    var totalTreesInfo: ClimateImpactInfo {
        .totalTrees(value: TreesProjection.shared.treesAt(.init()))
    }
    var totalInvestedInfo: ClimateImpactInfo {
        .totalInvested(value: InvestmentsProjection.shared.totalInvestedAt(.init()))
    }

    private let personalCounter = PersonalCounter()
    private var cells = [Int:NTPImpactCell]()
    private let referrals: Referrals
    init(referrals: Referrals) {
        self.referrals = referrals
        
        referrals.subscribe(self) { [weak self] _ in
            guard let self = self else { return }
            self.refreshCell(withInfo: self.invitesInfo)
        }
        
        personalCounter.subscribe(self) { [weak self] _ in
            guard let self = self else { return }
            self.refreshCell(withInfo: self.personalCounterInfo)
        }
    }
    
    deinit {
        referrals.unsubscribe(self)
        personalCounter.unsubscribe(self)
    }

    func subscribeToProjections() {
        guard !UIAccessibility.isReduceMotionEnabled else {
            refreshCell(withInfo: totalTreesInfo)
            refreshCell(withInfo: totalInvestedInfo)
            return
        }

        TreesProjection.shared.subscribe(self) { [weak self] _ in
            guard let self = self else { return }
            self.refreshCell(withInfo: self.totalTreesInfo)
        }
        
        InvestmentsProjection.shared.subscribe(self) { [weak self] _ in
            guard let self = self else { return }
            self.refreshCell(withInfo: self.totalInvestedInfo)
        }
    }

    func unsubscribeToProjections() {
        TreesProjection.shared.unsubscribe(self)
        InvestmentsProjection.shared.unsubscribe(self)
    }
    
    func refreshCell(withInfo info: ClimateImpactInfo) {
        let indexForInfo = infoItemSections.firstIndex { $0.contains(where: { $0 == info }) }
        guard let index = indexForInfo else { return }
        cells[index]?.refresh(items: infoItemSections[index])
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
                                              heightDimension: .estimated(NTPImpactCell.UX.estimatedHeight))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .estimated(NTPImpactCell.UX.estimatedHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

        let section = NSCollectionLayoutSection(group: group)

        section.contentInsets = sectionType.sectionInsets(traitCollection, bottomSpacing: 0)
        
        var supplementaryItems = [NSCollectionLayoutBoundarySupplementaryItem]()
        
        if NTPTooltip.highlight(for: User.shared, isInPromoTest: DefaultBrowserExperiment.isInPromoTest()) != nil {
            supplementaryItems.append(
                .init(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                        heightDimension: .absolute(1)),
                      elementKind: UICollectionView.elementKindSectionHeader,
                      alignment: .top)
            )
        } else {
            supplementaryItems.append(
                .init(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                        heightDimension: .estimated(100)),
                      elementKind: UICollectionView.elementKindSectionHeader,
                      alignment: .top)
            )
        }
        
        supplementaryItems.append(
            .init(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                    heightDimension: .estimated(NTPImpactDividerFooter.UX.estimatedHeight)),
                  elementKind: UICollectionView.elementKindSectionFooter,
                  alignment: .bottom)
        )
        section.boundarySupplementaryItems = supplementaryItems
        
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
        cell.configure(items: items)
        cell.delegate = delegate
        cells[indexPath.row] = cell
        return cell
    }
}
