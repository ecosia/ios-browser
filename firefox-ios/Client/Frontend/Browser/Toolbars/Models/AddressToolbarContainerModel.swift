// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Ecosia
import Shared
import ToolbarKit

final class AddressToolbarContainerModel: Equatable {
    let toolbarHelper: ToolbarHelperInterface

    let navigationActions: [ToolbarElement]
    let leadingPageActions: [ToolbarElement]
    let trailingPageActions: [ToolbarElement]
    let browserActions: [ToolbarElement]

    let toolbarLayoutStyle: ToolbarLayoutStyle
    let borderPosition: AddressToolbarBorderPosition?
    let searchEngineName: String
    let searchEngineImage: UIImage
    let searchEnginesManager: SearchEnginesManager
    let lockIconButtonA11yId: String?
    let lockIconImageName: String?
    let lockIconNeedsTheming: Bool
    let safeListedURLImageName: String?
    let url: URL?
    let isEmptySearch: Bool
    let searchTerm: String?
    let isEditing: Bool
    let didStartTyping: Bool
    let shouldShowKeyboard: Bool
    let editingAccessoryAction: ToolbarElement?
    let isPrivateMode: Bool
    let shouldSelectSearchTerm: Bool
    let shouldDisplayCompact: Bool
    let canShowNavigationHint: Bool
    let shouldAnimate: Bool
    let hasAlternativeLocationColor: Bool
    let isAddressBarMinimized: Bool
    let isAccessoryViewVisible: Bool

    let windowUUID: UUID

    @MainActor
    var addressToolbarConfig: AddressToolbarConfiguration {
        buildAddressToolbarConfig()
    }

    @MainActor
    private func buildAddressToolbarConfig() -> AddressToolbarConfiguration {
        let term = searchTerm ?? searchTermFromURL(url)
        let backgroundAlpha = toolbarHelper.glassEffectAlpha
        let shouldBlur = toolbarHelper.shouldBlur()
        let uxConfiguration: AddressToolbarUXConfiguration = .experiment(
            backgroundAlpha: backgroundAlpha,
            isAddressBarMinimized: isAddressBarMinimized,
            shouldBlur: shouldBlur,
            hasAlternativeLocationColor: hasAlternativeLocationColor)

        var droppableUrl: URL?
        if let url, !InternalURL.isValid(url: url) {
            droppableUrl = url
        }

        // Ecosia: suppress URL display during the empty-search state (upstream passes `url` directly).
        let displayURL: URL? = isEmptySearch ? nil : url
        /* Ecosia: Original flatMap returns nil for any regular URL (InternalURL returns nil for https:// URLs),
           so `nil ?? true` incorrectly treats all regular pages as home. Use map with `?? false` so that
           non-internal URLs evaluate to false (not home), while nil URL still defaults to true (home).
        let isHome = url.map { InternalURL($0)?.isAboutHomeURL ?? false } ?? true
        */
        // Ecosia: Regular URLs are not home; nil URL → home, internal about:home → home, everything else → not home
        let isHome = url.map { InternalURL($0)?.isAboutHomeURL ?? false } ?? true
        // Ecosia: Secure websites (shieldCheckmarkFill) show privacy-verified in the favicon slot
        let isSecure = lockIconImageName == StandardImageIdentifiers.Small.shieldCheckmarkFill
        let displaySearchEngineImage: UIImage? = ecosiaSearchEngineImage(
            isEditing: isEditing,
            isPrivate: isPrivateMode,
            isHome: isHome,
            isSecure: isSecure,
            defaultImage: searchEngineImage
        )

        let locationViewConfiguration = LocationViewConfiguration(
            searchEngineImageViewA11yId: AccessibilityIdentifiers.Browser.AddressToolbar.searchEngine,
            searchEngineImageViewA11yLabel: String(
                format: .AddressToolbar.SearchEngineA11yLabel,
                searchEngineName
            ),
            lockIconButtonA11yId: lockIconButtonA11yId,
            lockIconButtonA11yLabel: .AddressToolbar.PrivacyAndSecuritySettingsA11yLabel,
            urlTextFieldPlaceholder: .AddressToolbar.LocationPlaceholder,
            urlTextFieldA11yId: AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField,
            searchEngineImage: displaySearchEngineImage,
            lockIconImageName: lockIconImageName,
            lockIconNeedsTheming: lockIconNeedsTheming,
            safeListedURLImageName: safeListedURLImageName,
            url: displayURL,
            droppableUrl: droppableUrl,
            searchTerm: isEmptySearch ? nil : term,
            isEditing: isEditing,
            didStartTyping: didStartTyping,
            shouldShowKeyboard: shouldShowKeyboard,
            shouldSelectSearchTerm: shouldSelectSearchTerm,
            editingAccessoryAction: editingAccessoryAction,
            onTapLockIcon: { button in
                let action = ToolbarMiddlewareAction(buttonType: .trackingProtection,
                                                     buttonTapped: button,
                                                     gestureType: .tap,
                                                     windowUUID: self.windowUUID,
                                                     actionType: ToolbarMiddlewareActionType.didTapButton)
                store.dispatch(action)
            },
            onLongPress: {
                let action = ToolbarMiddlewareAction(buttonType: .locationView,
                                                     gestureType: .longPress,
                                                     windowUUID: self.windowUUID,
                                                     actionType: ToolbarMiddlewareActionType.didTapButton)
                store.dispatch(action)
            })
        return AddressToolbarConfiguration(
            locationViewConfiguration: locationViewConfiguration,
            navigationActions: navigationActions,
            leadingPageActions: leadingPageActions,
            trailingPageActions: trailingPageActions,
            browserActions: browserActions,
            borderConfiguration: AddressToolbarBorderConfiguration(
                a11yIdentifier: AccessibilityIdentifiers.Toolbar.topBorder,
                borderPosition: borderPosition
            ),
            uxConfiguration: uxConfiguration,
            shouldAnimate: shouldAnimate
        )
    }

