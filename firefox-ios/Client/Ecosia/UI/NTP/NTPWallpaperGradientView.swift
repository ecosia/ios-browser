// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

/// Fades the bottom of the NTP wallpaper into the toolbar colour behind the search bar.
final class NTPWallpaperGradientView: UIView, ThemeApplicable {

    struct UX {
        static let heightRatio: CGFloat = 0.3
        // Fully opaque from here down, i.e. behind the bottom toolbar.
        static let opaqueLocation: NSNumber = 0.65
    }

    override class var layerClass: AnyClass { CAGradientLayer.self }

    private var gradientLayer: CAGradientLayer? { layer as? CAGradientLayer }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        gradientLayer?.locations = [0, UX.opaqueLocation]
        gradientLayer?.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer?.endPoint = CGPoint(x: 0.5, y: 1)
    }

    required init?(coder: NSCoder) { nil }

    func pin(toBottomOf container: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: container.leadingAnchor),
            trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bottomAnchor.constraint(equalTo: container.bottomAnchor),
            heightAnchor.constraint(equalTo: container.heightAnchor, multiplier: UX.heightRatio)
        ])
    }

    func applyTheme(theme: Theme) {
        // Same colour as the bottom toolbar so the wallpaper blends into it.
        let color = theme.colors.layerSurfaceLow
        gradientLayer?.colors = [color.withAlphaComponent(0).cgColor, color.cgColor]
    }
}
