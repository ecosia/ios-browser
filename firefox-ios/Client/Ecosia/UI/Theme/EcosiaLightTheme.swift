// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Ecosia

struct EcosiaLightTheme: Theme {
    public var type: ThemeType = .light
    public var colors: EcosiaThemeColourPalette = EcosiaLightColourPalette()
}

class EcosiaLightColourPalette: EcosiaThemeColourPalette {
    var ecosia: EcosiaSemanticColors {
        EcosiaLightSemanticColors()
    }

    var fallbackTheme: Theme {
        LightTheme()
    }

    // MARK: - Layers
    var layer1: UIColor { ecosia.backgroundPrimaryDecorative }
    var layer2: UIColor { ecosia.backgroundElevation1 }
    var layer3: UIColor { ecosia.backgroundPrimaryDecorative }
    var layer4: UIColor { fallbackTheme.colors.layer4 }
    var layer5: UIColor { ecosia.backgroundElevation1 }
    var layer5Hover: UIColor { ecosia.backgroundQuaternary }
    var layerScrim: UIColor { fallbackTheme.colors.layerScrim }
    var layerGradient: Gradient { fallbackTheme.colors.layerGradient }
    var layerGradientOverlay: Gradient { fallbackTheme.colors.layerGradientOverlay }
    var layerAccentNonOpaque: UIColor { ecosia.buttonBackgroundPrimary }
    var layerAccentPrivate: UIColor { ecosia.buttonContentSecondary }
    var layerAccentPrivateNonOpaque: UIColor { ecosia.textPrimary }
    var layerSepia: UIColor { fallbackTheme.colors.layerSepia }
    var layerHomepage: Gradient { fallbackTheme.colors.layerHomepage }
    var layerInformation: UIColor { fallbackTheme.colors.layerInformation }
    var layerSuccess: UIColor { fallbackTheme.colors.layerSuccess }
    var layerWarning: UIColor { ecosia.stateError }
    var layerCritical: UIColor { fallbackTheme.colors.layerCritical }
    var layerCriticalSubdued: UIColor { fallbackTheme.colors.layerCriticalSubdued }
    var layerSelectedText: UIColor { fallbackTheme.colors.layerSelectedText }
    var layerAutofillText: UIColor { fallbackTheme.colors.layerAutofillText }
    var layerEmphasis: UIColor { fallbackTheme.colors.layerEmphasis }
    var layerGradientURL: Gradient { fallbackTheme.colors.layerGradientURL }
    var layerSurfaceLow: UIColor { ecosia.backgroundPrimaryDecorative }
    var layerSurfaceMedium: UIColor { ecosia.backgroundElevation1 }
    var layerSurfaceMediumAlt: UIColor { fallbackTheme.colors.layerSurfaceMediumAlt }
    var layerGradientSummary: Gradient { fallbackTheme.colors.layerGradientSummary }

    // MARK: - Actions
    var actionPrimary: UIColor { ecosia.buttonBackgroundPrimary }
    var actionPrimaryHover: UIColor { ecosia.buttonBackgroundPrimaryActive }
    var actionPrimaryDisabled: UIColor { fallbackTheme.colors.actionPrimaryDisabled }
    var actionSecondary: UIColor { ecosia.buttonBackgroundSecondary }
    var actionSecondaryDisabled: UIColor { fallbackTheme.colors.actionSecondaryDisabled }
    var actionSecondaryHover: UIColor { fallbackTheme.colors.actionSecondaryHover }
    var formSurfaceOff: UIColor { fallbackTheme.colors.formSurfaceOff }
    var formKnob: UIColor { fallbackTheme.colors.formKnob }
    var indicatorActive: UIColor { fallbackTheme.colors.indicatorActive }
    var indicatorInactive: UIColor { fallbackTheme.colors.indicatorInactive }
    var actionSuccess: UIColor { fallbackTheme.colors.actionSuccess }
    var actionWarning: UIColor { ecosia.stateError }
    var actionCritical: UIColor { fallbackTheme.colors.actionCritical }
    var actionInformation: UIColor { fallbackTheme.colors.actionInformation }
    var actionTabActive: UIColor { fallbackTheme.colors.actionTabActive }
    var actionTabInactive: UIColor { fallbackTheme.colors.actionTabInactive }
    var actionCloseButton: UIColor { fallbackTheme.colors.actionCloseButton }

    // MARK: - Text
    var textPrimary: UIColor { ecosia.textPrimary }
    var textSecondary: UIColor { ecosia.textSecondary }
    var textDisabled: UIColor { fallbackTheme.colors.textDisabled }
    var textCritical: UIColor { fallbackTheme.colors.textCritical }
    var textAccent: UIColor { ecosia.buttonBackgroundPrimary }
    var textOnDark: UIColor { fallbackTheme.colors.textOnDark }
    var textOnLight: UIColor { fallbackTheme.colors.textOnLight }
    var textInverted: UIColor { ecosia.textInversePrimary }
    var textInvertedDisabled: UIColor { fallbackTheme.colors.textInvertedDisabled }

    // MARK: - Icons
    var iconPrimary: UIColor { ecosia.buttonContentSecondary }
    var iconSecondary: UIColor { ecosia.buttonContentSecondary }
    var iconDisabled: UIColor { fallbackTheme.colors.iconDisabled }
    var iconAccent: UIColor { ecosia.iconDecorative }
    var iconOnColor: UIColor { fallbackTheme.colors.iconOnColor }
    var iconCritical: UIColor { ecosia.stateError }
    var iconSpinner: UIColor { fallbackTheme.colors.iconSpinner }
    var iconAccentViolet: UIColor { fallbackTheme.colors.iconAccentViolet }
    var iconAccentBlue: UIColor { fallbackTheme.colors.iconAccentBlue }
    var iconAccentPink: UIColor { fallbackTheme.colors.iconAccentPink }
    var iconAccentGreen: UIColor { fallbackTheme.colors.iconAccentGreen }
    var iconAccentYellow: UIColor { fallbackTheme.colors.iconAccentYellow }
    var iconRatingNeutral: UIColor { fallbackTheme.colors.iconRatingNeutral }

