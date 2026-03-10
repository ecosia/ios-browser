// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import UIKit

// MARK: - View Model

struct SpotlightToastViewModel {
    let image: UIImage?
    let titleText: String
    let descriptionText: String
    let currentStep: Int
    let totalSteps: Int
    let primaryButtonText: String
    let secondaryButtonText: String?
    /// Optional trailing icon displayed to the right of the secondary button text.
    let secondaryButtonIcon: UIImage?

    init(
        image: UIImage?,
        titleText: String,
        descriptionText: String,
        currentStep: Int,
        totalSteps: Int,
        primaryButtonText: String,
        secondaryButtonText: String?,
        secondaryButtonIcon: UIImage? = nil
    ) {
        self.image = image
        self.titleText = titleText
        self.descriptionText = descriptionText
        self.currentStep = currentStep
        self.totalSteps = totalSteps
        self.primaryButtonText = primaryButtonText
        self.secondaryButtonText = secondaryButtonText
        self.secondaryButtonIcon = secondaryButtonIcon
    }
}

// MARK: - SpotlightToast

class SpotlightToast: Toast, UIGestureRecognizerDelegate {
    struct UX {
        static let cornerRadius: CGFloat = 10
        static let cardPadding: CGFloat = 8
        static let contentPadding: CGFloat = 8
        static let verticalSpacing: CGFloat = 16
        static let buttonSpacing: CGFloat = 8

        static let subheadlineFontSize: CGFloat = 15

        static let buttonHeight: CGFloat = 40
        static let buttonCornerRadius: CGFloat = 20
        static let buttonHorizontalPadding: CGFloat = 16
        static let buttonInternalSpacing: CGFloat = 16
        static let secondaryButtonIconPadding: CGFloat = 4
        static let secondaryButtonIconSize: CGFloat = 16

        static let showAnimationDelay: TimeInterval = 0.5
        static let transitionAnimationDuration: TimeInterval = 0.5
        static let verticalAnimationOffset: CGFloat = 50

        /// Maximum width of the toast on wide layouts such as iPad.
        /// Matches the preferred form sheet width used by other modal screens (e.g. DefaultBrowserViewController).
        static let maxWidth: CGFloat = 544
        static let imageAspectRatio: CGFloat = 9/16
        static let imageCornerRadius: CGFloat = 8
    }

    // MARK: - Gradient Overlay

    /// Transparent-to-solid scrim behind the toast covering only the web view area.
    private final class GradientOverlayView: UIView {
        override class var layerClass: AnyClass { CAGradientLayer.self }

        override init(frame: CGRect) {
            super.init(frame: frame)
            let gradient = layer as! CAGradientLayer
            gradient.startPoint = CGPoint(x: 0.5, y: 0)
            gradient.endPoint   = CGPoint(x: 0.5, y: 1)
        }

        required init?(coder: NSCoder) { fatalError() }

        func apply(color: UIColor) {
            (layer as! CAGradientLayer).colors = [color.withAlphaComponent(0).cgColor, color.cgColor]
        }
    }

    private var gradientOverlay: GradientOverlayView?
    private var gradientColor: UIColor?

    // MARK: - Properties

    private var viewModel: SpotlightToastViewModel
    private var primaryButtonAction: (() -> Void)?
    private var secondaryButtonAction: (() -> Void)?

    // Reusable constraints for optional views
    private lazy var secondaryButtonHeightConstraint: NSLayoutConstraint = {
        secondaryButton.heightAnchor.constraint(equalToConstant: UX.buttonHeight)
    }()

    /// Pixel-aligned height set by `updateImageHeightIfNeeded()` once width is known.
    private lazy var imageHeightConstraint: NSLayoutConstraint = {
        spotlightImageView.heightAnchor.constraint(equalToConstant: 0)
    }()

    // MARK: - UI Components

