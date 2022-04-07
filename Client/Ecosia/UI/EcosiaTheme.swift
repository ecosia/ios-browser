/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

extension Theme {
    var isDark: Bool {
        return type(of: self) == DarkTheme.self
    }
}

extension UIView {
    func elevate() {
        ThemeManager.instance.current.isDark ? elevateDark() : elevateBright()
    }

    private func elevateBright() {
        layer.borderWidth = 1
        backgroundColor = UIColor.theme.ecosia.highlightedBackground
        layer.shadowRadius = 2
        layer.shadowOffset = .init(width: 0, height: 1)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.15
        layer.borderColor = UIColor.theme.ecosia.highlightedBorder.cgColor
    }

    private func elevateDark() {
        layer.borderWidth = 0
        backgroundColor = UIColor.theme.ecosia.highlightedBackground
    }
}

class EcosiaTheme {
    var primaryBrand: UIColor { UIColor(named: "primaryBrand")!}
    var secondaryBrand: UIColor { UIColor.Photon.Grey60 }
    var border: UIColor { .Light.border }

    var primaryBackground: UIColor { .Light.Background.primary }
    var tertiaryBackground: UIColor { .Light.Background.tertiary }
    var barBackground: UIColor { .white }
    var barSeparator: UIColor { UIColor.Photon.Grey20 }
    var treeCountText: UIColor { UIColor(named: "emerald")! }
    var treeCountBackground: UIColor { UIColor(rgb: 0xE2F7F1) }
    var impactTreeCountBackground: UIColor { treeCountBackground }
    var ntpImpactBackground: UIColor { .white}
    var impactBackground: UIColor { UIColor.Photon.Grey10 }
    var impactMultiplyCardBackground: UIColor { .white }
    var impactMultiplyCardBorder: UIColor { .Photon.Grey20 }
    
    var actionSheetBackground: UIColor { .Light.Background.primary }
    var modalBackground: UIColor { .white }

    var primaryText: UIColor { .Light.Text.primary }
    var primaryTextInverted: UIColor { .Dark.Text.primary }
    var secondaryText: UIColor { .Light.Text.secondary }
    var highContrastText: UIColor { UIColor.Photon.Grey90 }
    var navigationBarText: UIColor { .Light.Text.primary }

    var highlightedBackground: UIColor { .white }
    var highlightedBorder: UIColor { UIColor(named: "highlightedBorder")!}
    var hoverBackgroundColor: UIColor { UIColor.Photon.Grey20 }

    var primaryToolbar: UIColor { UIColor(named: "primaryToolbar")!}
    var primaryButton: UIColor { .Light.Button.primary }
    var primaryButtonActive: UIColor { .Light.Button.primaryActive }
    var textfieldPlaceholder: UIColor { UIColor.Photon.Grey60 }
    var personalCounterBorder: UIColor { UIColor.Photon.Grey20 }
    var personalCounterSelection: UIColor { UIColor.Photon.Grey20 }
    var privateButtonBackground: UIColor { UIColor.Photon.Grey70 }

    var banner: UIColor { return UIColor(named: "banner")!}
    var underlineGrey: UIColor { return UIColor(named: "underlineGrey")! }
    var cardText: UIColor { UIColor(named: "cardText")!}
    var welcomeScreenBackground: UIColor { UIColor.Photon.Grey70.withAlphaComponent(0.4) }

    var teal60: UIColor { UIColor(rgb: 0x267A82) }
    var segmentSelectedText: UIColor { UIColor(named: "primaryText")! }
    var segmentBackground: UIColor { .Light.Background.secondary }
    var warning: UIColor { .Light.State.warning }
    var information: UIColor { .Light.State.information }

    var tabBackground: UIColor { .Light.Background.primary }
    var tabSelectedBackground: UIColor { .Light.Button.primary }
    var tabSelectedPrivateBackground: UIColor { .Dark.Background.secondary }
}

final class DarkEcosiaTheme: EcosiaTheme {
    override var primaryBrand: UIColor { UIColor(named: "primaryBrandDark")!}
    override var secondaryBrand: UIColor { .white }
    override var border: UIColor { .Dark.border }

    override var primaryBackground: UIColor { .Dark.Background.primary }
    override var tertiaryBackground: UIColor { .Dark.Background.tertiary }
    override var barBackground: UIColor { UIColor.Photon.Grey80 }
    override var barSeparator: UIColor { UIColor.Photon.Grey60 }
    override var treeCountText: UIColor { .white }
    override var treeCountBackground: UIColor { UIColor.Photon.Grey70 }
    override var impactTreeCountBackground: UIColor { UIColor.Photon.Grey80 }
    override var ntpImpactBackground: UIColor { UIColor.Photon.Grey80}
    override var impactBackground: UIColor { UIColor.Photon.Grey60 }
    override var impactMultiplyCardBackground: UIColor { .Photon.Grey70 }
    override var impactMultiplyCardBorder: UIColor { .clear }

    override var actionSheetBackground: UIColor { .Dark.Background.secondary }
    override var modalBackground: UIColor { UIColor.Photon.Grey80 }

    override var primaryText: UIColor { .Dark.Text.primary}
    override var primaryTextInverted: UIColor { .Light.Text.primary }
    override var secondaryText: UIColor { .Dark.Text.secondary }
    override var highContrastText: UIColor { .white }
    override var navigationBarText: UIColor { .Dark.Text.primary }

    override var highlightedBackground: UIColor { UIColor.Photon.Grey70 }
    override var hoverBackgroundColor: UIColor { UIColor.Photon.Grey90 }

    override var primaryButton: UIColor { .Dark.Button.primary }
    override var primaryButtonActive: UIColor { .Dark.Button.primaryActive }

    override var textfieldPlaceholder: UIColor { UIColor.Photon.Grey40 }
    override var personalCounterBorder: UIColor { UIColor.Photon.Grey60 }
    override var personalCounterSelection: UIColor { UIColor.Photon.Grey60 }
    override var privateButtonBackground: UIColor { .white }

    override var banner: UIColor { return UIColor(named: "bannerDark")!}
    override var underlineGrey: UIColor { return UIColor(named: "underlineGreyDark")! }
    override var cardText: UIColor { UIColor(named: "cardTextDark")!}
    override var welcomeScreenBackground: UIColor { UIColor.Photon.Grey90.withAlphaComponent(0.8) }

    override var segmentSelectedText: UIColor { UIColor.Photon.Grey90 }
    override var segmentBackground: UIColor { .Dark.Background.tertiary }
    override var warning: UIColor { .Dark.State.warning }
    override var information: UIColor { .Dark.State.information }

    override var tabBackground: UIColor { .Dark.Background.tertiary }
    override var tabSelectedBackground: UIColor { .Dark.Button.primary }
    override var tabSelectedPrivateBackground: UIColor { .white}
}

extension UIImage {
    convenience init?(themed name: String) {
        let suffix = ThemeManager.instance.current.isDark ? "Dark" : ""
        self.init(named: name + suffix)
    }
}

extension DynamicFontHelper {
    var LargeSizeMediumFontAS: UIFont {
        let size = min(DeviceFontSize + 3, 18)
        return UIFont.systemFont(ofSize: size, weight: .medium)
    }
}
