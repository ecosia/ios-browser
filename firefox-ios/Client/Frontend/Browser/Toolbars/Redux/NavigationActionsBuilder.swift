// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Ecosia
import Redux
import UIKit

/// Builds the address bar's back/forward buttons, shown only when the navigation toolbar is hidden (compact layout)
/// and the navigation toolbar's actions (regular layout) when navigation bar and address bar are shown together
enum NavigationActionsBuilder {
    // Ecosia: Back arrow that cancels editing
    private static let cancelEditAction = ToolbarActionConfiguration(
        actionType: .cancelEdit,
        iconName: StandardImageIdentifiers.Large.chevronLeft,
        isFlippedForRTL: true,
        isEnabled: true,
        a11yLabel: AccessibilityIdentifiers.GeneralizedIdentifiers.back,
        a11yId: AccessibilityIdentifiers.Browser.UrlBar.cancelButton)

    private static let searchAction = ToolbarActionConfiguration(
        actionType: .search,
        iconName: StandardImageIdentifiers.Large.search,
        isEnabled: true,
        a11yLabel: .TabToolbarSearchAccessibilityLabel,
        a11yId: AccessibilityIdentifiers.Toolbar.searchButton)

    private static let homeAction = ToolbarActionConfiguration(
        actionType: .home,
        iconName: StandardImageIdentifiers.Large.home,
        isEnabled: true,
        a11yLabel: .TabToolbarHomeAccessibilityLabel,
        a11yId: AccessibilityIdentifiers.Toolbar.homeButton)

    /* Ecosia: Use Ecosia-owned nav-add icon instead of Firefox plusLarge
    private static let newTabAction = ToolbarActionConfiguration(
        actionType: .newTab,
        iconName: StandardImageIdentifiers.Large.plus,
        isEnabled: true,
        a11yLabel: .Toolbars.NewTabButton,
        a11yId: AccessibilityIdentifiers.Toolbar.addNewTabButton)
    */
    // Ecosia: nav-add lives in Client/Ecosia/UI/Ecosia.xcassets/TabToolbar/nav-add.imageset
    private static let newTabAction = ToolbarActionConfiguration(
        actionType: .newTab,
        iconName: "nav-add",
        isEnabled: true,
        a11yLabel: .Toolbars.NewTabButton,
        a11yId: AccessibilityIdentifiers.Toolbar.addNewTabButton)

    // Ecosia: History button shown on NTP instead of new-tab
    private static let historyAction = ToolbarActionConfiguration(
        actionType: .history,
        iconName: StandardImageIdentifiers.Large.history,
        isEnabled: true,
        a11yLabel: .TabToolbarHistoryAccessibilityLabel,
        a11yId: AccessibilityIdentifiers.Toolbar.historyButton)

    // Ecosia: `isEditing` added to show the back arrow (cancel edit) when editing
    static func getActions(isShowingNavigationToolbar: Bool,
                           canGoBack: Bool,
                           canGoForward: Bool,
                           isEditing: Bool = false) -> [ToolbarActionConfiguration] {
        // Ecosia: Show back arrow (cancel edit) when editing
        if isEditing { return [cancelEditAction] }
        guard !isShowingNavigationToolbar else { return [] }
        return [
            backAction(enabled: canGoBack),
            forwardAction(enabled: canGoForward)
        ]
    }

    static func getNavigationToolbarActions(isHomepage: Bool,
                                            canGoBack: Bool,
                                            canGoForward: Bool,
                                            middleButton: NavigationBarMiddleButtonType,
                                            toolbarLayout: ToolbarLayoutStyle?,
                                            tabTrayButtonStyle: TabTrayButtonStyle?,
                                            numberOfTabs: Int,
                                            showWarningBadge: Bool,
                                            previousTabScreenshot: UIImage?,
                                            nextTabScreenshot: UIImage?,
                                            isPrivateMode: Bool,
                                            isNovaDesignEnabled: Bool) -> [ToolbarActionConfiguration] {
        let customizedMiddleButton = switch middleButton {
        case .home: homeAction
        case .newTab: newTabAction
        }
        /* Ecosia: Show history on NTP, new tab on SERP/webpage
        let middleAction = isHomepage ? searchAction : customizedMiddleButton
        */
        let middleAction = isHomepage ? historyAction : customizedMiddleButton

        let iconName: String? = switch tabTrayButtonStyle {
        case .number, .none: StandardImageIdentifiers.Large.tab
        case .screenshot: nil
        }

        /* Ecosia: Custom ellipsis icon
        let menu = menuAction(iconName: StandardImageIdentifiers.Large.moreHorizontalRound,
                              showWarningBadge: showWarningBadge)
        */
        let menu = menuAction(iconName: "elipsis", showWarningBadge: showWarningBadge)
        let tabs = tabsAction(iconName: iconName,
                              numberOfTabs: numberOfTabs,
                              isPrivateMode: isPrivateMode,
                              isNovaDesignEnabled: isNovaDesignEnabled,
                              previousTabScreenshot: previousTabScreenshot,
                              nextTabScreenshot: nextTabScreenshot)

        /* Ecosia: Always use version2 order (back, forward, middle, tabs, menu)
        let trailingActions = switch toolbarLayout {
        case .version1, .none: [menu, tabs]
        case .version2: [tabs, menu]
        }
        */
        let trailingActions = [tabs, menu]

        let actions = [backAction(enabled: canGoBack),
                       forwardAction(enabled: canGoForward),
                       middleAction] + trailingActions
        return actions
    }

