// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import UIKit
import WebKit

// MARK: - View Model

struct SpotlightToastViewModel {
    let image: UIImage?
    let titleText: String
    let descriptionText: String
    let currentStep: Int
    let totalSteps: Int
    let primaryButtonText: String
    let secondaryButtonText: String?
}

// MARK: - SpotlightToast

class SpotlightToast: Toast, UIGestureRecognizerDelegate {
    struct UX {
        static let containerHeight: CGFloat = 368
        static let cornerRadius: CGFloat = 10
        static let contentPadding: CGFloat = 16
        static let verticalSpacing: CGFloat = 16
        static let buttonSpacing: CGFloat = 8
        static let imageHeight: CGFloat = 164
        static let imageCornerRadius: CGFloat = 8

        static let titleFontSize: CGFloat = 17
        static let descriptionFontSize: CGFloat = 15
        static let stepCounterFontSize: CGFloat = 13

        static let buttonHeight: CGFloat = 40
        static let buttonCornerRadius: CGFloat = 20
        static let buttonHorizontalPadding: CGFloat = 15
        static let buttonInternalSpacing: CGFloat = 16

        static let transitionAnimationDuration: CGFloat = 0.5
    }

    // MARK: - Properties

    private var viewModel: SpotlightToastViewModel
    private var primaryButtonAction: (() -> Void)?
    private var secondaryButtonAction: (() -> Void)?

    // MARK: - UI Components