    /* Ecosia: Add isSecure parameter to show privacy-verified icon in the favicon slot for secure websites
    private func ecosiaSearchEngineImage(isEditing: Bool, isPrivate: Bool, isHome: Bool, defaultImage: UIImage?) -> UIImage? {
        if isEditing {
            if isPrivate {
                return UIImage.templateImageNamed(StandardImageIdentifiers.Large.privateMode)
            }
            return .ecosia(named: "iconLogo")
        }
        if isHome {
            return defaultImage ?? UIImage.templateImageNamed("searchUrl")
        }
        return nil
    }
    */
    /// Ecosia: Search/logo icon for address bar (editing = Ecosia logo or private icon; home = default/search; secure = privacy-verified; else hidden).
    private func ecosiaSearchEngineImage(isEditing: Bool, isPrivate: Bool, isHome: Bool, isSecure: Bool, defaultImage: UIImage?) -> UIImage? {
        if isEditing {
            if isPrivate {
                return UIImage.templateImageNamed(StandardImageIdentifiers.Large.privateMode)
            }
            return .ecosia(named: "iconLogo")
        }
        if isHome {
            return defaultImage ?? UIImage.templateImageNamed("searchUrl")
        }
        if isSecure {
            return UIImage.ecosia(named: "privacy-verified")?.withRenderingMode(.alwaysTemplate)
        }
        return nil
    }