    // MARK: - Helper
    static func backAction(enabled: Bool) -> ToolbarActionConfiguration {
        return ToolbarActionConfiguration(
            actionType: .back,
            iconName: StandardImageIdentifiers.Large.chevronLeft,
            isFlippedForRTL: true,
            isEnabled: enabled,
            contextualHintType: ContextualHintType.navigation.rawValue,
            a11yLabel: .TabToolbarBackAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.backButton)
    }

    static func forwardAction(enabled: Bool) -> ToolbarActionConfiguration {
        return ToolbarActionConfiguration(
            actionType: .forward,
            iconName: StandardImageIdentifiers.Large.chevronRight,
            isFlippedForRTL: true,
            isEnabled: enabled,
            a11yLabel: .TabToolbarForwardAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.forwardButton)
    }

    private static func menuAction(iconName: String, showWarningBadge: Bool) -> ToolbarActionConfiguration {
        return ToolbarActionConfiguration(
            actionType: .menu,
            iconName: iconName,
            badgeImageName: showWarningBadge ? StandardImageIdentifiers.Large.warningFill : nil,
            maskImageName: showWarningBadge ? ImageIdentifiers.menuWarningMask : nil,
            isEnabled: true,
            a11yLabel: .Toolbars.MenuButtonAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.settingsMenuButton)
    }

    private static func tabsAction(iconName: String?,
                                   numberOfTabs: Int,
                                   isPrivateMode: Bool,
                                   isNovaDesignEnabled: Bool,
                                   previousTabScreenshot: UIImage?,
                                   nextTabScreenshot: UIImage?) -> ToolbarActionConfiguration {
        let largeContentTitle = numberOfTabs > 99 ?
            .Toolbars.TabsButtonOverflowLargeContentTitle :
            String(format: .Toolbars.TabsButtonLargeContentTitle, NSNumber(value: numberOfTabs))

        /* Ecosia: Replace the purple/Nova private-mode badge with the Ecosia incognito icon,
           which comes from the Ecosia bundle and needs its own size and offsets. The mask goes
           with it — the incognito glyph is tinted via `foregroundColorNormal` instead.
        let isNovaPrivate = isPrivateMode && isNovaDesignEnabled
        let badgeImageName = isNovaPrivate
            ? StandardImageIdentifiers.Medium.privateModeCircleFillStrokeMulticolor
            : StandardImageIdentifiers.Medium.privateModeCircleFillPurple
         */

        return ToolbarActionConfiguration(
            actionType: .tabs,
            iconName: iconName,
            /* Ecosia: see above.
            badgeImageName: isPrivateMode ? badgeImageName : nil,
            maskImageName: (isPrivateMode && iconName != nil) ? ImageIdentifiers.badgeMask : nil,
             */
            badgeImageName: isPrivateMode ? "incognito" : nil,
            badgeBundle: isPrivateMode ? .ecosia : nil,
            badgeSize: isPrivateMode ? CGSize(width: 12, height: 12) : nil,
            badgeXOffset: isPrivateMode ? 6 : nil,
            badgeYOffset: isPrivateMode ? -4 : nil,
            maskImageName: nil,
            numberOfTabs: numberOfTabs,
            isEnabled: true,
            largeContentTitle: largeContentTitle,
            previousTabScreenshot: previousTabScreenshot,
            nextTabScreenshot: nextTabScreenshot,
            a11yLabel: .Toolbars.TabsButtonAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.tabsButton)
    }
}
