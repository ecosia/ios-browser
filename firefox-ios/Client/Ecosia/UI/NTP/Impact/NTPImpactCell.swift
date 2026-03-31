// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Ecosia

final class NTPImpactCell: UICollectionViewCell, ThemeApplicable, ReusableCell {

    // MARK: - UX

    struct UX {
        // space-1s (8pt) gap between the two individual glass tiles, per Figma
        static let cellsSpacing: CGFloat = .ecosia.space._1s
        // 2× tile gap = 16pt — distance between title bottom and tiles top (Figma)
        static let titleToTilesGap: CGFloat = .ecosia.space._m
        // FoundersGroteskCond-SmBd at 36pt (Figma: Web/Headline/Headline 3 (4L), semibold)
        static let titleFont: UIFont = .ecosiaFamilyBrand(size: .ecosia.font._4l)
        // Fixed height reserved for the title — sized for up to 3 lines of brand font
        // (3 × ~39.6pt line height ≈ 119pt). Keeps the tiles stable when the title changes.
        static let titleReservedHeight: CGFloat = 120
        // In landscape the title fits in 1-2 shorter lines; reduce the reserved height so
        // the block doesn't have a large empty area above the bottom-pinned label.
        static let titleReservedHeightLandscape: CGFloat = 60
        // Horizontal inset for the title — nearly full-width for maximum readability
        static let titleHorizontalInset: CGFloat = .ecosia.space._s
        // Horizontal inset for the tiles (Figma redline: 61pt from cell edge)
        static let tilesHorizontalInset: CGFloat = 61
        // Minimum cell height in portrait — fills most of the wallpaper card.
        static let minimumCellHeight: CGFloat = 450
        // Minimum cell height in landscape — much shorter card; let content drive the size
        // with a small buffer so the block isn't flush against the header.
        static let minimumCellHeightLandscape: CGFloat = 220
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

    // Tracks the equal-height constraint added in configure() so it can be removed on reuse.
    private var tileEqualHeightConstraint: NSLayoutConstraint?

    // Updated in updateContainerAxisForCurrentTraits() to shrink the cell in landscape.
    private var minimumHeightConstraint: NSLayoutConstraint?
    // Updated in updateContainerAxisForCurrentTraits() to shrink the title area in landscape.
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

        // Build view hierarchy:
        //   contentView
        //     └─ contentBlock  (plain UIView, centered X+Y in cell)
        //           ├─ titleContainerView  (6pt insets — nearly full width; fixed height)
        //           │     └─ rotatingTitleLabel  (bottom-pinned inside)
        //           └─ tilesStack  (61pt insets from cell edge; = 6pt + 55pt within block)
        titleContainerView.addSubview(rotatingTitleLabel)
        contentBlock.addSubview(titleContainerView)
        contentBlock.addSubview(tilesStack)
        contentView.addSubview(contentBlock)

        // The additional inset tilesStack needs within contentBlock so it lands at the
        // Figma-specified 61pt from the cell edge (titleHorizontalInset + tilesIntraBlockInset = 61).
        let tilesIntraBlockInset = UX.tilesHorizontalInset - UX.titleHorizontalInset

        NSLayoutConstraint.activate([
            // Label — fills container width; bottom-aligned so short text hugs the tiles
            rotatingTitleLabel.leadingAnchor.constraint(equalTo: titleContainerView.leadingAnchor),
            rotatingTitleLabel.trailingAnchor.constraint(equalTo: titleContainerView.trailingAnchor),
            rotatingTitleLabel.bottomAnchor.constraint(equalTo: titleContainerView.bottomAnchor),
            rotatingTitleLabel.topAnchor.constraint(greaterThanOrEqualTo: titleContainerView.topAnchor),

            // Title container — 6pt insets, fixed height, anchored to the top of contentBlock
            titleContainerView.leadingAnchor.constraint(equalTo: contentBlock.leadingAnchor),
            titleContainerView.trailingAnchor.constraint(equalTo: contentBlock.trailingAnchor),
            titleContainerView.topAnchor.constraint(equalTo: contentBlock.topAnchor),
        ])

        let titleHeight = titleContainerView.heightAnchor.constraint(equalToConstant: UX.titleReservedHeight)
        titleContainerHeightConstraint = titleHeight
        titleHeight.isActive = true

        NSLayoutConstraint.activate([

            // Tiles — narrower than the title; extra inset applied within the block
            tilesStack.leadingAnchor.constraint(equalTo: contentBlock.leadingAnchor, constant: tilesIntraBlockInset),
            tilesStack.trailingAnchor.constraint(equalTo: contentBlock.trailingAnchor, constant: -tilesIntraBlockInset),
            tilesStack.topAnchor.constraint(equalTo: titleContainerView.bottomAnchor, constant: UX.titleToTilesGap),
            tilesStack.bottomAnchor.constraint(equalTo: contentBlock.bottomAnchor),

            // Content block — 6pt insets from cell, centered vertically so the group floats
            contentBlock.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.titleHorizontalInset),
            contentBlock.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.titleHorizontalInset),
            contentBlock.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])

        let heightConstraint = contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: UX.minimumCellHeight)
        minimumHeightConstraint = heightConstraint
        heightConstraint.isActive = true

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
        // Center alignment in landscape so tiles don't stretch to the full stack height.
        // In portrait .fill stretches tiles to the full width, which is the desired behaviour.
        tilesStack.alignment = isLandscape ? .center : .fill
        tilesStack.spacing = UX.cellsSpacing
        // Shrink the minimum cell height in landscape so the card is shorter and there is
        // less empty space between the title and the NTPHeader.
        minimumHeightConstraint?.constant = isLandscape ? UX.minimumCellHeightLandscape : UX.minimumCellHeight
        titleContainerHeightConstraint?.constant = isLandscape ? UX.titleReservedHeightLandscape : UX.titleReservedHeight
    }

    // MARK: - Title

    /// Updates the displayed title. The value is today's UTC-day title as resolved by
    /// `RotatingTitlesService` before being passed in — no timer, one title per day, matching web.
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

        // Reset tiles
        tileEqualHeightConstraint?.isActive = false
        tileEqualHeightConstraint = nil
        tilesStack.removeAllArrangedViews()

        var rows: [NTPImpactRowView] = []
        for (index, info) in items.enumerated() {
            let row = NTPImpactRowView(info: info)
            row.position = (index, items.count)
            row.delegate = delegate
            tilesStack.addArrangedSubview(row)
            rows.append(row)
        }

        // Equal height between the two tiles — the taller one drives the height for both.
        // .defaultHigh priority lets content expand further if absolutely needed.
        if rows.count == 2 {
            let constraint = rows[0].heightAnchor.constraint(equalTo: rows[1].heightAnchor)
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
