// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Ecosia

/// Vertical scrim that sits behind the focused NTP omnibox. Two effects fade
/// in together from `top → bottom`:
///
/// 1. A `UIVisualEffectView` (system ultra-thin material) blurs whatever sits
///    behind the scrim. A `CAGradientLayer` mask scales the visible effect
///    from 0 at the top to full at the bottom — matching the "blur 0 → 16"
///    fade in the design spec.
/// 2. A `CAGradientLayer` filled with the design-system `backgroundGradient`
///    colour (white in light, gray-90 in dark) sits on top of the blur and
///    fades from α 0 at the top to α 1 at ~70% down, then stays solid the
///    rest of the way. That solid tail keeps the colour fully opaque at the
///    visible bottom (where the keyboard cuts the scrim off) so the scrim
///    doesn't look like it dies on a half-opaque pixel.
///
/// The host shows the scrim on omnibox focus and hides it on blur via
/// `setVisible(_:animated:)`, so the homepage's pre-focus state is preserved
/// when the user isn't typing.
final class NTPSearchBarBackdropView: UIView, ThemeApplicable {

    private let blurView = UIVisualEffectView(effect: nil)
    private let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
    private let blurMaskLayer = CAGradientLayer()
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        isUserInteractionEnabled = false
        backgroundColor = .clear
        // Start fully invisible AND hidden so neither the blur nor the
        // gradient layer contribute anything to the unfocused homepage.
        alpha = 0
        isHidden = true

        // Blur first so its layer sits BEHIND the colour gradient layer
        // added afterwards (sublayers are rendered back-to-front in the
        // order they're appended).
        blurView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurView)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Mask the blur with the same fade curve as the colour layer (clear
        // at top → ~half-opaque at 70% → ~half-opaque at bottom). The peak
        // is capped at ~0.5 because the scrim sits behind iOS' own
        // translucent keyboard surface — a full-intensity blur there
        // compounds with the keyboard's own blur and reads as a strongly
        // tinted wash. Half-strength keeps the soft frosted-glass feel
        // above the pill without the bottom looking heavy-handed.
        blurMaskLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.white.withAlphaComponent(0.5).cgColor,
            UIColor.white.withAlphaComponent(0.5).cgColor
        ]
        blurMaskLayer.locations = [0.0, 0.7, 1.0]
        blurMaskLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        blurMaskLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        blurView.layer.mask = blurMaskLayer

        // Colour gradient uses a plain linear fade across the full height
        // (no solid plateau at the bottom). The visible bottom below the
        // pill is then a soft tail rather than a flat wash — the blur
        // (which keeps its `[0, 0.7, 1]` ramp) gives the bottom enough
        // body without the colour also stamping a solid bar.
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        layer.addSublayer(gradientLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // CAGradientLayer doesn't auto-resize with its host view; keep the
        // frames in sync without implicit animations so they don't lag
        // behind constraint-driven layout passes.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = bounds
        blurMaskLayer.frame = bounds
        CATransaction.commit()
    }

    func applyTheme(theme: any Theme) {
        let color = theme.colors.ecosia.backgroundGradient
        // Cap the colour tint at 50% even at the bottom of the scrim. Full
        // opacity reads as a solid bar across the gap between the pill and
        // the keyboard; capping it lets the wallpaper bleed through, which
        // is closer to the subtle fade in the design reference.
        gradientLayer.colors = [
            color.withAlphaComponent(0).cgColor,
            color.withAlphaComponent(0.5).cgColor
        ]
    }

    func setVisible(_ visible: Bool, animated: Bool, duration: TimeInterval = 0.2) {
        if visible {
            // Make sure the view participates in rendering before alpha
            // ramps up. Also install the blur effect — we keep it `nil`
            // while hidden so the system material isn't visible at α 0.
            isHidden = false
            if blurView.effect == nil {
                blurView.effect = blurEffect
            }
        }
        let targetAlpha: CGFloat = visible ? 1 : 0
        guard alpha != targetAlpha else { return }
        let finalise: () -> Void = { [weak self] in
            guard let self, !visible else { return }
            // Drop the effect AND mark hidden so neither the blur nor the
            // gradient can render — restoring the pre-focus state exactly.
            self.blurView.effect = nil
            self.isHidden = true
        }
        guard animated else {
            alpha = targetAlpha
            finalise()
            return
        }
        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut]) {
            self.alpha = targetAlpha
        } completion: { _ in
            finalise()
        }
    }
}
