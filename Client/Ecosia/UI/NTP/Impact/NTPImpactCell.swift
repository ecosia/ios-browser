/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core

final class NTPImpactCell: UICollectionViewCell, NotificationThemeable, ReusableCell {
    struct Model { // TODO: Do we actually need this?
        let personalCounter: Int
        let personalSearches: Int
        let friendsInvited: Int
        let totalTreesCounter: Int
        let totalAmountInvested: Int
    }
    
    private lazy var containerView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        stack.distribution = .fillEqually
        return stack
    }()
    private lazy var personalImpactOutlineView: NTPImpactOutlineView = {
        NTPImpactOutlineView(firstRow: personalCounterRow, secondRow: invitesRow)
    }()
    private let personalCounterRow = NTPImpactRowView()
    private let invitesRow = NTPImpactRowView()
    private lazy var communityImpactOutlineView: NTPImpactOutlineView = {
        NTPImpactOutlineView(firstRow: treesRow, secondRow: investmentRow)
    }()
    private let treesRow = NTPImpactRowView()
    private let investmentRow = NTPImpactRowView()
    private lazy var dividerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
        contentView.addSubview(containerView)
        contentView.addSubview(dividerView)
        
        containerView.addArrangedSubview(personalImpactOutlineView)
        containerView.addArrangedSubview(communityImpactOutlineView)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.widthAnchor.constraint(equalTo: widthAnchor),
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.bottomAnchor.constraint(equalTo: dividerView.topAnchor, constant: -32),
            dividerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            dividerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            dividerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    func applyTheme() {
        containerView.arrangedSubviews.forEach { view in
            (view as? NotificationThemeable)?.applyTheme()
        }
        dividerView.backgroundColor = .theme.ecosia.border
    }
    
    func configure(model: Model) {
        personalCounterRow.info = .personalCounter(value: model.personalCounter,
                                                   searches: model.personalSearches)
        invitesRow.info = .invites(value: model.friendsInvited)
        treesRow.info = .totalTrees(value: model.totalTreesCounter)
        investmentRow.info = .totalInvested(value: model.totalAmountInvested)
    }
}
