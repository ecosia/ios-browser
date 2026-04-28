// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Ecosia
import Common

@MainActor
protocol NTPImpactCellDelegate: AnyObject {
    func impactCellButtonClickedWithInfo(_ info: ClimateImpactInfo)
}

@MainActor final class NTPImpactCellViewModel {
    weak var delegate: NTPImpactCellDelegate?

    // Cache for async-computed values
    private var cachedTotalInvested: Int = 0
    private var cachedTotalTrees: Int = 0

    // Rotating USP title fetched from the CDN; nil until the first fetch completes (fallback shown).
    private(set) var rotatingTitle: String?

    var impactItems: [ClimateImpactInfo] {
        [totalTreesInfo, totalInvestedInfo]
    }
    var referralInfo: ClimateImpactInfo {
        .referral(value: User.shared.referrals.count)
    }
    var totalTreesInfo: ClimateImpactInfo {
        .totalTrees(value: cachedTotalTrees)
    }
    var totalInvestedInfo: ClimateImpactInfo {
        .totalInvested(value: cachedTotalInvested)
    }

    private func updateCachedTotalTrees() {
        Task { @MainActor in
            self.cachedTotalTrees = await TreesProjection.shared.treesAt(.init())
        }
    }

    private func updateCachedTotalInvested() {
        Task { @MainActor in
            self.cachedTotalInvested = await InvestmentsProjection.shared.totalInvestedAt(.init())
        }
    }

    private var cells = [Int: NTPImpactCell]()
    private let referrals: Referrals

    var theme: Theme

    init(referrals: Referrals, theme: Theme) {
        self.referrals = referrals
        self.theme = theme

        referrals.subscribe(self) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.refreshCell(withInfo: self.referralInfo)
            }
        }
    }

    deinit {
        // Note: referrals.unsubscribe(self) is @MainActor; cannot call from deinit.
        // Subscription closure uses [weak self] so no retain cycle.
    }

    // Fetch rotating title from CDN and cache it; fires once per session.
    private func fetchRotatingTitle() {
        Task { @MainActor in
            rotatingTitle = await RotatingTitlesService.shared.titles().first
            cells[0]?.updateTitle(rotatingTitle)
        }
    }

    func start() {
        updateCachedTotalTrees()
        updateCachedTotalInvested()
        fetchRotatingTitle()

        guard !UIAccessibility.isReduceMotionEnabled else {
            Task { @MainActor in
                async let trees = TreesProjection.shared.treesAt(.init())
                async let invested = InvestmentsProjection.shared.totalInvestedAt(.init())
                self.cachedTotalTrees = await trees
                self.cachedTotalInvested = await invested
                self.refreshCell(withInfo: self.totalTreesInfo)
                self.refreshCell(withInfo: self.totalInvestedInfo)
            }
            return
        }

        TreesProjection.shared.subscribe(self) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.updateCachedTotalTrees()
                self.refreshCell(withInfo: self.totalTreesInfo)
            }
        }

        InvestmentsProjection.shared.subscribe(self) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.updateCachedTotalInvested()
                self.refreshCell(withInfo: self.totalInvestedInfo)
            }
        }
    }

    func stop() {
        TreesProjection.shared.unsubscribe(self)
        InvestmentsProjection.shared.unsubscribe(self)
    }

    func refreshCell(withInfo info: ClimateImpactInfo) {
        guard impactItems.contains(where: { $0 == info }) else { return }
        cells[0]?.refresh(items: impactItems)
    }

    /// Registers a cell so it can be refreshed when projection data updates (e.g. trees planted).
    /// Call this when configuring the cell in the collection view data source.
    func registerCell(_ cell: NTPImpactCell, forSectionIndex index: Int) {
        cells[index] = cell
    }
}

/* Ecosia: Removed legacy protocol conformances - now using EcosiaHomepageAdapter
// MARK: HomeViewModelProtocol
extension NTPImpactCellViewModel: HomepageViewModelProtocol {

    func setTheme(theme: Theme) {
        self.theme = theme
    }

    var sectionType: HomepageSectionType {
        .impact
    }

    var headerViewModel: LabelButtonHeaderViewModel {
        .emptyHeader
    }

    func section(for traitCollection: UITraitCollection, size: CGSize) -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(widthDimension: .fractionalWidth(1),
                              heightDimension: .estimated(200))
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(widthDimension: .fractionalWidth(1),
                              heightDimension: .estimated(200)),
            subitem: item,
            count: 1
        )
        let section = NSCollectionLayoutSection(group: group)

        section.contentInsets = sectionType.sectionInsets(traitCollection, bottomSpacing: 0)

        var supplementaryItems = [NSCollectionLayoutBoundarySupplementaryItem]()
        if NTPTooltip.highlight() != nil {
            supplementaryItems.append(
                .init(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                        heightDimension: .absolute(1)),
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
        1
    }

    var isEnabled: Bool {
        User.shared.showClimateImpact
    }
}

extension NTPImpactCellViewModel: HomepageSectionHandler {

    func configure(_ cell: UICollectionViewCell, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = cell as? NTPImpactCell else { return UICollectionViewCell() }
        cell.configure(items: impactItems, title: rotatingTitle, delegate: delegate, theme: theme)
        cells[0] = cell
        return cell
    }
}
*/
