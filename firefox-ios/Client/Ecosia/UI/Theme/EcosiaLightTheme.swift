// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

struct EcosiaLightTheme: Theme {
    public var type: ThemeType = .light
    public var colors: EcosiaThemeColourPalette = EcosiaLightColourPalette()
}

class EcosiaLightColourPalette: EcosiaThemeColourPalette {
    var ecosia: EcosiaSemanticColors {
        EcosiaLightSemanticColors()
    }

    // TODO Ecosia Upgrade: Review new colors and older ones that are no longer on the protocol [MOB-3152]
    var layerInformation: UIColor { fallbackTheme.colors.layerInformation }
    var layerSuccess: UIColor { fallbackTheme.colors.layerSuccess }
    var layerCritical: UIColor { fallbackTheme.colors.layerCritical }
    var layerSelectedText: UIColor { fallbackTheme.colors.layerSelectedText }
    var layerAutofillText: UIColor { fallbackTheme.colors.layerAutofillText }
    var actionPrimaryDisabled: UIColor { fallbackTheme.colors.actionPrimaryDisabled }
    var actionSuccess: UIColor { fallbackTheme.colors.actionSuccess }
    var actionCritical: UIColor { fallbackTheme.colors.actionCritical }
    var actionInformation: UIColor { fallbackTheme.colors.actionInformation }
    var textCritical: UIColor { fallbackTheme.colors.textCritical }
    var textInvertedDisabled: UIColor { fallbackTheme.colors.textInvertedDisabled }
    var iconAccent: UIColor { fallbackTheme.colors.iconAccent }
    var iconCritical: UIColor { fallbackTheme.colors.iconCritical }
    var iconRatingNeutral: UIColor { fallbackTheme.colors.iconRatingNeutral }

    /* TODO Ecosia Upgrade: Review if ok to switch to directly linking fallback theme. [MOB-3152]
    // The alternative is receiving window here since `getCurrentTheme` now requires it.
     let fallbackDefaultThemeManager: ThemeManager = DefaultThemeManager(sharedContainerIdentifier: AppInfo.sharedContainerIdentifier)
     */
    var fallbackTheme: Theme {
        LightTheme()
    }

    // MARK: - Layers
    var layer1: UIColor { ecosia.backgroundTertiary }
    var layer2: UIColor { fallbackTheme.colors.layer2 }
    var layer3: UIColor { ecosia.ntpBackground }
    var layer4: UIColor { fallbackTheme.colors.layer4 }
    var layer5: UIColor { ecosia.backgroundSecondary }
    var layer6: UIColor { .legacyTheme.ecosia.homePanelBackground }
    var layer5Hover: UIColor { ecosia.secondarySelectedBackground }
    var layerScrim: UIColor { fallbackTheme.colors.layerScrim }
    var layerGradient: Common.Gradient { fallbackTheme.colors.layerGradient }
    var layerGradientOverlay: Common.Gradient { fallbackTheme.colors.layerGradientOverlay }
    var layerAccentNonOpaque: UIColor { ecosia.buttonBackgroundPrimary }
    var layerAccentPrivate: UIColor { fallbackTheme.colors.layerAccentPrivate }
    var layerAccentPrivateNonOpaque: UIColor { ecosia.textPrimary }
    var layerSepia: UIColor { fallbackTheme.colors.layerSepia }
    var layerWarning: UIColor { .legacyTheme.ecosia.warning }
    var layerRatingA: UIColor { fallbackTheme.colors.layerRatingA }
    var layerRatingASubdued: UIColor { fallbackTheme.colors.layerRatingASubdued }
    var layerRatingB: UIColor { fallbackTheme.colors.layerRatingB }
    var layerRatingBSubdued: UIColor { fallbackTheme.colors.layerRatingBSubdued }
    var layerRatingC: UIColor { fallbackTheme.colors.layerRatingC }
    var layerRatingCSubdued: UIColor { fallbackTheme.colors.layerRatingCSubdued }
    var layerRatingD: UIColor { fallbackTheme.colors.layerRatingD }
    var layerRatingDSubdued: UIColor { fallbackTheme.colors.layerRatingDSubdued }
    var layerRatingF: UIColor { fallbackTheme.colors.layerRatingF }
    var layerRatingFSubdued: UIColor { fallbackTheme.colors.layerRatingFSubdued }
    var layerHomepage: Common.Gradient { fallbackTheme.colors.layerHomepage }
    var layerSearch: UIColor { fallbackTheme.colors.layerSearch }
    var layerGradientURL: Common.Gradient { fallbackTheme.colors.layerGradientURL }
    var actionTabActive: UIColor { fallbackTheme.colors.actionTabActive }
    var actionTabInactive: UIColor { fallbackTheme.colors.actionTabInactive }
    var borderToolbarDivider: UIColor { fallbackTheme.colors.borderToolbarDivider }

