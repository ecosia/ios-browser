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
        let targetOpacity = scrollAlpha.isZero ? 0 : UX.shadowOpacity
        guard layer.shadowOpacity != targetOpacity else { return }
        layer.shadowOpacity = targetOpacity
    }

    // Ecosia: Update border based on editing state (legacy URLBarView overlay border styling)
    func updateBorder(isEditing: Bool, theme: Theme) {
        if isEditing {
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
