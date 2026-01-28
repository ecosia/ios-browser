// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Accessibility identifiers for Ecosia-specific UI elements
public struct EcosiaAccessibilityIdentifiers {
    public static let logo = "ecosia-logo"

    public struct TabToolbar {
        public static let circleButton = "TabToolbar.circleButton"
    }

    public struct FindInPage {
        public static let searchField = "FindInPage.searchField"
        public static let matchCount = "FindInPage.matchCount"
        public static let findPrevious = "FindInPage.find_previous"
        public static let findNext = "FindInPage.find_next"
        public static let findClose = "FindInPage.close"
    }
}
