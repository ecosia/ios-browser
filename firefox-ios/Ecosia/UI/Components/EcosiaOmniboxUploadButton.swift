// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

/// Paperclip upload control for the NTP omnibox bottom-left corner.
/// Shows a circular pressed-state background using the transparent-button active token.
public final class EcosiaOmniboxUploadButton: UIButton, ThemeApplicable {

    private enum UX {
        static let iconSize: CGFloat = 20
    }

    private let highlightCircle: UIView = .build { circle in
        circle.isUserInteractionEnabled = false
        circle.isHidden = true
        circle.layer.cornerRadius = .ecosia.space._3l / 2
    }

    private let iconView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = false
        imageView.image = UIImage.ecosia(named: "attachment")?.withRenderingMode(.alwaysTemplate)
    }

    private var currentTheme: Theme?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var isHighlighted: Bool {
        didSet {
            highlightCircle.isHidden = !isHighlighted
        }
    }

    private func setup() {
        backgroundColor = .clear
        accessibilityIdentifier = "NTPSearchBarUploadButton"
        accessibilityLabel = String.localized(.upload)
        accessibilityHint = String.localized(.uploadAccessibilityHint)

        addSubview(highlightCircle)
        addSubview(iconView)

        NSLayoutConstraint.activate([
            highlightCircle.centerXAnchor.constraint(equalTo: centerXAnchor),
            highlightCircle.centerYAnchor.constraint(equalTo: centerYAnchor),
            highlightCircle.widthAnchor.constraint(equalToConstant: .ecosia.space._3l),
            highlightCircle.heightAnchor.constraint(equalToConstant: .ecosia.space._3l),

            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: UX.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: UX.iconSize)
        ])
    }

    public func applyTheme(theme: any Theme) {
        currentTheme = theme
        let colors = theme.colors.ecosia
        iconView.tintColor = colors.buttonContentSecondary
        highlightCircle.backgroundColor = colors.buttonBackgroundTransparentActive
    }
}
