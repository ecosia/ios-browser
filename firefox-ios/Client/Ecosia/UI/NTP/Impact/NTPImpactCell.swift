// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Ecosia

final class NTPImpactCell: UICollectionViewCell, ThemeApplicable, ReusableCell {

    // MARK: - UX

    struct UX {
        static let cellsSpacing: CGFloat = .ecosia.space._1s
        static let titleToTilesGap: CGFloat = .ecosia.space._m
        static let titleFont: UIFont = .ecosiaFamilyBrand(size: .ecosia.font._4l)
        // Fixed height for up to 3 lines of brand font (~39.6pt line height × 3 ≈ 119pt).
        // Keeps the tiles stable when the rotating title changes.
        static let titleReservedHeight: CGFloat = 120
        // In landscape the title fits in fewer lines; reduce reserved height to avoid dead space.
        static let titleReservedHeightLandscape: CGFloat = 60
        static let titleHorizontalInset: CGFloat = .ecosia.space._s
        static let tilesHorizontalInset: CGFloat = 61
    }

    // MARK: - Subviews

    // Transparent wrapper that groups title + tiles so the whole block can be centered X+Y.
    // The title and tiles have different horizontal insets, so this is a plain UIView rather
    // than a UIStackView — each child is positioned with its own constraints inside.
    private let contentBlock: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    // Fixed-height wrapper for the rotating label. Its height never changes regardless of
    // how many lines the label uses, keeping the tiles completely stable during rotation.
    // The label is bottom-pinned inside so short text hugs the tiles and free space floats above.
    private let titleContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.clipsToBounds = true
        return view
    }()

    private let rotatingTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UX.titleFont
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        label.accessibilityIdentifier = EcosiaAccessibilityIdentifiers.NTP.rotatingTitle
        return label
    }()

    private lazy var tilesStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        // .fill lets each tile self-size; equal height is enforced via an explicit constraint
        // in configure() to avoid the circular dependency that .fillEqually creates.
        stack.alignment = .fill
        stack.distribution = .fill
        stack.spacing = UX.cellsSpacing
        return stack
    }()

    // MARK: - State

    private(set) weak var delegate: NTPImpactCellDelegate? {
        didSet { impactRows.forEach { $0.delegate = delegate } }
    }

    private var tileEqualHeightConstraint: NSLayoutConstraint?
    private var titleContainerHeightConstraint: NSLayoutConstraint?

    private var impactRows: [NTPImpactRowView] {
        tilesStack.arrangedSubviews.compactMap { $0 as? NTPImpactRowView }
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

    // MARK: - Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()
        rotatingTitleLabel.text = nil
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateContainerAxisForCurrentTraits()
        // Invalidate the cell so the collection view recalculates the section height
        // after the axis switches. Labels re-wrap correctly because labelsStack uses .fill alignment,
        // which gives each label an explicit width constraint at all times.
        invalidateIntrinsicContentSize()
    }

    // MARK: - Setup

    private func setup() {
        contentView.backgroundColor = .clear

        titleContainerView.addSubview(rotatingTitleLabel)
        contentBlock.addSubview(titleContainerView)
        contentBlock.addSubview(tilesStack)
        contentView.addSubview(contentBlock)

        // tilesHorizontalInset is measured from the cell edge; subtract titleHorizontalInset
        // (the contentBlock inset) to get the inset required within contentBlock itself.
        let tilesIntraBlockInset = UX.tilesHorizontalInset - UX.titleHorizontalInset

        NSLayoutConstraint.activate([
            rotatingTitleLabel.leadingAnchor.constraint(equalTo: titleContainerView.leadingAnchor),
            rotatingTitleLabel.trailingAnchor.constraint(equalTo: titleContainerView.trailingAnchor),
            rotatingTitleLabel.bottomAnchor.constraint(equalTo: titleContainerView.bottomAnchor),
            rotatingTitleLabel.topAnchor.constraint(greaterThanOrEqualTo: titleContainerView.topAnchor),

            titleContainerView.leadingAnchor.constraint(equalTo: contentBlock.leadingAnchor),
            titleContainerView.trailingAnchor.constraint(equalTo: contentBlock.trailingAnchor),
            titleContainerView.topAnchor.constraint(equalTo: contentBlock.topAnchor),
        ])

        let titleHeight = titleContainerView.heightAnchor.constraint(equalToConstant: UX.titleReservedHeight)
        titleContainerHeightConstraint = titleHeight
        titleHeight.isActive = true

        NSLayoutConstraint.activate([
            tilesStack.leadingAnchor.constraint(equalTo: contentBlock.leadingAnchor, constant: tilesIntraBlockInset),
            tilesStack.trailingAnchor.constraint(equalTo: contentBlock.trailingAnchor, constant: -tilesIntraBlockInset),
            tilesStack.topAnchor.constraint(equalTo: titleContainerView.bottomAnchor, constant: UX.titleToTilesGap),
            tilesStack.bottomAnchor.constraint(equalTo: contentBlock.bottomAnchor),

            // Top/bottom pins let compositional layout measure the cell height from content
            // without needing a hard minimum height constant.
            contentBlock.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.titleHorizontalInset),
            contentBlock.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.titleHorizontalInset),
            contentBlock.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UX.titleToTilesGap),
            contentBlock.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -UX.titleToTilesGap),
        ])

        updateContainerAxisForCurrentTraits()
    }

    // MARK: - Orientation

    /// Switches the impact tiles between vertical (portrait) and horizontal (landscape) layout.
    /// In landscape on iPhone (compact vertical size class), tiles appear side by side.
    private func updateContainerAxisForCurrentTraits() {
        let isLandscape = traitCollection.verticalSizeClass == .compact
        tilesStack.axis = isLandscape ? .horizontal : .vertical
        // In landscape (horizontal axis), fillEqually splits the available width evenly so
        // neither tile stretches wider than the other. In portrait (vertical axis), .fill lets each
        // tile self-size by its content height — equal height is then enforced by tileEqualHeightConstraint.
        tilesStack.distribution = isLandscape ? .fillEqually : .fill
        tilesStack.alignment = isLandscape ? .center : .fill
        tilesStack.spacing = UX.cellsSpacing
        titleContainerHeightConstraint?.constant = isLandscape ? UX.titleReservedHeightLandscape : UX.titleReservedHeight
    }

    // MARK: - Title

    func updateTitle(_ title: String?) {
        rotatingTitleLabel.text = title
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        tilesStack.arrangedSubviews.forEach { view in
            (view as? Themeable)?.applyTheme()
            (view as? ThemeApplicable)?.applyTheme(theme: theme)
        }
    }

    // MARK: - Configure

    func configure(items: [ClimateImpactInfo],
                   title: String?,
                   delegate: NTPImpactCellDelegate?,
                   theme: Theme) {
        self.delegate = delegate

        tileEqualHeightConstraint?.isActive = false
        tileEqualHeightConstraint = nil
        tilesStack.removeAllArrangedViews()

        var rows: [NTPImpactRowView] = []
        for info in items {
            let row = NTPImpactRowView(info: info)
            row.delegate = delegate
            tilesStack.addArrangedSubview(row)
            rows.append(row)
        }

        // Always exactly 2 tiles (trees + invested). Equal height so the taller one drives
        // both — .defaultHigh lets content still expand if absolutely needed.
        assert(rows.count == 2, "NTPImpactCell expects exactly 2 tiles")
        if let first = rows.first, let last = rows.last, first !== last {
            let constraint = first.heightAnchor.constraint(equalTo: last.heightAnchor)
            constraint.priority = .defaultHigh
            constraint.isActive = true
            tileEqualHeightConstraint = constraint
        }

        updateTitle(title)
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
