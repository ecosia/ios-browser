// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/*
 
The purpose of this file is to build an adapter layer and begin to utilize the `ThemeColourPalette` that Firefox provide.
WHY?
In the previous releases of Firefox the theming architecture relied on a protocol approach without any sort of dependency injection as part of the `applyTheme()` function.
 However, since the codebase bigger restructure, the Theming has gone thru a major refactor as well.
 By having this adapter in, we can benefit of the `Theme` object being passed as part of the `func applyTheme(theme: Theme)` function so that all the places having it implemented will receive the new colors.
 The setup of these Dark and Light Ecosia's Colour Palette is definted by the `EcosiaThemeManager`.
 However, the need of a `fallbackDefaultThemeManager` of type `DefaultThemeManager` is crucial as we don't have all the colors defined ourselves and we rely on the Firefox ones we can't get access to as part of the `BrowserKit` package.
 Once and if we'll have all the colors defined, we can remove the `fallbackDefaultThemeManager` variable.
*/

import Common
import UIKit

public struct EcosiaLightTheme: Theme {
    public var type: ThemeType = .light
    public var colors: ThemeColourPalette = EcosiaLightColourPalette()

    public init() {}
}

public struct EcosiaDarkTheme: Theme {
    public var type: ThemeType = .dark
    public var colors: ThemeColourPalette = EcosiaDarkColourPalette()

    public init() {}
}

private class EcosiaDarkColourPalette: EcosiaLightColourPalette {
    override var layer1: UIColor { .legacyTheme.ecosia.primaryBackground }
}

private class EcosiaLightColourPalette: ThemeColourPalette {
    
    private static var fallbackDefaultThemeManager: ThemeManager = {
        DefaultThemeManager(sharedContainerIdentifier: AppInfo.sharedContainerIdentifier)
    }()
        
    // MARK: - Layers
    var layer1: UIColor { .legacyTheme.ecosia.tertiaryBackground }
    var layer2: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.layer2 }
    var layer3: UIColor { .legacyTheme.ecosia.primaryBackground }
    var layer4: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.layer4 }
    var layer5: UIColor { .legacyTheme.ecosia.secondaryBackground }
    var layer6: UIColor { .legacyTheme.ecosia.homePanelBackground }
    var layer5Hover: UIColor { .legacyTheme.ecosia.secondarySelectedBackground }
    var layerScrim: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.layerScrim }
    var layerGradient = fallbackDefaultThemeManager.currentTheme.colors.layerGradient
    var layerGradientOverlay = fallbackDefaultThemeManager.currentTheme.colors.layerGradientOverlay
    var layerAccentNonOpaque: UIColor { .legacyTheme.ecosia.primaryButton }
    var layerAccentPrivate: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.layerAccentPrivate }
    var layerAccentPrivateNonOpaque: UIColor { .legacyTheme.ecosia.primaryText }
    var layerLightGrey30: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.layerLightGrey30 }
    var layerSepia: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.layerSepia }
    var layerInfo: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.layerInfo }
    var layerConfirmation: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.layerConfirmation }
    var layerWarning: UIColor { .legacyTheme.ecosia.warning }
    var layerError: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.layerError }
    var layerRatingA: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.layerRatingA }
    var layerRatingASubdued: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.layerRatingASubdued }
    var layerRatingB: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.layerRatingB }
    var layerRatingBSubdued: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.layerRatingBSubdued }
    var layerRatingC: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.layerRatingC }
    var layerRatingCSubdued: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.layerRatingCSubdued }
    var layerRatingD: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.layerRatingD }
    var layerRatingDSubdued: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.layerRatingDSubdued }
    var layerRatingF: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.layerRatingF }
    var layerRatingFSubdued: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.layerRatingFSubdued }
    var layerHomepage: Common.Gradient = fallbackDefaultThemeManager.currentTheme.colors.layerHomepage
    var layerSearch: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.layerSearch }
    var layerGradientURL: Common.Gradient = fallbackDefaultThemeManager.currentTheme.colors.layerGradientURL
    var actionTabActive: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.actionTabActive }
    var actionTabInactive: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.actionTabInactive }
    var borderToolbarDivider: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.borderToolbarDivider }

    // MARK: - Actions
    var actionPrimary: UIColor { .legacyTheme.ecosia.primaryButton }
    var actionPrimaryHover: UIColor { .legacyTheme.ecosia.primaryButtonActive }
    var actionSecondary: UIColor { .legacyTheme.ecosia.secondaryButton }
    var actionSecondaryHover: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.actionSecondaryHover }
    var formSurfaceOff: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.formSurfaceOff }
    var formKnob: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.formKnob }
    var indicatorActive: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.indicatorActive }
    var indicatorInactive: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.indicatorInactive }
    var actionConfirmation: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.actionConfirmation }
    var actionWarning: UIColor { .legacyTheme.ecosia.warning }
    var actionError: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.actionError }

    // MARK: - Text
    var textPrimary: UIColor { .legacyTheme.ecosia.primaryText }
    var textSecondary: UIColor { .legacyTheme.ecosia.secondaryText }
    var textDisabled: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.textDisabled }
    var textWarning: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.textWarning }
    var textAccent: UIColor { .legacyTheme.ecosia.primaryButton }
    var textOnDark: UIColor { .legacyTheme.ecosia.primaryTextInverted }
    var textOnLight: UIColor { .legacyTheme.ecosia.primaryTextInverted }
    var textInverted: UIColor { .legacyTheme.ecosia.primaryTextInverted }

    // MARK: - Icons
    var iconPrimary: UIColor { .legacyTheme.ecosia.primaryIcon }
    var iconSecondary: UIColor { .legacyTheme.ecosia.secondaryIcon }
    var iconDisabled: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.iconDisabled }
    var iconAction: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.iconAction }
    var iconOnColor: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.iconOnColor }
    var iconWarning: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.iconWarning }
    var iconSpinner: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.iconSpinner }
    var iconAccentViolet: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.iconAccentViolet }
    var iconAccentBlue: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.iconAccentBlue }
    var iconAccentPink: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.iconAccentPink }
    var iconAccentGreen: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.iconAccentGreen }
    var iconAccentYellow: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.iconAccentYellow }

    // MARK: - Border
    var borderPrimary: UIColor { .legacyTheme.ecosia.barSeparator }
    var borderAccent: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.borderAccent }
    var borderAccentNonOpaque: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.borderAccentNonOpaque }
    var borderAccentPrivate: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.borderAccentPrivate }
    var borderInverted: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.borderInverted }

    // MARK: - Shadow
    var shadowDefault: UIColor { Self.fallbackDefaultThemeManager.currentTheme.colors.shadowDefault }
}

