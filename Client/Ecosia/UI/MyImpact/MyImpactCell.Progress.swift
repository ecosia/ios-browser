/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

extension MyImpactCell {
    final class Progress: UIView {
        var value = Double(1) {
            didSet {
                (layer as! CAShapeLayer).strokeEnd = value
            }
        }
        
        override class var layerClass: AnyClass {
            CAShapeLayer.self
        }
        
        required init?(coder: NSCoder) { nil }
        
        init() {
            super.init(frame: .zero)
            translatesAutoresizingMaskIntoConstraints = false
            widthAnchor.constraint(equalToConstant: 240).isActive = true
            heightAnchor.constraint(equalToConstant: 150).isActive = true
            (layer as! CAShapeLayer).fillColor = UIColor.clear.cgColor
            (layer as! CAShapeLayer).lineWidth = 8
            (layer as! CAShapeLayer).lineCap = .round
            layer.masksToBounds = true
            
            (layer as! CAShapeLayer).path = { path in
                path
                    .addArc(center: .init(x: 120, y: 120),
                            radius: 112,
                            startAngle: .pi - 0.2,
                            endAngle: 0.2,
                            clockwise: false)
                return path
            } (CGMutablePath())
        }
        
        func update(color: UIColor) {
            (layer as! CAShapeLayer).strokeColor = color.cgColor
        }
    }
}
