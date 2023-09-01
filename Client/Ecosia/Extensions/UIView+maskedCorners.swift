// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension UIView {
    fileprivate struct Positions: OptionSet {
        static let top = Positions(rawValue: 1)
        static let bottom = Positions(rawValue: 1 << 1)
        let rawValue: Int8
        
        static func derive(row: Int, totalCount: Int) -> Positions {
            var pos = Positions()
            if row == 0 { pos.insert(.top) }
            if row == totalCount - 1 { pos.insert(.bottom) }
            return pos
        }
    }
    
    func setMaskedCornersUsingPosition(row: Int, totalCount: Int) {
        let pos = Positions.derive(row: row, totalCount: totalCount)
        var masked: CACornerMask = []
        if pos.contains(.top) {
            masked.formUnion(.layerMinXMinYCorner)
            masked.formUnion(.layerMaxXMinYCorner)
        }
        if pos.contains(.bottom) {
            masked.formUnion(.layerMinXMaxYCorner)
            masked.formUnion(.layerMaxXMaxYCorner)
        }
        layer.maskedCorners = masked
    }
}
