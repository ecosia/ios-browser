/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core

final class NTPImpactCell: UICollectionViewCell, NotificationThemeable, ReusableCell {
    struct UX {
        static let estimatedHeight: CGFloat = NTPImpactRowView.UX.height*2 + cellsSpacing
        static let cellsSpacing: CGFloat = 12
    }
    
    weak var delegate: NTPImpactCellDelegate? {
        didSet {
            containerStack.arrangedSubviews
                .compactMap { $0 as? NTPImpactRowView }
                .forEach { $0.delegate = delegate }
        }
    }
    
    private lazy var containerStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .fill
        return stack
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        applyTheme()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
        applyTheme()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupConstraints()
    }

    private func setup() {
        contentView.addSubview(containerStack)
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: topAnchor),
            containerStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.cellsSpacing)
        ])
    }

    func applyTheme() {
        containerStack.arrangedSubviews.forEach { view in
            (view as? NotificationThemeable)?.applyTheme()
        }
    }
    
    func configure(items: [ClimateImpactInfo]) {
        containerStack.removeAllArrangedViews() // Remove existing view upon reuse
        
        for (index, info) in items.enumerated() {
            let row = NTPImpactRowView(info: info)
            row.info = info // Needed to force info setup after init
            row.position = (index, items.count)
            row.delegate = delegate
            containerStack.addArrangedSubview(row)
        }
    }
    
    func refresh(items: [ClimateImpactInfo]) {
        for (index, view) in containerStack.arrangedSubviews.enumerated() {
            guard let row = view as? NTPImpactRowView else { return }
            let info = items[index]
            row.info = info
        }
    }
}