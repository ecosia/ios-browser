/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core
import Common

protocol NTPSeedCounterDelegate: NSObject {
    func didTapSeedCounter()
}

final class NTPSeedCounterCell: UICollectionViewCell, ReusableCell {

    private var seedCounter: UIButton!
    weak var delegate: NTPSeedCounterDelegate?

    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setup() {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal

        seedCounter = UIButton()
        seedCounter.setImage(.init(named: "seedIcon"), for: .normal)
        seedCounter.translatesAutoresizingMaskIntoConstraints = false
        seedCounter.clipsToBounds = true
        seedCounter.contentMode = .scaleAspectFit
        seedCounter.heightAnchor.constraint(equalToConstant: 48).isActive = true
        seedCounter.widthAnchor.constraint(equalToConstant: 48).isActive = true
        seedCounter.addTarget(self, action: #selector(openClimateImpactCounter), for: .touchUpInside)
        contentView.addSubview(seedCounter)
        seedCounter.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16).isActive = true
    }
    
    @objc private func openClimateImpactCounter() {
        delegate?.didTapSeedCounter()
    }
}
