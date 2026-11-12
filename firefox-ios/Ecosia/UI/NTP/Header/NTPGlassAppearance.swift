// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import UIKit
import Common

/// How the NTP glass buttons look, based on the background behind them.
public enum NTPGlassAppearance: Equatable {
    /// Dark glass with static light content, in both light and dark mode.
    case dark
    /// Light glass with static dark content, in both light and dark mode.
    case light
    /// On a solid background: the glass and its content follow the theme.
    case themed

    /// A wallpaper's text colour tells whether it is dark (light text) or light (dark text).
    public init(hasWallpaper: Bool, wallpaperTextColor: UIColor?) {
        guard hasWallpaper else {
            self = .themed
            return
        }
        guard let wallpaperTextColor, Self.isDark(wallpaperTextColor) else {
            self = .dark
            return
        }
        self = .light
    }

    /// The interface style to force on the views hosting the glass.
    /// Native glass takes its light or dark look from the UIKit interface style,
    /// not from the SwiftUI colour scheme, so it has to be set at the UIKit level.
    public var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .dark: return .dark
        case .light: return .light
        case .themed: return .unspecified
        }
    }

    /// The colour for icons and text on the glass.
    public func contentColor(for theme: Theme) -> UIColor {
        switch self {
        case .dark: return theme.colors.ecosia.textStaticLight
        case .light: return theme.colors.ecosia.textStaticDark
        case .themed: return theme.colors.ecosia.textPrimary
        }
    }

    private static func isDark(_ color: UIColor) -> Bool {
        var white: CGFloat = 0
        guard color.getWhite(&white, alpha: nil) else { return false }
        return white < 0.5
    }
}

/// Themed content colours for every glass appearance, for views themed with `ecosiaThemed`.
public struct NTPGlassContentTheme: EcosiaThemeable {
    private var darkContentColor = Color.white
    private var lightContentColor = Color.black
    private var themedContentColor = Color.primary

    public init() {}

    public mutating func applyTheme(theme: Theme) {
        darkContentColor = Color(NTPGlassAppearance.dark.contentColor(for: theme))
        lightContentColor = Color(NTPGlassAppearance.light.contentColor(for: theme))
        themedContentColor = Color(NTPGlassAppearance.themed.contentColor(for: theme))
    }

    public func contentColor(for appearance: NTPGlassAppearance) -> Color {
        switch appearance {
        case .dark: return darkContentColor
        case .light: return lightContentColor
        case .themed: return themedContentColor
        }
    }
}
