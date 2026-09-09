// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class ProgressView: UIView {
    private var shapeLayer: CAShapeLayer { layer as! CAShapeLayer } // swiftlint:disable:this force_cast

    var value = Double(1) {
        didSet { shapeLayer.strokeEnd = value }
    }
    var color: UIColor = .clear {
        didSet { shapeLayer.strokeColor = color.cgColor }
    }

    override class var layerClass: AnyClass {
        CAShapeLayer.self
    }

    required init?(coder: NSCoder) { nil }

    init(size: CGSize, lineWidth: CGFloat) {
        super.init(frame: .init(size: size))
        isUserInteractionEnabled = false
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: size.width).isActive = true
        heightAnchor.constraint(equalToConstant: size.height).isActive = true
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = lineWidth
        shapeLayer.lineCap = .round
        layer.masksToBounds = true

        shapeLayer.path = { path in
            path
                .addArc(center: .init(x: size.width/2, y: size.width/2),
                        radius: size.width/2 - lineWidth,
                        startAngle: .pi - 0.2,
                        endAngle: 0.2,
                        clockwise: false)
            return path
        }(CGMutablePath())
    }
}
