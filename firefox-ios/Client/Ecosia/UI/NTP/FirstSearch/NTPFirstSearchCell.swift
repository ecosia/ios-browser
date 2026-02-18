// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import SwiftUI

/// Cell displayed during the product tour's "First Search" state
/// This is a lightweight wrapper around the SwiftUI NTPFirstSearchView
final class NTPFirstSearchCell: UICollectionViewCell, ReusableCell, ThemeApplicable {

    // MARK: - Properties

    var onCloseButtonTapped: (() -> Void)?
    var onSearchSuggestionTapped: ((String) -> Void)?

    private var hostingController: UIHostingController<NTPFirstSearchView>?
    private var windowUUID: WindowUUID = .XCTestDefaultUUID

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }

    // MARK: - Setup

    private func setupCell() {
        contentView.backgroundColor = .clear
    }

    private func setupSwiftUIView(title: String, description: String, suggestions: [String]) {
        // Remove existing hosting controller if needed
        if hostingController != nil {
            return // Already set up, no need to recreate
        }

        // Create SwiftUI view
        let swiftUIView = NTPFirstSearchView(
            title: title,
            description: description,
            suggestions: suggestions,
            windowUUID: windowUUID,
            onClose: { [weak self] in
                self?.onCloseButtonTapped?()
            },
            onSearchSuggestionTapped: { [weak self] suggestion in
                self?.onSearchSuggestionTapped?(suggestion)
            }
        )

        // Create and configure hosting controller
        let hosting = UIHostingController(rootView: swiftUIView)
        hosting.view.backgroundColor = .clear
        hosting.view.translatesAutoresizingMaskIntoConstraints = false

        // Add to content view
        contentView.addSubview(hosting.view)

        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        hostingController = hosting
    }

    // MARK: - Configuration

    func configure(title: String,
                   description: String,
                   suggestions: [String],
                   windowUUID: WindowUUID) {
        self.windowUUID = windowUUID
        setupSwiftUIView(title: title, description: description, suggestions: suggestions)
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        // No need to do anything here - the SwiftUI view handles theme changes
        // via the ecosiaThemed modifier automatically
        contentView.backgroundColor = .clear
    }

    // MARK: - Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()

        // Clean up hosting controller
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()
        hostingController = nil

        // Reset stored values
        onCloseButtonTapped = nil
        onSearchSuggestionTapped = nil
    }
}
