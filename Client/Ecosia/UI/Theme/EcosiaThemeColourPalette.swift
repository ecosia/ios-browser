// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

fileprivate var themeManager: ThemeManager {
    AppContainer.shared.resolve()
}

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

private class EcosiaDarkColourPalette: EcosiaLightColourPalette {}

private class EcosiaLightColourPalette: ThemeColourPalette {
        
    // MARK: - Layers
    var layer1: UIColor = themeManager.currentTheme.colors.layer1
    var layer2: UIColor = themeManager.currentTheme.colors.layer2
    var layer3: UIColor = themeManager.currentTheme.colors.layer3
    var layer4: UIColor = themeManager.currentTheme.colors.layer4
    var layer5: UIColor = themeManager.currentTheme.colors.layer5
    var layer6: UIColor = themeManager.currentTheme.colors.layer6
    var layer5Hover: UIColor = themeManager.currentTheme.colors.layer5Hover
    var layerScrim: UIColor = themeManager.currentTheme.colors.layerScrim
    var layerGradient = themeManager.currentTheme.colors.layerGradient
    var layerGradientOverlay = themeManager.currentTheme.colors.layerGradientOverlay
    var layerAccentNonOpaque: UIColor = themeManager.currentTheme.colors.layerAccentNonOpaque
    var layerAccentPrivate: UIColor = themeManager.currentTheme.colors.layerAccentPrivate
    var layerAccentPrivateNonOpaque: UIColor = themeManager.currentTheme.colors.layerAccentPrivateNonOpaque
    var layerLightGrey30: UIColor = themeManager.currentTheme.colors.layerLightGrey30
    var layerSepia: UIColor = themeManager.currentTheme.colors.layerSepia
    var layerInfo: UIColor = themeManager.currentTheme.colors.layerInfo
    var layerConfirmation: UIColor = themeManager.currentTheme.colors.layerConfirmation
    var layerWarning: UIColor = UIColor.legacyTheme.ecosia.warning
    var layerError: UIColor = themeManager.currentTheme.colors.layerError
    var layerRatingA: UIColor = themeManager.currentTheme.colors.layerRatingA
    var layerRatingASubdued: UIColor = themeManager.currentTheme.colors.layerRatingASubdued
    var layerRatingB: UIColor = themeManager.currentTheme.colors.layerRatingB
    var layerRatingBSubdued: UIColor = themeManager.currentTheme.colors.layerRatingBSubdued
    var layerRatingC: UIColor = themeManager.currentTheme.colors.layerRatingC
    var layerRatingCSubdued: UIColor = themeManager.currentTheme.colors.layerRatingCSubdued
    var layerRatingD: UIColor = themeManager.currentTheme.colors.layerRatingD
    var layerRatingDSubdued: UIColor = themeManager.currentTheme.colors.layerRatingDSubdued
    var layerRatingF: UIColor = themeManager.currentTheme.colors.layerRatingF
    var layerRatingFSubdued: UIColor = themeManager.currentTheme.colors.layerRatingFSubdued

    // MARK: - Actions
    var actionPrimary: UIColor = UIColor.legacyTheme.ecosia.primaryButton
    var actionPrimaryHover: UIColor = UIColor.legacyTheme.ecosia.primaryButtonActive
    var actionSecondary: UIColor = UIColor.legacyTheme.ecosia.secondaryButton
    var actionSecondaryHover: UIColor = themeManager.currentTheme.colors.actionSecondaryHover
    var formSurfaceOff: UIColor = themeManager.currentTheme.colors.formSurfaceOff
    var formKnob: UIColor = themeManager.currentTheme.colors.formKnob
    var indicatorActive: UIColor = themeManager.currentTheme.colors.indicatorActive
    var indicatorInactive: UIColor = themeManager.currentTheme.colors.indicatorInactive
    var actionConfirmation: UIColor = themeManager.currentTheme.colors.actionConfirmation
    var actionWarning: UIColor = UIColor.legacyTheme.ecosia.warning
    var actionError: UIColor = themeManager.currentTheme.colors.actionError

    // MARK: - Text
    var textPrimary: UIColor = UIColor.legacyTheme.ecosia.primaryText
    var textSecondary: UIColor = UIColor.legacyTheme.ecosia.secondaryText
    var textSecondaryAction: UIColor = themeManager.currentTheme.colors.textSecondaryAction
    var textDisabled: UIColor = themeManager.currentTheme.colors.textDisabled
    var textWarning: UIColor = themeManager.currentTheme.colors.textWarning
    var textAccent: UIColor = themeManager.currentTheme.colors.textAccent
    var textOnDark: UIColor = themeManager.currentTheme.colors.textOnDark
    var textOnLight: UIColor = themeManager.currentTheme.colors.textOnLight
    var textInverted: UIColor = UIColor.legacyTheme.ecosia.primaryTextInverted

    // MARK: - Icons
    var iconPrimary: UIColor = UIColor.legacyTheme.ecosia.primaryIcon
    var iconSecondary: UIColor = UIColor.legacyTheme.ecosia.secondaryIcon
    var iconDisabled: UIColor = themeManager.currentTheme.colors.iconDisabled
    var iconAction: UIColor = themeManager.currentTheme.colors.iconAction
    var iconOnColor: UIColor = themeManager.currentTheme.colors.iconOnColor
    var iconWarning: UIColor = themeManager.currentTheme.colors.iconWarning
    var iconSpinner: UIColor = themeManager.currentTheme.colors.iconSpinner
    var iconAccentViolet: UIColor = themeManager.currentTheme.colors.iconAccentViolet
    var iconAccentBlue: UIColor = themeManager.currentTheme.colors.iconAccentBlue
    var iconAccentPink: UIColor = themeManager.currentTheme.colors.iconAccentPink
    var iconAccentGreen: UIColor = themeManager.currentTheme.colors.iconAccentGreen
    var iconAccentYellow: UIColor = themeManager.currentTheme.colors.iconAccentYellow

    // MARK: - Border
    var borderPrimary: UIColor = themeManager.currentTheme.colors.borderPrimary
    var borderAccent: UIColor = themeManager.currentTheme.colors.borderAccent
    var borderAccentNonOpaque: UIColor = themeManager.currentTheme.colors.borderAccentNonOpaque
    var borderAccentPrivate: UIColor = themeManager.currentTheme.colors.borderAccentPrivate
    var borderInverted: UIColor = themeManager.currentTheme.colors.borderInverted

    // MARK: - Shadow
    var shadowDefault: UIColor = themeManager.currentTheme.colors.shadowDefault
}

