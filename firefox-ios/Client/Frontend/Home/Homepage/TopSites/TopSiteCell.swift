// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import SiteImageView
import Storage
import UIKit

/// The TopSite cell that appears for the homepage rebuild project.
class TopSiteCell: UICollectionViewCell, ReusableCell {
    // MARK: - Variables

    private var homeTopSite: TopSiteConfiguration?

    struct UX {
        // Ecosia: Figma shortcut-most-visited-iOS icon container: Fixed 56×56px
        static let imageBackgroundSize = CGSize(width: 56, height: 56)
        static let pinIconSize = CGSize(width: 12, height: 12)
        static let pinBackgroundSize = CGSize(width: 16, height: 16)
        static let pinBackgroundCornerRadius: CGFloat = pinBackgroundSize.width / 2
        static let pinBackgroundShadowOffset = CGSize(width: 1, height: 1)
        static let pinBackgroundShadowOpacity: Float = 1.0
        static let pinBackgroundShadowRadius: CGFloat = 4.0
        // Ecosia: space-1s (8pt) — gap between icon container and label (Figma: Gap space-1s)
        static let textSafeSpace: CGFloat = .ecosia.space._1s
        // Ecosia: border-radius-l (10pt) — Figma shortcut icon container Radius: border-radius-l
        static let faviconCornerRadius: CGFloat = .ecosia.borderRadius._l
        static let faviconTransparentBackgroundInset: CGFloat = 8
        // Ecosia: 16pt inset renders the favicon at 24×24pt within the 56pt container
        // (56 − 16 − 16 = 24pt). Confirmed from Figma: favicon is 24×24px.
        static let ecosiaGlassIconInset: CGFloat = 16
        static let transparencyThreshold: CGFloat = 15
        // Ecosia: Tag used to identify the dark-tint overlay added for the NTP glass style.
        static let ecosiaGlassTintTag: Int = 9953
    }

    private var rootContainer: UIView = .build { view in
        view.backgroundColor = .clear
        view.layer.cornerRadius = UX.faviconCornerRadius
    }

