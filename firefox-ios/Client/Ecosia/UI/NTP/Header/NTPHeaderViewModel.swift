// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import SwiftUI
import Ecosia

final class NTPHeaderViewModel: ObservableObject {
    struct UX {
        static let topInset: CGFloat = 24
    }

    // MARK: - Properties
    internal weak var delegate: NTPHeaderDelegate?
    internal var theme: Theme
    private let windowUUID: WindowUUID
    let profile: Profile
    private(set) var auth: EcosiaAuth
    var onTapAction: ((UIButton) -> Void)?

    // Use centralized auth state provider for consistency
    private let authStateProvider = EcosiaAuthUIStateProvider.shared

    // Computed properties that delegate to the centralized provider
    var seedCount: Int { authStateProvider.seedCount }
    var isLoggedIn: Bool { authStateProvider.isLoggedIn }
    var userAvatarURL: URL? { authStateProvider.avatarURL }
    var balanceIncrement: Int? { authStateProvider.balanceIncrement }

    // MARK: - Initialization
    init(profile: Profile,
         theme: Theme,
         windowUUID: WindowUUID,
         auth: EcosiaAuth,
         delegate: NTPHeaderDelegate? = nil) {
        self.profile = profile
        self.theme = theme
        self.windowUUID = windowUUID
        self.auth = auth
        self.delegate = delegate
    }

    // MARK: - Public Methods

    func openAISearch() {
        delegate?.headerOpenAISearch()
        Analytics.shared.aiSearchNTPButtonTapped()
    }

    func performLogin() {
        auth.login()
    }

    func performLogout() {
        EcosiaLogger.auth.info("Performing immediate logout without confirmation")
        auth.logout()
    }
}

extension NTPHeaderViewModel {

    /// Delegates to the centralized auth state provider
    func registerVisitIfNeeded() {
        // The centralized provider handles this automatically on login
        // This method is kept for backward compatibility but does nothing
    }
}

// MARK: HomeViewModelProtocol
extension NTPHeaderViewModel: HomepageViewModelProtocol, FeatureFlaggable {
    var sectionType: HomepageSectionType {
        return .header
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
        return true
    }

    func setTheme(theme: Theme) {
        self.theme = theme
    }

    func refreshData(for traitCollection: UITraitCollection, size: CGSize, isPortrait: Bool, device: UIUserInterfaceIdiom) {
        // No data refresh needed for multi-purpose header
    }
}

extension NTPHeaderViewModel: HomepageSectionHandler {

    func configure(_ cell: UICollectionViewCell, at indexPath: IndexPath) -> UICollectionViewCell {
        if #available(iOS 16.0, *) {
            guard let headerCell = cell as? NTPHeader else { return cell }
            headerCell.configure(with: self, windowUUID: windowUUID)
            return headerCell
        }
        return cell
    }

    func didSelectItem(at indexPath: IndexPath, homePanelDelegate: HomePanelDelegate?, libraryPanelDelegate: LibraryPanelDelegate?) {
        // This cell handles its own button actions, no cell selection needed
    }
}