    private lazy var containerStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.verticalSpacing
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.layoutMargins = UIEdgeInsets(
            top: UX.contentPadding,
            left: UX.contentPadding,
            bottom: UX.contentPadding,
            right: UX.contentPadding
        )
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layer.cornerRadius = UX.cornerRadius
        stackView.clipsToBounds = true
    }

    private lazy var spotlightImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = UX.imageCornerRadius
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.font = DefaultDynamicFontHelper.preferredBoldFont(
            withTextStyle: .body,
            size: UX.titleFontSize
        )
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
    }

    private lazy var descriptionLabel: UILabel = .build { label in
        label.font = DefaultDynamicFontHelper.preferredFont(
            withTextStyle: .body,
            size: UX.descriptionFontSize
        )
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
    }

    private lazy var bottomRowStackView: UIStackView = .build { stackView in
        stackView.axis = .horizontal
        stackView.spacing = UX.buttonSpacing
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
    }

    private lazy var stepCounterLabel: UILabel = .build { label in
        label.font = DefaultDynamicFontHelper.preferredFont(
            withTextStyle: .footnote,
            size: UX.stepCounterFontSize
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
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = DefaultDynamicFontHelper.preferredFont(
                withTextStyle: .body,
                size: UX.titleFontSize
            )
            return outgoing
        }
        button.configuration = config
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
                withTextStyle: .body,
                size: UX.titleFontSize
            )
            return outgoing
        }
        button.configuration = config
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
        if viewModel.image != nil {
            containerStackView.addArrangedSubview(spotlightImageView)
            NSLayoutConstraint.activate([
                spotlightImageView.heightAnchor.constraint(equalToConstant: UX.imageHeight)
            ])
        }
        containerStackView.addArrangedSubview(titleLabel)
        containerStackView.addArrangedSubview(descriptionLabel)
        containerStackView.addArrangedSubview(bottomRowStackView)
        bottomRowStackView.addArrangedSubview(stepCounterLabel)
        bottomRowStackView.addArrangedSubview(buttonStackView)

        // Add buttons to button stack view
        if viewModel.secondaryButtonText != nil {
            secondaryButton.addTarget(self, action: #selector(secondaryButtonTapped), for: .touchUpInside)
            buttonStackView.addArrangedSubview(secondaryButton)
            NSLayoutConstraint.activate([
                secondaryButton.heightAnchor.constraint(equalToConstant: UX.buttonHeight)
            ])
        }
        primaryButton.addTarget(self, action: #selector(primaryButtonTapped), for: .touchUpInside)
        buttonStackView.addArrangedSubview(primaryButton)

        NSLayoutConstraint.activate([
            containerStackView.leadingAnchor.constraint(equalTo: toastView.leadingAnchor, constant: Toast.UX.toastOffset),
            containerStackView.trailingAnchor.constraint(equalTo: toastView.trailingAnchor, constant: -Toast.UX.toastOffset),
            containerStackView.topAnchor.constraint(equalTo: toastView.topAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: toastView.bottomAnchor, constant: -Toast.UX.toastOffset),

            toastView.leadingAnchor.constraint(equalTo: leadingAnchor),
            toastView.trailingAnchor.constraint(equalTo: trailingAnchor),
            toastView.heightAnchor.constraint(equalTo: heightAnchor),

            heightAnchor.constraint(equalToConstant: UX.containerHeight + Toast.UX.toastOffset),

            primaryButton.heightAnchor.constraint(equalToConstant: UX.buttonHeight)
        ])

        // Animation constraint
        animationConstraint = toastView.topAnchor.constraint(
            equalTo: topAnchor,
            constant: UX.containerHeight + Toast.UX.toastOffset
        )
        animationConstraint?.isActive = true
    }

    private func configureContent() {
        spotlightImageView.image = viewModel.image
        titleLabel.text = viewModel.titleText
        descriptionLabel.text = viewModel.descriptionText
        stepCounterLabel.text = "\(viewModel.currentStep) / \(viewModel.totalSteps)"

        // Update button text
        primaryButton.setTitle(viewModel.primaryButtonText, for: .normal)
        if let secondaryButtonText = viewModel.secondaryButtonText {
            secondaryButton.setTitle(secondaryButtonText, for: .normal)
        }
    }

    // MARK: - Theme

    override func applyTheme(theme: Theme) {
        super.applyTheme(theme: theme)
        containerStackView.backgroundColor = theme.colors.ecosia.backgroundFeatured
        titleLabel.textColor = theme.colors.ecosia.textPrimary
        descriptionLabel.textColor = theme.colors.ecosia.textPrimary
        stepCounterLabel.textColor = theme.colors.ecosia.textPrimary
        var secondaryConfig = secondaryButton.configuration
        secondaryConfig?.baseForegroundColor = theme.colors.ecosia.textPrimary
        secondaryConfig?.baseBackgroundColor = .clear
        secondaryButton.configuration = secondaryConfig
        var primaryConfig = primaryButton.configuration
        primaryConfig?.baseForegroundColor = theme.colors.ecosia.textPrimary
        primaryConfig?.baseBackgroundColor = .clear
        primaryConfig?.background.strokeColor = theme.colors.ecosia.textPrimary
        primaryButton.configuration = primaryConfig
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

    /// Show the spotlight toast with custom animation duration
    func show(
        in viewController: UIViewController,
        bottomAnchorView: UIView,
        delay: DispatchTimeInterval = .milliseconds(500)
    ) {
        self.viewController = viewController

        showToast(
            viewController: viewController,
            delay: delay,
            duration: nil,  // Don't auto-dismiss
            updateConstraintsOn: { toast in
                guard let superview = toast.superview else { return [] }
                return [
                    toast.leadingAnchor.constraint(equalTo: superview.leadingAnchor),
                    toast.trailingAnchor.constraint(equalTo: superview.trailingAnchor),
                    toast.bottomAnchor.constraint(equalTo: bottomAnchorView.topAnchor)
                ]
            }
        )
    }

    /// Transition to a new view model with directional animation
    /// - Parameters:
    ///   - newViewModel: The new spotlight step to display
    ///   - direction: The direction of transition (.forward or .backward)
    ///   - completion: Called when transition is complete
    func transition(to newViewModel: SpotlightToastViewModel, direction: TransitionDirection, completion: (() -> Void)? = nil) {
        // Create a snapshot of the current content
        guard let snapshot = containerStackView.snapshotView(afterScreenUpdates: false) else {
            // Just update content if snapshot fails
            self.viewModel = newViewModel
            configureContent()
            completion?()
            return
        }

        // Forward: new content comes from right, old goes left
        // Backward: new content comes from left, old goes right
        let containerWidth = containerStackView.bounds.width
        let spacing = Toast.UX.toastOffset * 2  // Space between the views
        let animationOffset = containerWidth + spacing
        let exitOffset: CGFloat = direction == .forward ? -animationOffset : animationOffset
        let entryOffset: CGFloat = direction == .forward ? animationOffset : -animationOffset

        // Position the snapshot exactly where the current content is
        snapshot.frame = containerStackView.frame
        snapshot.alpha = containerStackView.alpha
        snapshot.transform = containerStackView.transform
        toastView.addSubview(snapshot)

        // Update the view model and reconfigure content
        self.viewModel = newViewModel
        configureContent()

        // Position the new content off-screen horizontally
        containerStackView.transform = CGAffineTransform(translationX: entryOffset, y: 0)
        containerStackView.alpha = 1.0  // Keep visible during horizontal slide

        UIView.animate(
            withDuration: UX.transitionAnimationDuration,
            delay: 0,
            options: [.curveEaseInOut],
            animations: {
                // Exit animation: slide horizontally off-screen
                snapshot.transform = CGAffineTransform(translationX: exitOffset, y: 0)

                // Enter animation: slide to center position
                self.containerStackView.transform = .identity
            }
        ) { _ in
            snapshot.removeFromSuperview()
            completion?()
        }
    }

    override func dismiss(_ buttonPressed: Bool) {
        guard !dismissed else { return }

        dismissed = true
        superview?.removeGestureRecognizer(gestureRecognizer)

        UIView.animate(
            withDuration: Toast.UX.toastAnimationDuration,
            animations: {
                self.animationConstraint?.constant = UX.containerHeight + Toast.UX.toastOffset
                self.layoutIfNeeded()
            }
        ) { finished in
            self.removeFromSuperview()
            if !buttonPressed {
                self.completionHandler?(false)
            }
        }
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