    private lazy var imageView: FaviconImageView = {
        let imageView = FaviconImageView { [weak self] in
            self?.configureFaviconWithTransparency()
        }
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var descriptionWrapper: UIStackView = .build { stackView in
        stackView.backgroundColor = .clear
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
    }

    private lazy var pinImageBackgroundView: UIView = .build { view in
        view.backgroundColor = LightTheme().colors.layer2
        view.layer.cornerRadius = UX.pinBackgroundCornerRadius
        view.isHidden = true
    }

    private lazy var pinImageView: UIImageView = .build { imageView in
        imageView.image = UIImage(named: StandardImageIdentifiers.Large.pinFill)
    }

    private lazy var titleLabel: UILabel = .build { titleLabel in
        titleLabel.textAlignment = .center
        // Ecosia: Figma shortcut label Typography: iOS/Footnote/Regular
        titleLabel.font = .preferredFont(forTextStyle: .footnote)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.preferredMaxLayoutWidth = UX.imageBackgroundSize.width + HomepageUX.shadowRadius
        titleLabel.backgroundColor = .clear
        titleLabel.setContentHuggingPriority(UILayoutPriority(1000), for: .vertical)
    }

    private lazy var sponsoredLabel: UILabel = .build { sponsoredLabel in
        sponsoredLabel.textAlignment = .center
        sponsoredLabel.font = FXFontStyles.Regular.caption1.scaledFont()
        sponsoredLabel.adjustsFontForContentSizeCategory = true
        sponsoredLabel.preferredMaxLayoutWidth = UX.imageBackgroundSize.width + HomepageUX.shadowRadius
    }

    private lazy var selectedOverlay: UIView = .build { selectedOverlay in
        selectedOverlay.isHidden = true
        selectedOverlay.layer.cornerRadius = HomepageUX.generalCornerRadius
    }

    override var isSelected: Bool {
        didSet {
            selectedOverlay.isHidden = !isSelected
        }
    }

    override var isHighlighted: Bool {
        didSet {
            selectedOverlay.isHidden = !isHighlighted
        }
    }

    private var textColor: UIColor?
    private var imageViewConstraints: [NSLayoutConstraint] = []
    private var theme: Theme?
    // Ecosia: When true, always use the NTP glass style regardless of Firefox wallpaper state.
    // Set by Ecosia cell configuration since Ecosia always shows an NTP background image.
    var ecosiaGlassStyleEnabled: Bool = false

    // MARK: - Inits

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = true
        accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell

        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        titleLabel.text = nil
        sponsoredLabel.text = nil
        pinImageBackgroundView.isHidden = true
        imageViewConstraints.forEach { $0.constant = 0 }
        // Ecosia: Clean up glass-style views added in adjustBlur
        ecosiaRemoveGlassTintView()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        selectedOverlay.isHidden = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        rootContainer.setNeedsLayout()
        rootContainer.layoutIfNeeded()
        rootContainer.layer.shadowPath = UIBezierPath(roundedRect: rootContainer.bounds,
                                                      cornerRadius: UX.faviconCornerRadius).cgPath

        pinImageBackgroundView.layer.shadowPath = UIBezierPath(roundedRect: pinImageBackgroundView.bounds,
                                                               cornerRadius: UX.pinBackgroundCornerRadius).cgPath
        pinImageBackgroundView.layer.shadowColor = theme?.colors.shadowStrong.cgColor
        pinImageBackgroundView.layer.shadowOpacity = UX.pinBackgroundShadowOpacity
        pinImageBackgroundView.layer.shadowOffset = UX.pinBackgroundShadowOffset
        pinImageBackgroundView.layer.shadowRadius = UX.pinBackgroundShadowRadius

        // Ecosia: `addBlurEffect` guards on `!bounds.isEmpty` so it silently no-ops when called
        // during `configure()` before the first layout pass (new cells start with zero bounds).
        // Re-apply the glass style here once bounds are known, but only when the
        // UIVisualEffectView has not been added yet to avoid redundant work.
        if ecosiaGlassStyleEnabled,
           !rootContainer.subviews.contains(where: { $0 is UIVisualEffectView }),
           let theme {
            adjustBlur(theme: theme)
        }
    }

    // MARK: - Public methods

    func configure(_ topSite: TopSiteConfiguration,
                   position: Int,
                   theme: Theme,
                   textColor: UIColor?) {
        self.theme = theme
        homeTopSite = topSite
        titleLabel.text = topSite.title
        accessibilityLabel = topSite.accessibilityLabel
        accessibilityTraits = .link

        let siteURLString = topSite.site.url
        var imageResource: SiteResource?

        switch topSite.type {
        case .sponsoredSite(let siteInfo):
            if let url = URL(string: siteInfo.imageURL) {
                imageResource = .remoteURL(url: url)
            }
        case .pinnedSite, .suggestedSite:
            imageResource = topSite.site.faviconResource
        default:
            break
        }

        if imageResource == nil,
           let siteURL = URL(string: siteURLString),
           let domainNoTLD = siteURL.baseDomain?.split(separator: ".").first,
           domainNoTLD == "google" {
            // Exception for Google top sites, which all return blurry low quality favicons that on the home screen.
            // Return our bundled G icon for all of the Google Suite.
            // Parse example: "https://drive.google.com/drive/home" > "drive.google.com" > "google"
            imageResource = GoogleTopSiteManager.Constants.faviconResource
        }

        let viewModel = FaviconImageViewModel(siteURLString: siteURLString,
                                              siteResource: imageResource,
                                              faviconCornerRadius: UX.faviconCornerRadius)
        imageView.setFavicon(viewModel)
        self.textColor = textColor

        configurePinnedSite(topSite)
        configureSponsoredSite(topSite)
        configureFaviconWithTransparency()

        applyTheme(theme: theme)
    }

    // MARK: - Setup Helper methods

