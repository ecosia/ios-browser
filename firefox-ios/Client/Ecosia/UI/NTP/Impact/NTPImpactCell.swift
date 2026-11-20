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
        // The title gets a fixed height so the tiles stay put when the rotating title changes.
        // It is measured from the font: a hard-coded 120pt assumed a 39.6pt line, but the brand
        // font's line is about 42.3pt, so only 2 lines fitted and a 3rd was clipped.
        static let titleMaxLines = 3
        // In landscape the title is wider, so fewer lines fit and less space is reserved.
        static let titleMaxLinesLandscape = 2
        static var titleReservedHeight: CGFloat { reservedTitleHeight(lines: titleMaxLines) }
        static var titleReservedHeightLandscape: CGFloat { reservedTitleHeight(lines: titleMaxLinesLandscape) }

        static func reservedTitleHeight(lines: Int) -> CGFloat {
            ceil(titleFont.lineHeight * CGFloat(lines))
        }
        static let titleHorizontalInset: CGFloat = .ecosia.space._s
    }

    // MARK: - Subviews

    // Vertical stack that groups title + tiles. Using a UIStackView (instead of a
    // plain UIView with manual constraints) lets us hide the tiles container and
    // have the cell height collapse automatically — critical for the Climate Impact
    // toggle that hides impact rows while keeping the rotating title visible.
    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fill
        stack.spacing = UX.titleToTilesGap
        stack.backgroundColor = .clear
        // Ecosia: Refuse to be vertically compressed by an undersized cell.
        // Back-navigating from the SERP can briefly hand the layout a smaller
        // container, which would otherwise squeeze this stack (and the impact
        // rows inside) and pull TopSites up to fill the gap. Holding the
        // intrinsic height keeps the cards stable through the transition.
        stack.setContentCompressionResistancePriority(.required, for: .vertical)
        // Ecosia: Refuse to be vertically stretched by an oversized cell.
        // On iPad the impact section is sized to fill the remaining card
        // height, which would otherwise drag this stack (and `.fill`
        // distribute it across the tiles) into a giant block. Required
        // hugging keeps it at its intrinsic height so the cell self-sizes
        // via `.estimated` and the rows render at their natural height.
        stack.setContentHuggingPriority(.required, for: .vertical)
        return stack
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
        // A title longer than the reserved lines shrinks to fit. UILabel only shrinks
        // multi-line text with a line limit and a truncating line break mode.
        label.numberOfLines = UX.titleMaxLines
        label.lineBreakMode = .byTruncatingTail
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        label.accessibilityIdentifier = EcosiaAccessibilityIdentifiers.NTP.rotatingTitle
        return label
    }()

    // Hiding this view in the parent stack collapses both the tiles and the inter-item spacing automatically.
    private let tilesContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    private lazy var tilesStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = UX.cellsSpacing
        // Ecosia: see `contentStack` comment — hold the intrinsic stack
        // height so the impact rows don't get squeezed during transitions,
        // and hug vertically so the tiles never inflate to fill an oversized
        // section (iPad portrait was producing ~500pt-tall rows otherwise).
        stack.setContentCompressionResistancePriority(.required, for: .vertical)
        stack.setContentHuggingPriority(.required, for: .vertical)
        return stack
    }()

    // MARK: - State

    private(set) weak var delegate: NTPImpactCellDelegate? {
        didSet { impactRows.forEach { $0.delegate = delegate } }
    }

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
        updateTitleHeightForCurrentTraits()
        invalidateIntrinsicContentSize()
    }

    // MARK: - Setup

    private func setup() {
        contentView.backgroundColor = .clear

        // Title label inside its fixed-height container
        titleContainerView.addSubview(rotatingTitleLabel)

        tilesContainer.addSubview(tilesStack)

        // Assemble the vertical content stack
        contentStack.addArrangedSubview(titleContainerView)
        contentStack.addArrangedSubview(tilesContainer)
        contentView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            rotatingTitleLabel.leadingAnchor.constraint(equalTo: titleContainerView.leadingAnchor),
            rotatingTitleLabel.trailingAnchor.constraint(equalTo: titleContainerView.trailingAnchor),
            rotatingTitleLabel.bottomAnchor.constraint(equalTo: titleContainerView.bottomAnchor),
            rotatingTitleLabel.topAnchor.constraint(greaterThanOrEqualTo: titleContainerView.topAnchor),
        ])

        let titleHeight = titleContainerView.heightAnchor.constraint(equalToConstant: UX.titleReservedHeight)
        titleContainerHeightConstraint = titleHeight
        titleHeight.isActive = true

        NSLayoutConstraint.activate([
            // Cards hug their content and stay centred; they only shrink when the width runs out.
            tilesStack.centerXAnchor.constraint(equalTo: tilesContainer.centerXAnchor),
            tilesStack.leadingAnchor.constraint(greaterThanOrEqualTo: tilesContainer.leadingAnchor),
            tilesStack.topAnchor.constraint(equalTo: tilesContainer.topAnchor),
            tilesStack.bottomAnchor.constraint(equalTo: tilesContainer.bottomAnchor),

            contentStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.titleHorizontalInset),
            contentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.titleHorizontalInset),
            /* Center the content vertically inside the impact section, which is sized to fill
               the remaining card height above TopSites. >= / <= guards prevent overflow on small screens.
             */
            contentStack.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: UX.titleToTilesGap),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -UX.titleToTilesGap),
        ])

        // Ecosia: Centring is a soft constraint so it breaks first when the
        // cell is shorter than the content needs (e.g. during a transient
        // back-navigation layout pass). Otherwise the system trades off
        // against compression resistance and the impact rows end up squeezed.
        let centerY = contentStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        centerY.priority = .defaultLow
        centerY.isActive = true

        updateTitleHeightForCurrentTraits()
    }

    // MARK: - Orientation

    private func updateTitleHeightForCurrentTraits() {
        let isLandscape = traitCollection.verticalSizeClass == .compact
        titleContainerHeightConstraint?.constant = isLandscape ? UX.titleReservedHeightLandscape : UX.titleReservedHeight
        rotatingTitleLabel.numberOfLines = isLandscape ? UX.titleMaxLinesLandscape : UX.titleMaxLines
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

        tilesStack.removeAllArrangedViews()

        for info in items {
            let row = NTPImpactRowView(info: info)
            row.delegate = delegate
            tilesStack.addArrangedSubview(row)
        }

        tilesContainer.isHidden = items.isEmpty

        updateTitle(title)
        updateTitleHeightForCurrentTraits()
        applyTheme(theme: theme)
    }

    func refresh(items: [ClimateImpactInfo]) {
        impactRows.forEach { row in
            let matchingInfo = items.first { $0.rawValue == row.info.rawValue }
            guard let info = matchingInfo else { return }
            row.info = info
        }
    }

    /// Configures the cell with fixed display strings for snapshot tests.
    func configureForSnapshot(
        rows: [NTPImpactSnapshotRow],
        title: String,
        theme: Theme
    ) {
        delegate = nil

        tilesStack.removeAllArrangedViews()

        var impactRowViews: [NTPImpactRowView] = []
        for row in rows {
            let impactRow = NTPImpactRowView(info: row.info)
            tilesStack.addArrangedSubview(impactRow)
            impactRowViews.append(impactRow)
        }

        tilesContainer.isHidden = rows.isEmpty

        updateTitle(title)
        updateTitleHeightForCurrentTraits()
        applyTheme(theme: theme)

        for (impactRow, row) in zip(impactRowViews, rows) {
            impactRow.applySnapshotDisplay(
                title: row.title,
                subtitle: row.subtitle,
                image: row.info.image
            )
        }
    }
}
