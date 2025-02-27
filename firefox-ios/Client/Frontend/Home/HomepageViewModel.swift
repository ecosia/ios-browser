// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import Ecosia

protocol HomepageViewModelDelegate: AnyObject {
    func reloadView()
}

protocol HomepageDataModelDelegate: AnyObject {
    func reloadView()
}

class HomepageViewModel: FeatureFlaggable, InjectedThemeUUIDIdentifiable {
    struct UX {
        // Ecosia: Update `spacingBetweenSections`
        // static let spacingBetweenSections: CGFloat = 62
        static let spacingBetweenSections: CGFloat = 32
        static let standardInset: CGFloat = 16
        static let iPadInset: CGFloat = 50
        static let iPadTopSiteInset: CGFloat = 25

        // Shadow
        static let shadowRadius: CGFloat = 4
        static let shadowOffset = CGSize(width: 0, height: 2)
        static let shadowOpacity: Float = 1 // shadow opacity set to 0.16 through shadowDefault themed color

        // General
        static let generalCornerRadius: CGFloat = 8
        static let generalBorderWidth: CGFloat = 0.5
        static let generalIconCornerRadius: CGFloat = 4
        static let fallbackFaviconSize = CGSize(width: 36, height: 36)

        static func leadingInset(
            traitCollection: UITraitCollection,
            interfaceIdiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom
        ) -> CGFloat {
            guard interfaceIdiom != .phone else { return standardInset }

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

    let windowUUID: WindowUUID
    let nimbus: FxNimbus
    let profile: Profile
    var isZeroSearch: Bool {
        didSet {
            topSiteViewModel.isZeroSearch = isZeroSearch
            /* Ecosia: Remove bookmarks section
            bookmarksViewModel.isZeroSearch = isZeroSearch
             */
            /* Ecosia: Remove `jumpBackIn` section reference
            jumpBackInViewModel.isZeroSearch = isZeroSearch
             */
            /* Ecosia: Remove History Highlights and Pocket
            pocketViewModel.isZeroSearch = isZeroSearch
             */
        }
    }

    // Note: Should reload the view when have inconsistency between childViewModels count
    // and shownSections count in order to avoid a crash
    var shouldReloadView: Bool {
        return childViewModels.filter({ $0.shouldShow }).count != shownSections.count
    }

    var theme: Theme {
        didSet {
            childViewModels.forEach { $0.setTheme(theme: theme) }
        }
    }

    /// Record view appeared is sent multiple times, this avoids recording telemetry multiple times for one appearance
    var viewAppeared = false

    var newSize: CGSize?

    var shownSections = [HomepageSectionType]()
    weak var delegate: HomepageViewModelDelegate?
    private var wallpaperManager: WallpaperManager
    private var logger: Logger
    private let viewWillAppearEventThrottler = Throttler(seconds: 0.5)

    // Child View models
    private var childViewModels: [HomepageViewModelProtocol]
    var headerViewModel: HomepageHeaderViewModel
    // Ecosia: Remove message Card  from HomePage
    // var messageCardViewModel: HomepageMessageCardViewModel
    var topSiteViewModel: TopSitesViewModel
    /* Ecosia Remove bookmarks section
    var bookmarksViewModel: BookmarksViewModel
     */
    /* Ecosia: Remove `jumpBackIn` section reference
    var jumpBackInViewModel: JumpBackInViewModel
     */
    /* Ecosia: Remove History Highlights and Pocket
    var historyHighlightsViewModel: HistoryHighlightsViewModel
    var pocketViewModel: PocketViewModel
     */
    /* Ecosia: Remove `customizeHome` reference
    var customizeButtonViewModel: CustomizeHomepageSectionViewModel
     */

    var shouldDisplayHomeTabBanner: Bool {
        false
        // Ecosia: Remove message Card  from HomePage
        // return messageCardViewModel.shouldDisplayMessageCard
    }

    // Ecosia: Add Ecosia's ViewModels
    var libraryViewModel: NTPLibraryCellViewModel
    var impactViewModel: NTPImpactCellViewModel
    var newsViewModel: NTPNewsCellViewModel
    var aboutEcosiaViewModel: NTPAboutEcosiaCellViewModel
    var ntpCustomizationViewModel: NTPCustomizationCellViewModel
    var climateImpactCounterViewModel: NTPSeedCounterViewModel
    var accountLoginViewModel: NTPAccountLoginViewModel
    /*
     Ecosia: Represents the container that stores some of the `HomepageSectionType`s.
     The earlier a section type appears in the array, the higher its priority.
     */
    private let cardsPrioritySectionTypes: [HomepageSectionType] = []

    // MARK: - Initializers
    init(profile: Profile,
         isPrivate: Bool,
         tabManager: TabManager,
         nimbus: FxNimbus = FxNimbus.shared,
         referrals: Referrals, // Ecosia: Add referrals
         isZeroSearch: Bool = false,
         theme: Theme,
         wallpaperManager: WallpaperManager = WallpaperManager(),
         logger: Logger = DefaultLogger.shared) {
        self.profile = profile
        self.isZeroSearch = isZeroSearch
        self.theme = theme
        self.logger = logger
        self.windowUUID = tabManager.windowUUID

        self.headerViewModel = HomepageHeaderViewModel(profile: profile, theme: theme, tabManager: tabManager)
        /* Ecosia: Remove message Card  from HomePage
        let messageCardAdaptor = MessageCardDataAdaptorImplementation()
        self.messageCardViewModel = HomepageMessageCardViewModel(dataAdaptor: messageCardAdaptor, theme: theme)
        messageCardAdaptor.delegate = messageCardViewModel
         */
        self.topSiteViewModel = TopSitesViewModel(profile: profile,
                                                  theme: theme,
                                                  wallpaperManager: wallpaperManager)
        // Ecosia: Add Ecosia's ViewModels
        self.libraryViewModel = NTPLibraryCellViewModel(theme: theme)
        self.impactViewModel = NTPImpactCellViewModel(referrals: referrals, theme: theme)
        self.newsViewModel = NTPNewsCellViewModel(theme: theme)
        self.aboutEcosiaViewModel = NTPAboutEcosiaCellViewModel(theme: theme)
        self.ntpCustomizationViewModel = NTPCustomizationCellViewModel(theme: theme)
        self.climateImpactCounterViewModel = NTPSeedCounterViewModel(profile: profile, theme: theme)
        self.accountLoginViewModel = NTPAccountLoginViewModel(profile: profile, theme: theme)

        self.wallpaperManager = wallpaperManager
        /* Ecosia: Remove `jumpBackIn` section reference
        let jumpBackInAdaptor = JumpBackInDataAdaptorImplementation(profile: profile,
                                                                    tabManager: tabManager)
        self.jumpBackInViewModel = JumpBackInViewModel(
            profile: profile,
            isPrivate: isPrivate,
            theme: theme,
            tabManager: tabManager,
            adaptor: jumpBackInAdaptor,
            wallpaperManager: wallpaperManager)
         */
        /* Ecosia: Remove bookmarks section
        self.bookmarksViewModel = BookmarksViewModel(profile: profile,
                                                     theme: theme,
                                                     wallpaperManager: wallpaperManager)
         */
        /* Ecosia: Remove History Highlights and Pocket
        let deletionUtility = HistoryDeletionUtility(with: profile)
        let historyDataAdaptor = HistoryHighlightsDataAdaptorImplementation(
            profile: profile,
            tabManager: tabManager,
            deletionUtility: deletionUtility)
        self.historyHighlightsViewModel = HistoryHighlightsViewModel(
            with: profile,
            isPrivate: isPrivate,
            theme: theme,
            historyHighlightsDataAdaptor: historyDataAdaptor,
            wallpaperManager: wallpaperManager)

        let pocketDataAdaptor = PocketDataAdaptorImplementation(pocketAPI: PocketProvider(prefs: profile.prefs))
        self.pocketViewModel = PocketViewModel(pocketDataAdaptor: pocketDataAdaptor,
                                               theme: theme,
                                               prefs: profile.prefs,
                                               wallpaperManager: wallpaperManager)
        pocketDataAdaptor.delegate = pocketViewModel
         */
        // Ecosia: Remove `customizeHome` reference
        // self.customizeButtonViewModel = CustomizeHomepageSectionViewModel(theme: theme)

        /* 
         Ecosia: Replace view models.
        self.childViewModels = [headerViewModel,
                                messageCardViewModel,
                                topSiteViewModel,
                                jumpBackInViewModel,
                                bookmarksViewModel,
                                historyHighlightsViewModel,
                                pocketViewModel,
                                customizeButtonViewModel
        ]
         */
        // Ecosia: Those models needs to follow strictly the order defined in `enum HomepageSectionType`
        self.childViewModels = [accountLoginViewModel,
                                climateImpactCounterViewModel,
                                headerViewModel,
                                libraryViewModel,
                                topSiteViewModel,
                                impactViewModel,
                                newsViewModel,
                                aboutEcosiaViewModel,
                                ntpCustomizationViewModel]
        self.isPrivate = isPrivate

        self.nimbus = nimbus
        // Ecosia: Add Ecosia's ViewModels delegates
        newsViewModel.dataModelDelegate = self
        topSiteViewModel.delegate = self
        /* Ecosia Remove bookmarks section
        bookmarksViewModel.delegate = self
         */
        /* Ecosia: Remove History Highlights and Pocket
        historyHighlightsViewModel.delegate = self
         */
        /* Ecosia: Remove History Highlights and Pocket
        pocketViewModel.delegate = self
         */
        /* Ecosia: Remove `jumpBackIn` section reference
        jumpBackInViewModel.delegate = self
         */
        /* Ecosia: Remove message Card  from HomePage
        messageCardViewModel.delegate = self
         */

        /* Ecosia: Remove `jumpBackIn` section reference
        Task {
            await jumpBackInAdaptor.setDelegate(delegate: jumpBackInViewModel)
        }
         */
        updateEnabledSections()
    }

    // MARK: - Interfaces

    func recordViewAppeared() {
        guard !viewAppeared else { return }

        viewAppeared = true
        // TODO: FXIOS-9428 - Need to fix issue where viewWillAppear is called twice so we can remove the throttle workaround
        viewWillAppearEventThrottler.throttle {
            Experiments.events.recordEvent(BehavioralTargetingEvent.homepageViewed)
        }
        nimbus.features.homescreenFeature.recordExposure()
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .view,
                                     object: .firefoxHomepage,
                                     value: .fxHomepageOrigin,
                                     extras: TelemetryWrapper.getOriginExtras(isZeroSearch: isZeroSearch))

        // Firefox home page tracking i.e. being shown from awesomebar vs bottom right hamburger menu
        let trackingValue: TelemetryWrapper.EventValue = isZeroSearch
        ? .openHomeFromAwesomebar : .openHomeFromPhotonMenuButton
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .open,
                                     object: .firefoxHomepage,
                                     value: trackingValue,
                                     extras: nil)
        // Ecosia: Only execute screenWasShown for shown sections
        // childViewModels.forEach { $0.screenWasShown() }
        shownSections.forEach { section in
            if let viewModel = childViewModels.first(where: { $0.sectionType == section }) {
                viewModel.screenWasShown()
            }
        }

