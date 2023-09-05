// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class NTPImpactOutlineView: UIStackView, NotificationThemeable {

    private var firstRow: NTPImpactRowView
    private let secondRow: NTPImpactRowView?
    private let dividerView = UIView()
    private lazy var dividerContainer = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.layoutMargins = .init(top: 0, left: 16, bottom: 0, right: 0)
        stack.isLayoutMarginsRelativeArrangement = true
        stack.addArrangedSubview(dividerView)
        return stack
    }()

    init(firstRow: NTPImpactRowView, secondRow: NTPImpactRowView?) {
        self.firstRow = firstRow
        self.secondRow = secondRow
        super.init(frame: .zero)
        setup()
        applyTheme()
    }

    required init(coder: NSCoder) {
        firstRow = NTPImpactRowView()
        secondRow = nil
        super.init(coder: coder)
    }

    private func setup() {
        axis = .vertical
        alignment = .fill
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 10
        
        addArrangedSubview(firstRow)
        
        if let secondRow = secondRow {
            addArrangedSubview(dividerContainer)
            addArrangedSubview(secondRow)
            
            dividerContainer.heightAnchor.constraint(equalToConstant: 1).isActive = true
        }
    }

    func applyTheme() {
        backgroundColor = .theme.ecosia.secondaryBackground
        dividerView.backgroundColor = .theme.ecosia.border
        firstRow.applyTheme()
        secondRow?.applyTheme()
    }
}
