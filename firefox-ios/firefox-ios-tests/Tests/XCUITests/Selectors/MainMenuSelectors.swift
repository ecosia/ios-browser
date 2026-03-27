// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol MainMenuSelectorSet {
    var DESKTOP_SITE: Selector { get }
    var BOOKMARKS_BUTTON: Selector { get }
    var HISTORY_BUTTON: Selector { get }
    var READING_LIST_BUTTON: Selector { get }
    var DOWNLOADS_BUTTON: Selector { get }
    var SETTINGS_CELL: Selector { get }
    var all: [Selector] { get }
}

struct MainMenuSelectors: MainMenuSelectorSet {
    private enum IDs {
        static let desktopSite  = AccessibilityIdentifiers.MainMenu.desktopSite
        static let bookmarks    = AccessibilityIdentifiers.MainMenu.bookmarks
        static let history      = AccessibilityIdentifiers.MainMenu.history
        static let downloads    = AccessibilityIdentifiers.MainMenu.downloads
        static let readingList  = AccessibilityIdentifiers.MainMenu.readingList
        static let settings     = AccessibilityIdentifiers.MainMenu.settings
    }

    let DESKTOP_SITE = Selector.cellById(
        IDs.desktopSite,
        description: "Desktop Site",
        groups: ["MainMenu"]
    )

    let BOOKMARKS_BUTTON = Selector.buttonId(
        IDs.bookmarks,
        description: "Bookmarks button in Main Menu",
        groups: ["MainMenu"]
    )

    let HISTORY_BUTTON = Selector.buttonId(
        IDs.history,
        description: "History button in Main Menu",
        groups: ["MainMenu"]
    )

    // Ecosia: Reading List replaces Passwords in the compact menu
    let READING_LIST_BUTTON = Selector.buttonId(
        IDs.readingList,
        description: "Reading List button in Main Menu",
        groups: ["MainMenu"]
    )

    let DOWNLOADS_BUTTON = Selector.buttonId(
        IDs.downloads,
        description: "Downloads button in Main Menu",
        groups: ["MainMenu"]
    )

    let SETTINGS_CELL = Selector.tableCellById(
        IDs.settings,
        description: "Settings cell in Main Menu",
        groups: ["MainMenu"]
    )

    var all: [Selector] { [DESKTOP_SITE, BOOKMARKS_BUTTON, HISTORY_BUTTON, READING_LIST_BUTTON,
                           DOWNLOADS_BUTTON, SETTINGS_CELL] }
}
