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

private class EcosiaDarkSemanticColors: EcosiaSemanticColors {
    var backgroundPrimary: UIColor = EcosiaColorPrimitive.Gray90
    var backgroundSecondary: UIColor = EcosiaColorPrimitive.Gray80
    var backgroundTertiary: UIColor = EcosiaColorPrimitive.Gray70
    var backgroundQuaternary: UIColor = EcosiaColorPrimitive.Green20
    var borderDecorative: UIColor = EcosiaColorPrimitive.Gray60
    var brandPrimary: UIColor = EcosiaColorPrimitive.Green30
    var buttonBackgroundPrimary: UIColor = EcosiaColorPrimitive.Green30
    var buttonBackgroundPrimaryActive: UIColor = EcosiaColorPrimitive.Green50
    var buttonBackgroundSecondary: UIColor = EcosiaColorPrimitive.Gray70
    var buttonBackgroundSecondaryHover: UIColor = EcosiaColorPrimitive.Gray70
    var buttonContentSecondary: UIColor = EcosiaColorPrimitive.White
    var buttonBackgroundTransparentActive: UIColor = EcosiaColorPrimitive.Gray30.withAlphaComponent(0.32)
    var iconPrimary: UIColor = EcosiaColorPrimitive.White
    var iconSecondary: UIColor = EcosiaColorPrimitive.Green30
    var iconDecorative: UIColor = EcosiaColorPrimitive.Gray40
    var stateError: UIColor = EcosiaColorPrimitive.Red30
    var stateInformation: UIColor = EcosiaColorPrimitive.Blue30
    var stateDisabled: UIColor = EcosiaColorPrimitive.Gray50
    var textPrimary: UIColor = EcosiaColorPrimitive.White
    var textSecondary: UIColor = EcosiaColorPrimitive.Gray30
    var textTertiary: UIColor = EcosiaColorPrimitive.Gray70

    // MARK: Unmapped Snowflakes
    var barBackground: UIColor = EcosiaColorPrimitive.Gray80
    var barSeparator: UIColor = .Photon.Grey60
    var ntpCellBackground: UIColor = EcosiaColorPrimitive.Gray70
    var ntpBackground: UIColor = EcosiaColorPrimitive.Gray90
    var ntpIntroBackground: UIColor = EcosiaColorPrimitive.Gray80
    var impactMultiplyCardBackground: UIColor = EcosiaColorPrimitive.Gray70
    var newsPlaceholder: UIColor = EcosiaColorPrimitive.Gray50
    var modalBackground: UIColor = EcosiaColorPrimitive.Gray80
    var modalHeader: UIColor = EcosiaColorPrimitive.Gray80
}
