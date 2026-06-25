// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Ecosia

/// Single attachment preview tile in the omnibox strip — loading spinner, file card, or image thumbnail.
final class OmniboxAttachmentTileView: UIView, ThemeApplicable {

    enum UX {
        static let fileSize = CGSize(width: 128, height: 56)
        static let imageSize = CGSize(width: 74, height: 74)
        static let cornerRadius: CGFloat = .ecosia.borderRadius._m
        static let removeButtonContainerSize: CGFloat = 32
        static let removeButtonIconSize: CGFloat = 16
        static let glassBorderWidth: CGFloat = 1
    }

    var onRemove: (() -> Void)?

    private let containerView: UIView = .build { view in
        view.layer.cornerRadius = UX.cornerRadius
        view.clipsToBounds = true
    }

    private let spinner: UIActivityIndicatorView = .build { spinner in
        spinner.hidesWhenStopped = true
    }

    private let fileNameLabel: UILabel = .build { label in
        label.font = .preferredFont(forTextStyle: .caption2)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingMiddle
    }

    private let fileSizeLabel: UILabel = .build { label in
        label.font = .preferredFont(forTextStyle: .caption2)
        label.adjustsFontForContentSizeCategory = true
    }

    private let imageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
    }

    private let imageLoadingOverlay: UIView = .build { view in
        view.isHidden = true
        view.isUserInteractionEnabled = false
    }

    private let removeButtonContainer: UIView = .build { view in
        view.layer.cornerRadius = UX.removeButtonContainerSize / 2
        view.clipsToBounds = true
    }

    private let removeGlassBlur: UIVisualEffectView = .build { blur in
        blur.effect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        blur.isUserInteractionEnabled = false
    }

    private let removeGlassTint: UIView = .build { view in
        view.isUserInteractionEnabled = false
    }

    private let removeIconView: UIImageView = .build { imageView in
        imageView.image = UIImage.ecosia(named: "close")?.withRenderingMode(.alwaysTemplate)
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = false
    }

    private lazy var removeButton: UIButton = .build { _ in }

    private var widthConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?
    private var currentLayout: OmniboxAttachment.Layout = .file
    private var currentTheme: Theme?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        clipsToBounds = false
        addSubview(containerView)
        containerView.addSubviews(spinner, fileNameLabel, fileSizeLabel, imageView, imageLoadingOverlay)
        addSubview(removeButtonContainer)
        removeButtonContainer.addSubviews(removeGlassBlur, removeGlassTint, removeIconView)
        addSubview(removeButton)
        removeButton.accessibilityLabel = String.localized(.cancel)
        removeButton.addTarget(self, action: #selector(removeTapped), for: .touchUpInside)

        widthConstraint = widthAnchor.constraint(equalToConstant: UX.fileSize.width)
        heightConstraint = heightAnchor.constraint(equalToConstant: UX.fileSize.height)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),

            spinner.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

            fileNameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: .ecosia.space._1s),
            fileNameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -.ecosia.space._1s),
            fileNameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: .ecosia.space._1s),

            fileSizeLabel.leadingAnchor.constraint(equalTo: fileNameLabel.leadingAnchor),
            fileSizeLabel.trailingAnchor.constraint(equalTo: fileNameLabel.trailingAnchor),
            fileSizeLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -.ecosia.space._1s),

            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            imageLoadingOverlay.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageLoadingOverlay.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageLoadingOverlay.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            imageLoadingOverlay.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            removeButtonContainer.topAnchor.constraint(equalTo: topAnchor, constant: -6),
            removeButtonContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 6),
            removeButtonContainer.widthAnchor.constraint(equalToConstant: UX.removeButtonContainerSize),
            removeButtonContainer.heightAnchor.constraint(equalToConstant: UX.removeButtonContainerSize),

            removeGlassBlur.topAnchor.constraint(equalTo: removeButtonContainer.topAnchor),
            removeGlassBlur.leadingAnchor.constraint(equalTo: removeButtonContainer.leadingAnchor),
            removeGlassBlur.trailingAnchor.constraint(equalTo: removeButtonContainer.trailingAnchor),
            removeGlassBlur.bottomAnchor.constraint(equalTo: removeButtonContainer.bottomAnchor),

            removeGlassTint.topAnchor.constraint(equalTo: removeButtonContainer.topAnchor),
            removeGlassTint.leadingAnchor.constraint(equalTo: removeButtonContainer.leadingAnchor),
            removeGlassTint.trailingAnchor.constraint(equalTo: removeButtonContainer.trailingAnchor),
            removeGlassTint.bottomAnchor.constraint(equalTo: removeButtonContainer.bottomAnchor),

            removeIconView.centerXAnchor.constraint(equalTo: removeButtonContainer.centerXAnchor),
            removeIconView.centerYAnchor.constraint(equalTo: removeButtonContainer.centerYAnchor),
            removeIconView.widthAnchor.constraint(equalToConstant: UX.removeButtonIconSize),
            removeIconView.heightAnchor.constraint(equalToConstant: UX.removeButtonIconSize),

            removeButton.topAnchor.constraint(equalTo: removeButtonContainer.topAnchor),
            removeButton.leadingAnchor.constraint(equalTo: removeButtonContainer.leadingAnchor),
            removeButton.trailingAnchor.constraint(equalTo: removeButtonContainer.trailingAnchor),
            removeButton.bottomAnchor.constraint(equalTo: removeButtonContainer.bottomAnchor),

            widthConstraint,
            heightConstraint
        ].compactMap { $0 })
    }

    func configure(attachment: OmniboxAttachment, previewImage: UIImage?) {
        currentLayout = attachment.layout
        let size = attachment.layout == .image ? UX.imageSize : UX.fileSize
        widthConstraint?.constant = size.width
        heightConstraint?.constant = size.height

        resetVisibility()

        switch attachment.layout {
        case .image:
            configureImageTile(attachment: attachment, previewImage: previewImage)
        case .file:
            configureFileTile(attachment: attachment)
        }

        applyRemoveButtonStyle(for: attachment.layout)
        if let currentTheme { applyTheme(theme: currentTheme) }
    }

    func applyTheme(theme: any Theme) {
        currentTheme = theme
        let colors = theme.colors
        let ecosia = (colors as? EcosiaThemeColourPalette)?.ecosia

        if currentLayout == .image {
            containerView.backgroundColor = colors.ecosia.backgroundQuaternary
        } else {
            containerView.backgroundColor = colors.ecosia.backgroundQuaternary
        }

        fileNameLabel.textColor = colors.ecosia.textPrimary
        fileSizeLabel.textColor = colors.ecosia.textSecondary
        spinner.color = colors.ecosia.textSecondary
        imageLoadingOverlay.backgroundColor = colors.ecosia.textPrimary.withAlphaComponent(0.35)

        removeGlassTint.backgroundColor = ecosia?.buttonBgGlassStatic
            ?? EcosiaColor.Gray90.withAlphaComponent(0.32)
        removeButtonContainer.layer.borderColor = (ecosia?.borderGlassStatic
            ?? EcosiaColor.White.withAlphaComponent(0x3D / 255.0)).cgColor

        applyRemoveButtonStyle(for: currentLayout)
    }

    private func resetVisibility() {
        spinner.stopAnimating()
        spinner.isHidden = true
        fileNameLabel.isHidden = true
        fileSizeLabel.isHidden = true
        imageView.isHidden = true
        imageLoadingOverlay.isHidden = true
        removeButton.isHidden = false
        removeButtonContainer.isHidden = false
    }

    private func configureImageTile(attachment: OmniboxAttachment, previewImage: UIImage?) {
        switch attachment.state {
        case .loading:
            if let previewImage {
                showImagePreview(previewImage, uploading: true, failed: false)
            } else {
                spinner.isHidden = false
                spinner.startAnimating()
                removeButton.isHidden = true
                removeButtonContainer.isHidden = true
            }
        case .ready:
            showImagePreview(previewImage, uploading: false, failed: false)
        case .failed:
            showImagePreview(previewImage, uploading: false, failed: true)
        }
    }

    private func showImagePreview(_ image: UIImage?, uploading: Bool, failed: Bool) {
        imageView.isHidden = false
        imageView.image = image
        imageLoadingOverlay.isHidden = !uploading
        containerView.layer.borderWidth = failed ? 1 : 0
        containerView.layer.borderColor = failed
            ? (currentTheme?.colors.ecosia.stateError.cgColor)
            : nil
        if uploading {
            spinner.isHidden = false
            spinner.startAnimating()
            spinner.color = currentTheme?.colors.ecosia.buttonContentPrimary ?? .white
        }
        bringSubviewToFront(imageLoadingOverlay)
        bringSubviewToFront(spinner)
        bringSubviewToFront(removeButtonContainer)
        bringSubviewToFront(removeButton)
    }

    private func configureFileTile(attachment: OmniboxAttachment) {
        switch attachment.state {
        case .loading:
            spinner.isHidden = false
            spinner.startAnimating()
            removeButton.isHidden = true
            removeButtonContainer.isHidden = true
        case .failed:
            fileNameLabel.isHidden = false
            fileNameLabel.text = attachment.fileName
            fileSizeLabel.isHidden = false
            fileSizeLabel.text = String.localized(.uploadAttachmentFailed)
        case .ready(let byteCount, _, _):
            fileNameLabel.isHidden = false
            fileNameLabel.text = attachment.fileName
            fileSizeLabel.isHidden = false
            fileSizeLabel.text = Self.formattedByteCount(byteCount)
        }
    }

    private func applyRemoveButtonStyle(for layout: OmniboxAttachment.Layout) {
        guard let colors = currentTheme?.colors else { return }
        switch layout {
        case .file:
            removeGlassBlur.isHidden = true
            removeGlassTint.isHidden = true
            removeButtonContainer.backgroundColor = .clear
            removeButtonContainer.layer.borderWidth = 0
            removeIconView.tintColor = colors.ecosia.buttonContentSecondary
        case .image:
            removeGlassBlur.isHidden = false
            removeGlassTint.isHidden = false
            removeButtonContainer.backgroundColor = .clear
            removeButtonContainer.layer.borderWidth = UX.glassBorderWidth
            removeIconView.tintColor = colors.ecosia.buttonContentPrimary
        }
    }

    @objc private func removeTapped() {
        onRemove?()
    }

    private static func formattedByteCount(_ byteCount: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(byteCount), countStyle: .file)
    }
}