    private lazy var containerStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.cardPadding
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.layoutMargins = .init(equalInset: UX.cardPadding)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layer.cornerRadius = UX.cornerRadius
        stackView.clipsToBounds = true
    }

    private lazy var textContentStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.verticalSpacing
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.layoutMargins = .init(equalInset: UX.contentPadding)
        stackView.isLayoutMarginsRelativeArrangement = true
    }

    private lazy var spotlightImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = UX.imageCornerRadius
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.font = DefaultDynamicFontHelper.preferredBoldFont(
            withTextStyle: .subheadline,
            size: UX.subheadlineFontSize
        )
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
    }

    private lazy var descriptionLabel: UILabel = .build { label in
        label.font = DefaultDynamicFontHelper.preferredFont(
            withTextStyle: .subheadline,
            size: UX.subheadlineFontSize
        )
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
    }

    private lazy var bottomRowStackView: UIStackView = .build { stackView in
        stackView.axis = .horizontal
        stackView.spacing = UX.buttonSpacing
        stackView.alignment = .center
        stackView.distribution = .fill
    }

    private lazy var stepCounterLabel: UILabel = .build { label in
        label.font = DefaultDynamicFontHelper.preferredFont(
            withTextStyle: .subheadline,
            size: UX.subheadlineFontSize
        )
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private lazy var buttonStackView: UIStackView = .build { stackView in
        stackView.axis = .horizontal
        stackView.spacing = UX.buttonInternalSpacing
        stackView.alignment = .fill
        stackView.distribution = .fill
    }

    private lazy var secondaryButton: UIButton = .build { button in
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: UX.buttonHorizontalPadding,
            bottom: 0,
            trailing: UX.buttonHorizontalPadding
        )
        config.imagePlacement = .trailing
        config.imagePadding = UX.secondaryButtonIconPadding
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = DefaultDynamicFontHelper.preferredFont(
                withTextStyle: .subheadline,
                size: UX.subheadlineFontSize
            )
            return outgoing
        }
        button.configuration = config
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private lazy var primaryButton: UIButton = .build { button in
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: UX.buttonHorizontalPadding,
            bottom: 0,
            trailing: UX.buttonHorizontalPadding
        )
        config.cornerStyle = .capsule
        config.background.strokeWidth = 1
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = DefaultDynamicFontHelper.preferredFont(
                withTextStyle: .subheadline,
                size: UX.subheadlineFontSize
            )
            return outgoing
        }
        button.configuration = config
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    // MARK: - Initialization

    init(
        viewModel: SpotlightToastViewModel,
        theme: Theme?,
        primaryAction: @escaping () -> Void,
        secondaryAction: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.primaryButtonAction = primaryAction
        self.secondaryButtonAction = secondaryAction

        super.init(frame: .zero)

        setupView()
        configureContent()

        if let theme = theme {
            applyTheme(theme: theme)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        self.clipsToBounds = true
        self.addSubview(toastView)
        toastView.addSubview(containerStackView)

        // Configure gesture recognizer for custom tap handling
        gestureRecognizer.isEnabled = true
        gestureRecognizer.delegate = self

        // Build view hierarchy
        configureImageView(for: viewModel)
        textContentStackView.addArrangedSubview(titleLabel)
        textContentStackView.addArrangedSubview(descriptionLabel)
        textContentStackView.addArrangedSubview(bottomRowStackView)
        containerStackView.addArrangedSubview(textContentStackView)
        bottomRowStackView.addArrangedSubview(stepCounterLabel)
        bottomRowStackView.addArrangedSubview(UIView()) // Flexible spacer to right-align buttons
        bottomRowStackView.addArrangedSubview(buttonStackView)

        // Add buttons to button stack view
        configureSecondaryButton(for: viewModel)
        primaryButton.addTarget(self, action: #selector(primaryButtonTapped), for: .touchUpInside)
        buttonStackView.addArrangedSubview(primaryButton)

        NSLayoutConstraint.activate([
            containerStackView.leadingAnchor.constraint(equalTo: toastView.leadingAnchor, constant: UX.cardPadding),
            containerStackView.trailingAnchor.constraint(equalTo: toastView.trailingAnchor, constant: -UX.cardPadding),
            containerStackView.topAnchor.constraint(equalTo: toastView.topAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: toastView.bottomAnchor, constant: -UX.cardPadding),

            toastView.leadingAnchor.constraint(equalTo: leadingAnchor),
            toastView.trailingAnchor.constraint(equalTo: trailingAnchor),
            toastView.topAnchor.constraint(equalTo: topAnchor),
            toastView.bottomAnchor.constraint(equalTo: bottomAnchor),

            primaryButton.heightAnchor.constraint(equalToConstant: UX.buttonHeight)
        ])
    }

    /// Adds or removes the image view from the container stack based on the view model.
    /// The image view always uses the same fixed aspect ratio so all steps look consistent.
    private func configureImageView(for viewModel: SpotlightToastViewModel) {
        if viewModel.image != nil {
            if spotlightImageView.superview == nil {
                containerStackView.insertArrangedSubview(spotlightImageView, at: 0)
                imageHeightConstraint.isActive = true
            }
        } else {
            if spotlightImageView.superview != nil {
                containerStackView.removeArrangedSubview(spotlightImageView)
                spotlightImageView.removeFromSuperview()
                imageHeightConstraint.isActive = false
            }
        }
    }

    /// Updates the image height constraint to a pixel-aligned value based on the
    /// current width and the desired aspect ratio. This avoids sub-pixel rounding
    /// differences that occur when using a multiplier-based constraint, which can
    /// cause visible shifts during snapshot-based transition animations.
    private func updateImageHeightIfNeeded() {
        let width = spotlightImageView.bounds.width
        guard width > 0 else { return }
        let scale = traitCollection.displayScale > 0 ? traitCollection.displayScale : UIScreen.main.scale
        let exactHeight = width * UX.imageAspectRatio
        let pixelAlignedHeight = ceil(exactHeight * scale) / scale
        if imageHeightConstraint.constant != pixelAlignedHeight {
            imageHeightConstraint.constant = pixelAlignedHeight
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateImageHeightIfNeeded()
    }

    /// Adds or removes the secondary button from the button stack based on the view model
    private func configureSecondaryButton(for viewModel: SpotlightToastViewModel) {
        if viewModel.secondaryButtonText != nil {
            if secondaryButton.superview == nil {
                secondaryButton.addTarget(self, action: #selector(secondaryButtonTapped), for: .touchUpInside)
                buttonStackView.insertArrangedSubview(secondaryButton, at: 0)
                secondaryButtonHeightConstraint.isActive = true
            }
        } else {
            if secondaryButton.superview != nil {
                secondaryButton.removeTarget(self, action: #selector(secondaryButtonTapped), for: .touchUpInside)
                buttonStackView.removeArrangedSubview(secondaryButton)
                secondaryButton.removeFromSuperview()
                secondaryButtonHeightConstraint.isActive = false
            }
        }
    }

    /// Configures the secondary button's trailing icon based on the view model
    private func configureSecondaryButtonIcon(for viewModel: SpotlightToastViewModel) {
        guard var config = secondaryButton.configuration else { return }
        if let icon = viewModel.secondaryButtonIcon {
            let size = CGSize(width: UX.secondaryButtonIconSize, height: UX.secondaryButtonIconSize)
            let renderer = UIGraphicsImageRenderer(size: size)
            let resizedIcon = renderer.image { _ in
                icon.draw(in: CGRect(origin: .zero, size: size))
            }
            config.image = resizedIcon.withRenderingMode(.alwaysTemplate)
        } else {
            config.image = nil
        }
        secondaryButton.configuration = config
    }

    private func configureContent() {
        spotlightImageView.image = viewModel.image
        titleLabel.text = viewModel.titleText
        descriptionLabel.text = viewModel.descriptionText

        if viewModel.totalSteps > 1 {
            stepCounterLabel.text = "\(viewModel.currentStep) / \(viewModel.totalSteps)"
            stepCounterLabel.isHidden = false
        } else {
            stepCounterLabel.text = nil
            stepCounterLabel.isHidden = true
        }

        // Update button text
        primaryButton.setTitle(viewModel.primaryButtonText, for: .normal)
        if let secondaryButtonText = viewModel.secondaryButtonText {
            secondaryButton.setTitle(secondaryButtonText, for: .normal)
        }

        // Update secondary button icon
        configureSecondaryButtonIcon(for: viewModel)
    }

    // MARK: - Theme

    override func applyTheme(theme: Theme) {
        super.applyTheme(theme: theme)
        containerStackView.backgroundColor = theme.colors.ecosia.backgroundFeatured
        titleLabel.textColor = theme.colors.ecosia.textPrimary
        descriptionLabel.textColor = theme.colors.ecosia.textPrimary
        stepCounterLabel.textColor = theme.colors.ecosia.textPrimary

        if secondaryButton.superview != nil {
            var secondaryConfig = secondaryButton.configuration
            secondaryConfig?.baseForegroundColor = theme.colors.ecosia.buttonContentSecondary
            secondaryConfig?.baseBackgroundColor = .clear
            secondaryButton.configuration = secondaryConfig
        }

        var primaryConfig = primaryButton.configuration
        primaryConfig?.baseForegroundColor = theme.colors.ecosia.textPrimary
        primaryConfig?.baseBackgroundColor = .clear
        primaryConfig?.background.strokeColor = theme.colors.ecosia.textPrimary
        primaryButton.configuration = primaryConfig

        gradientColor = theme.colors.ecosia.backgroundGradient
        gradientOverlay?.apply(color: theme.colors.ecosia.backgroundGradient)
    }

    // MARK: - Actions

    @objc
    private func primaryButtonTapped() {
        primaryButtonAction?()
    }

    @objc
    private func secondaryButtonTapped() {
        secondaryButtonAction?()
    }

    // MARK: - Public Methods

    /// Show the spotlight toast with animation
    func show(
        in viewController: UIViewController,
        bottomAnchorView: UIView,
        delay: TimeInterval = UX.showAnimationDelay
    ) {
        self.viewController = viewController
        translatesAutoresizingMaskIntoConstraints = false

        // Gradient overlay behind the toast (web view area only, not over toolbars)
        let overlay = GradientOverlayView()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.alpha = 0
        if let color = gradientColor { overlay.apply(color: color) }
        viewController.view.insertSubview(overlay, belowSubview: bottomAnchorView)
        gradientOverlay = overlay

        viewController.view.addSubview(self)

        // On iPhone portrait the toast fills the full view width (matching Toast behaviour).
        // On iPad and landscape the width is capped at maxWidth and centred.
        // The high-priority equality makes the toast prefer full width; the required
        // lessThanOrEqualTo cap wins whenever the view is wider than maxWidth.
        let preferFullWidth = widthAnchor.constraint(equalTo: viewController.view.widthAnchor)
        preferFullWidth.priority = .defaultHigh

        NSLayoutConstraint.activate([
            preferFullWidth,
            widthAnchor.constraint(lessThanOrEqualToConstant: UX.maxWidth),
            centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            leadingAnchor.constraint(greaterThanOrEqualTo: viewController.view.leadingAnchor),
            trailingAnchor.constraint(lessThanOrEqualTo: viewController.view.trailingAnchor),
            bottomAnchor.constraint(equalTo: bottomAnchorView.topAnchor),

            overlay.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            overlay.topAnchor.constraint(equalTo: topAnchor),
            overlay.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)
        ])

        // Set initial state: below and transparent
        containerStackView.transform = CGAffineTransform(translationX: 0, y: UX.verticalAnimationOffset)
        containerStackView.alpha = 0

        // Compute the pixel-aligned height
        updateImageHeightIfNeeded()

        layoutIfNeeded()

        // Animate to final position
        UIView.animate(
            withDuration: Toast.UX.toastAnimationDuration,
            delay: delay,
            options: [.curveEaseOut],
            animations: {
                self.containerStackView.transform = .identity
                self.containerStackView.alpha = 1.0
                self.gradientOverlay?.alpha = 1.0
            }
        )
    }

    /// Transition to a new view model with directional animation
    /// - Parameters:
    ///   - newViewModel: The new spotlight step to display
    ///   - direction: The direction of transition (.forward or .backward)
    ///   - completion: Called when transition is complete
    func transition(
        to newViewModel: SpotlightToastViewModel,
        direction: TransitionDirection,
        completion: (() -> Void)? = nil
    ) {
        guard let snapshot = containerStackView.snapshotView(afterScreenUpdates: false) else {
            // Fallback: just update content if snapshot fails
            self.viewModel = newViewModel
            configureImageView(for: newViewModel)
            configureSecondaryButton(for: newViewModel)
            configureContent()
            completion?()
            return
        }

        // Calculate offsets for horizontal slide animation
        let containerWidth = containerStackView.bounds.width
        let spacing: CGFloat = UX.cardPadding * 2
        let animationOffset = containerWidth + spacing
        let exitOffset: CGFloat = direction == .forward ? -animationOffset : animationOffset
        let entryOffset: CGFloat = direction == .forward ? animationOffset : -animationOffset

        // Position snapshot at current location
        snapshot.frame = containerStackView.frame
        snapshot.alpha = containerStackView.alpha
        snapshot.transform = containerStackView.transform
        toastView.addSubview(snapshot)

        // Update content and reconfigure optional views
        self.viewModel = newViewModel
        configureImageView(for: newViewModel)
        configureSecondaryButton(for: newViewModel)
        configureContent()
        containerStackView.transform = CGAffineTransform(translationX: entryOffset, y: 0)
        containerStackView.alpha = 1.0

        // Animate transition
        UIView.animate(
            withDuration: UX.transitionAnimationDuration,
            delay: 0,
            options: [.curveEaseInOut],
            animations: {
                snapshot.transform = CGAffineTransform(translationX: exitOffset, y: 0)
                self.containerStackView.transform = .identity
            },
            completion: { _ in
                snapshot.removeFromSuperview()
                completion?()
            }
        )
    }

    override func dismiss(_ buttonPressed: Bool) {
        guard !dismissed else { return }

        dismissed = true
        superview?.removeGestureRecognizer(gestureRecognizer)

        UIView.animate(
            withDuration: Toast.UX.toastAnimationDuration,
            animations: {
                self.containerStackView.transform = CGAffineTransform(translationX: 0, y: UX.verticalAnimationOffset)
                self.containerStackView.alpha = 0
                self.gradientOverlay?.alpha = 0
            },
            completion: { _ in
                self.gradientOverlay?.removeFromSuperview()
                self.gradientOverlay = nil
                self.removeFromSuperview()
                if !buttonPressed {
                    self.completionHandler?(false)
                }
            }
        )
    }

    // MARK: - Gesture Handling

    /// Override tap handling to dismiss on taps outside the toast
    /// Note: shouldReceive touch already filters out touches on the toast itself,
    /// so this will only be called for touches outside the toast
    override func handleTap(_ gestureRecognizer: UIGestureRecognizer) {
        dismiss(false)
        completionHandler?(false)
    }

    /// Allow simultaneous recognition with other gestures, except for web view gestures
    /// This ensures URL bar gestures still work while blocking web view interaction
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        // Allow simultaneous recognition with other gestures (like URL text field)
        return true
    }

    /// Decide whether to handle each touch based on location
    /// This filters out touches on the toast itself (so buttons work)
    /// and touches on the web view (so web content remains interactive)
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let touchLocation = touch.location(in: self)

        // If the touch is on the toast itself, don't handle it with our gesture
        // (let buttons handle their own touches)
        if toastView.frame.contains(touchLocation) {
            return false
        }

        // For other touches outside the toast (like URL bar), we want to handle them
        return true
    }
}

// MARK: - TransitionDirection

enum TransitionDirection {
    case forward
    case backward
}
