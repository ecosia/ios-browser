// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import SwiftUI
import Ecosia

final class NTPMultiPurposeEcosiaHeaderViewModel: ObservableObject {
    struct UX {
        static let topInset: CGFloat = 24
    }

    // MARK: - Properties
    private let windowUUID: WindowUUID
    internal weak var delegate: NTPMultiPurposeEcosiaHeaderDelegate?
    internal var theme: Theme

    // MARK: - Initialization
    init(theme: Theme,
         windowUUID: WindowUUID,
         delegate: NTPMultiPurposeEcosiaHeaderDelegate? = nil) {
        self.theme = theme
        self.windowUUID = windowUUID
        self.delegate = delegate
    }

    // MARK: - Public Methods

    func openAISearch() {
        delegate?.multiPurposeEcosiaHeaderDidRequestAISearch()
        Analytics.shared.aiSearchNTPButtonTapped()
    }
}

// MARK: HomeViewModelProtocol
extension NTPMultiPurposeEcosiaHeaderViewModel: HomepageViewModelProtocol, FeatureFlaggable {
    var sectionType: HomepageSectionType {
        return .multiPurposeEcosiaHeader
    }

    var headerViewModel: LabelButtonHeaderViewModel {
        return .emptyHeader
    }

    func section(for traitCollection: UITraitCollection, size: CGSize) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                              heightDimension: .estimated(64))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .estimated(64))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

        let section = NSCollectionLayoutSection(group: group)

        section.contentInsets = NSDirectionalEdgeInsets(
            top: UX.topInset,
            leading: 0,
            bottom: 0,
            trailing: 0)

        return section
    }

    func numberOfItemsInSection() -> Int {
        return 1
    }

    var isEnabled: Bool {
        AISearchMVPExperiment.isEnabled
    }

    func setTheme(theme: Theme) {
        self.theme = theme
    }

    func refreshData(for traitCollection: UITraitCollection, size: CGSize, isPortrait: Bool, device: UIUserInterfaceIdiom) {
        // No data refresh needed for multi-purpose header
    }
}

extension NTPMultiPurposeEcosiaHeaderViewModel: HomepageSectionHandler {

    func configure(_ cell: UICollectionViewCell, at indexPath: IndexPath) -> UICollectionViewCell {
        if #available(iOS 16.0, *) {
            guard let multiPurposeHeaderCell = cell as? NTPMultiPurposeEcosiaHeader else { return cell }
            multiPurposeHeaderCell.configure(with: self, windowUUID: windowUUID)
            return multiPurposeHeaderCell
        }
        return cell
    }

    func didSelectItem(at indexPath: IndexPath, homePanelDelegate: HomePanelDelegate?, libraryPanelDelegate: LibraryPanelDelegate?) {
        // This cell handles its own button actions, no cell selection needed
    }
}