        // Ecosia
        if NTPTooltip.highlight() == .referralSpotlight {
            Analytics.shared.referral(action: .view, label: .promo)
        }

        impactViewModel.subscribeToProjections()
    }

    func recordViewDisappeared() {
        viewAppeared = false
        // Ecosia: Unsubscribe to projections
        impactViewModel.unsubscribeToProjections()
    }

    // MARK: - Manage sections

    func updateEnabledSections() {
        shownSections.removeAll()

        /* Ecosia: Handle priority of cards view models
         childViewModels.forEach {
             if $0.shouldShow { shownSections.append($0.sectionType) }
         }
         */
        var prioritySectionAdded = false
        childViewModels.forEach {
            if $0.shouldShow {
                if cardsPrioritySectionTypes.contains($0.sectionType) {
                    if !prioritySectionAdded {
                        shownSections.append($0.sectionType)
                        prioritySectionAdded = true
                    }
                    // If a priority section has already been added, skip the rest
                } else {
                    // Non-priority section, add if shouldShow is true
                    shownSections.append($0.sectionType)
                }
            }
            // If shouldShow is false, skip this viewModel
        }

        logger.log("Homepage amount of sections shown \(shownSections.count)",
                   level: .debug,
                   category: .legacyHomepage)
    }

    func refreshData(for traitCollection: UITraitCollection, size: CGSize) {
        updateEnabledSections()
        childViewModels.forEach {
            $0.refreshData(for: traitCollection,
                           size: size,
                           isPortrait: UIWindow.isPortrait,
                           device: UIDevice.current.userInterfaceIdiom)
        }
    }
}

// MARK: - HomepageDataModelDelegate
extension HomepageViewModel: HomepageDataModelDelegate {
    func reloadView() {
        delegate?.reloadView()
    }
}

// Ecosia: NTPLayoutHighlightDataSource
extension HomepageViewModel: NTPLayoutHighlightDataSource {
    func getSectionViewModel(shownSection: Int) -> HomepageViewModelProtocol? {
        guard let actualSectionNumber = shownSections[safe: shownSection]?.rawValue else { return nil }
        return childViewModels[safe: actualSectionNumber]
    }
}
