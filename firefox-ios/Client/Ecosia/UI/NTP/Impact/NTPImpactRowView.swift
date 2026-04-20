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
        static let horizontalSpacing: CGFloat = .ecosia.space._m
        static let padding: CGFloat = .ecosia.space._s
        static let titleSubtitleGap: CGFloat = .ecosia.space._2s
        static let imageHeight: CGFloat = 24
        static let glassBorderWidth: CGFloat = 1
    }

    // MARK: - UI Elements

    // Gaussian blur glass background (see ADR 0003)
    private let glassBackground: NTPImpactGlassBackgroundView = {
        let view = NTPImpactGlassBackgroundView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let mainContainerView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = UX.horizontalSpacing
        return stack
    }()

    // alignment = .fill gives each label an explicit width constraint from the stack so UILabel
    // always knows its available width for line-wrapping — including after device rotation.
    // (With .leading, no width constraint is applied and preferredMaxLayoutWidth stays stale.)
    private let labelsStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = UX.titleSubtitleGap
        return stack
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
        label.font = .ecosiaFamilyBrand(size: .ecosia.font._3l)
        label.adjustsFontSizeToFitWidth = true
        label.adjustsFontForContentSizeCategory = true
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
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
            imageView.accessibilityIdentifier = info.imageAccessibilityIdentifier
            titleLabel.text = info.title
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
        setupView()
        setupConstraints()
        setupTapGestureIfNeeded()
    }

    required init?(coder: NSCoder) { nil }

    // MARK: - Setup Methods

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = .ecosia.borderRadius._l
        clipsToBounds = true
        addSubview(glassBackground)

        labelsStack.addArrangedSubview(titleLabel)
        labelsStack.addArrangedSubview(subtitleLabel)
        labelsStack.isAccessibilityElement = true
        labelsStack.shouldGroupAccessibilityChildren = true
        labelsStack.accessibilityLabel = info.accessibilityLabel
        labelsStack.accessibilityIdentifier = info.accessibilityIdentifier

        imageContainer.addSubview(imageView)
        mainContainerView.addArrangedSubview(imageContainer)
        mainContainerView.addArrangedSubview(labelsStack)

        addSubview(mainContainerView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            glassBackground.topAnchor.constraint(equalTo: topAnchor),
            glassBackground.leadingAnchor.constraint(equalTo: leadingAnchor),
            glassBackground.trailingAnchor.constraint(equalTo: trailingAnchor),
            glassBackground.bottomAnchor.constraint(equalTo: bottomAnchor),

            mainContainerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            mainContainerView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: UX.padding),
            mainContainerView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -UX.padding),
            mainContainerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.padding),
            mainContainerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.padding),

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
        imageView.accessibilityIdentifier = info.imageAccessibilityIdentifier
        titleLabel.text = info.title
        subtitleLabel.text = info.subtitle
    }

    // MARK: - Private Setup

    /// Adds a full-tile tap gesture for counter tiles that have a destination URL
    /// (tree counter → plants page; money counter → financial reports).
    private func setupTapGestureIfNeeded() {
        guard info.destinationURL != nil else { return }
        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTileTap))
        addGestureRecognizer(tap)
    }

    // MARK: - Actions

    @objc private func handleTileTap() {
        delegate?.impactCellButtonClickedWithInfo(info)
    }
}
