// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import SwiftUI

final class NTPAccountLoginViewModel: ObservableObject {
    struct UX {
        static let topInset: CGFloat = 24
    }

    // MARK: - Published Properties
    @Published var seedCount: Int = 1
    @Published var isLoggedIn: Bool = false
    @Published var userAvatarURL: URL?
    
    // MARK: - Private Properties
    private let profile: Profile
    private(set) var auth: EcosiaAuth
    private let windowUUID: WindowUUID
    private var authStateObserver: NSObjectProtocol?
    weak var delegate: NTPSeedCounterDelegate?
    var onTapAction: ((UIButton) -> Void)?
    var theme: Theme
    
    // MARK: - Initialization
    init(profile: Profile,
         theme: Theme,
         auth: EcosiaAuth,
         windowUUID: WindowUUID) {
        self.profile = profile
        self.auth = auth
        self.theme = theme
        self.windowUUID = windowUUID
        
        // Initialize auth state
        updateAuthState()
        
        // Set up auth state monitoring
        setupAuthStateMonitoring()
    }
    
    deinit {
        // Remove notification observer
        if let observer = authStateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Public Methods
    
    func updateSeedCount(_ count: Int) {
        seedCount = count
    }
    
    func performLogin() {
        auth.login()
    }
    
    func performLogout() {
        auth.logout()
    }
    
    // MARK: - Private Methods
    
    private func updateAuthState() {
        isLoggedIn = auth.isLoggedIn
        
        // TODO: Get user avatar URL from EcosiaAuth when available
        // For now, using placeholder
        userAvatarURL = nil
    }
    
    private func setupAuthStateMonitoring() {
        NotificationCenter.default.addObserver(
            forName: .EcosiaAuthStateChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateAuthState()
        }
    }
}

// MARK: HomeViewModelProtocol
extension NTPAccountLoginViewModel: HomepageViewModelProtocol, FeatureFlaggable {
    var sectionType: HomepageSectionType {
        return .accountLogin
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
        true
    }

    func setTheme(theme: Theme) {
        self.theme = theme
    }
}

extension NTPAccountLoginViewModel: HomepageSectionHandler {

    func configure(_ cell: UICollectionViewCell, at indexPath: IndexPath) -> UICollectionViewCell {
        if #available(iOS 16.0, *) {
            guard let accountLoginCell = cell as? NTPAccountLoginCell else { return cell }
            accountLoginCell.configure(with: self, windowUUID: windowUUID)
            return accountLoginCell
        }
        return cell
    }
}
