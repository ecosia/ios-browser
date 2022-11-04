// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Core

class NTPNewsViewModel {
    struct UX {
        static let bottomSpacing: CGFloat = 12
    }

    private let news = News()
    private (set) var items = [NewsWrapper]()
    private let images = Images(.init(configuration: .ephemeral))
    private let goodall = Goodall.shared
    weak var delegate: HomepageDataModelDelegate?

    init() {
        news.subscribeAndReceive(self) { [weak self] in
            guard let self = self else { return }
            self.items = $0.map({ NewsWrapper(model: $0, promo: nil) })

            if let promo = Promo.current(for: .shared, using: .shared) {
                self.items.insert(.init(model: nil, promo: promo), at: 0)
            }

            self.delegate?.reloadView()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(localeDidChange), name: NSLocale.currentLocaleDidChangeNotification, object: nil)

    }

    @objc func localeDidChange() {
        Goodall.shared.refresh(force: true)
    }

}

// MARK: HomeViewModelProtocol
extension NTPNewsViewModel: HomepageViewModelProtocol {
    var isEnabled: Bool {
        true
    }

    var sectionType: HomepageSectionType {
        return .news
    }

    var headerViewModel: LabelButtonHeaderViewModel {
        return LabelButtonHeaderViewModel(title: .localized(.stories), isButtonHidden: true)
    }

    func section(for traitCollection: UITraitCollection) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                              heightDimension: .estimated(100))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .estimated(100))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

        let section = NSCollectionLayoutSection(group: group)

        let insets = sectionType.sectionInsets(traitCollection)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: insets,
            bottom: UX.bottomSpacing,
            trailing: insets)

        let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                          heightDimension: .estimated(100.0))
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: size,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top)
        let footer = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: size,
            elementKind: UICollectionView.elementKindSectionFooter,
            alignment: .bottom)
        section.boundarySupplementaryItems = [header, footer]
        return section
    }

    func numberOfItemsInSection() -> Int {
        let num = Promo.isEnabled(for: .shared, using: .shared) ? 4 : 3
        return min(num, items.count)
    }

    var hasData: Bool {
        numberOfItemsInSection() > 0
    }

    func refreshData(for traitCollection: UITraitCollection,
                     isPortrait: Bool = UIWindow.isPortrait,
                     device: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom) {

        news.load(session: .shared, force: !hasData)
    }

}

extension NTPNewsViewModel: HomepageSectionHandler {

    func configure(_ cell: UICollectionViewCell, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = cell as? NewsCell else { return UICollectionViewCell() }
        let itemCount = numberOfItemsInSection()
        cell.defaultBackgroundColor = { .theme.ecosia.ntpImpactBackground }
        cell.configure(items[indexPath.row], images: images, positions: .derive(row: indexPath.row, items: itemCount))
        return cell
    }

    func didSelectItem(at indexPath: IndexPath, homePanelDelegate: HomePanelDelegate?, libraryPanelDelegate: LibraryPanelDelegate?) {

        let index = indexPath.row
        guard index >= 0, items.count > index else { return }
        Analytics.shared.navigationOpenNews(items[index].trackingName)
        homePanelDelegate?.homePanel(didSelectURL: items[index].targetUrl, visitType: .link, isGoogleTopSite: false)
    }
}

struct NewsWrapper {
    let model: NewsModel?
    let promo: Core.Promo?

    var trackingName: String {
        return model?.trackingName ?? promo!.trackingName
    }

    var targetUrl: URL {
        return model?.targetUrl ?? promo!.targetUrl
    }

    var text: String {
        return model?.text ?? promo!.text
    }
}

extension Core.Promo {
    static func current(for user: User, using goodall: Goodall) -> Promo? {
        guard let variant = Promo.variant(for: .shared, using: .shared) else { return nil }
        switch variant {
        case .control:
            return .treeStore
        case .test:
            return .treeCard
        }
    }

    static var treeStore: Core.Promo {
        .init(text: "Buy trees in the Ecosia tree store to delight a friend - or treat yourself",
              image: "treeStore",
              icon: "treestore_logo",
              highlight:nil,
              description: "Tree store",
              targetUrl: URL(string: "https://plant.ecosia.org/?utm_source=referral&utm_medium=product&utm_campaign=q4e1_ios_app_ntp")!,
              trackingName: "ios_tree_store")
    }

    static var treeCard: Core.Promo {
        .init(text: "Plant trees and earn eco-friendly rewards with Treecard",
              image: "treeCard",
              icon: "treecard_logo",
              highlight: "Sponsored" + " ·",
              description: "Tree card",
              targetUrl: URL(string: "https://www.treecard.org/ecosia")!,
              trackingName: "ios_tree_card")
    }
}
