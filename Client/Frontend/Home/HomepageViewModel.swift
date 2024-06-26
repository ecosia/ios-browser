// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Core

protocol HomepageViewModelDelegate: AnyObject {
    func reloadView()
}

protocol HomepageDataModelDelegate: AnyObject {
    func reloadView()
}

class HomepageViewModel: FeatureFlaggable, NTPLayoutHighlightDataSource {

    struct UX {
        static let spacingBetweenSections: CGFloat = 32
        static let standardInset: CGFloat = 16 // Ecosia: update value
        static let iPadInset: CGFloat = 50
        static let iPadTopSiteInset: CGFloat = 25

        static func leadingInset(traitCollection: UITraitCollection) -> CGFloat {
            guard UIDevice.current.userInterfaceIdiom != .phone else { return standardInset }

            // Handles multitasking on iPad
            return traitCollection.horizontalSizeClass == .regular ? iPadInset : standardInset
        }

        static func topSiteLeadingInset(traitCollection: UITraitCollection) -> CGFloat {
            guard UIDevice.current.userInterfaceIdiom != .phone else { return 0 }

            // Handles multitasking on iPad
            return traitCollection.horizontalSizeClass == .regular ? iPadTopSiteInset : 0
        }
    }

    // MARK: - Properties

    // Privacy of home page is controlled through notifications since tab manager selected tab
    // isn't always the proper privacy mode that should be reflected on the home page
    var isPrivate: Bool {
        didSet {
            childViewModels.forEach {
                $0.updatePrivacyConcernedSection(isPrivate: isPrivate)
            }
        }
    }

    //Ecosia: let nimbus: FxNimbus
    let profile: Profile

    var isZeroSearch: Bool {
        didSet {
            topSiteViewModel.isZeroSearch = isZeroSearch
            // Ecosia // jumpBackInViewModel.isZeroSearch = isZeroSearch
            // Ecosia // recentlySavedViewModel.isZeroSearch = isZeroSearch
            // Ecosia // pocketViewModel.isZeroSearch = isZeroSearch
        }
    }

    /// Record view appeared is sent multiple times, this avoids recording telemetry multiple times for one appearance
    private var viewAppeared: Bool = false

    var shownSections = [HomepageSectionType]()
    weak var delegate: HomepageViewModelDelegate?

    // Child View models
    private var childViewModels: [HomepageViewModelProtocol]
    var headerViewModel: HomeLogoHeaderViewModel
    var bookmarkNudgeViewModel: NTPBookmarkNudgeCellViewModel
    var libraryViewModel: NTPLibraryCellViewModel
    var topSiteViewModel: TopSitesViewModel
    var impactViewModel: NTPImpactCellViewModel
    var newsViewModel: NTPNewsCellViewModel
    var aboutEcosiaViewModel: NTPAboutEcosiaCellViewModel
    var ntpCustomizationViewModel: NTPCustomizationCellViewModel

    var shouldDisplayHomeTabBanner: Bool {
        return false // Ecoaia: return messageCardViewModel.shouldDisplayMessageCard
    }

    // MARK: - Initializers
    init(profile: Profile,
         isPrivate: Bool,
         tabManager: TabManagerProtocol,
         urlBar: URLBarViewProtocol,
         //Ecosia: remove experiments // nimbus: FxNimbus = FxNimbus.shared,
         referrals: Referrals, // Ecosia: Add referrals
         isZeroSearch: Bool = false) {
        self.profile = profile
        self.isZeroSearch = isZeroSearch

        self.headerViewModel = .init()
        self.libraryViewModel = NTPLibraryCellViewModel()
        self.bookmarkNudgeViewModel = NTPBookmarkNudgeCellViewModel()
        self.topSiteViewModel = TopSitesViewModel(profile: profile)
        self.impactViewModel = NTPImpactCellViewModel(referrals: referrals)
        self.newsViewModel = NTPNewsCellViewModel()
        self.aboutEcosiaViewModel = NTPAboutEcosiaCellViewModel()
        self.ntpCustomizationViewModel = NTPCustomizationCellViewModel()
        self.childViewModels = [headerViewModel,
                                bookmarkNudgeViewModel,
                                libraryViewModel,
                                topSiteViewModel,
                                impactViewModel,
                                newsViewModel,
                                aboutEcosiaViewModel,
                                ntpCustomizationViewModel]
        self.isPrivate = isPrivate
        topSiteViewModel.delegate = self
        newsViewModel.dataModelDelegate = self
        updateEnabledSections()
    }

    // MARK: - Interfaces

    func recordViewAppeared() {
        guard !viewAppeared else { return }

        viewAppeared = true

        if NTPTooltip.highlight() == .referralSpotlight {
            Analytics.shared.showInvitePromo()
        }
        
        if User.shared.showsBookmarksNTPNudgeCard() {
            Analytics.shared.bookmarksNtp(action: .view)
        }
        
        impactViewModel.subscribeToProjections()
    }

    func recordViewDisappeared() {
        viewAppeared = false
        impactViewModel.unsubscribeToProjections()
    }

    // MARK: - Manage sections

    func updateEnabledSections() {
        shownSections.removeAll()

        childViewModels.forEach {
            if $0.shouldShow { shownSections.append($0.sectionType) }
        }
    }

    func refreshData(for traitCollection: UITraitCollection) {
        updateEnabledSections()
        childViewModels.forEach {
            $0.refreshData(for: traitCollection, isPortrait: UIWindow.isPortrait, device: UIDevice.current.userInterfaceIdiom)
        }
    }

    // MARK: - Section ViewModel helper

    func getSectionViewModel(shownSection: Int) -> HomepageViewModelProtocol? {
        guard let actualSectionNumber = shownSections[safe: shownSection]?.rawValue else { return nil }
        return childViewModels[safe: actualSectionNumber]
    }
}

// MARK: - HomepageDataModelDelegate
extension HomepageViewModel: HomepageDataModelDelegate {
    func reloadView() {
        delegate?.reloadView()
    }
}
