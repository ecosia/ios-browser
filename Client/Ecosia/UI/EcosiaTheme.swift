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

    var primaryBackground: UIColor { .white }
    var barBackground: UIColor { .white }
    var barSeparator: UIColor { UIColor.Photon.Grey20 }

    var actionSheetBackground: UIColor { .white }
    var modalBackground: UIColor { .white }

    var primaryText: UIColor { UIColor(named: "primaryText")! }
    var secondaryText: UIColor { UIColor.Photon.Grey50 }
    var highContrastText: UIColor { UIColor.Photon.Grey90 }

    var highlightedBackground: UIColor { .white }
    var highlightedBorder: UIColor { UIColor(named: "highlightedBorder")!}
    var hoverBackgroundColor: UIColor { UIColor.Photon.Grey20 }

    var primaryToolbar: UIColor { UIColor(named: "primaryToolbar")!}
    var primaryButton: UIColor { UIColor.Photon.Blue50 }
    var textfieldPlaceholder: UIColor { UIColor.Photon.Grey50 }
    var personalCounterBorder: UIColor { UIColor.Photon.Grey30 }
    var personalCounterSelection: UIColor { UIColor.Photon.Grey20 }

    var banner: UIColor { return UIColor(named: "banner")!}
    var underlineGrey: UIColor { return UIColor(named: "underlineGrey")! }
    var cardText: UIColor { UIColor(named: "cardText")!}
    var welcomeScreenBackground: UIColor { UIColor.Photon.Grey70.withAlphaComponent(0.4) }
}

final class DarkEcosiaTheme: EcosiaTheme {
    override var highContrastText: UIColor { .white }
    override var primaryBrand: UIColor { UIColor(named: "primaryBrandDark")!}
    override var secondaryBrand: UIColor { .white }
    override var primaryBackground: UIColor { UIColor.Photon.Grey90 }
    override var barBackground: UIColor { UIColor.Photon.Grey80 }
    override var barSeparator: UIColor { UIColor.Photon.Grey60 }
    override var actionSheetBackground: UIColor { UIColor.Photon.Grey70 }
    override var modalBackground: UIColor { UIColor.Photon.Grey80 }
    override var textfieldPlaceholder: UIColor { UIColor.Photon.Grey20 }
    override var personalCounterBorder: UIColor { UIColor.Photon.Grey60 }
    override var personalCounterSelection: UIColor { UIColor.Photon.Grey60 }


    override var primaryText: UIColor { UIColor(named: "primaryTextDark")! }
    override var secondaryText: UIColor { UIColor.Photon.Grey30 }
    override var highlightedBackground: UIColor { UIColor.Photon.Grey70 }

    override var banner: UIColor { return UIColor(named: "bannerDark")!}
    override var underlineGrey: UIColor { return UIColor(named: "underlineGreyDark")! }
    override var hoverBackgroundColor: UIColor { UIColor.Photon.Grey90 }
    override var cardText: UIColor { UIColor(named: "cardTextDark")!}
    override var welcomeScreenBackground: UIColor { UIColor.Photon.Grey90.withAlphaComponent(0.8) }
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
