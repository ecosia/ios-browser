// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

public struct AddressToolbarUXConfiguration {
    // Ecosia: Use 22pt corner radius to match legacy URLBarView Ecosia styling on all iOS versions.
    private(set) var toolbarCornerRadius: CGFloat = 22
    let browserActionsAddressBarDividerWidth: CGFloat
    let isLocationTextCentered: Bool
    let hasAlternativeLocationColor: Bool
    let locationTextFieldTrailingPadding: CGFloat
    let shouldBlur: Bool
    let backgroundAlpha: CGFloat
    /// Alpha value that controls element visibility during scroll-based address bar transitions.
    /// Changes between 0 (hidden) and 1 (visible) based on scroll direction.
    let scrollAlpha: CGFloat

    public static func experiment(backgroundAlpha: CGFloat = 1.0,
                                  scrollAlpha: CGFloat = 1.0,
                                  shouldBlur: Bool = false,
                                  hasAlternativeLocationColor: Bool = false) -> AddressToolbarUXConfiguration {
        AddressToolbarUXConfiguration(
            browserActionsAddressBarDividerWidth: 0.0,
            isLocationTextCentered: true,
            hasAlternativeLocationColor: hasAlternativeLocationColor,
            locationTextFieldTrailingPadding: 0,
            shouldBlur: shouldBlur,
            backgroundAlpha: backgroundAlpha,
            scrollAlpha: scrollAlpha
        )
    }

    public static func `default`(backgroundAlpha: CGFloat = 1.0,
                                 scrollAlpha: CGFloat = 1.0,
                                 shouldBlur: Bool = false,
                                 hasAlternativeLocationColor: Bool = false) -> AddressToolbarUXConfiguration {
        AddressToolbarUXConfiguration(
            toolbarCornerRadius: 8.0,
            browserActionsAddressBarDividerWidth: 4.0,
            isLocationTextCentered: false,
            hasAlternativeLocationColor: hasAlternativeLocationColor,
            locationTextFieldTrailingPadding: 8.0,
            shouldBlur: shouldBlur,
            backgroundAlpha: backgroundAlpha,
            scrollAlpha: scrollAlpha
        )
    }

    func addressToolbarBackgroundColor(theme: some Theme) -> UIColor {
        /* Ecosia: Use Ecosia background for toolbar (legacy URLBarView applyTheme)
        let backgroundColor = isLocationTextCentered ? theme.colors.layerSurfaceLow : theme.colors.layer1
         */
        let backgroundColor = theme.colors.ecosia.backgroundPrimary
        if shouldBlur {
            return backgroundColor.withAlphaComponent(backgroundAlpha)
        }

        return backgroundColor
    }

    func locationContainerBackgroundColor(theme: some Theme) -> UIColor {
        guard !scrollAlpha.isZero else { return .clear }

        /* Ecosia: Use Ecosia location background; overlay (centered) = backgroundPrimary, non-overlay = backgroundTertiary
        if hasAlternativeLocationColor {
            return isLocationTextCentered ? theme.colors.layerSurfaceMediumAlt : theme.colors.layerEmphasis
        } else {
            return isLocationTextCentered ? theme.colors.layerSurfaceMedium : theme.colors.layerEmphasis
        }
         */
        return isLocationTextCentered ? theme.colors.ecosia.backgroundPrimary : theme.colors.ecosia.backgroundTertiary
    }

    public func locationViewVerticalPaddings(addressBarPosition: AddressToolbarPosition) -> (top: CGFloat, bottom: CGFloat) {
        return switch addressBarPosition {
        case .top:
            (top: 8, bottom: 8)
        case .bottom:
            (top: 8, bottom: 8)
        }
    }
}