    /// Returns a skeleton (placeholder) `AddressToolbarConfiguration` for the address bar.
    /// This method is intended to provide a minimal configuration for loading or placeholder states,
    /// with only essential actions and UI elements set up. Most properties are left empty or set to default values.
    /// - Parameter tab: The tab whose URL, secure content status are used to configure
    /// and determine which page actions should be displayed.
    ///   used to determine trailing actions.
    /// - Returns: A skeleton `AddressToolbarConfiguration` suitable for placeholder or loading UI.
    @MainActor
    func getSkeletonAddressBarConfiguration(for tab: Tab?) -> AddressToolbarConfiguration {
        let backgroundAlpha = toolbarHelper.glassEffectAlpha
        let shouldBlur = toolbarHelper.shouldBlur()
        let uxConfiguration: AddressToolbarUXConfiguration = .experiment(backgroundAlpha: backgroundAlpha,
                                                                         shouldBlur: shouldBlur)
        // Leading Page Actions
        let shareAction: ToolbarActionConfiguration = .init(
            actionType: .share,
            iconName: StandardImageIdentifiers.Medium.shareApple,
            isEnabled: true,
            hasCustomColor: true,
            a11yLabel: "",
            a11yId: AccessibilityIdentifiers.Toolbar.shareButton
        )

        // Trailing Page Actions
        let reloadAction: ToolbarActionConfiguration = .init(
            actionType: .reload,
            iconName: StandardImageIdentifiers.Medium.arrowClockwise,
            isEnabled: true,
            hasCustomColor: true,
            a11yLabel: "",
            a11yId: AccessibilityIdentifiers.Toolbar.reloadButton
        )

        var leadingPageElements = [ToolbarElement]()
        var trailingPageElements = [ToolbarElement]()

        let url = tab?.url?.displayURL
        if url != nil {
            leadingPageElements = Self.mapActions([shareAction], isShowingTopTabs: false, windowUUID: windowUUID)
            trailingPageElements = Self.mapActions([reloadAction], isShowingTopTabs: false, windowUUID: windowUUID)
        }

        var lockIconImageName: String?
        var lockIconNeedsTheming = true

        let hasSecureContent = tab?.webView?.hasOnlySecureContent == true
        let isWebsiteMode = tab?.url?.isReaderModeURL == false

        if isWebsiteMode {
            lockIconImageName = hasSecureContent ?
                StandardImageIdentifiers.Small.shieldCheckmarkFill :
                StandardImageIdentifiers.Small.shieldSlashFillMulticolor
            lockIconNeedsTheming = hasSecureContent
        }

        let locationViewConfiguration = LocationViewConfiguration(
            searchEngineImageViewA11yId: "",
            searchEngineImageViewA11yLabel: "",
            lockIconButtonA11yId: nil,
            lockIconButtonA11yLabel: "",
            urlTextFieldPlaceholder: .AddressToolbar.LocationPlaceholder,
            urlTextFieldA11yId: "",
            searchEngineImage: nil,
            lockIconImageName: lockIconImageName,
            lockIconNeedsTheming: lockIconNeedsTheming,
            safeListedURLImageName: safeListedURLImageName,
            url: url,
            droppableUrl: nil,
            searchTerm: nil,
            isEditing: false,
            didStartTyping: false,
            shouldShowKeyboard: false,
            shouldSelectSearchTerm: false,
            onTapLockIcon: { _ in },
            onLongPress: {})

        return AddressToolbarConfiguration(
            locationViewConfiguration: locationViewConfiguration,
            navigationActions: [],
            leadingPageActions: leadingPageElements,
            trailingPageActions: trailingPageElements,
            browserActions: [],
            borderConfiguration: AddressToolbarBorderConfiguration(
                a11yIdentifier: AccessibilityIdentifiers.Toolbar.topBorder,
                borderPosition: borderPosition
            ),
            uxConfiguration: uxConfiguration,
            shouldAnimate: shouldAnimate
        )
    }

    @MainActor
    init(
        state: ToolbarState,
        profile: Profile,
        searchEnginesManager: SearchEnginesManager = AppContainer.shared.resolve(),
        toolbarHelper: ToolbarHelperInterface = ToolbarHelper(),
        windowUUID: UUID
    ) {
        self.borderPosition = state.addressToolbar.borderPosition
        self.navigationActions = Self.mapActions(state.addressToolbar.navigationActions,
                                                 isShowingTopTabs: state.isShowingTopTabs,
                                                 windowUUID: windowUUID)
        self.leadingPageActions = Self.mapActions(state.addressToolbar.leadingPageActions,
                                                  isShowingTopTabs: state.isShowingTopTabs,
                                                  windowUUID: windowUUID)
        self.trailingPageActions = Self.mapActions(state.addressToolbar.trailingPageActions,
                                                   isShowingTopTabs: state.isShowingTopTabs,
                                                   windowUUID: windowUUID)
        self.browserActions = Self.mapActions(state.addressToolbar.browserActions,
                                              isShowingTopTabs: state.isShowingTopTabs,
                                              windowUUID: windowUUID)
        self.editingAccessoryAction = state.addressToolbar.editingAccessoryAction.map {
            Self.mapAction($0, isShowingTopTabs: state.isShowingTopTabs, windowUUID: windowUUID)
        }

        // If the user has selected an alternative search engine, use that. Otherwise, use the default engine.
        let searchEngineModel = state.addressToolbar.alternativeSearchEngine
                                ?? searchEnginesManager.defaultEngine?.generateModel()
        let hasAlternativeLocationColor = state.toolbarPosition == .top &&
                                            !state.isShowingTopTabs &&
                                            state.isShowingNavigationToolbar

        self.windowUUID = windowUUID
        self.searchEngineName = searchEngineModel?.name ?? ""
        self.searchEngineImage = searchEngineModel?.image ?? UIImage()
        self.searchEnginesManager = searchEnginesManager
        self.lockIconButtonA11yId = state.addressToolbar.lockIconButtonA11yId
        self.lockIconImageName = state.addressToolbar.lockIconImageName
        self.lockIconNeedsTheming = state.addressToolbar.lockIconNeedsTheming
        self.safeListedURLImageName = state.addressToolbar.safeListedURLImageName
        self.url = state.addressToolbar.url
        self.isEmptySearch = state.addressToolbar.isEmptySearch
        self.searchTerm = state.addressToolbar.searchTerm
        self.isEditing = state.addressToolbar.isEditing
        self.didStartTyping = state.addressToolbar.didStartTyping
        self.shouldShowKeyboard = state.addressToolbar.shouldShowKeyboard
        self.isPrivateMode = state.isPrivateMode
        self.shouldSelectSearchTerm = state.addressToolbar.shouldSelectSearchTerm
        self.shouldDisplayCompact = state.isShowingNavigationToolbar
        self.canShowNavigationHint = state.canShowNavigationHint
        self.shouldAnimate = state.shouldAnimate
        self.isAddressBarMinimized = state.isAddressBarMinimized
        self.isAccessoryViewVisible = state.isAccessoryViewVisible
        self.hasAlternativeLocationColor = hasAlternativeLocationColor
        self.toolbarLayoutStyle = state.toolbarLayout
        self.toolbarHelper = toolbarHelper
    }