    // MARK: - Border
    var borderPrimary: UIColor { ecosia.borderDecorative }
    var borderAccent: UIColor { actionPrimary }
    var borderAccentNonOpaque: UIColor { actionPrimary }
    var borderAccentPrivate: UIColor { actionPrimary }
    var borderInverted: UIColor { fallbackTheme.colors.borderInverted }
    var borderToolbarDivider: UIColor { fallbackTheme.colors.borderToolbarDivider }

    // MARK: - Shadow
    var shadowSubtle: UIColor { fallbackTheme.colors.shadowSubtle }
    var shadowDefault: UIColor { fallbackTheme.colors.shadowDefault }
    var shadowStrong: UIColor { fallbackTheme.colors.shadowStrong }
    var shadowBorder: UIColor { fallbackTheme.colors.shadowBorder }

    // MARK: - Gradient
    var gradientOnboardingStop1: UIColor { fallbackTheme.colors.gradientOnboardingStop1 }
    var gradientOnboardingStop2: UIColor { fallbackTheme.colors.gradientOnboardingStop2 }
    var gradientOnboardingStop3: UIColor { fallbackTheme.colors.gradientOnboardingStop3 }
    var gradientOnboardingStop4: UIColor { fallbackTheme.colors.gradientOnboardingStop4 }
}

private struct EcosiaLightSemanticColors: EcosiaSemanticColors {
    var backgroundNeutralInverse: UIColor = EcosiaColor.Gray80
    var backgroundNeutralTertiary: UIColor = EcosiaColor.Gray70
    var backgroundFeatured: UIColor = EcosiaColor.Grellow100
    var backgroundGradient: UIColor = EcosiaColor.White
    var backgroundPrimary: UIColor = EcosiaColor.White
    var backgroundPrimaryDecorative: UIColor = EcosiaColor.Gray10
    var backgroundRoleNegative: UIColor = EcosiaColor.Peach100
    var backgroundSecondary: UIColor = EcosiaColor.Gray10
    var backgroundTertiary: UIColor = EcosiaColor.Gray20
    var backgroundQuaternary: UIColor = EcosiaColor.Gray20
    var backgroundElevation1: UIColor = EcosiaColor.White
    var backgroundElevation2: UIColor = EcosiaColor.White
    var borderDecorative: UIColor = EcosiaColor.Gray30
    var borderNegative: UIColor = EcosiaColor.Claret300
    var formBorderPrimaryActive: UIColor = EcosiaColor.Gray70
    var brandFeatured: UIColor = EcosiaColor.Grellow100
    var brandImpact: UIColor = EcosiaColor.Yellow40
    var brandPrimary: UIColor = EcosiaColor.Gray70
    var buttonBackgroundFeatured: UIColor = EcosiaColor.Grellow100
    var buttonBackgroundFeaturedActive: UIColor = EcosiaColor.Grellow300
    var buttonBackgroundFeaturedHover: UIColor = EcosiaColor.Grellow200
    var buttonBackgroundPrimary: UIColor = EcosiaColor.Gray70
    var buttonBackgroundPrimaryActive: UIColor = EcosiaColor.Gray50
    var buttonBackgroundSecondary: UIColor = EcosiaColor.White
    var buttonBackgroundSecondaryActive: UIColor = EcosiaColor.Gray40
    var buttonBackgroundSecondaryHover: UIColor = EcosiaColor.Gray30
    var buttonBackgroundTransparentActive: UIColor = EcosiaColor.Gray30.withAlphaComponent(0.32)
    var buttonContentPrimary: UIColor = EcosiaColor.White
    var buttonContentSecondary: UIColor = EcosiaColor.Gray70
    var buttonContentSecondaryStatic: UIColor = EcosiaColor.Gray70
    var highlighter: UIColor = EcosiaColor.Grellow100.withAlphaComponent(0.32)
    var linkPrimary: UIColor = EcosiaColor.Gray70
    var iconDecorative: UIColor = EcosiaColor.Gray50
    var iconInverseStrong: UIColor = EcosiaColor.White
    var segmentedControlBackgroundActive: UIColor = EcosiaColor.Gray70
    var segmentedControlBackgroundRest: UIColor = EcosiaColor.Gray30
    var stateDisabled: UIColor = EcosiaColor.Gray30
    var stateError: UIColor = EcosiaColor.Red50
    var switchKnobActive: UIColor = EcosiaColor.Gray70
    var switchKnobDisabled: UIColor = EcosiaColor.Gray30
    var textPrimary: UIColor = EcosiaColor.Gray70
    var textInversePrimary: UIColor = EcosiaColor.White
    var textSecondary: UIColor = EcosiaColor.Gray50
    var textStaticDark: UIColor = EcosiaColor.Gray70
    var textStaticLight: UIColor = EcosiaColor.White
    // NTP glass tokens are "static" — same value in light and dark because they overlay a photo.
    var buttonBgGlassStatic: UIColor = EcosiaColor.Gray90.withAlphaComponent(0.32)
    var buttonBgGlassStaticActive: UIColor = EcosiaColor.Gray90.withAlphaComponent(0.64)
    var borderGlassStatic: UIColor = EcosiaColor.White.withAlphaComponent(0x3D / 255.0)
}
