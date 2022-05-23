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
    var primaryBrand: UIColor { .Light.Brand.primary}
    var secondaryBrand: UIColor { UIColor.Photon.Grey60 }
    var border: UIColor { .Light.border }

    var primaryBackground: UIColor { .Light.Background.primary }
    var tertiaryBackground: UIColor { .Light.Background.tertiary }
    var quarternaryBackground: UIColor { .Light.Background.quarternary }
    var barBackground: UIColor { .white }
    var barSeparator: UIColor { UIColor.Photon.Grey20 }
    var treeCountText: UIColor { UIColor(named: "emerald")! }
    var treeCountBackground: UIColor { UIColor(rgb: 0xE2F7F1) }
    var impactTreeCountBackground: UIColor { treeCountBackground }
    var impactBackground: UIColor { UIColor.Photon.Grey10 }
    var impactSeparator: UIColor { UIColor.Photon.Grey40 }
    var treeCounterProgressTotal: UIColor { .Light.Background.tertiary }
    var treeCounterProgressCurrent: UIColor { .Light.Brand.primary }
    var treeCounterProgressBorder: UIColor { .Light.Background.primary }

    var ntpCellBackground: UIColor { .Light.Background.primary }
    var ntpBackground: UIColor { .Light.Background.tertiary }
    var ntpIntroBackground: UIColor { .Light.Background.primary }
    var ntpImpactBackground: UIColor { .white }

    var impactMultiplyCardBackground: UIColor { .Light.Background.primary }
    var trackingSheetBackground: UIColor { .Light.Background.tertiary }
    var moreNewsButton: UIColor { .Light.Button.secondary }
    
    var actionSheetBackground: UIColor { .Light.Background.primary }
    var modalBackground: UIColor { .Light.Background.tertiary }
    var modalHeader: UIColor { .init(red: 0.153, green: 0.322, blue: 0.263, alpha: 1) }

    var primaryText: UIColor { .Light.Text.primary }
    var primaryTextInverted: UIColor { .Dark.Text.primary }
    var secondaryText: UIColor { .Light.Text.secondary }
    var highContrastText: UIColor { UIColor.Photon.Grey90 }
    var navigationBarText: UIColor { .Light.Text.primary }

    var primaryIcon: UIColor { .Light.Icon.primary }
    
    var highlightedBackground: UIColor { .Light.Background.highlighted }
    var highlightedBorder: UIColor { UIColor(named: "highlightedBorder")!}
    var hoverBackgroundColor: UIColor { UIColor.Photon.Grey20 }

    var primaryToolbar: UIColor { UIColor(named: "primaryToolbar")!}
    var primaryButton: UIColor { .Light.Button.primary }
    var primaryButtonActive: UIColor { .Light.Button.primaryActive }
    var secondaryButton: UIColor { .Light.Button.secondary }
    var textfieldPlaceholder: UIColor { .Light.Text.secondary }
    var textfieldIconTint: UIColor { .Light.Button.primary }
    var personalCounterBorder: UIColor { UIColor.Photon.Grey20 }
    var personalCounterSelection: UIColor { UIColor.Photon.Grey20 }
    var privateButtonBackground: UIColor { UIColor.Photon.Grey70 }

    var banner: UIColor { return UIColor(named: "banner")!}
    var underlineGrey: UIColor { return UIColor(named: "underlineGrey")! }
    var cardText: UIColor { UIColor(named: "cardText")!}
    var modalOverlayBackground: UIColor { UIColor(rgb: 0x333333).withAlphaComponent(0.4) }

    var teal60: UIColor { UIColor(rgb: 0x267A82) }
    var segmentSelectedText: UIColor { .Light.Text.primary }
    var segmentBackground: UIColor { .Light.Background.secondary }

    var warning: UIColor { .Light.State.warning }
    var information: UIColor { .Light.State.information }
    var disabled: UIColor { .Light.State.disabled }

    var tabBackground: UIColor { .Light.Background.primary }
    var tabSelectedBackground: UIColor { .Light.Button.primary }
    var tabSelectedPrivateBackground: UIColor { .Dark.Background.secondary }

    var toastImageTint: UIColor { .init(red: 0.847, green: 1, blue: 0.502, alpha: 1) }
    var autocompleteBackground: UIColor { .Light.Background.primary }
    var welcomeBackground: UIColor { .Light.Background.tertiary }
    var welcomeElementBackground: UIColor { .Light.Background.primary }
}

final class DarkEcosiaTheme: EcosiaTheme {
    override var primaryBrand: UIColor { .Dark.Brand.primary}
    override var secondaryBrand: UIColor { .white }
    override var border: UIColor { .Dark.border }