    private func setupLayout() {
        pinImageBackgroundView.addSubview(pinImageView)

        descriptionWrapper.addArrangedSubview(titleLabel)
        descriptionWrapper.addArrangedSubview(sponsoredLabel)

        rootContainer.addSubview(imageView)
        rootContainer.addSubview(selectedOverlay)
        rootContainer.addSubview(pinImageBackgroundView)
        contentView.addSubview(rootContainer)
        contentView.addSubview(descriptionWrapper)

        NSLayoutConstraint.activate([
            rootContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            rootContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            rootContainer.widthAnchor.constraint(equalToConstant: UX.imageBackgroundSize.width),
            rootContainer.heightAnchor.constraint(equalToConstant: UX.imageBackgroundSize.height),

            descriptionWrapper.topAnchor.constraint(equalTo: rootContainer.bottomAnchor, constant: UX.textSafeSpace),
            descriptionWrapper.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            descriptionWrapper.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            descriptionWrapper.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            selectedOverlay.topAnchor.constraint(equalTo: rootContainer.topAnchor),
            selectedOverlay.leadingAnchor.constraint(equalTo: rootContainer.leadingAnchor),
            selectedOverlay.trailingAnchor.constraint(equalTo: rootContainer.trailingAnchor),
            selectedOverlay.bottomAnchor.constraint(equalTo: rootContainer.bottomAnchor),

            pinImageView.centerXAnchor.constraint(equalTo: pinImageBackgroundView.centerXAnchor),
            pinImageView.centerYAnchor.constraint(equalTo: pinImageBackgroundView.centerYAnchor),
            pinImageView.widthAnchor.constraint(equalToConstant: UX.pinIconSize.width),
            pinImageView.heightAnchor.constraint(equalToConstant: UX.pinIconSize.height),

            pinImageBackgroundView.topAnchor.constraint(equalTo: rootContainer.topAnchor, constant: -4),
            pinImageBackgroundView.leadingAnchor.constraint(equalTo: rootContainer.leadingAnchor, constant: -4),
            pinImageBackgroundView.widthAnchor.constraint(equalToConstant: UX.pinBackgroundSize.width),
            pinImageBackgroundView.heightAnchor.constraint(equalToConstant: UX.pinBackgroundSize.height),
        ])

        imageViewConstraints = [
            imageView.topAnchor.constraint(equalTo: rootContainer.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: rootContainer.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: rootContainer.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: rootContainer.bottomAnchor),
        ]
        NSLayoutConstraint.activate(imageViewConstraints)
    }

    private func configurePinnedSite(_ topSite: TopSiteConfiguration) {
        guard topSite.isPinned else { return }
        // Ecosia: Pin badge is not part of the glass NTP design — always hidden in Ecosia style.
        guard !ecosiaGlassStyleEnabled else { return }

        pinImageBackgroundView.isHidden = false
    }

    private func configureSponsoredSite(_ topSite: TopSiteConfiguration) {
        guard topSite.isSponsored else { return }

        sponsoredLabel.text = topSite.sponsoredText
    }

    // Add insets to favicons with transparent backgrounds
    private func configureFaviconWithTransparency() {
        guard let image = imageView.image,
              let percentTransparent = image.percentTransparent,
              percentTransparent > UX.transparencyThreshold else { return }

        self.imageViewConstraints.forEach { constraint in
            if constraint.firstAttribute == .trailing || constraint.firstAttribute == .bottom {
                constraint.constant = -UX.faviconTransparentBackgroundInset
            } else {
                constraint.constant = UX.faviconTransparentBackgroundInset
            }
            // Inner corner radius = outer corner radius - inset
            self.imageView.layer.cornerRadius = UX.faviconCornerRadius - UX.faviconTransparentBackgroundInset
        }
    }

    // Ecosia: Removes the dark-tint overlay view added by the NTP glass style.
    private func ecosiaRemoveGlassTintView() {
        rootContainer.viewWithTag(UX.ecosiaGlassTintTag)?.removeFromSuperview()
    }

