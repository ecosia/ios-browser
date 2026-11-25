// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import ComponentLibrary
import Ecosia

/// A view representing an individual impact row, used in the New Tab Page to display environmental impact information.
@MainActor
final class NTPImpactRowView: UIView, ThemeApplicable {

    // MARK: - UX Constants

    struct UX {
        static let iconTitleSpacing: CGFloat = .ecosia.space._2s
        static let padding: CGFloat = .ecosia.space._s
        static let titleSubtitleGap: CGFloat = .ecosia.space._2s
        static let imageHeight: CGFloat = 24
        static let titleFont: UIFont = .ecosiaFamilyBrand(size: .ecosia.font._3l)
        // Headline 4: 1.2 line height (28.8pt); the font's own line height is 28.2pt.
        static let titleLineHeight: CGFloat = 28.8
        static let glassBorderWidth: CGFloat = 1
    }

    // MARK: - UI Elements

    // Gaussian blur glass background (see ADR 0003)
    private let glassBackground: NTPImpactGlassBackgroundView = {
        let view = NTPImpactGlassBackgroundView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let titleRow: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = UX.iconTitleSpacing
        return stack
    }()

    // alignment = .fill gives the subtitle an explicit width so it re-wraps after rotation;
    // the title row is centred by its own wrapper instead.
    private let labelsStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = UX.titleSubtitleGap
        return stack
    }()

    private let titleRowWrapper: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var imageContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var imageView: UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.contentMode = .scaleAspectFit
        return image
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UX.titleFont
        label.adjustsFontSizeToFitWidth = true
        label.adjustsFontForContentSizeCategory = true
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return label
    }()

    // Proportional digits make the live counter change width as it ticks. Reserving the width of the
    // widest digits keeps the card and the icon still; the font shrinks only when the card runs out of room.
    private lazy var titleWidthConstraint: NSLayoutConstraint = {
        let constraint = titleLabel.widthAnchor.constraint(equalToConstant: 0)
        constraint.priority = .defaultHigh - 1
        return constraint
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        // Force word-wrap so words are never split mid-word across lines.
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    // MARK: - Properties

    weak var delegate: NTPImpactCellDelegate?

    var info: ClimateImpactInfo {
        didSet {
            imageView.image = info.image
            imageContainer.isHidden = info.image == nil
            imageView.accessibilityIdentifier = info.imageAccessibilityIdentifier
            setTitle(info.title)
            subtitleLabel.text = info.subtitle
        }
    }

    var customBackgroundColor: UIColor?

    // MARK: - Initialization

    init(info: ClimateImpactInfo) {
        self.info = info
        super.init(frame: .zero)
        defer {
            // Trigger the didSet observer so subviews are populated on first configure.
            self.info = info
        }
        // Ecosia: Refuse vertical compression so the impact row keeps its
        // intrinsic height (icon + labels + padding) even when the enclosing
        // cell is given less space than expected by the section layout.
        setContentCompressionResistancePriority(.required, for: .vertical)
        setupView()
        setupConstraints()
        setupTapGestureIfNeeded()
    }

    required init?(coder: NSCoder) { nil }

    // MARK: - Setup Methods

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = .ecosia.borderRadius._l
        // Don't clip — single-line labels (especially with Dynamic Type
        // bumped up) need to render their full intrinsic height even when
        // the row is sized smaller. The glass background and border still
        // honour the corner radius via `layer.cornerRadius`, so the rounded
        // card outline stays intact.
        clipsToBounds = false
        // Mirror the row's rounding on the glass background so its sharp
        // rectangle corners don't peek past the rounded border outline.
        // Without this, the trailing top/bottom corners look ragged.
        glassBackground.layer.cornerRadius = .ecosia.borderRadius._l
        addSubview(glassBackground)

        imageContainer.addSubview(imageView)
        titleRow.addArrangedSubview(imageContainer)
        titleRow.addArrangedSubview(titleLabel)
        titleRow.translatesAutoresizingMaskIntoConstraints = false
        titleRowWrapper.addSubview(titleRow)

        labelsStack.addArrangedSubview(titleRowWrapper)
        labelsStack.addArrangedSubview(subtitleLabel)
        labelsStack.isAccessibilityElement = true
        labelsStack.shouldGroupAccessibilityChildren = true
        labelsStack.accessibilityLabel = info.accessibilityLabel
        labelsStack.accessibilityIdentifier = info.accessibilityIdentifier

        addSubview(labelsStack)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            glassBackground.topAnchor.constraint(equalTo: topAnchor),
            glassBackground.leadingAnchor.constraint(equalTo: leadingAnchor),
            glassBackground.trailingAnchor.constraint(equalTo: trailingAnchor),
            glassBackground.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Top-aligned so both counters line up when the shorter card is stretched to its neighbour's height.
            labelsStack.topAnchor.constraint(equalTo: topAnchor, constant: UX.padding),
            labelsStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -UX.padding),
            labelsStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.padding),
            labelsStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.padding),

            titleRow.topAnchor.constraint(equalTo: titleRowWrapper.topAnchor),
            titleRow.bottomAnchor.constraint(equalTo: titleRowWrapper.bottomAnchor),
            titleRow.centerXAnchor.constraint(equalTo: titleRowWrapper.centerXAnchor),
            titleRow.leadingAnchor.constraint(greaterThanOrEqualTo: titleRowWrapper.leadingAnchor),

            imageContainer.heightAnchor.constraint(equalToConstant: UX.imageHeight),
            imageContainer.widthAnchor.constraint(equalTo: imageContainer.heightAnchor),

            imageView.topAnchor.constraint(equalTo: imageContainer.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor),
            titleWidthConstraint,
        ])

        // Hug the content vertically; the shorter card gives this up to match its neighbour.
        // The labels must not stretch instead, or the number would re-centre inside a taller label.
        [titleLabel, subtitleLabel].forEach {
            $0.setContentHuggingPriority(.defaultHigh + 1, for: .vertical)
            $0.setContentCompressionResistancePriority(.required, for: .vertical)
        }
        titleRow.heightAnchor.constraint(equalTo: titleLabel.heightAnchor).isActive = true
        let hugBottom = labelsStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.padding)
        hugBottom.priority = .defaultHigh
        hugBottom.isActive = true
    }

    // MARK: - ThemeApplicable

    /// Applies literal display values for snapshot tests; bypasses `ClimateImpactInfo` formatting.
    func applySnapshotDisplay(
        title: String,
        subtitle: String,
        image: UIImage?
    ) {
        imageView.image = image
        imageContainer.isHidden = image == nil
        setTitle(title)
        subtitleLabel.text = subtitle
    }

    func applyTheme(theme: Theme) {
        let ecosia = (theme.colors as? EcosiaThemeColourPalette)?.ecosia
        backgroundColor = .clear
        layer.borderWidth = UX.glassBorderWidth
        layer.borderColor = (ecosia?.borderGlassStatic ?? EcosiaColor.White.withAlphaComponent(0x3D / 255.0)).cgColor
        glassBackground.applyTheme(theme: theme)
        glassBackground.loadCurrentWallpaper()
        titleLabel.textColor = .white
        subtitleLabel.textColor = .white
        imageView.tintColor = .white
        // Re-apply content to ensure rows added after initial layout are fully populated.
        imageView.image = info.image
        imageContainer.isHidden = info.image == nil
        imageView.accessibilityIdentifier = info.imageAccessibilityIdentifier
        setTitle(info.title)
        subtitleLabel.text = info.subtitle
    }

    private func setTitle(_ title: String) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = UX.titleLineHeight
        paragraph.maximumLineHeight = UX.titleLineHeight
        // Next to the icon the number hugs it so the gap stays the same; the reserved slack goes to the end.
        paragraph.alignment = imageContainer.isHidden ? .center : .natural
        let attributes: [NSAttributedString.Key: Any] = [.font: UX.titleFont, .paragraphStyle: paragraph]
        titleLabel.attributedText = NSAttributedString(string: title, attributes: attributes)
        titleWidthConstraint.constant = Self.stableWidth(of: title, attributes: attributes)
    }

    /// Width of `title` with every digit swapped for the font's widest digit, so it only changes
    /// when the number gains a digit.
    private static func stableWidth(of title: String, attributes: [NSAttributedString.Key: Any]) -> CGFloat {
        let template = String(title.map { $0.isNumber ? widestDigit : $0 })
        return ceil((template as NSString).size(withAttributes: attributes).width)
    }

    private static let widestDigit: Character = {
        let attributes: [NSAttributedString.Key: Any] = [.font: UX.titleFont]
        return "0123456789".max {
            (String($0) as NSString).size(withAttributes: attributes).width
                < (String($1) as NSString).size(withAttributes: attributes).width
        } ?? "0"
    }()

    // MARK: - Private Setup

    /// Adds a full-tile tap gesture for counter tiles that have a destination URL
    /// (tree counter → plants page; money counter → financial reports).
    private func setupTapGestureIfNeeded() {
        guard info.destinationURL != nil else { return }
        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTileTap))
        addGestureRecognizer(tap)
    }

    // MARK: - Touch Highlight (mirrors NTPGlassButtonStyle pressed state)

    // Ecosia: Provide the same glass-active pressed feedback as EcosiaCustomizeButton.
    // The tintView steps from buttonBgGlassStatic (32 %) to buttonBgGlassStaticActive (64 %)
    // while the finger is down, exactly matching NTPGlassButtonStyle's behaviour.

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        glassBackground.setHighlighted(true)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        glassBackground.setHighlighted(false)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        glassBackground.setHighlighted(false)
    }

    // MARK: - Actions

    @objc private func handleTileTap() {
        HapticFeedback.impact()
        delegate?.impactCellButtonClickedWithInfo(info)
    }
}