    @MainActor
    func searchTermFromURL(_ url: URL?) -> String? {
        var searchURL: URL? = url

        if let url = searchURL, InternalURL.isValid(url: url) {
            searchURL = url
        }

        /* Ecosia: The search engine XML template is hardcoded to ecosia.org, so
           queryForSearchURL fails for staging (ecosia-staging.xyz) whose shortDisplayString
           doesn't match. Fall back to the URL-provider-aware Ecosia framework method so
           all environments and search verticals (images, videos, news) show the query.
           Only Ecosia URLs are turned into a query: a third-party provider's `q` can carry
           a chat mode's prompt instruction, which must not surface in the address bar.
        return searchEnginesManager.queryForSearchURL(searchURL)
        */
        guard searchURL?.isEcosia() == true else { return nil }
        if let term = searchEnginesManager.queryForSearchURL(searchURL) { return term }
        return searchURL?.isEcosiaSearchVertical() == true ? searchURL?.getEcosiaSearchQuery() : nil
    }

    @MainActor
    private static func mapActions(_ actions: [ToolbarActionConfiguration],
                                   isShowingTopTabs: Bool,
                                   windowUUID: UUID) -> [ToolbarElement] {
        return actions.map { action in
            mapAction(action, isShowingTopTabs: isShowingTopTabs, windowUUID: windowUUID)
        }
    }

    @MainActor
    private static func mapAction(_ action: ToolbarActionConfiguration,
                                  isShowingTopTabs: Bool,
                                  windowUUID: UUID) -> ToolbarElement {
        return ToolbarElement(
            iconName: action.iconName,
            title: action.actionLabel,
            badgeImageName: action.badgeImageName,
            bottomBadgeImage: action.bottomBadgeImage,
            // Ecosia: Forward badge customisation parameters for the incognito icon. These follow
            // `bottomBadgeImage`, which 155.1 inserted ahead of them in `ToolbarElement.init`.
            badgeBundle: action.badgeBundle,
            badgeSize: action.badgeSize,
            badgeXOffset: action.badgeXOffset,
            badgeYOffset: action.badgeYOffset,
            maskImageName: action.maskImageName,
            templateModeForImage: action.templateModeForImage,
            loadingConfig: action.loadingConfig,
            numberOfTabs: action.numberOfTabs,
            isEnabled: action.isEnabled,
            isFlippedForRTL: action.isFlippedForRTL,
            isSelected: action.isSelected,
            hasCustomColor: action.hasCustomColor,
            hasHighlightedColor: action.hasHighlightedColor,
            largeContentTitle: action.largeContentTitle,
            contextualHintType: action.contextualHintType,
            a11yLabel: action.a11yLabel,
            a11yHint: action.a11yHint,
            a11yId: action.a11yId,
            cacheId: action.cacheId,
            a11yCustomActionName: action.a11yCustomActionName,
            a11yCustomAction: getA11yCustomAction(action: action, windowUUID: windowUUID),
            hasLongPressAction: action.canPerformLongPressAction(isShowingTopTabs: isShowingTopTabs),
            previousTabScreenshot: action.previousTabScreenshot,
            nextTabScreenshot: action.nextTabScreenshot,
            onSelected: getOnSelected(actionType: action.actionType, windowUUID: windowUUID),
            onLongPress: getOnLongPress(action: action, windowUUID: windowUUID, isShowingTopTabs: isShowingTopTabs),
            menuElements: getMenuElements(action: action, windowUUID: windowUUID)
        )
    }

