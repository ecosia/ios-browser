// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

// This file is owned by Ecosia, it is only part of BrowserKit.Common since it needs to be used inside it.
// It contains all of Ecosia official semantic color tokens referenced in the link below.
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

/// Serves to make Firefox themes conform the new protocol.
/// Should never end up in production UI!
class FakeEcosiaSemanticColors: EcosiaSemanticColors {
    var backgroundPrimary: UIColor = .systemGray
    var backgroundSecondary: UIColor = .systemGray
    var backgroundTertiary: UIColor = .systemGray
    var backgroundQuaternary: UIColor = .systemGray
    var borderDecorative: UIColor = .systemGray
    var brandPrimary: UIColor = .systemGray
    var buttonBackgroundPrimary: UIColor = .systemGray
    var buttonBackgroundPrimaryActive: UIColor = .systemGray
    var buttonBackgroundSecondary: UIColor = .systemGray
    var buttonBackgroundSecondaryHover: UIColor = .systemGray
    var buttonContentSecondary: UIColor = .systemGray
    var buttonBackgroundTransparentActive: UIColor = .systemGray
    var iconPrimary: UIColor = .systemGray
    var iconSecondary: UIColor = .systemGray
    var iconDecorative: UIColor = .systemGray
    var stateError: UIColor = .systemGray
    var stateInformation: UIColor = .systemGray
    var stateDisabled: UIColor = .systemGray
    var textPrimary: UIColor = .systemGray
    var textSecondary: UIColor = .systemGray
    var textTertiary: UIColor = .systemGray
}