    // MARK: - Actions
    var actionPrimary: UIColor { ecosia.buttonBackgroundPrimary }
    var actionPrimaryHover: UIColor { ecosia.buttonBackgroundPrimaryActive }
    var actionSecondary: UIColor { ecosia.buttonBackgroundSecondary }
    var actionSecondaryHover: UIColor { fallbackTheme.colors.actionSecondaryHover }
    var formSurfaceOff: UIColor { fallbackTheme.colors.formSurfaceOff }
    var formKnob: UIColor { fallbackTheme.colors.formKnob }
    var indicatorActive: UIColor { fallbackTheme.colors.indicatorActive }
    var indicatorInactive: UIColor { fallbackTheme.colors.indicatorInactive }
    var actionWarning: UIColor { .legacyTheme.ecosia.warning }

    // MARK: - Text
    var textPrimary: UIColor { ecosia.textPrimary }
    var textSecondary: UIColor { ecosia.textSecondary }
    var textDisabled: UIColor { fallbackTheme.colors.textDisabled }
    var textAccent: UIColor { ecosia.buttonBackgroundPrimary }
    var textOnDark: UIColor { fallbackTheme.colors.textOnDark }
    var textOnLight: UIColor { fallbackTheme.colors.textOnLight }
    var textInverted: UIColor { ecosia.textInversePrimary }

    // MARK: - Icons
    var iconPrimary: UIColor { ecosia.iconPrimary }
    var iconSecondary: UIColor { ecosia.iconSecondary }
    var iconDisabled: UIColor { fallbackTheme.colors.iconDisabled }
    var iconOnColor: UIColor { fallbackTheme.colors.iconOnColor }
    var iconWarning: UIColor { .legacyTheme.ecosia.warning }
    var iconSpinner: UIColor { fallbackTheme.colors.iconSpinner }
    var iconAccentViolet: UIColor { fallbackTheme.colors.iconAccentViolet }
    var iconAccentBlue: UIColor { fallbackTheme.colors.iconAccentBlue }
    var iconAccentPink: UIColor { fallbackTheme.colors.iconAccentPink }
    var iconAccentGreen: UIColor { fallbackTheme.colors.iconAccentGreen }
    var iconAccentYellow: UIColor { fallbackTheme.colors.iconAccentYellow }

    // MARK: - Border
    var borderPrimary: UIColor { ecosia.barSeparator }
    var borderAccent: UIColor { actionPrimary }
    var borderAccentNonOpaque: UIColor { actionPrimary }
    var borderAccentPrivate: UIColor { actionPrimary }
    var borderInverted: UIColor { fallbackTheme.colors.borderInverted }

    // MARK: - Shadow
    var shadowDefault: UIColor { fallbackTheme.colors.shadowDefault }
}

private struct EcosiaLightSemanticColors: EcosiaSemanticColors {
    var backgroundPrimary: UIColor = EcosiaColor.White
    var backgroundSecondary: UIColor = EcosiaColor.Gray10
    var backgroundTertiary: UIColor = EcosiaColor.Gray20
    var backgroundQuaternary: UIColor = EcosiaColor.DarkGreen50
    var borderDecorative: UIColor = EcosiaColor.Gray30
    var brandPrimary: UIColor = EcosiaColor.Green50
    var buttonBackgroundPrimary: UIColor = EcosiaColor.Green50
    var buttonBackgroundPrimaryActive: UIColor = EcosiaColor.Green70 // ⚠️ Mismatch
    var buttonBackgroundSecondary: UIColor = EcosiaColor.White
    var buttonBackgroundSecondaryHover: UIColor = EcosiaColor.Gray10 // ⚠️ Mismatch
    var buttonContentSecondary: UIColor = EcosiaColor.Gray70
    var buttonBackgroundTransparentActive: UIColor = EcosiaColor.Green70.withAlphaComponent(0.24)
    var backgroundHighlighted: UIColor = EcosiaColor.Green10
    var iconPrimary: UIColor = EcosiaColor.Black // ⚠️ Mismatch
    var iconSecondary: UIColor = EcosiaColor.Green60 // ⚠️ Mismatch
    var iconDecorative: UIColor = EcosiaColor.Gray50
    var stateError: UIColor = EcosiaColor.Red40
    var stateInformation: UIColor = EcosiaColor.Blue50 // ⚠️ No match
    var stateDisabled: UIColor = EcosiaColor.Gray30
    var textPrimary: UIColor = EcosiaColor.Black // ⚠️ Mismatch
    var textInversePrimary: UIColor = EcosiaColor.White
    var textSecondary: UIColor = EcosiaColor.Gray50
    var textTertiary: UIColor = EcosiaColor.White

    // MARK: Unmapped Snowflakes
    var barBackground: UIColor = EcosiaColor.White
    var barSeparator: UIColor = .Photon.Grey20
    var ntpCellBackground: UIColor = EcosiaColor.White
    var ntpBackground: UIColor = EcosiaColor.Gray20
    var ntpIntroBackground: UIColor = EcosiaColor.White
    var impactMultiplyCardBackground: UIColor = EcosiaColor.White
    var newsPlaceholder: UIColor = EcosiaColor.Gray10
    var modalBackground: UIColor = EcosiaColor.Gray20
    var modalHeader: UIColor = EcosiaColor.DarkGreen50
    var secondarySelectedBackground: UIColor = EcosiaColor.Gray10
    var buttonBackgroundNTPCustomization: UIColor = EcosiaColor.Gray10
    var privateButtonBackground: UIColor = .Photon.Grey70
}
