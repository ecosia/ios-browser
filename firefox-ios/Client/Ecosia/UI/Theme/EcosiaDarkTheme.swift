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

public struct EcosiaDarkTheme: Theme {
    public var type: ThemeType = .dark
    public var colors: EcosiaThemeColourPalette = EcosiaDarkColourPalette()
}

private class EcosiaDarkColourPalette: EcosiaLightColourPalette {
    override var ecosia: EcosiaSemanticColors {
        EcosiaDarkSemanticColors()
    }

    override var fallbackTheme: Theme {
        DarkTheme()
    }

    override var layer1: UIColor { ecosia.backgroundPrimary }
}

private struct EcosiaDarkSemanticColors: EcosiaSemanticColors {
    var backgroundPrimary: UIColor = EcosiaColor.Gray90
    var backgroundSecondary: UIColor = EcosiaColor.Gray80
    var backgroundTertiary: UIColor = EcosiaColor.Gray70
    var backgroundQuaternary: UIColor = EcosiaColor.Green20
    var borderDecorative: UIColor = EcosiaColor.Gray60
    var brandPrimary: UIColor = EcosiaColor.Green30
    var buttonBackgroundPrimary: UIColor = EcosiaColor.Green30
    var buttonBackgroundPrimaryActive: UIColor = EcosiaColor.Green50 // ⚠️ Mismatch
    var buttonBackgroundSecondary: UIColor = EcosiaColor.Gray70 // ⚠️ Mismatch
    var buttonBackgroundSecondaryHover: UIColor = EcosiaColor.Gray70
    var buttonContentSecondary: UIColor = EcosiaColor.White
    var buttonBackgroundTransparentActive: UIColor = EcosiaColor.Gray30.withAlphaComponent(0.32)
    var backgroundHighlighted: UIColor = EcosiaColor.DarkGreen30
    var iconPrimary: UIColor = EcosiaColor.White
    var iconSecondary: UIColor = EcosiaColor.Green30
    var iconDecorative: UIColor = EcosiaColor.Gray40 // ⚠️ Mismatch
    var stateError: UIColor = EcosiaColor.Red30
    var stateInformation: UIColor = EcosiaColor.Blue30 // ⚠️ No match
    var stateDisabled: UIColor = EcosiaColor.Gray50
    var textPrimary: UIColor = EcosiaColor.White
    var textInversePrimary: UIColor = EcosiaColor.Black // ⚠️ Mismatch
    var textSecondary: UIColor = EcosiaColor.Gray30
    var textTertiary: UIColor = EcosiaColor.Gray70 // ⚠️ Mismatch

    // MARK: Unmapped Snowflakes
    var barBackground: UIColor = EcosiaColor.Gray80
    var barSeparator: UIColor = .Photon.Grey60
    var ntpCellBackground: UIColor = EcosiaColor.Gray70
    var ntpBackground: UIColor = EcosiaColor.Gray90
    var ntpIntroBackground: UIColor = EcosiaColor.Gray80
    var impactMultiplyCardBackground: UIColor = EcosiaColor.Gray70
    var newsPlaceholder: UIColor = EcosiaColor.Gray50
    var modalBackground: UIColor = EcosiaColor.Gray80
    var modalHeader: UIColor = EcosiaColor.Gray80
    var secondarySelectedBackground: UIColor = .init(rgb: 0x3A3A3A)
    var buttonBackgroundNTPCustomization: UIColor = EcosiaColor.Gray80
    var privateButtonBackground: UIColor = EcosiaColor.White
    var tabSelectedPrivateBackground: UIColor = EcosiaColor.White
}
