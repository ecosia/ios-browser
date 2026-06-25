// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Ecosia

/// Horizontally scrollable row of attachment previews above the omnibox text field.
final class OmniboxAttachmentsStripView: UIView, ThemeApplicable {

    enum UX {
        static let tileSpacing: CGFloat = .ecosia.space._1s
        static let horizontalInset: CGFloat = .ecosia.space._m
        /// Room for the remove button that overlaps the top edge of image tiles.
        static let removeButtonTopInset: CGFloat = 8
        static var tileHeight: CGFloat {
            OmniboxAttachmentTileView.UX.imageSize.height + removeButtonTopInset
        }
    }

    var onRemoveAttachment: ((UUID) -> Void)?

    private let scrollView: UIScrollView = .build { scrollView in
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
    }

    private let stackView: UIStackView = .build { stack in
        stack.axis = .horizontal
        stack.spacing = UX.tileSpacing
        stack.alignment = .center
    }

    private var previewImages: [UUID: UIImage] = [:]
    private var tileViews: [UUID: OmniboxAttachmentTileView] = [:]
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
        addSubview(scrollView)
        scrollView.clipsToBounds = false
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: UX.tileHeight),

            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor,
                                           constant: UX.removeButtonTopInset),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor,
                                               constant: UX.horizontalInset),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor,
                                                constant: -UX.horizontalInset),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])
    }

    func setAttachments(_ attachments: [OmniboxAttachment], previewImages: [UUID: UIImage]) {
        self.previewImages = previewImages

        let attachmentIDs = Set(attachments.map(\.id))
        tileViews.keys.filter { !attachmentIDs.contains($0) }.forEach { id in
            tileViews[id]?.removeFromSuperview()
            tileViews.removeValue(forKey: id)
        }

        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for attachment in attachments {
            let tile = tileViews[attachment.id] ?? makeTile(for: attachment.id)
            tile.configure(attachment: attachment, previewImage: previewImages[attachment.id])
            if let theme = currentTheme {
                tile.applyTheme(theme: theme)
            }
            stackView.addArrangedSubview(tile)
        }

        isHidden = attachments.isEmpty
    }

    func applyTheme(theme: any Theme) {
        currentTheme = theme
        tileViews.values.forEach { $0.applyTheme(theme: theme) }
    }

    private func makeTile(for id: UUID) -> OmniboxAttachmentTileView {
        let tile = OmniboxAttachmentTileView()
        tile.translatesAutoresizingMaskIntoConstraints = false
        tile.onRemove = { [weak self] in
            self?.onRemoveAttachment?(id)
        }
        tileViews[id] = tile
        return tile
    }
}
