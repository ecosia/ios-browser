// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Ecosia

final class OmniboxUploadOptionView: UIControl {

    private enum UX {
        static let iconContainerSize: CGFloat = 56
        static let iconSize: CGFloat = 24
        static let spacing: CGFloat = .ecosia.space._1s
    }

    let option: OmniboxUploadOption

    private let iconContainer: UIView = .build { view in
        view.layer.cornerRadius = .ecosia.borderRadius._m
        view.isUserInteractionEnabled = false
    }

    private let iconView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = false
    }

    private let titleLabel: UILabel = .build { label in
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 2
        label.isUserInteractionEnabled = false
    }

    init(option: OmniboxUploadOption) {
        self.option = option
        super.init(frame: .zero)
        setup()
        configureContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        isAccessibilityElement = true
        accessibilityTraits = .button

        addSubview(iconContainer)
        iconContainer.addSubview(iconView)
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            iconContainer.topAnchor.constraint(equalTo: topAnchor),
            iconContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: UX.iconContainerSize),
            iconContainer.heightAnchor.constraint(equalToConstant: UX.iconContainerSize),

            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: UX.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: UX.iconSize),

            titleLabel.topAnchor.constraint(equalTo: iconContainer.bottomAnchor, constant: UX.spacing),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func configureContent() {
        switch option {
        case .photos:
            titleLabel.text = String.localized(.photos)
            iconView.image = UIImage.ecosia(named: "upload-photos")?.withRenderingMode(.alwaysTemplate)
            accessibilityLabel = String.localized(.photos)
            accessibilityHint = String.localized(.uploadPhotosAccessibilityHint)
            accessibilityIdentifier = "OmniboxUploadPhotosOption"
        case .camera:
            titleLabel.text = String.localized(.camera)
            iconView.image = UIImage.ecosia(named: "upload-camera")?.withRenderingMode(.alwaysTemplate)
            accessibilityLabel = String.localized(.camera)
            accessibilityHint = String.localized(.uploadCameraAccessibilityHint)
            accessibilityIdentifier = "OmniboxUploadCameraOption"
        case .files:
            titleLabel.text = String.localized(.files)
            iconView.image = UIImage.ecosia(named: "upload-files")?.withRenderingMode(.alwaysTemplate)
            accessibilityLabel = String.localized(.files)
            accessibilityHint = String.localized(.uploadFilesAccessibilityHint)
            accessibilityIdentifier = "OmniboxUploadFilesOption"
        }
    }

    func applyTheme(theme: Theme) {
        let colors = theme.colors.ecosia
        iconContainer.backgroundColor = colors.backgroundElevation1
        iconView.tintColor = colors.buttonContentSecondary
        titleLabel.textColor = colors.textSecondary
    }
}
