// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

extension LegacyTheme {
    var isDark: Bool {
        return type(of: self) == DarkTheme.self
    }
}

class EcosiaTheme {
    var secondaryBackground: UIColor { .Light.Background.secondary }
    var tertiaryBackground: UIColor { .Light.Background.tertiary }
    var quarternaryBackground: UIColor { .Light.Background.quarternary }
    var barBackground: UIColor { .white }
    var barSeparator: UIColor { UIColor.Photon.Grey20 }
    var impactBackground: UIColor { .Light.Background.primary }
    var impactSeparator: UIColor { UIColor.Photon.Grey40 }
    var treeCounterProgressTotal: UIColor { .Light.Background.tertiary }
    var treeCounterProgressCurrent: UIColor { .Light.Brand.primary }
    var treeCounterProgressBorder: UIColor { .Light.Background.tertiary }

    var ntpCellBackground: UIColor { .Light.Background.primary }
    var ntpBackground: UIColor { .Light.Background.tertiary }
    var ntpIntroBackground: UIColor { .Light.Background.primary }
    var ntpImpactBackground: UIColor { .Light.Background.primary }

    var impactMultiplyCardBackground: UIColor { .Light.Background.primary }
    var trackingSheetBackground: UIColor { .Light.Background.tertiary }
    var moreNewsButton: UIColor { .Light.Button.backgroundSecondary }
    var newsPlaceholder: UIColor { .Light.Background.secondary }

    var actionSheetBackground: UIColor { .Light.Background.primary }
    var actionSheetCancelButton: UIColor { .Light.Button.backgroundPrimaryActive }
    var modalBackground: UIColor { .Light.Background.tertiary }
    var modalHeader: UIColor { .init(red: 0.153, green: 0.322, blue: 0.263, alpha: 1) }

    var whatsNewCloseButton: UIColor { .Light.Text.primary }

    var primaryText: UIColor { .Light.Text.primary }
    var primaryTextInverted: UIColor { .Dark.Text.primary }
    var secondaryText: UIColor { .Light.Text.secondary }
    var navigationBarText: UIColor { .Light.Text.primary }
    var tertiaryText: UIColor { .Light.Text.tertiary }

    var primaryIcon: UIColor { .Light.Icon.primary }
    var secondaryIcon: UIColor { .Light.Icon.secondary }
    var decorativeIcon: UIColor { .Light.Icon.decorative }

    var highlightedBackground: UIColor { .Light.Background.highlighted }
    var primarySelectedBackground: UIColor { .Light.Background.secondary }
    var secondarySelectedBackground: UIColor { .Light.Background.secondary }

    var primaryButton: UIColor { .Light.Button.backgroundPrimary }
    var primaryButtonActive: UIColor { .Light.Button.backgroundPrimaryActive }
    var secondaryButton: UIColor { .Light.Button.backgroundSecondary }
    var secondaryButtonContent: UIColor { .Light.Button.contentSecondary }
    var secondaryButtonBackground: UIColor { .Light.Button.secondaryBackground }
    var activeTransparentBackground: UIColor { .Light.Button.backgroundTransparentActive }

    var textfieldPlaceholder: UIColor { .Light.Text.secondary }
    var textfieldIconTint: UIColor { .Light.Button.backgroundPrimary }
    var personalCounterSelection: UIColor { UIColor.Photon.Grey20 }
    var privateButtonBackground: UIColor { UIColor.Photon.Grey70 }

    var modalOverlayBackground: UIColor { UIColor(rgb: 0x333333).withAlphaComponent(0.4) }

    var segmentSelectedText: UIColor { .Light.Text.primary }
    var segmentBackground: UIColor { .Light.Background.secondary }

    var warning: UIColor { .Light.State.error }
    var information: UIColor { .Light.State.information }
    var disabled: UIColor { .Light.State.disabled }

    var tabBackground: UIColor { .Light.Background.primary }
    var tabSelectedBackground: UIColor { .Light.Button.backgroundPrimary }
    var tabSelectedPrivateBackground: UIColor { .Dark.Background.secondary }

    var toastImageTint: UIColor { .init(red: 0.847, green: 1, blue: 0.502, alpha: 1) }
    var autocompleteBackground: UIColor { .Light.Background.primary }
    var welcomeBackground: UIColor { .Light.Background.tertiary }
    var welcomeElementBackground: UIColor { .Light.Background.primary }

    var homePanelBackground: UIColor { return .Light.Background.tertiary }
    var peach: UIColor { .init(rgb: 0xFFE6BF) }
}

final class DarkEcosiaTheme: EcosiaTheme {
    override var secondaryBackground: UIColor { .Dark.Background.secondary }
    override var tertiaryBackground: UIColor { .Dark.Background.tertiary }
    override var quarternaryBackground: UIColor { .Dark.Background.quarternary }
    override var barBackground: UIColor { .Dark.Background.secondary }
    override var barSeparator: UIColor { UIColor.Photon.Grey60 }
    override var impactBackground: UIColor { .Dark.Background.tertiary }
    override var impactSeparator: UIColor { UIColor.Photon.Grey60 }
    override var treeCounterProgressTotal: UIColor { .Dark.Background.secondary }
    override var treeCounterProgressCurrent: UIColor { .Dark.Brand.primary }
    override var treeCounterProgressBorder: UIColor { .Dark.Background.tertiary }

