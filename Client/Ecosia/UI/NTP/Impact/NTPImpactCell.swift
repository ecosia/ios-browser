/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core

final class NTPImpactCell: UICollectionViewCell, NotificationThemeable, ReusableCell {
    struct UX {
        static let cellsSpacing: CGFloat = 12
        static let dividerInset: CGFloat = 16
        static let dividerSpacing: CGFloat = 32
    }
    
    private lazy var containerStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .fill
        return stack
    }()
    private let dividerView = UIView()
    private lazy var dividerContainer = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.layoutMargins = .init(top: UX.dividerSpacing, left: UX.dividerInset, bottom: -UX.cellsSpacing, right: UX.dividerInset)
        stack.isLayoutMarginsRelativeArrangement = true
        stack.addArrangedSubview(dividerView)
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
        
        // TODO: Check if really needed to keep constraints on cell reuse
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
            containerStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.cellsSpacing),
            dividerView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    func applyTheme() {
        containerStack.arrangedSubviews.forEach { view in
            (view as? NotificationThemeable)?.applyTheme()
        }
        dividerView.backgroundColor = .theme.ecosia.border
    }
    
    func configure(items: [ClimateImpactInfo], addBottomDivider: Bool = false) {
        // Remove existing view upon reuse
        containerStack.removeAllArrangedViews()
        
        for (index, info) in items.enumerated() {
            let row = NTPImpactRowView()
            row.info = info
            row.position = (index, items.count)
            containerStack.addArrangedSubview(row)
        }
        dividerContainer.isHidden = !addBottomDivider
        if addBottomDivider {
            containerStack.addArrangedSubview(dividerContainer)
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
