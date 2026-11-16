// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import UIKit
import Common

/// How the NTP header buttons look, based on the background behind them.
public enum NTPGlassAppearance: Equatable {
    /// On a wallpaper: always dark glass with static light content, in both light and dark mode.
    case wallpaper
    /// On a solid background: solid secondary buttons whose content follows the theme.
    case themed

    public init(hasWallpaper: Bool) {
        self = hasWallpaper ? .wallpaper : .themed
    }

    /// The interface style to force on the views hosting the glass.
    /// Native glass takes its light or dark look from the UIKit interface style,
    /// not from the SwiftUI colour scheme, so it has to be set at the UIKit level.
    public var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .wallpaper: return .dark
        case .themed: return .unspecified
        }
    }

    /// The colour for icons and text on the glass.
    public func contentColor(for theme: Theme) -> UIColor {
        switch self {
        case .wallpaper: return theme.colors.ecosia.textStaticLight
        case .themed: return theme.colors.ecosia.buttonContentSecondary
        }
    }
}

/// Themed content colours for both glass appearances, for views themed with `ecosiaThemed`.
public struct NTPGlassContentTheme: EcosiaThemeable {
    private var wallpaperContentColor = Color.white
    private var themedContentColor = Color.primary

    public init() {}

    public mutating func applyTheme(theme: Theme) {
        wallpaperContentColor = Color(NTPGlassAppearance.wallpaper.contentColor(for: theme))
        themedContentColor = Color(NTPGlassAppearance.themed.contentColor(for: theme))
    }

    public func contentColor(for appearance: NTPGlassAppearance) -> Color {
        switch appearance {
        case .wallpaper: return wallpaperContentColor
        case .themed: return themedContentColor
        }
    }
}
