// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Ecosia

/// Darkens the bottom of the NTP wallpaper so the omnibox and toolbar read against any image.
final class NTPWallpaperGradientView: UIView {

    struct UX {
        static let heightRatio: CGFloat = 0.4
        static let bottomAlpha: CGFloat = 0.9
    }

    override class var layerClass: AnyClass { CAGradientLayer.self }

    private var gradientLayer: CAGradientLayer? { layer as? CAGradientLayer }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        gradientLayer?.colors = [
            EcosiaColor.Gray90.withAlphaComponent(0).cgColor,
            EcosiaColor.Gray90.withAlphaComponent(UX.bottomAlpha).cgColor
        ]
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
}
