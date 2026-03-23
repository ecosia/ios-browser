// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

final class NTPImpactCell: UICollectionViewCell, ThemeApplicable, ReusableCell {
    struct UX {
        // Ecosia: space-1s (8pt) gap between the two individual glass tiles, per Figma
        static let cellsSpacing: CGFloat = .ecosia.space._1s
    }

    private(set) weak var delegate: NTPImpactCellDelegate? {
        didSet {
            impactRows.forEach { $0.delegate = delegate }
        }
    }

    // Ecosia: Tracks the equal-height constraint added in configure() so it can be removed on reuse.
    private var tileEqualHeightConstraint: NSLayoutConstraint?

    private lazy var containerStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        // Ecosia: .fill allows each tile to self-size from its intrinsic content (padding respected).
        // Equal height is enforced via an explicit constraint in configure() instead of .fillEqually,
        // which would create a circular dependency that breaks self-sizing and ignores padding.
        stack.alignment = .fill
        stack.distribution = .fill
        stack.spacing = UX.cellsSpacing
        return stack
    }()
    
    private var impactRows: [NTPImpactRowView] {
        containerStack.arrangedSubviews.compactMap { $0 as? NTPImpactRowView }
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateContainerAxisForCurrentTraits()
        // Ecosia: Invalidate the cell so the collection view recalculates the section height
        // after the axis switches. Labels re-wrap correctly because labelsStack uses .fill alignment,
        // which gives each label an explicit width constraint at all times.
        invalidateIntrinsicContentSize()
    }

    private func setup() {
        contentView.backgroundColor = .clear
        contentView.addSubview(containerStack)
        // Ecosia: Position the tiles stack within the cell using Figma redline values.
        // Top 124pt, leading/trailing 61pt, bottom 68pt.
        // The bottom uses greaterThanOrEqualTo on the contentView side so the cell can grow
        // when Dynamic Type increases the tile height, while always keeping at least 68pt below.
        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 124),
            containerStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 61),
            containerStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -61),
            contentView.bottomAnchor.constraint(greaterThanOrEqualTo: containerStack.bottomAnchor, constant: 68),
        ])
        updateContainerAxisForCurrentTraits()
    }

    /// Switches the impact tiles between vertical (portrait) and horizontal (landscape) layout.
    /// In landscape on iPhone (compact vertical size class), tiles appear side by side.
    private func updateContainerAxisForCurrentTraits() {
        let isLandscape = traitCollection.verticalSizeClass == .compact
        containerStack.axis = isLandscape ? .horizontal : .vertical
        // Ecosia: In landscape (horizontal axis), fillEqually splits the available width evenly so
        // neither tile stretches wider than the other. In portrait (vertical axis), .fill lets each
        // tile self-size by its content height — equal height is then enforced by tileEqualHeightConstraint.
        containerStack.distribution = isLandscape ? .fillEqually : .fill
        containerStack.spacing = UX.cellsSpacing
    }

    func applyTheme(theme: Theme) {
        containerStack.arrangedSubviews.forEach { view in
            (view as? Themeable)?.applyTheme()
            (view as? ThemeApplicable)?.applyTheme(theme: theme)
        }
    }

    func configure(items: [ClimateImpactInfo], delegate: NTPImpactCellDelegate?, theme: Theme) {
        self.delegate = delegate
        tileEqualHeightConstraint?.isActive = false
        tileEqualHeightConstraint = nil
        containerStack.removeAllArrangedViews()

        var rows: [NTPImpactRowView] = []
        for (index, info) in items.enumerated() {
            let row = NTPImpactRowView(info: info)
            row.position = (index, items.count)
            row.delegate = delegate
            containerStack.addArrangedSubview(row)
            rows.append(row)
        }

        // Ecosia: Equal height between tiles — the taller tile (subtitle may wrap) drives the
        // height for both. Using .defaultHigh priority lets content still expand if needed.
        if rows.count >= 2 {
            let constraint = rows[0].heightAnchor.constraint(equalTo: rows[1].heightAnchor)
            constraint.priority = .defaultHigh
            constraint.isActive = true
            tileEqualHeightConstraint = constraint
        }

        updateContainerAxisForCurrentTraits()
        applyTheme(theme: theme)
    }

    func refresh(items: [ClimateImpactInfo]) {
        impactRows.forEach { row in
            let matchingInfo = items.first { $0.rawValue == row.info.rawValue }
            guard let info = matchingInfo else { return }
            row.info = info
        }
    }
}