    override var primaryBackground: UIColor { .Dark.Background.primary }
    override var tertiaryBackground: UIColor { .Dark.Background.tertiary }
    override var quarternaryBackground: UIColor { .Dark.Background.quarternary }
    override var barBackground: UIColor { UIColor.Photon.Grey80 }
    override var barSeparator: UIColor { UIColor.Photon.Grey60 }
    override var treeCountText: UIColor { .white }
    override var treeCountBackground: UIColor { UIColor.Photon.Grey70 }
    override var impactTreeCountBackground: UIColor { UIColor.Photon.Grey80 }
    override var impactSeparator: UIColor { UIColor.Photon.Grey60 }
    override var treeCounterProgressTotal: UIColor { .Dark.Background.secondary }
    override var treeCounterProgressCurrent: UIColor { .Dark.Brand.primary }
    override var treeCounterProgressBorder: UIColor { .Dark.Background.primary }

    override var ntpCellBackground: UIColor { .Dark.Background.tertiary }
    override var ntpBackground: UIColor { .Dark.Background.primary }
    override var ntpImpactBackground: UIColor { .Dark.Background.secondary}
    override var ntpIntroBackground: UIColor { .Dark.Background.tertiary }

    override var impactBackground: UIColor { UIColor.Photon.Grey60 }
    override var impactMultiplyCardBackground: UIColor { .Dark.Background.tertiary }
    override var trackingSheetBackground: UIColor { .Dark.Background.secondary }
    override var moreNewsButton: UIColor { .Dark.Background.tertiary }

    override var actionSheetBackground: UIColor { .Dark.Background.secondary }
    override var modalBackground: UIColor { .Dark.Background.secondary }
    override var modalHeader: UIColor { .Dark.Background.secondary }

    override var primaryText: UIColor { .Dark.Text.primary}
    override var primaryTextInverted: UIColor { .Light.Text.primary }
    override var secondaryText: UIColor { .Dark.Text.secondary }
    override var highContrastText: UIColor { .white }
    override var navigationBarText: UIColor { .Dark.Text.primary }

    override var primaryIcon: UIColor { .Dark.Icon.primary }
    
    override var highlightedBackground: UIColor { .Dark.Background.highlighted }
    override var hoverBackgroundColor: UIColor { UIColor.Photon.Grey90 }

    override var primaryButton: UIColor { .Dark.Button.primary }
    override var primaryButtonActive: UIColor { .Dark.Button.primaryActive }
    override var secondaryButton: UIColor { .Dark.Button.secondary }

    override var textfieldPlaceholder: UIColor { .Dark.Text.secondary }
    override var textfieldIconTint: UIColor { .Dark.Text.secondary }

    override var personalCounterBorder: UIColor { UIColor.Photon.Grey60 }
    override var personalCounterSelection: UIColor { UIColor.Photon.Grey60 }
    override var privateButtonBackground: UIColor { .white }

    override var banner: UIColor { return UIColor(named: "bannerDark")!}
    override var underlineGrey: UIColor { return UIColor(named: "underlineGreyDark")! }
    override var cardText: UIColor { UIColor(named: "cardTextDark")!}
    override var modalOverlayBackground: UIColor { UIColor(rgb: 0x333333).withAlphaComponent(0.6) }

    override var segmentSelectedText: UIColor { UIColor.Photon.Grey90 }
    override var segmentBackground: UIColor { .Dark.Background.tertiary }

    override var warning: UIColor { .Dark.State.warning }
    override var information: UIColor { .Dark.State.information }
    override var disabled: UIColor { .Dark.State.disabled }

    override var tabBackground: UIColor { .Dark.Background.tertiary }
    override var tabSelectedBackground: UIColor { .Dark.Button.primary }
    override var tabSelectedPrivateBackground: UIColor { .white}

    override var toastImageTint: UIColor { .init(red: 0.153, green: 0.322, blue: 0.263, alpha: 1) }
    override var autocompleteBackground: UIColor { .Dark.Background.secondary }
    override var welcomeBackground: UIColor { .Dark.Background.secondary }
    override var welcomeElementBackground: UIColor { .Dark.Background.secondary }
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

class EcosiaPrimaryButton: UIButton {
    override var isSelected: Bool {
        set {
            super.isSelected = newValue
            update()
        }
        get {
            return super.isSelected
        }
    }

    override var isHighlighted: Bool {
        set {
            super.isHighlighted = newValue
            update()
        }
        get {
            return super.isHighlighted
        }
    }

    private func update() {
        backgroundColor = (isSelected || isHighlighted) ? .theme.ecosia.primaryButtonActive : .theme.ecosia.primaryButton
    }
}
