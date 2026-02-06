// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

/// A wrapped UIImageView which displays a plain search engine icon with no tapping features.
final class PlainSearchEngineView: UIView,
                                   SearchEngineView,
                                   ThemeApplicable {
    // MARK: - Properties
    private enum UX {
        /* Ecosia: Use different sizes for editing vs not editing (legacy URLBarView sizing)
        static let cornerRadius: CGFloat = 4
        static let imageViewSize = CGSize(width: 24, height: 24)
        */
        static let cornerRadius: CGFloat = if #available(iOS 26.0, *) { 12 } else { 4 }
        // Ecosia: Use different sizes for editing (overlay) vs not editing (legacy URLBarView sizing)
        static let imageViewSizeMedium = CGSize(width: 24, height: 24) // When editing
        static let imageViewSizeSmall = CGSize(width: 16, height: 16) // When not editing
    }

    private lazy var searchEngineImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = UX.cornerRadius
        imageView.isAccessibilityElement = true
        imageView.clipsToBounds = true
    }

    // Ecosia: Store constraints for dynamic sizing based on isEditing
    private var imageViewWidthConstraint: NSLayoutConstraint?
    private var imageViewHeightConstraint: NSLayoutConstraint?

    private var theme: Theme?
    private var isURLTextFieldCentered = false {
        didSet {
            // We need to call applyTheme to ensure the colors are updated in sync whenever the layout changes.
            guard let theme, isURLTextFieldCentered != oldValue else { return }
            applyTheme(theme: theme)
        }
    }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /* Ecosia: Configure with LocationViewConfiguration and dynamic sizing
    func configure(_ state: LocationViewState, delegate: LocationViewDelegate) {
        searchEngineImageView.image = state.searchEngineImage
        configureA11y(state)
    }
    */
    func configure(_ config: LocationViewConfiguration, isLocationTextCentered: Bool, delegate: LocationViewDelegate) {
        isURLTextFieldCentered = isLocationTextCentered
        searchEngineImageView.image = config.searchEngineImage
        // Ecosia: Adjust icon size based on editing state (24pt when editing, 16pt when not, like legacy URLBarView)
        updateIconSize(isEditing: config.isEditing)
        configureA11y(config)
    }

    // MARK: - Layout

    private func setupLayout() {
        translatesAutoresizingMaskIntoConstraints = true
        addSubviews(searchEngineImageView)

        /* Ecosia: Store constraints for dynamic sizing
        NSLayoutConstraint.activate([
            searchEngineImageView.heightAnchor.constraint(equalToConstant: UX.imageViewSize.height),
            searchEngineImageView.widthAnchor.constraint(equalToConstant: UX.imageViewSize.width),
        */
        // Ecosia: Store constraints for dynamic sizing
        imageViewHeightConstraint = searchEngineImageView.heightAnchor.constraint(equalToConstant: UX.imageViewSizeMedium.height)
        imageViewWidthConstraint = searchEngineImageView.widthAnchor.constraint(equalToConstant: UX.imageViewSizeMedium.width)

        NSLayoutConstraint.activate([
            imageViewHeightConstraint!,
            imageViewWidthConstraint!,
            searchEngineImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            searchEngineImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            searchEngineImageView.topAnchor.constraint(greaterThanOrEqualTo: self.topAnchor),
            searchEngineImageView.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor),
            searchEngineImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            searchEngineImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
        ])
    }

    // Ecosia: Update icon size based on editing state (legacy URLBarView behaviour)
    private func updateIconSize(isEditing: Bool) {
        let size = isEditing ? UX.imageViewSizeMedium : UX.imageViewSizeSmall
        imageViewWidthConstraint?.constant = size.width
        imageViewHeightConstraint?.constant = size.height
    }

    // MARK: - Accessibility

    /* Ecosia: Use LocationViewConfiguration instead of LocationViewState
    private func configureA11y(_ state: LocationViewState) {
        searchEngineImageView.accessibilityIdentifier = state.searchEngineImageViewA11yId
        searchEngineImageView.accessibilityLabel = state.searchEngineImageViewA11yLabel
        searchEngineImageView.largeContentTitle = state.searchEngineImageViewA11yLabel
        searchEngineImageView.largeContentImage = nil
    }
    */
    private func configureA11y(_ config: LocationViewConfiguration) {
        searchEngineImageView.accessibilityIdentifier = config.searchEngineImageViewA11yId
        searchEngineImageView.accessibilityLabel = config.searchEngineImageViewA11yLabel
        searchEngineImageView.largeContentTitle = config.searchEngineImageViewA11yLabel
        searchEngineImageView.largeContentImage = nil
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        let colors = theme.colors
        /* Ecosia: Use Ecosia background for search engine icon area (legacy URLBarView search icon)
        searchEngineImageView.backgroundColor = isURLTextFieldCentered ? colors.layerSurfaceLow : colors.layer2
         */
        searchEngineImageView.backgroundColor = colors.ecosia.backgroundTertiary
        self.theme = theme
    }
}