    @MainActor
    private static func getA11yCustomAction(action: ToolbarActionConfiguration, windowUUID: UUID) -> (() -> Void)? {
        return action.a11yCustomActionName != nil ? {
            let action = ToolbarMiddlewareAction(buttonType: action.actionType,
                                                 windowUUID: windowUUID,
                                                 actionType: ToolbarMiddlewareActionType.customA11yAction)
            store.dispatch(action)
        } : nil
    }

    @MainActor
    private static func getOnSelected(actionType: ToolbarActionConfiguration.ActionType,
                                      windowUUID: UUID) -> ((UIButton) -> Void)? {
        return { button in
            let action = ToolbarMiddlewareAction(buttonType: actionType,
                                                 buttonTapped: button,
                                                 gestureType: .tap,
                                                 windowUUID: windowUUID,
                                                 actionType: ToolbarMiddlewareActionType.didTapButton)
            store.dispatch(action)
        }
    }

    @MainActor
    private static func getOnLongPress(action: ToolbarActionConfiguration,
                                       windowUUID: UUID,
                                       isShowingTopTabs: Bool) -> ((UIButton) -> Void)? {
        return action.canPerformLongPressAction(isShowingTopTabs: isShowingTopTabs) ? { button in
            let action = ToolbarMiddlewareAction(buttonType: action.actionType,
                                                 buttonTapped: button,
                                                 gestureType: .longPress,
                                                 windowUUID: windowUUID,
                                                 actionType: ToolbarMiddlewareActionType.didTapButton)
            store.dispatch(action)
        } : nil
    }

    @MainActor
    private static func getMenuElements(action: ToolbarActionConfiguration, windowUUID: UUID) -> [ToolbarMenuElement] {
        return action.menuElements.map { menuElement in
            ToolbarMenuElement(
                title: menuElement.title,
                imageName: menuElement.imageName,
                a11yIdentifier: menuElement.a11yIdentifier,
                onSelected: getOnSelected(actionType: menuElement.actionType, windowUUID: windowUUID)
            )
        }
    }

    static func == (lhs: AddressToolbarContainerModel, rhs: AddressToolbarContainerModel) -> Bool {
        lhs.navigationActions == rhs.navigationActions &&
        lhs.leadingPageActions == rhs.leadingPageActions &&
        lhs.trailingPageActions == rhs.trailingPageActions &&
        lhs.browserActions == rhs.browserActions &&
        lhs.toolbarLayoutStyle == rhs.toolbarLayoutStyle &&
        lhs.borderPosition == rhs.borderPosition &&
        lhs.searchEngineName == rhs.searchEngineName &&
        lhs.searchEngineImage == rhs.searchEngineImage &&
        lhs.lockIconButtonA11yId == rhs.lockIconButtonA11yId &&
        lhs.lockIconImageName == rhs.lockIconImageName &&
        lhs.lockIconNeedsTheming == rhs.lockIconNeedsTheming &&
        lhs.safeListedURLImageName == rhs.safeListedURLImageName &&
        lhs.url == rhs.url &&
        lhs.isEmptySearch == rhs.isEmptySearch &&
        lhs.searchTerm == rhs.searchTerm &&
        lhs.isEditing == rhs.isEditing &&
        lhs.didStartTyping == rhs.didStartTyping &&
        lhs.shouldShowKeyboard == rhs.shouldShowKeyboard &&
        lhs.editingAccessoryAction == rhs.editingAccessoryAction &&
        lhs.isPrivateMode == rhs.isPrivateMode &&
        lhs.shouldSelectSearchTerm == rhs.shouldSelectSearchTerm &&
        lhs.shouldDisplayCompact == rhs.shouldDisplayCompact &&
        lhs.canShowNavigationHint == rhs.canShowNavigationHint &&
        lhs.shouldAnimate == rhs.shouldAnimate &&
        lhs.isAddressBarMinimized == rhs.isAddressBarMinimized &&
        lhs.isAccessoryViewVisible == rhs.isAccessoryViewVisible &&
        lhs.hasAlternativeLocationColor == rhs.hasAlternativeLocationColor &&

        lhs.windowUUID == rhs.windowUUID
    }
}
