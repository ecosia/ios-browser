// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

// This file contains all of Ecosia official semantic color tokens referenced in the link below.
// https://www.figma.com/design/8T2rTBVwynJKSdY6MQo5PQ/%E2%9A%9B%EF%B8%8F--Foundations?node-id=2237-3418&t=UKHtrxcc9UtOihsm-0
// They are adopted by `EcosiaLightTheme` and `EcosiaDarkTheme` and should use `EcosiaColorPrimitive`.
public protocol EcosiaSemanticColors {
    // MARK: - Background
    var backgroundPrimary: UIColor { get }
    var backgroundSecondary: UIColor { get }
    var backgroundTertiary: UIColor { get }
    var backgroundQuaternary: UIColor { get }

    // MARK: - Border
    var borderDecorative: UIColor { get }

    // MARK: - Brand
    var brandPrimary: UIColor { get }

    // MARK: - Button
    var buttonBackgroundPrimary: UIColor { get }
    var buttonBackgroundPrimaryActive: UIColor { get }
    var buttonBackgroundSecondary: UIColor { get }
    var buttonBackgroundSecondaryHover: UIColor { get }
    var buttonContentSecondary: UIColor { get }
    var buttonBackgroundTransparentActive: UIColor { get }

    // MARK: - Icon
    var iconPrimary: UIColor { get }
    var iconSecondary: UIColor { get }
    var iconDecorative: UIColor { get }

    // MARK: - State
    var stateError: UIColor { get }
    var stateInformation: UIColor { get }
    var stateDisabled: UIColor { get }

    // MARK: - Text
    var textPrimary: UIColor { get }
    var textSecondary: UIColor { get }
    var textTertiary: UIColor { get }
}

public protocol EcosiaThemeColourPalette: ThemeColourPalette {
    var ecosia: EcosiaSemanticColors { get }
}
