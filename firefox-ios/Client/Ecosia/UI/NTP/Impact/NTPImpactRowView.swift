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

    /// Contains constants used for layout and sizing within the `NTPImpactRowView`.
    /// All spacing/sizing values map to Ecosia design tokens (Figma Foundations).
    struct UX {
        // space-m (16pt) — horizontal gap between icon and statistic title (Figma: Gap 16px)
        static let horizontalSpacing: CGFloat = .ecosia.space._m
        // space-m (16pt) — uniform inset around the tile content (Figma: padding-m)
        static let padding: CGFloat = .ecosia.space._m
        // space-2s (4pt) — vertical gap between [icon+title row] and subtitle (Figma: Gap space-2s)
        static let titleSubtitleGap: CGFloat = .ecosia.space._2s
        // 24pt icon — matches Figma NTP impact icon specification
        static let imageHeight: CGFloat = 24
        static let glassBorderAlpha: CGFloat = NTPGlassUX.borderAlpha
        static let glassBorderWidth: CGFloat = 1
    }

    // MARK: - UI Elements

    // Core Image 24px Gaussian blur glass background (see ADR 0003)
    private let glassBackground: NTPImpactGlassBackgroundView = {
        let view = NTPImpactGlassBackgroundView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // Horizontal container — icon (24×24) on the left, labelsStack on the right.
    // Flow: Horizontal, Gap: space-m (16pt), padding: space-m (16pt) on all sides.
    private let mainContainerView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = UX.horizontalSpacing
        return stack
    }()

    // Vertical labels stack — statistic title above, description below.
    // Flow: Vertical, Gap: space-2s (4pt) per Figma .mobile-globalcounter-item spec.
    // alignment = .fill gives each label an explicit width constraint from the stack,
    // so UILabel always knows its available width for line-wrapping — including after rotation.
    // (With .leading, no width constraint is applied and preferredMaxLayoutWidth stays stale.)
    private let labelsStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = UX.titleSubtitleGap
        return stack
    }()

    /// A container view for the image.
    private lazy var imageContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// The image view representing the icon in the row.
    private lazy var imageView: UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.contentMode = .scaleAspectFit
        return image
    }()

    /// A label for displaying the statistic (large number).
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .ecosiaFamilyBrand(size: .ecosia.font._3l)
        label.adjustsFontSizeToFitWidth = true
        label.adjustsFontForContentSizeCategory = true
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return label
    }()

    /// A label for displaying the description below the statistic.
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        // Force word-wrap so words are never split mid-word across lines.
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    /// A resizable button for performing actions related to the row (referral row only).
    private lazy var actionButton: ResizableButton = {
        let button = ResizableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .footnote).semibold()
        button.titleLabel?.textAlignment = .right
        // ResizableButton defaults to numberOfLines=0; force single line so the button
        // never expands the referral row taller than the trees/invested rows.
        button.titleLabel?.numberOfLines = 1
        button.configuration?.titleLineBreakMode = .byTruncatingTail
        button.contentHorizontalAlignment = .right
        button.contentVerticalAlignment = .center
        button.buttonEdgeInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        button.clipsToBounds = true
        return button
    }()

    /// A divider view separating rows visually.
    private lazy var dividerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Properties

    /// Delegate for handling user interactions with the row.
    weak var delegate: NTPImpactCellDelegate?

    /// The information to display in this row, including title, subtitle, and button information.
    var info: ClimateImpactInfo {
        didSet {
            imageView.image = info.image
            imageView.accessibilityIdentifier = info.imageAccessibilityIdentifier
            titleLabel.text = info.title
            subtitleLabel.text = info.subtitle
            actionButton.isHidden = forceHideActionButton ? true : info.buttonTitle == nil
            actionButton.setTitle(info.buttonTitle, for: .normal)
        }
    }

    /// The current position of this row in the overall list.
    var position: (row: Int, totalCount: Int) = (0, 0) {
        didSet {
            // Each tile is a fully-rounded individual glass card (Figma: border-radius-l on
            // all 4 corners). The divider is replaced by the 8pt gap in the parent stack view.
            dividerView.isHidden = true
        }
    }

    /// Whether to forcefully hide the action button in this row.
    var forceHideActionButton: Bool = false {
        didSet {
            actionButton.isHidden = forceHideActionButton
        }
    }

    /// Optional background color for the row.
    var customBackgroundColor: UIColor?

    // MARK: - Initialization

    /// Initializes a new `NTPImpactRowView` with the provided `ClimateImpactInfo`.
    ///
    /// - Parameter info: The `ClimateImpactInfo` object containing the data to display in the row.
    init(info: ClimateImpactInfo) {
        self.info = info
        super.init(frame: .zero)
        defer {
            // Ensure info setup is completed after initialization
            self.info = info
        }
        setupView()
        setupConstraints()
    }

    /// Not supported, as `NTPImpactRowView` requires `ClimateImpactInfo` during initialization.
    required init?(coder: NSCoder) { nil }

    // MARK: - Setup Methods

    /// Configures and adds subviews to the view.
    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = .ecosia.borderRadius._l
        // clipsToBounds ensures glassBackground respects rounded corners
        clipsToBounds = true
        addSubview(glassBackground)
        addSubview(dividerView)

        // Figma structure — labels stack: [statistic title] / [description]
        labelsStack.addArrangedSubview(titleLabel)
        labelsStack.addArrangedSubview(subtitleLabel)
        labelsStack.isAccessibilityElement = true
        labelsStack.shouldGroupAccessibilityChildren = true
        labelsStack.accessibilityLabel = info.accessibilityLabel
        labelsStack.accessibilityIdentifier = info.accessibilityIdentifier

        // Figma structure — horizontal row: [icon] + [labelsStack] + [action button]
        imageContainer.addSubview(imageView)
        mainContainerView.addArrangedSubview(imageContainer)
        mainContainerView.addArrangedSubview(labelsStack)
        mainContainerView.addArrangedSubview(actionButton)

        addSubview(mainContainerView)
    }

    /// Sets up the layout constraints for the view's subviews.
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            glassBackground.topAnchor.constraint(equalTo: topAnchor),
            glassBackground.leadingAnchor.constraint(equalTo: leadingAnchor),
            glassBackground.trailingAnchor.constraint(equalTo: trailingAnchor),
            glassBackground.bottomAnchor.constraint(equalTo: bottomAnchor),

            mainContainerView.topAnchor.constraint(equalTo: topAnchor, constant: UX.padding),
            mainContainerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.padding),
            mainContainerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.padding),
            mainContainerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.padding),

            dividerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.padding),
            dividerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dividerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: 1),

            imageContainer.heightAnchor.constraint(equalToConstant: UX.imageHeight),
            imageContainer.widthAnchor.constraint(equalTo: imageContainer.heightAnchor),

            imageView.topAnchor.constraint(equalTo: imageContainer.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor),
        ])
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        // Glassmorphism — exact 24px Gaussian blur via Core Image (ADR 0003).
        // glassBackground handles the blur + dark tint; the white border gives the glass edge.
        backgroundColor = .clear
        layer.borderWidth = UX.glassBorderWidth
        layer.borderColor = UIColor(white: 1, alpha: UX.glassBorderAlpha).cgColor
        glassBackground.loadCurrentWallpaper()
        // White text and icons over glassmorphism wallpaper background
        titleLabel.textColor = .white
        subtitleLabel.textColor = .white
        actionButton.setTitleColor(.white, for: .normal)
        imageView.tintColor = .white
        dividerView.backgroundColor = theme.colors.ecosia.borderDecorative
        // Re-apply content so the row is populated when theme runs after being added to the hierarchy (e.g. referral row)
        imageView.image = info.image
        imageView.accessibilityIdentifier = info.imageAccessibilityIdentifier
        titleLabel.text = info.title
        subtitleLabel.text = info.subtitle
        actionButton.isHidden = forceHideActionButton ? true : info.buttonTitle == nil
        actionButton.setTitle(info.buttonTitle, for: .normal)
    }

    // MARK: - Actions

    /// Handles the action button tap event, notifying the delegate.
    @objc private func buttonAction() {
        delegate?.impactCellButtonClickedWithInfo(info)
    }
}
