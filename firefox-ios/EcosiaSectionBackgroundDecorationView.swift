import UIKit

/// A reusable background decoration view for Ecosia sections on the Homepage (NTP).
///
/// This decoration view observes background configuration changes and updates itself
/// automatically. Backgrounds can come from an app asset, a local file, or a
/// remote URL (downloaded and cached by the background manager).
final class EcosiaSectionBackgroundDecorationView: UICollectionReusableView {
    static let elementKind = "EcosiaSectionBackgroundDecoration"

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    private var observer: NSObjectProtocol?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        registerForUpdates()
        updateImage()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // Ensure image is up-to-date on reuse
        updateImage()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Refresh for trait changes (scale/class/style) to pick best asset and maintain contrast
        if previousTraitCollection?.displayScale != traitCollection.displayScale ||
            previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle ||
            previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass ||
            previousTraitCollection?.verticalSizeClass != traitCollection.verticalSizeClass {
            updateImage()
        }
    }

    private func registerForUpdates() {
        observer = NotificationCenter.default.addObserver(
            forName: EcosiaSectionBackgroundManager.Notifications.backgroundDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateImage()
        }
    }

    private func updateImage() {
        EcosiaSectionBackgroundManager.shared.loadCurrentImage { [weak self] image in
            guard let self = self else { return }
            if let img = image {
                self.imageView.image = img
                self.backgroundColor = .clear
            } else {
                self.imageView.image = nil
                // Fallback: subtle green-tinted background that adapts to dark mode
                if #available(iOS 13.0, *) {
                    self.backgroundColor = UIColor { tc in
                        if tc.userInterfaceStyle == .dark {
                            return UIColor(red: 0.10, green: 0.16, blue: 0.11, alpha: 1.0)
                        } else {
                            return UIColor(red: 0.90, green: 0.96, blue: 0.90, alpha: 1.0)
                        }
                    }
                } else {
                    self.backgroundColor = UIColor.green.withAlphaComponent(0.15)
                }
            }
        }
    }
}
