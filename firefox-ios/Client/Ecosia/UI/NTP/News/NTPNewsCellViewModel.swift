// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common
import Ecosia

@MainActor
protocol NTPNewsCellDelegate: AnyObject {
    func openSeeAllNews()
}

@MainActor
final class NTPNewsCellViewModel {
    private let news = News()
    private(set) var items = [NewsModel]()
    private let images = Images(.init(configuration: .ephemeral))
    weak var delegate: NTPNewsCellDelegate?
    weak var dataModelDelegate: HomepageDataModelDelegate?
    var theme: Theme

    init(delegate: NTPNewsCellDelegate? = nil, theme: Theme) {
        self.delegate = delegate
        self.theme = theme
        news.subscribeAndReceive(self) { [weak self] newItems in
            Task { @MainActor in
                guard let self else { return }
                self.items = newItems
                self.dataModelDelegate?.reloadView()
            }
        }
    }
}

/* Ecosia: Removed legacy protocol conformances - now using EcosiaHomepageAdapter
// MARK: HomeViewModelProtocol
extension NTPNewsCellViewModel: HomepageViewModelProtocol {

    func setTheme(theme: Theme) {
        self.theme = theme
    }

    var isEnabled: Bool {
        User.shared.showEcosiaNews
    }

    var sectionType: HomepageSectionType {
        return .news
    }

    var headerViewModel: LabelButtonHeaderViewModel {
        .init(title: .localized(.ecosiaNews),
              titleA11yIdentifier: "ecosia_news",
              isButtonHidden: false,
              buttonTitle: .localized(.seeAll),
              buttonAction: { [weak self] _ in self?.delegate?.openSeeAllNews()
              },
              buttonA11yIdentifier: "see_all")
    }

    func section(for traitCollection: UITraitCollection, size: CGSize) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .estimated(100.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .estimated(300.0))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

        let section = NSCollectionLayoutSection(group: group)

        section.contentInsets = sectionType.sectionInsets(traitCollection)

        let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                          heightDimension: .estimated(100.0))
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: size,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top)
        section.boundarySupplementaryItems = [header]
        return section
    }

    func numberOfItemsInSection() -> Int {
        return min(3, items.count)
    }

    var hasData: Bool {
        numberOfItemsInSection() > 0
    }

    func refreshData(for traitCollection: UITraitCollection, size: CGSize, isPortrait: Bool, device: UIUserInterfaceIdiom) {
        news.load(session: .shared, force: !hasData)
    }
}

extension NTPNewsCellViewModel: HomepageSectionHandler {

    func configure(_ cell: UICollectionViewCell, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = cell as? NTPNewsCell else { return UICollectionViewCell() }
        let itemCount = numberOfItemsInSection()
        cell.configure(items[indexPath.row], images: images, row: indexPath.row, totalCount: itemCount)
        cell.applyTheme(theme: theme)
        return cell
    }

    func didSelectItem(at indexPath: IndexPath, homePanelDelegate: HomePanelDelegate?, libraryPanelDelegate: LibraryPanelDelegate?) {

        let index = indexPath.row
        guard index >= 0, items.count > index else { return }
        let item = items[index]
        homePanelDelegate?.homePanel(didSelectURL: item.targetUrl, visitType: .link, isGoogleTopSite: false)
        Analytics.shared.navigationOpenNews(item.trackingName)
    }
}
*/// MARK: - Public Methods for Adapter

extension NTPNewsCellViewModel {
    var numberOfItemsInSection: Int {
        return min(3, items.count)
    }
    
    var hasData: Bool {
        numberOfItemsInSection > 0
    }
    
    func refreshData(for traitCollection: UITraitCollection, size: CGSize, isPortrait: Bool, device: UIUserInterfaceIdiom) {
        news.load(session: .shared, force: !hasData)
    }
}
