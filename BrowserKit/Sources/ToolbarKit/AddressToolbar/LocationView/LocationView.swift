// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

final class LocationView: UIView,
                          LocationTextFieldDelegate,
                          ThemeApplicable,
                          AccessibilityActionsSource,
                          MenuHelperURLBarInterface {
    // MARK: - Properties
    private enum UX {
        static let horizontalSpace: CGFloat = 8
        static let gradientViewWidth: CGFloat = 40
        static let safeOffset: CGFloat = 40
        static let lockIconImageViewSize = CGSize(width: 40, height: 24)
        static let shieldImageViewSize = CGSize(width: 24, height: 24)
        static let iconContainerNoLockLeadingSpace: CGFloat = 16
        static let iconAnimationTime: CGFloat = 0.1
        static let iconAnimationDelay: CGFloat = 0.03
        static let bottomAddressBarYoffset: CGFloat = -16
        static let bottomAddressBarYoffsetForHomeButton: CGFloat = -28
        static let topAddressBarYoffset: CGFloat = 26
        static let smallScale: CGFloat = 0.7
        static let identityResetAnimationDuration: TimeInterval = 0.2
        static let effectViewCornerRadius: CGFloat = 24
        static let effectViewLeadingPadding: CGFloat = -12
        static let effectViewTrailingPadding: CGFloat = 18
    }

    private var urlAbsolutePath: String?
    private var searchTerm: String?
    private var onTapLockIcon: (@MainActor (UIButton) -> Void)?
    private var onLongPress: (@MainActor () -> Void)?
    private weak var delegate: LocationViewDelegate?
    private var theme: any Theme = LightTheme()
    private var isUnifiedSearchEnabled = false
    private var lockIconImageName: String?
    private var lockIconNeedsTheming = false
    private var safeListedURLImageName: String?
    private var hasAlternativeLocationColor = false
    private var config: LocationViewConfiguration?
    private(set) var isAddressBarMinimized = false

    private var isEditing = false
    private var isURLTextFieldEmpty: Bool {
        urlTextField.text?.isEmpty == true
    }

    // Ecosia: Passthrough for live overlay text decisions in BVC.
    var plainUserText: String {
        urlTextField.plainUserText
    }

    private var hasHomeIndicator: Bool {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return false }
        return window.safeAreaInsets.bottom > 0
    }

    private var tapGestureRecognizer: UITapGestureRecognizer?
    private var longPressGestureRecognizer: UILongPressGestureRecognizer?

    /// Determines if the URL text field's content is wider than the visible area, accounting for a safe offset.
    /// An additional offset (default is 0) used when reader mode is available,
    /// to ensure the text does not overlap the icon when the view is constrained to its superview.
    private func isNormalizedHostWiderThanVisibleArea(safeOffset offset: CGFloat = 0) -> Bool {
        guard let text = urlTextField.text, let font = urlTextField.font, !isAddressBarMinimized else {
            return false
        }
        let (_, normalizedHost) = URL.getSubdomainAndHost(from: text)
        let locationViewVisibleWidth = frame.width - iconContainerStackView.frame.width - UX.horizontalSpace - offset
        let urlTextFieldWidth = normalizedHost.size(withAttributes: [.font: font]).width

        return urlTextFieldWidth >= locationViewVisibleWidth
    }

    private var dotWidth: CGFloat {
        guard let font = urlTextField.font else { return 0 }
        let fontAttributes = [NSAttributedString.Key.font: font]
        let width = "...".size(withAttributes: fontAttributes).width
        return CGFloat(width)
    }

    private lazy var gradientLayer = CAGradientLayer()
    private lazy var gradientView: UIView = .build()
    private lazy var containerView: UIView = .build()

    private var containerViewConstraints: [NSLayoutConstraint] = []
    private var urlTextFieldLeadingConstraint: NSLayoutConstraint?
    private var urlTextFieldTrailingConstraint: NSLayoutConstraint?
    private var iconContainerStackViewLeadingConstraint: NSLayoutConstraint?
    private var lockIconWidthAnchor: NSLayoutConstraint?
    /* Ecosia: Pins the empty icon stack to zero width during editing so auto layout doesn't
       resolve the ambiguous (no-content, no explicit width) stack to an arbitrary large value. */
    private var iconContainerStackViewWidthConstraint: NSLayoutConstraint?

    // MARK: - Search Engine / Lock Image
    private(set) lazy var iconContainerStackView: UIStackView = .build { view in
        view.alignment = .center
    }

    // TODO FXIOS-10210 Once the Unified Search experiment is complete, we will only need to use `DropDownSearchEngineView`
    // and we can remove `PlainSearchEngineView` from the project.
    private lazy var plainSearchEngineView: PlainSearchEngineView = .build()
    private lazy var dropDownSearchEngineView: DropDownSearchEngineView = .build()
    private(set) lazy var searchEngineContentView: SearchEngineView = plainSearchEngineView
    private(set) lazy var lockIconButton: UIButton = .build { button in
        button.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(self.didTapLockIcon), for: .touchUpInside)
    }

    private lazy var glassEffect: UIVisualEffect? = if #available(iOS 26.0, *) { UIGlassEffect() } else { nil }
    private lazy var effectView: UIVisualEffectView = .build {
        $0.layer.cornerRadius = UX.effectViewCornerRadius
    }

    // MARK: - URL Text Field
    private lazy var urlTextField: LocationTextField = .build { [self] urlTextField in
        urlTextField.backgroundColor = .clear
        urlTextField.font = FXFontStyles.Regular.body.scaledFont()
        urlTextField.adjustsFontForContentSizeCategory = true
        urlTextField.autocompleteDelegate = self
        urlTextField.accessibilityActionsSource = self
        // Update the `textAlignment` property only when the entire layout direction is RTL or LTR,
        // similar to Apple's handling in Safari, ensuring that `textAlignment` remains in sync with the layout constraints.
        let layoutDirection = UIView.userInterfaceLayoutDirection(for: semanticContentAttribute)
        urlTextField.textAlignment = layoutDirection == .rightToLeft ? .right : .left
    }

    private var isURLTextFieldCentered = false {
        didSet {
            // We need to call applyTheme to ensure the colors are updated in sync whenever the layout changes.
            guard isURLTextFieldCentered != oldValue else { return }
            applyTheme(theme: theme)
        }
    }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupLayout()
        setupGradientLayer()
        addLongPressGestureRecognizer()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        // Skip if urlTextField is already first responder to avoid triggering duplicate delegate callbacks
        guard !urlTextField.isFirstResponder else { return true }
        return urlTextField.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
        // Skip if urlTextField has already resigned to avoid redundant state changes
        guard urlTextField.isFirstResponder else { return true }
        return urlTextField.resignFirstResponder()
    }

    func configureNonInteractive(_ config: LocationViewConfiguration, uxConfig: AddressToolbarUXConfiguration) {
        isURLTextFieldCentered = uxConfig.isLocationTextCentered
        hasAlternativeLocationColor = uxConfig.hasAlternativeLocationColor
        configureLockIconButton(config)
        configureURLPlaceholder(basedOn: config)
        setTextFieldPlaceholder(color: theme.colors.textPrimary)
        urlTextField.text = config.url?.absoluteString
        updateIconContainer(isURLTextFieldCentered: isURLTextFieldCentered,
                            locationTextFieldTrailingPadding: uxConfig.locationTextFieldTrailingPadding)
        layoutContainerView(isEditing: config.isEditing, isURLTextFieldCentered: isURLTextFieldCentered)
        /* Ecosia: Pass whether a search query is displayed so URL truncation is skipped on SERPs.
           New call site in 155.1 — `configureNonInteractive` did not exist at the fork point, so it
           auto-merged in without Ecosia's argument.
        formatAndTruncateURLTextField()
        */
        formatAndTruncateURLTextField(hasSearchTerm: config.searchTerm != nil)
    }

    func configure(_ config: LocationViewConfiguration,
                   delegate: LocationViewDelegate,
                   isUnifiedSearchEnabled: Bool,
                   uxConfig: AddressToolbarUXConfiguration,
                   addressBarPosition: AddressToolbarPosition) {
        self.config = config
        isURLTextFieldCentered = uxConfig.isLocationTextCentered
        hasAlternativeLocationColor = uxConfig.hasAlternativeLocationColor

        // TODO FXIOS-10210 Once the Unified Search experiment is complete, we won't need this extra layout logic and can
        // simply use the `.build` method on `DropDownSearchEngineView` on `LocationView`'s init.
        searchEngineContentView = isUnifiedSearchEnabled
                                  ? dropDownSearchEngineView
                                  : plainSearchEngineView

        searchEngineContentView.configure(
            config,
            isLocationTextCentered: uxConfig.isLocationTextCentered,
            delegate: delegate
        )

        applyToolbarAlphaIfNeeded(
            isAddressBarMinimized: uxConfig.isAddressBarMinimized,
            barPosition: addressBarPosition
        )
        configureLockIconButton(config)
        configureURLTextField(config)
        configureA11y(config)

        // Must be called before updateIconContainer. The overflow check inside updateIconContainer measures
        // urlTextField.text to determine layout; without this call the text still holds the raw URL instead
        // of the normalized host, causing overflow to trigger incorrectly in reader mode
        // and producing a visible shift when the lock icon is hidden.

        /* Ecosia: Pass whether a search query is displayed so URL truncation is skipped on SERPs.
        formatAndTruncateURLTextField()
        */
        formatAndTruncateURLTextField(hasSearchTerm: config.searchTerm != nil)
        updateIconContainer(isURLTextFieldCentered: isURLTextFieldCentered,
                            locationTextFieldTrailingPadding: uxConfig.locationTextFieldTrailingPadding)
        handleGesture(&tapGestureRecognizer, type: UITapGestureRecognizer.self, action: #selector(becomeFirstResponder))
        handleGesture(
            &longPressGestureRecognizer,
            type: UILongPressGestureRecognizer.self,
            action: #selector(handleLongPress)
        )
        self.delegate = delegate
        self.isUnifiedSearchEnabled = isUnifiedSearchEnabled
        searchTerm = config.searchTerm
        onLongPress = config.onLongPress

        layoutContainerView(isEditing: config.isEditing, isURLTextFieldCentered: isURLTextFieldCentered)
        applyTheme(theme: theme)
    }

    // Ecosia: Replace the field's contents from code (suggestion "append" arrow).
    //
    // This deliberately bypasses Redux. `configureURLTextField` refuses to write the text
    // field while `didStartTyping` is set — which it always is once the user has typed
    // enough to surface suggestions — so a state round-trip cannot deliver the appended
    // query. That same guard is what makes writing directly safe: a later reconfigure
    // won't clobber what we set here.
    func setPlainUserText(_ text: String) {
        urlTextField.setPlainUserText(text)
        // Keep the cached term in step so a subsequent re-focus reports the appended query
        // to `locationViewDidBeginEditing` rather than the pre-append one.
        searchTerm = text
    }

    private func layoutContainerView(isEditing: Bool, isURLTextFieldCentered: Bool) {
        var newConstraints: [NSLayoutConstraint] = []
        if isEditing || !isURLTextFieldCentered || isNormalizedHostWiderThanVisibleArea() {
            // leading alignment configuration
            newConstraints = [
                /* Ecosia: Update leading anchor spacing for URL bar
                containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
                 */
                containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
                containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            ]
        } else if isNormalizedHostWiderThanVisibleArea(safeOffset: UX.safeOffset) {
            newConstraints = [
                containerView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
                containerView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
                containerView.centerXAnchor.constraint(equalTo: centerXAnchor)
            ]
        } else if let superview, !isNormalizedHostWiderThanVisibleArea(safeOffset: UX.safeOffset) {
            newConstraints = [
                containerView.leadingAnchor.constraint(greaterThanOrEqualTo: superview.leadingAnchor),
                containerView.trailingAnchor.constraint(lessThanOrEqualTo: superview.trailingAnchor),
                containerView.centerXAnchor.constraint(equalTo: superview.centerXAnchor)
            ]
        }

        // Only update the constraints if necessary
        guard !newConstraints.isEmpty else { return }

        NSLayoutConstraint.deactivate(containerViewConstraints)
        containerViewConstraints = newConstraints
        NSLayoutConstraint.activate(containerViewConstraints)
    }

    func setAutocompleteSuggestion(_ suggestion: String?) {
        urlTextField.setAutocompleteSuggestion(suggestion)
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()

        layoutContainerView(isEditing: isEditing, isURLTextFieldCentered: isURLTextFieldCentered)
        updateGradient()
        // Updates the URL text field's leading constraint to ensure it reflects the current layout state
        // during layout passes, such as on screen size or orientation changes.
        updateURLTextFieldLeadingConstraintBasedOnState()
    }

    private func setupLayout() {
        if #available(iOS 26.0, *) {
            addSubview(effectView)
            effectView.contentView.addSubview(containerView)
        } else {
            addSubview(containerView)
        }
        containerView.addSubviews(urlTextField, iconContainerStackView, gradientView)
        if #available(iOS 26.0, *) {
            NSLayoutConstraint.activate([
                effectView.topAnchor.constraint(equalTo: urlTextField.topAnchor),
                effectView.leadingAnchor.constraint(equalTo: iconContainerStackView.leadingAnchor,
                                                    constant: UX.effectViewLeadingPadding),
                effectView.trailingAnchor.constraint(equalTo: urlTextField.trailingAnchor,
                                                     constant: UX.effectViewTrailingPadding),
                effectView.bottomAnchor.constraint(equalTo: urlTextField.bottomAnchor)
            ])
        }
        iconContainerStackView.addArrangedSubview(searchEngineContentView)

        urlTextFieldLeadingConstraint = urlTextField.leadingAnchor.constraint(equalTo: iconContainerStackView.trailingAnchor)
        urlTextFieldLeadingConstraint?.isActive = true

        urlTextFieldTrailingConstraint = urlTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        urlTextFieldTrailingConstraint?.isActive = true

        iconContainerStackViewLeadingConstraint = iconContainerStackView.leadingAnchor.constraint(
            equalTo: containerView.leadingAnchor
        )
        iconContainerStackViewLeadingConstraint?.isActive = true

        containerViewConstraints = [
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ]

        NSLayoutConstraint.activate(containerViewConstraints)
        NSLayoutConstraint.activate([
            gradientView.topAnchor.constraint(equalTo: urlTextField.topAnchor),
            gradientView.bottomAnchor.constraint(equalTo: urlTextField.bottomAnchor),
            gradientView.leadingAnchor.constraint(equalTo: iconContainerStackView.trailingAnchor),
            gradientView.widthAnchor.constraint(equalToConstant: UX.gradientViewWidth),

            urlTextField.topAnchor.constraint(equalTo: containerView.topAnchor),
            urlTextField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            iconContainerStackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            iconContainerStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func setupGradientLayer() {
        gradientLayer.locations = [0, 1]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradientView.layer.addSublayer(gradientLayer)
    }

    private func updateGradient() {
        let showGradientForLongURL = isNormalizedHostWiderThanVisibleArea() && !isEditing
        gradientView.isHidden = !showGradientForLongURL
        // Use the containerView height since gradient's view height could be still not updated here
        // This can avoid to call containerView.layoutIfNeeded() which is an expensive call.
        let gradientLayerSize = CGSize(width: gradientView.bounds.width, height: containerView.frame.height)
        gradientLayer.frame = CGRect(origin: gradientView.bounds.origin, size: gradientLayerSize)
    }

    private func updateURLTextFieldLeadingConstraintBasedOnState() {
        let shouldAdjustForOverflow = isNormalizedHostWiderThanVisibleArea() && !isEditing
        let shouldAdjustForNonEmpty = !isURLTextFieldEmpty && !isEditing

        func handleOverflowAdjustment() {
            // Hide the leading "..." by moving them behind the lock icon.
            updateURLTextFieldLeadingConstraint(constant: -dotWidth)
            if lockIconImageName == nil {
                // This is the case when we are in reader mode and the lock icon is not visible.
                updateWidthForLockIcon(UX.lockIconImageViewSize.width)
                iconContainerStackViewLeadingConstraint?.constant = 0
            }
        }

        if shouldAdjustForOverflow {
            handleOverflowAdjustment()
        } else if shouldAdjustForNonEmpty {
            /* Ecosia: Original 0pt gap was designed for the 40pt lock icon, which provided its own
               visual separation. The 16pt favicon needs explicit spacing so the URL text doesn't
               crowd it — use horizontalSpace to match the same gap applied by updateUIForSearchEngineDisplay.
            updateURLTextFieldLeadingConstraint()
            */
            updateURLTextFieldLeadingConstraint(constant: UX.horizontalSpace)
        } else {
            updateURLTextFieldLeadingConstraint(constant: UX.horizontalSpace)
        }
    }

    private func updateURLTextFieldLeadingConstraint(constant: CGFloat = 0) {
        urlTextFieldLeadingConstraint?.constant = constant
    }

    /// Rebuilds the icon container only when its arrangement actually changes. `configure` runs on every
    /// toolbar state update, and tearing the stack down to re-add the same icon just invalidates layout.
    private func setContainerIcons(_ icons: [UIView]) {
        guard !iconContainerStackView.arrangedSubviews.elementsEqual(icons, by: { $0 === $1 }) else { return }
        iconContainerStackView.removeAllArrangedViews()
        icons.forEach { iconContainerStackView.addArrangedSubview($0) }
    }

    private func updateIconContainer(isURLTextFieldCentered: Bool,
                                     locationTextFieldTrailingPadding: CGFloat) {
        guard !isEditing else {
            /* Ecosia: Use dedicated editing-display helper (hides search engine icon) and skip icon animation.
            updateUIForSearchEngineDisplay(isURLTextFieldCentered: isURLTextFieldCentered)
            urlTextFieldTrailingConstraint?.constant = 0
            animateIconAppearance()
             */
            updateUIForEditingDisplay()
            urlTextFieldTrailingConstraint?.constant = 0
            return
        }

        /* Ecosia: Always show search engine view (favicon when browsing, logo when home);
           lock icon replaced by site favicon for a cleaner Ecosia address bar experience
        if isURLTextFieldEmpty {
            updateUIForSearchEngineDisplay(isURLTextFieldCentered: isURLTextFieldCentered)
        } else {
            updateUIForLockIconDisplay()
        }
        */
        /* Ecosia: When browsing (non-empty URL), pass isURLTextFieldCentered=false so the icon is always
           added to the stack. The .experiment config hard-codes isLocationTextCentered=true, which would
           otherwise skip adding the icon via the `!isURLTextFieldCentered || isEditing` guard. */
        let effectiveCentered = isURLTextFieldCentered && isURLTextFieldEmpty
        updateUIForSearchEngineDisplay(isURLTextFieldCentered: effectiveCentered)
        animateIconAppearance()
        urlTextFieldTrailingConstraint?.constant = -locationTextFieldTrailingPadding
    }

    private func animateIconAppearance() {
        /* Ecosia: Always show the search engine view (favicon when browsing, logo when home/editing);
           the lock icon button is not used — site identity is conveyed via the favicon instead
        let shouldShowLockIcon: Bool
        if isEditing {
            lockIconButton.alpha = 0
            shouldShowLockIcon = false
        } else if isURLTextFieldEmpty {
            shouldShowLockIcon = false
        } else if lockIconImageName == nil {
            shouldShowLockIcon = false
        } else {
            shouldShowLockIcon = true
        }

        let searchEngineAlpha: CGFloat = shouldShowLockIcon ? 0 : 1
        let lockIconAlpha: CGFloat = shouldShowLockIcon ? 1 : 0

        // Skip the animation when both icons already sit at their target alpha, otherwise every toolbar
        // state update kicks off an animation block that has nothing to animate.
        guard searchEngineContentView.alpha != searchEngineAlpha || lockIconButton.alpha != lockIconAlpha
        else { return }

        let isAnimationEnabled = !UIAccessibility.isReduceMotionEnabled
        if isAnimationEnabled {
            UIView.animate(withDuration: UX.iconAnimationTime, delay: UX.iconAnimationDelay) {
                self.searchEngineContentView.alpha = searchEngineAlpha
                self.lockIconButton.alpha = lockIconAlpha
            }
        } else {
            searchEngineContentView.alpha = searchEngineAlpha
            lockIconButton.alpha = lockIconAlpha
        }
        */
        let isAnimationEnabled = !UIAccessibility.isReduceMotionEnabled
        if isAnimationEnabled {
            UIView.animate(withDuration: UX.iconAnimationTime, delay: UX.iconAnimationDelay) {
                self.searchEngineContentView.alpha = 1
                self.lockIconButton.alpha = 0
            }
        } else {
            searchEngineContentView.alpha = 1
            lockIconButton.alpha = 0
        }
    }

    private func updateUIForSearchEngineDisplay(isURLTextFieldCentered: Bool) {
        let shouldShowSearchEngine = !isURLTextFieldCentered || isEditing
        setContainerIcons(shouldShowSearchEngine ? [searchEngineContentView] : [])
        if shouldShowSearchEngine {
            // Ecosia: Icon is present — let its content determine the stack width.
            iconContainerStackViewWidthConstraint?.isActive = false
            iconContainerStackViewWidthConstraint = nil
        } else {
            /* Ecosia: No icon added (NTP centered mode). An empty UIStackView has no intrinsic
               width so auto layout would resolve the ambiguity to an arbitrary large value and
               push urlTextField to the right — pin it explicitly to zero to prevent that.
               `setContainerIcons([])` does not do this for us. */
            iconContainerStackViewWidthConstraint?.isActive = false
            iconContainerStackViewWidthConstraint = iconContainerStackView.widthAnchor.constraint(equalToConstant: 0)
            iconContainerStackViewWidthConstraint?.isActive = true
        }
        updateURLTextFieldLeadingConstraint(constant: UX.horizontalSpace)
        iconContainerStackViewLeadingConstraint?.constant = UX.horizontalSpace
        updateGradient()
    }

    // Ecosia: Remove the search engine icon when editing so the text field has full width.
    private func updateUIForEditingDisplay() {
        setContainerIcons([])
        // Pin the empty stack to zero-width explicitly — an empty UIStackView has no intrinsic
        // width so auto layout would resolve the ambiguity to a large value and push the text
        // field to the right. With width=0 and leading=0, urlTextField.leading resolves to
        // iconContainerStackView.trailing(0) + UX.horizontalSpace(8) = 8 pt ≡ Ecosia _1s.
        iconContainerStackViewWidthConstraint?.isActive = false
        iconContainerStackViewWidthConstraint = iconContainerStackView.widthAnchor.constraint(equalToConstant: 0)
        iconContainerStackViewWidthConstraint?.isActive = true
        iconContainerStackViewLeadingConstraint?.constant = 0
        updateURLTextFieldLeadingConstraint(constant: UX.horizontalSpace)
        updateGradient()
    }

    private func updateUIForLockIconDisplay() {
        guard !isEditing else { return }
        setContainerIcons([lockIconButton])
        // Ecosia: Release the zero-width editing constraint so the lock icon can size the stack.
        iconContainerStackViewWidthConstraint?.isActive = false
        iconContainerStackViewWidthConstraint = nil

        updateURLTextFieldLeadingConstraintBasedOnState()

        let leadingConstraint = lockIconImageName == nil ? UX.iconContainerNoLockLeadingSpace : 0.0
        iconContainerStackViewLeadingConstraint?.constant = leadingConstraint
        updateGradient()
    }

    private func updateWidthForLockIcon(_ width: CGFloat) {
        lockIconWidthAnchor?.isActive = false
        lockIconWidthAnchor = lockIconButton.widthAnchor.constraint(equalToConstant: width)
        lockIconWidthAnchor?.isActive = true
    }

    // MARK: - LocationView Scaling
    private func shrinkLocationView(barPosition: AddressToolbarPosition) {
        /* Ecosia: Keep the location view and `urlTextField` interactive even while shrunk into the
           compact pill. With interaction disabled the tap that visually hits the pill is dropped on
           the floor — no gesture in the toolbar fires, so the toolbar never re-expands (and the
           container-level tap can't compensate when the pill is the only thing covering the tap
           point). Letting the text field receive the tap routes it through the normal
           `textFieldDidBeginEditing` → `addressToolbarDidBeginEditing` pipeline, which both expands
           the bar and enters overlay mode. Upstream disabled only `urlTextField` inside the
           animation block at 147.2; 155.1 moved it here and added the view-level flag, which would
           block the text field's touches too.
        urlTextField.isUserInteractionEnabled = false
        isUserInteractionEnabled = false
         */

        let isiPad = UIDevice.current.userInterfaceIdiom == .pad
        let bottomAddressBarYoffset = if #available(iOS 26.0, *) {
            UX.bottomAddressBarYoffset
        } else {
            hasHomeIndicator ? UX.bottomAddressBarYoffset : UX.bottomAddressBarYoffsetForHomeButton
        }
        let yOffset: CGFloat = (barPosition == .bottom && !isiPad) ? bottomAddressBarYoffset : UX.topAddressBarYoffset
        UIView.animate(
            withDuration: UX.identityResetAnimationDuration,
            delay: 0,
            options: [.curveEaseInOut],
            animations: {
                let scaledTransformation = CGAffineTransform(scaleX: UX.smallScale, y: UX.smallScale)
                    .translatedBy(x: 0, y: yOffset)
                self.transform = scaledTransformation
            })
    }

    private func restoreLocationViewSize() {
        urlTextField.isUserInteractionEnabled = true
        isUserInteractionEnabled = true
        UIView.animate(
            withDuration: UX.identityResetAnimationDuration,
            delay: 0,
            options: [.curveEaseInOut],
            animations: { [unowned self] in
                transform = .identity
            })
    }

    private func removeGlassEffectImmediately() {
        guard #available(iOS 26.0, *) else { return }
        /// Workaround for iOS 26.0 bug: Setting `effectView.effect` to `nil` doesn't remove the glass effect.
        /// We work around this by first setting it to `UIBlurEffect()` and then to `nil`, which forces an immediate removal.
        effectView.effect = UIBlurEffect()
        effectView.effect = nil
    }

    private func applyToolbarAlphaIfNeeded(isAddressBarMinimized: Bool, barPosition: AddressToolbarPosition) {
        self.isAddressBarMinimized = isAddressBarMinimized
        if isAddressBarMinimized {
            shrinkLocationView(barPosition: barPosition)
            if #available(iOS 26.0, *), barPosition == .bottom {
                effectView.effect = glassEffect
            } else {
                removeGlassEffectImmediately()
            }
        } else {
            restoreLocationViewSize()
            removeGlassEffectImmediately()
        }
        applyTheme(theme: theme)
    }

    // MARK: - `urlTextField` Configuration
    private func configureURLTextField(_ config: LocationViewConfiguration) {
        let configurationIsEditing = config.isEditing
        configureURLPlaceholder(basedOn: config)
        // This code is fragile and needs to be called in this exact location or it will break.
        // This is because when we rotate the device, a `keyboardWillHide` notification is fired
        // even though we have set the text field to the first responder. When that notification fires
        // this notification is re-called for both skeleton toolbars where `shouldShowKeyboard` is false
        // causing the keyboard to hide.
        // TODO: FXIOS-14618 don't fire the `keyboardWillHide` notification on device rotation
        let shouldShowKeyboard = configurationIsEditing && config.shouldShowKeyboard
        urlTextField.editingAccessoryAction = configurationIsEditing ?
            config.editingAccessoryAction :
            nil
        // Ecosia: Keyboard hidden while overlay editing continues — do not commit inline
        // autocomplete on resign (avoids trailing spaces when scrolling suggestions).
        urlTextField.commitsAutocompleteOnEndEditing = shouldShowKeyboard
        /* Ecosia: Firefox toggles first responder unconditionally on shouldShowKeyboard.
        _ = shouldShowKeyboard ? becomeFirstResponder() : resignFirstResponder()
        */
        if shouldShowKeyboard {
            _ = becomeFirstResponder()
        } else if configurationIsEditing && !config.didStartTyping {
            // Do not resign while the user is typing — suggestion highlight updates
            // can clear shouldShowKeyboard after keyboard drag-dismiss.
            _ = resignFirstResponder()
        }

        // Remove the default drop interaction from the URL text field so that our
        // custom drop interaction on the BVC can accept dropped URLs.
        if let dropInteraction = urlTextField.textDropInteraction {
            urlTextField.removeInteraction(dropInteraction)
        }

        let targetAlpha: CGFloat = configurationIsEditing ? 1 : 0
        let isAnimationEnabled = !UIAccessibility.isReduceMotionEnabled
        if isAnimationEnabled {
            UIView.animate(withDuration: UX.iconAnimationTime, delay: UX.iconAnimationDelay) {
                self.urlTextField.clearButton?.alpha = targetAlpha
            }
        } else {
            urlTextField.clearButton?.alpha = targetAlpha
        }

        // Once the user started typing we should not update the text anymore as that interferes with
        // setting the autocomplete suggestions which is done using a delegate method.
        guard !config.didStartTyping else { return }
        /* Ecosia: Show the search query in the collapsed address bar when on a SERP.
           Firefox only showed the search term while editing; Ecosia shows it in both
           editing and collapsed states so users always see what they searched for.
        let shouldShowSearchTerm = (config.searchTerm != nil) && configurationIsEditing
        */
        let shouldShowSearchTerm = config.searchTerm != nil
        let text = shouldShowSearchTerm ? config.searchTerm : config.url?.absoluteString
        urlTextField.text = text

        DispatchQueue.main.async { [unowned self] in
            if shouldShowKeyboard && config.shouldSelectSearchTerm {
                let start = urlTextField.beginningOfDocument
                let end = urlTextField.endOfDocument
                urlTextField.selectedTextRange = urlTextField.textRange(from: start, to: end)
            }
        }
    }

    private func configureURLPlaceholder(basedOn config: LocationViewConfiguration) {
        isEditing = config.isEditing
        if !isEditing && config.url != nil {
            // allow proper centering of the urlTextField removing placeholder size.
            urlTextField.placeholder = nil
        } else {
            urlTextField.placeholder = config.urlTextFieldPlaceholder
        }
        urlAbsolutePath = config.url?.absoluteString
    }

    /* Ecosia: Accept whether a search query is displayed so URL truncation can be skipped on SERPs.
    private func formatAndTruncateURLTextField() {
    */
    /// Updates the URL text field (when not editing) by:
    /// - Extracting the subdomain and normalized host.
    /// - Applying primary color to the host and secondary color to the subdomain.
    /// - Truncating from the head if the text is too long.
    /// - Setting the styled result as the text field's attributed text.
    private func formatAndTruncateURLTextField(hasSearchTerm: Bool) {
        guard !isEditing else { return }
        // Ecosia: When a search query is available the text field already shows it as plain text;
        // applying URL-style host truncation here would overwrite the query with a hostname.
        guard !hasSearchTerm else { return }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingHead

        let urlString = urlAbsolutePath ?? ""
        let (subdomain, normalizedHost) = URL.getSubdomainAndHost(from: urlString)

        let (primaryColor, secondaryColor) = getPrimaryAndSecondaryColors()
        let attributedString = NSMutableAttributedString(
            string: normalizedHost,
            attributes: [.foregroundColor: primaryColor])

        if let subdomain {
            let range = NSRange(location: 0, length: subdomain.count)
            attributedString.addAttribute(.foregroundColor, value: secondaryColor, range: range)
        }
        attributedString.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: NSRange(
                location: 0,
                length: attributedString.length
            )
        )
        urlTextField.attributedText = attributedString
    }

    // MARK: - `lockIconButton` Configuration
    private func configureLockIconButton(_ config: LocationViewConfiguration) {
        lockIconButton.isUserInteractionEnabled = isURLTextFieldCentered ? false : true
        lockIconImageName = config.lockIconImageName
        lockIconNeedsTheming = config.lockIconNeedsTheming
        safeListedURLImageName = config.safeListedURLImageName
        guard lockIconImageName != nil else {
            updateWidthForLockIcon(0)
            return
        }
        if isURLTextFieldCentered {
            updateWidthForLockIcon(UX.shieldImageViewSize.width)
        } else {
            updateWidthForLockIcon(UX.lockIconImageViewSize.width)
        }
        onTapLockIcon = config.onTapLockIcon

        setLockIconImage()
    }

    private func setLockIconImage() {
        guard let lockIconImageName, !lockIconImageName.isEmpty else { return }
        var lockImage: UIImage?

        if let safeListedURLImageName {
            if theme.isNova {
                let shieldDotImageName = StandardImageIdentifiers.Medium.shieldCheckmarkDotFillMulticolor
                lockIconButton.setImage(UIImage(named: shieldDotImageName), for: .normal)
                return
            }

            lockImage = UIImage(named: lockIconImageName)

            if lockIconNeedsTheming {
                /* Ecosia: Use Ecosia's secondary text colour for the lock glyph.
                lockImage = lockImage?.withTintColor(theme.colors.textSecondary)
                */
                lockImage = lockImage?.withTintColor(theme.colors.ecosia.textSecondary)
            }
            /* Ecosia: Use Ecosia's decorative colour for the safe-listed URL dot.
            let safeListedURLImageColor = theme.colors.iconAccentBlue
            */
            let safeListedURLImageColor = theme.colors.ecosia.iconDecorative
            if let dotImage = UIImage(named: safeListedURLImageName)?.withTintColor(safeListedURLImageColor) {
                let origin = isURLTextFieldCentered ? CGPoint(x: 10, y: 10) : CGPoint(x: 13.5, y: 13)
                let image = lockImage?.overlayWith(image: dotImage, modifier: 0.4, origin: origin)
                lockIconButton.setImage(image, for: .normal)
            }
        } else {
            lockImage = UIImage(named: lockIconImageName)

            if lockIconNeedsTheming {
                lockImage = lockImage?.withRenderingMode(.alwaysTemplate)
            }

            lockIconButton.setImage(lockImage, for: .normal)
        }
    }

    // MARK: - Gesture Recognizers
    private func addLongPressGestureRecognizer() {
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(LocationView.handleLongPress))
        urlTextField.addGestureRecognizer(gestureRecognizer)
    }

    private func handleGesture<T: UIGestureRecognizer>(
        _ gesture: inout T?,
        type: T.Type,
        action: Selector
    ) {
        if isURLTextFieldCentered {
            if gesture == nil {
                let newGesture = type.init(target: self, action: action)
                addGestureRecognizer(newGesture)
                gesture = newGesture
            }
        } else if let existingGesture = gesture {
            removeGestureRecognizer(existingGesture)
            gesture = nil
        }
    }

    // MARK: - Selectors
    @objc
    private func didTapLockIcon() {
        onTapLockIcon?(lockIconButton)
    }

    @objc
    private func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            onLongPress?()
        }
    }

    // MARK: - MenuHelperURLBarInterface
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == MenuHelperURLBarModel.selectorPasteAndGo {
            return UIPasteboard.general.hasStrings
        }

        return super.canPerformAction(action, withSender: sender)
    }

    func menuHelperPasteAndGo() {
        UIPasteboard.general.asyncString { [weak self] contents in
            guard let contents else { return }
            ensureMainThread {
                self?.urlTextField.text = contents
                self?.delegate?.locationViewDidSubmitText(contents)
            }
        }
    }

    // MARK: - LocationTextFieldDelegate
    func locationTextFieldDidEnterText(_ text: String) {
        delegate?.locationViewDidEnterText(text)
    }

    func locationTextFieldShouldReturn(_ textField: LocationTextField) -> Bool {
        guard let text = textField.text else { return true }
        if !text.trimmingCharacters(in: .whitespaces).isEmpty {
            delegate?.locationViewDidSubmitText(text)
            _ = textField.resignFirstResponder()
            return true
        } else {
            return false
        }
    }

    func locationTextFieldShouldClear() -> Bool {
        delegate?.locationViewDidClearText()
        return true
    }

    func locationTextFieldDidBeginEditing(_ textField: UITextField) {
        guard !isEditing else { return }
        updateUIForSearchEngineDisplay(isURLTextFieldCentered: isURLTextFieldCentered)
        let searchText = searchTerm != nil ? searchTerm : urlAbsolutePath

        // `attributedText` property is set to nil to remove all formatting and truncation set before.
        textField.attributedText = nil
        textField.text = searchText

        delegate?.locationViewDidBeginEditing(searchText ?? "", shouldShowSuggestions: searchTerm != nil)
    }

    func locationTextFieldDidEndEditing() {
        if isURLTextFieldEmpty {
            updateGradient()
        } else if isEditing {
            // Ecosia: Keyboard drag-dismiss resigns first responder while overlay editing
            // continues. updateUIForSearchEngineDisplay adds icon-container leading inset
            // inside the pill; keep the editing layout instead.
            updateUIForEditingDisplay()
        } else {
            /* Ecosia: Show search engine view (favicon) instead of lock icon when editing ends
            updateUIForLockIconDisplay()
            */
            // Ecosia: URL is present (non-empty), so pass false to ensure the favicon icon is added to the stack.
            updateUIForSearchEngineDisplay(isURLTextFieldCentered: false)
        }
    }

    func locationTextFieldNeedsSearchReset() {
        delegate?.locationTextFieldNeedsSearchReset()
    }

    func locationTextFieldDidDisplayEditingAccessoryButton(_ button: UIButton, contextualHintType: String) {
        delegate?.locationViewDidDisplayEditingAccessoryButton(button, contextualHintType: contextualHintType)
    }

    // MARK: - Accessibility
    private func configureA11y(_ config: LocationViewConfiguration) {
        lockIconButton.accessibilityIdentifier = config.lockIconButtonA11yId
        lockIconButton.accessibilityLabel = config.lockIconButtonA11yLabel

        urlTextField.accessibilityIdentifier = config.urlTextFieldA11yId
        accessibilityElements = [iconContainerStackView, urlTextField]
    }

    func accessibilityCustomActionsForView(_ view: UIView) -> [UIAccessibilityCustomAction]? {
        guard view === urlTextField else { return nil }
        return delegate?.locationViewAccessibilityActions()
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        self.theme = theme
        let colors = theme.colors
        /* Ecosia: Use backgroundElevation1 to match the locationContainer background so the
           gradient fade blends seamlessly into the URL bar pill on long URLs.
        let usesAlternativeLocationColor = !theme.isNova && hasAlternativeLocationColor
        let mainBackgroundColor = usesAlternativeLocationColor ? colors.layerSurfaceMediumAlt : colors.layerSurfaceMedium
         */
        let mainBackgroundColor = colors.ecosia.backgroundElevation1
        // Ecosia: the URL text, subdomain and lock tint are recoloured in
        // `getPrimaryAndSecondaryColors()`, which upstream now routes all three through.
        let (primaryColor, secondaryColor) = getPrimaryAndSecondaryColors()

        gradientLayer.colors = Gradient(
            colors: [
                mainBackgroundColor.withAlphaComponent(1),
                mainBackgroundColor.withAlphaComponent(0)
            ]
        ).cgColors
        searchEngineContentView.applyTheme(theme: theme)
        lockIconButton.tintColor = secondaryColor
        lockIconButton.backgroundColor = isAddressBarMinimized ? nil : mainBackgroundColor
        urlTextField.applyTheme(theme: theme)
        urlTextField.textColor = primaryColor
        /* Ecosia: Use Ecosia text color for the placeholder.
        setTextFieldPlaceholder(color: colors.textPrimary)
        */
        setTextFieldPlaceholder(color: colors.ecosia.textPrimary)

        setLockIconImage()
        // Applying the theme to urlTextField can cause the url formatting to get removed
        // so we apply it again
        /* Ecosia: Pass whether a search query is displayed so URL truncation is skipped on SERPs.
        formatAndTruncateURLTextField()
        */
        formatAndTruncateURLTextField(hasSearchTerm: searchTerm != nil)
    }

    private func getPrimaryAndSecondaryColors() -> (primary: UIColor, secondary: UIColor) {
        if #available(iOS 26.0, *), isAddressBarMinimized {
            // We want to use system colors when the location view is fully transparent
            // To make sure it blends well with the background when using glass effect.
            return (.label, .label)
        } else {
            /* Ecosia: Use Ecosia text colors for the URL, its subdomain and the lock icon tint.
            return (theme.colors.textPrimary, theme.colors.textSecondary)
            */
            return (theme.colors.ecosia.textPrimary, theme.colors.ecosia.textSecondary)
        }
    }

    private func setTextFieldPlaceholder(color: UIColor) {
        guard let placeholder = urlTextField.placeholder, !placeholder.isEmpty else { return }
        urlTextField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: color]
        )
    }
}

fileprivate extension UIImage {
    func overlayWith(image: UIImage,
                     modifier: CGFloat = 0.35,
                     origin: CGPoint = CGPoint(x: 15, y: 16)) -> UIImage {
        let newSize = CGSize(width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        draw(in: CGRect(origin: CGPoint.zero, size: newSize))
        image.draw(in: CGRect(origin: origin,
                              size: CGSize(width: size.width * modifier,
                                           height: size.height * modifier)))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return newImage
    }
}
