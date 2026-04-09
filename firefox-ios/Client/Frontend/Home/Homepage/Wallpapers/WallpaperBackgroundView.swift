// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

class WallpaperBackgroundView: UIView {
    // MARK: - UI Elements
    private lazy var pictureView: UIImageView = .build { imageView in
        imageView.image = nil
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
    }

    // MARK: - Variables
    var wallpaperState: WallpaperState? {
        didSet {
            updateImageToCurrentWallpaper()
        }
    }

    // MARK: - Initializers & Setup
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = .clear
        addSubview(pictureView)

        NSLayoutConstraint.activate([
            pictureView.leadingAnchor.constraint(equalTo: leadingAnchor),
            pictureView.topAnchor.constraint(equalTo: topAnchor),
            pictureView.bottomAnchor.constraint(equalTo: bottomAnchor),
            pictureView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    // MARK: - Methods
    public func updateImageForOrientationChange() {
        updateImageToCurrentWallpaper()
    }

    // Ecosia: Propagates the card corner radius to both the container layer and the inner
    // pictureView layer. Because pictureView has its own clipsToBounds = true and fills
    // the container exactly, only setting cornerRadius on `self` is not sufficient —
    // pictureView's rectangular clip wins in the CA render tree before the parent mask
    // is applied. Setting the radius on pictureView ensures the image pixels are actually
    // clipped to the rounded shape.
    func applyEcosiaCornerRadius(_ radius: CGFloat) {
        layer.cornerRadius = radius
        clipsToBounds = true
        pictureView.layer.cornerRadius = radius
        pictureView.clipsToBounds = true
    }

    // Ecosia: BrowserViewController.embedContent calls
    // `viewController.view.subviews.forEach { $0.clipsToBounds = false }` to allow toolbar
    // translucency blur to bleed through content. This resets the clipsToBounds we set in
    // applyEcosiaCornerRadius, causing the bottom corners to appear square.
    //
    // A CAShapeLayer applied as layer.mask is immune to clipsToBounds being overridden:
    // masksToBounds controls whether the *layer's own bounds* are used as a clip rect,
    // but layer.mask is a separate compositing mask that is always honoured by Core Animation
    // regardless of masksToBounds. Setting it here (on every layout pass so it tracks
    // bounds changes from rotation/safe-area updates) guarantees all four corners stay
    // clipped even after BrowserViewController forces clipsToBounds = false.
    override func layoutSubviews() {
        super.layoutSubviews()
        guard layer.cornerRadius > 0, !bounds.isEmpty else { return }
        clipsToBounds = true
        pictureView.clipsToBounds = true
        let mask = CAShapeLayer()
        mask.path = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
        layer.mask = mask
    }

    private func updateImageToCurrentWallpaper() {
        guard let state = wallpaperState else { return }
        ensureMainThread {
            let currentWallpaperImage = self.currentWallpaperImage(from: state)
            UIView.animate(withDuration: 0.3) {
                self.pictureView.image = currentWallpaperImage
            }
        }
    }

    private func currentWallpaperImage(from wallpaperState: WallpaperState) -> UIImage? {
        let isLandscape = UIDevice.current.orientation.isLandscape
        return isLandscape ?
        wallpaperState.wallpaperConfiguration.landscapeImage :
         wallpaperState.wallpaperConfiguration.portraitImage
    }
}