    override var ntpCellBackground: UIColor { .Dark.Background.tertiary }
    override var ntpBackground: UIColor { .Dark.Background.primary }
    override var ntpImpactBackground: UIColor { .Dark.Background.secondary}
    override var ntpIntroBackground: UIColor { .Dark.Background.tertiary }

    override var impactMultiplyCardBackground: UIColor { .Dark.Background.tertiary }
    override var trackingSheetBackground: UIColor { .Dark.Background.secondary }
    override var moreNewsButton: UIColor { .Dark.Background.primary }
    override var newsPlaceholder: UIColor { .Grey.fifty }

    override var actionSheetBackground: UIColor { .Dark.Background.secondary }
    override var actionSheetCancelButton: UIColor { .Dark.Button.backgroundPrimaryActive }
    override var modalBackground: UIColor { .Dark.Background.secondary }
    override var modalHeader: UIColor { .Dark.Background.secondary }

    override var whatsNewCloseButton: UIColor { .white }

    override var primaryText: UIColor { .Dark.Text.primary}
    override var primaryTextInverted: UIColor { .Light.Text.primary }
    override var secondaryText: UIColor { .Dark.Text.secondary }
    override var navigationBarText: UIColor { .Dark.Text.primary }
    override var tertiaryText: UIColor { .Dark.Text.tertiary }

    override var primaryIcon: UIColor { .Dark.Icon.primary }
    override var secondaryIcon: UIColor { .Dark.Icon.secondary }
    override var decorativeIcon: UIColor { .Dark.Icon.decorative }

    override var highlightedBackground: UIColor { .Dark.Background.highlighted }

    override var primarySelectedBackground: UIColor { .Dark.Background.tertiary }
    override var secondarySelectedBackground: UIColor { .init(red: 0.227, green: 0.227, blue: 0.227, alpha: 1) }

    override var primaryButton: UIColor { .Dark.Button.backgroundPrimary }
    override var primaryButtonActive: UIColor { .Dark.Button.backgroundPrimaryActive }
    override var secondaryButton: UIColor { .Dark.Button.backgroundSecondary }
    override var secondaryButtonContent: UIColor { .Dark.Button.contentSecondary }
    override var secondaryButtonBackground: UIColor { .Dark.Button.secondaryBackground }
    override var activeTransparentBackground: UIColor { .Dark.Button.backgroundTransparentActive }

    override var textfieldPlaceholder: UIColor { .Dark.Text.secondary }
    override var textfieldIconTint: UIColor { .Dark.Button.backgroundPrimary }

    override var personalCounterSelection: UIColor { UIColor.Photon.Grey60 }
    override var privateButtonBackground: UIColor { .white }

    override var modalOverlayBackground: UIColor { UIColor(rgb: 0x333333).withAlphaComponent(0.6) }

    override var segmentSelectedText: UIColor { UIColor.Photon.Grey90 }
    override var segmentBackground: UIColor { .Dark.Background.tertiary }

    override var warning: UIColor { .Dark.State.error }
    override var information: UIColor { .Dark.State.information }
    override var disabled: UIColor { .Dark.State.disabled }

    override var tabBackground: UIColor { .Dark.Background.tertiary }
    override var tabSelectedBackground: UIColor { .Dark.Button.backgroundPrimary }
    override var tabSelectedPrivateBackground: UIColor { .white}

    override var toastImageTint: UIColor { .init(red: 0.153, green: 0.322, blue: 0.263, alpha: 1) }
    override var autocompleteBackground: UIColor { .Dark.Background.secondary }
    override var welcomeBackground: UIColor { .Dark.Background.secondary }
    override var welcomeElementBackground: UIColor { .Dark.Background.secondary }

    override var homePanelBackground: UIColor { return .Dark.Background.secondary }
    override var peach: UIColor { .init(rgb: 0xCC7722) }
}

extension UIImage {
    convenience init?(themed name: String) {
        let suffix = LegacyThemeManager.instance.current.isDark ? "Dark" : ""
        self.init(named: name + suffix)
    }
}

class EcosiaPrimaryButton: UIButton {
    override var isSelected: Bool {
        get {
            return super.isSelected
        }
        set {
            super.isSelected = newValue
            update()
        }
    }

    override var isHighlighted: Bool {
        get {
            return super.isHighlighted
        }
        set {
            super.isHighlighted = newValue
            update()
        }
    }

    private func update() {
        backgroundColor = (isSelected || isHighlighted) ? .legacyTheme.ecosia.primaryButtonActive : .legacyTheme.ecosia.primaryButton
    }
}
