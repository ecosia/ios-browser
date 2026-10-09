// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

/// Indeterminate upload progress ring — 24×24, 2pt stroke, ~270° arc rotating clockwise.
final class OmniboxUploadLoaderView: UIView {

    enum UX {
        static let size: CGFloat = 24
        static let lineWidth: CGFloat = 2
        /// Visible arc length as a fraction of the full circle (~270°).
        static let arcFraction: CGFloat = 0.75
    }

    private let trackLayer = CAShapeLayer()
    private let arcLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        translatesAutoresizingMaskIntoConstraints = false
        layer.addSublayer(trackLayer)
        layer.addSublayer(arcLayer)
        configureLayers()
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: UX.size),
            heightAnchor.constraint(equalToConstant: UX.size)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let path = circlePath()
        trackLayer.path = path
        arcLayer.path = path
        trackLayer.frame = bounds
        arcLayer.frame = bounds
    }

    func applyTheme(theme: any Theme, onDarkBackground: Bool = false) {
        let colors = theme.colors.ecosia
        if onDarkBackground {
            trackLayer.strokeColor = colors.buttonContentPrimary.withAlphaComponent(0.35).cgColor
            arcLayer.strokeColor = colors.buttonContentPrimary.cgColor
        } else {
            trackLayer.strokeColor = colors.backgroundQuaternary.cgColor
            arcLayer.strokeColor = colors.textPrimary.cgColor
        }
    }

    func startAnimating() {
        guard arcLayer.animation(forKey: "rotation") == nil else { return }
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.fromValue = 0
        rotation.toValue = Double.pi * 2
        rotation.duration = 1
        rotation.repeatCount = .infinity
        rotation.isRemovedOnCompletion = false
        arcLayer.add(rotation, forKey: "rotation")
    }

    func stopAnimating() {
        arcLayer.removeAnimation(forKey: "rotation")
    }

    private func configureLayers() {
        [trackLayer, arcLayer].forEach { layer in
            layer.fillColor = UIColor.clear.cgColor
            layer.lineWidth = UX.lineWidth
            layer.lineCap = .round
            layer.strokeStart = 0
        }
        trackLayer.strokeEnd = 1
        arcLayer.strokeEnd = UX.arcFraction
    }

    private func circlePath() -> CGPath {
        let radius = (UX.size / 2) - UX.lineWidth
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        return UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: (3 * .pi) / 2,
            clockwise: true
        ).cgPath
    }
}