    private func setupShadow(theme: Theme) {
        rootContainer.layer.cornerRadius = UX.faviconCornerRadius
        rootContainer.layer.shadowPath = UIBezierPath(roundedRect: rootContainer.bounds,
                                                      cornerRadius: UX.faviconCornerRadius).cgPath
        rootContainer.layer.shadowColor = theme.colors.shadowStrong.cgColor
        rootContainer.layer.shadowOpacity = HomepageUX.shadowOpacity
        rootContainer.layer.shadowOffset = HomepageUX.shadowOffset
        rootContainer.layer.shadowRadius = HomepageUX.shadowRadius
    }
}

// MARK: ThemeApplicable
extension TopSiteCell: ThemeApplicable {
    func applyTheme(theme: Theme) {
        // Ecosia: Force white text over the glass wallpaper background; wallpaper textColor
        // may be nil or dark which would be invisible against the NTP dark wallpaper.
        let labelColor: UIColor = ecosiaGlassStyleEnabled ? .white : (textColor ?? theme.colors.textPrimary)
        titleLabel.textColor = labelColor
        sponsoredLabel.textColor = labelColor
        selectedOverlay.backgroundColor = theme.colors.layer5Hover.withAlphaComponent(0.25)

        adjustBlur(theme: theme)
    }
}

// MARK: - Blurrable
extension TopSiteCell: Blurrable {
    func adjustBlur(theme: Theme) {
        // Ecosia: `ecosiaGlassStyleEnabled` is set to true by Ecosia cell configuration because
        // Ecosia always shows an NTP background image. Firefox's `shouldApplyWallpaperBlur` checks
        // Firefox's own WallpaperManager which returns false for the Ecosia background.
        if shouldApplyWallpaperBlur || ecosiaGlassStyleEnabled {
            /* Ecosia: Replace system material with the shared NTP "Glass Static" style so
               shortcut tiles match impact tiles and the pencil button over the wallpaper.
            rootContainer.layoutIfNeeded()
            rootContainer.addBlurEffect(using: .systemThickMaterial)
            */
            // Ecosia: Blur base (makes the tile distinct against any wallpaper color) +
            // dark tint overlay (rgba(26,26,26,0.32)) + white border (rgba(255,255,255,0.24)).
            // This mirrors the impact-tile glass technique: blur + tint + border.
            rootContainer.removeVisualEffectView()
            ecosiaRemoveGlassTintView()
            rootContainer.backgroundColor = .clear
            rootContainer.addBlurEffect(using: .systemUltraThinMaterial)
            rootContainer.clipsToBounds = true
            // Insert dark tint above the UIVisualEffectView (index 0) but below the favicon.
            let tintView = UIView()
            tintView.tag = UX.ecosiaGlassTintTag
            tintView.backgroundColor = NTPGlassUX.darkTintColor
            tintView.frame = rootContainer.bounds
            tintView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            tintView.isUserInteractionEnabled = false
            rootContainer.insertSubview(tintView, at: 1)
            rootContainer.layer.borderColor = UIColor.white.withAlphaComponent(NTPGlassUX.borderAlpha).cgColor
            // Ecosia: Figma shortcut icon container Border: 0.5px
            rootContainer.layer.borderWidth = 0.5
            // Ecosia: Inset favicon by 14pt so glass ring is visible around the icon (Figma Padding: 14px).
            let inset = UX.ecosiaGlassIconInset  // 14pt
            imageViewConstraints.forEach { constraint in
                if constraint.firstAttribute == .trailing || constraint.firstAttribute == .bottom {
                    constraint.constant = -inset
                } else {
                    constraint.constant = inset
                }
            }
            imageView.layer.cornerRadius = max(0, UX.faviconCornerRadius - inset)
        } else {
            // If blur is disabled set background color
            rootContainer.removeVisualEffectView()
            ecosiaRemoveGlassTintView()
            rootContainer.backgroundColor = theme.colors.layer5
            rootContainer.layer.borderWidth = 0
            rootContainer.clipsToBounds = false
            imageViewConstraints.forEach { $0.constant = 0 }
            imageView.layer.cornerRadius = 0
            setupShadow(theme: theme)
        }
    }
}
