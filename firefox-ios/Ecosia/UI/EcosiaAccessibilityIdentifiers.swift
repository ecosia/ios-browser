// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Accessibility identifiers for Ecosia-specific UI elements
public struct EcosiaAccessibilityIdentifiers {
    
    public static let bannerLogo = "ecosia_logo"

    public struct Account {
        public static let navButton = "account_nav_button"
        public static let seedCountView = "seed_count_view"
        public static let userAvatar = "user_avatar"
        public static let defaultAvatar = "default_avatar"
    }

    public struct NTP {
        public static let rotatingTitle = "ntp_rotating_title"
        public static let headerLogo = "ntp_header_logo"
        public static let customizeButton = "ntp_customize_button"

        public struct ClimateImpact {
            public static let friendsAndTreesInvitesCounter = "friends_and_trees_invites_counter"
            public static let totalTreesCount = "total_trees_count"
            public static let totalInvestedCount = "total_invested_count"
            public static let referralImage = "referral_image"
            public static let totalTreesImage = "total_trees_image"
            public static let totalInvestedImage = "total_invested_image"
        }
    }

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
