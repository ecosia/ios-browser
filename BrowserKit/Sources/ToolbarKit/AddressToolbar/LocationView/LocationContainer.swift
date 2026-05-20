// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

final class LocationContainer: UIView, ThemeApplicable {
    private enum UX {
        static let shadowRadius: CGFloat = 14
        static let shadowOpacity: Float = 1
        static let shadowOffset = CGSize(width: 0, height: 2)
        // Ecosia: Border when editing (legacy URLBarView overlay border)
        static let borderWidthEditing: CGFloat = 2
    }

    // Ecosia: cached so the border can be refreshed when only the scroll
    // alpha changes (e.g. address bar shrinking into its compact pill).
    private var isEditing = false
    private var scrollAlpha: CGFloat = 1
    private var borderTheme: Theme?

    init() {
        super.init(frame: .zero)
        setupShadow()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
    }

    private func setupShadow() {
        layer.shadowRadius = UX.shadowRadius
        layer.shadowOffset = UX.shadowOffset
        layer.shadowOpacity = UX.shadowOpacity
        layer.masksToBounds = false
    }

    func updateShadowOpacityBasedOn(scrollAlpha: CGFloat) {
        self.scrollAlpha = scrollAlpha
        let targetOpacity = scrollAlpha.isZero ? 0 : UX.shadowOpacity
        if layer.shadowOpacity != targetOpacity {
            layer.shadowOpacity = targetOpacity
        }
        // Ecosia: re-evaluate the editing border too. While shrinking into
        // the compact pill the toolbar's editing state can still be true,
        // but the border should disappear alongside the shadow so the pill
        // doesn't carry a leftover outline.
        refreshEditingBorder()
    }

    // Ecosia: Update border based on editing state (legacy URLBarView overlay border styling)
    func updateBorder(isEditing: Bool, theme: Theme) {
        self.isEditing = isEditing
        self.borderTheme = theme
        refreshEditingBorder()
    }

    private func refreshEditingBorder() {
        let shouldShowBorder = isEditing && !scrollAlpha.isZero
        if shouldShowBorder, let theme = borderTheme {
            layer.borderWidth = UX.borderWidthEditing
            layer.borderColor = theme.colors.ecosia.buttonBackgroundPrimary.cgColor
        } else {
            layer.borderWidth = 0
            layer.borderColor = nil
        }
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        layer.shadowColor = theme.colors.shadowStrong.cgColor
    }
}
