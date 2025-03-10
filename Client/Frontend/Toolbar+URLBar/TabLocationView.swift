// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

protocol TabLocationViewDelegate: AnyObject {
    func tabLocationViewDidTapLocation(_ tabLocationView: TabLocationView)
    func tabLocationViewDidLongPressLocation(_ tabLocationView: TabLocationView)
    func tabLocationViewDidTapReaderMode(_ tabLocationView: TabLocationView)
    func tabLocationViewDidTapReload(_ tabLocationView: TabLocationView)
    func tabLocationViewDidTapShield(_ tabLocationView: TabLocationView)
    func tabLocationViewDidBeginDragInteraction(_ tabLocationView: TabLocationView)
    func tabLocationViewDidTapShare(_ tabLocationView: TabLocationView, button: UIButton)
    func tabLocationViewPresentCFR(at sourceView: UIView)

    /// - returns: whether the long-press was handled by the delegate; i.e. return `false` when the conditions for even starting handling long-press were not satisfied
    @discardableResult
    func tabLocationViewDidLongPressReaderMode(_ tabLocationView: TabLocationView) -> Bool
    func tabLocationViewDidLongPressReload(_ tabLocationView: TabLocationView)
    func tabLocationViewLocationAccessibilityActions(_ tabLocationView: TabLocationView) -> [UIAccessibilityCustomAction]?
}

class TabLocationView: UIView, FeatureFlaggable {
    // MARK: UX
    struct UX {
        static let hostFontColor = UIColor.black
        static let spacing: CGFloat = 8
        static let statusIconSize: CGFloat = 18
        static let buttonSize: CGFloat = 40
        static let urlBarPadding = 4
        // Ecosia: Update show/hide locker icon based on Firefox v128
        static let trackingProtectionAnimationDuration = 0.3
        static let trackingProtectionxOffset = CGAffineTransform(translationX: 25, y: 0)
    }

    // MARK: Variables
    weak var delegate: TabLocationViewDelegate?
    var longPressRecognizer: UILongPressGestureRecognizer!
    var tapRecognizer: UITapGestureRecognizer!
    var contentView: UIStackView!

    var notificationCenter: NotificationProtocol = NotificationCenter.default

    /* Ecosia: Update show/hide locker icon based on Firefox v128
     private var blockerStatus: BlockerStatus = .noBlockedURLs
     private var hasSecureContent = false
    */
    /// Tracking protection button, gets updated from tabDidChangeContentBlocking
    var blockerStatus: BlockerStatus = .noBlockedURLs {
        didSet {
            if oldValue != blockerStatus { setTrackingProtection(theme: themeManager.currentTheme) }
        }
    }

    var hasSecureContent = false {
        didSet {
            if oldValue != hasSecureContent { setTrackingProtection(theme: themeManager.currentTheme) }
        }
    }
    private var themeManager: ThemeManager = AppContainer.shared.resolve()

    private let menuBadge = BadgeWithBackdrop(imageName: ImageIdentifiers.menuBadge, backdropCircleSize: 32)

    var url: URL? {
        willSet { handleShoppingAdsCacheURLChange(newURL: newValue) }
        didSet {
            hideButtons()
            updateTextWithURL()
            /* Ecosia: Update show/hide locker icon based on Firefox v128
            trackingProtectionButton.isHidden = !isValidHttpUrlProtocol
            shareButton.isHidden = !(shouldEnableShareButtonFeature && isValidHttpUrlProtocol)
             */
            setNeedsUpdateConstraints()
            showTrackingProtectionButton(for: url)
        }
    }

    var shouldEnableShareButtonFeature: Bool {
        guard featureFlags.isFeatureEnabled(.shareToolbarChanges, checking: .buildOnly) else {
            return false
        }
        return true
    }

    var readerModeState: ReaderModeState {
        get {
            return readerModeButton.readerModeState
        }
        set (newReaderModeState) {
            guard newReaderModeState != self.readerModeButton.readerModeState else { return }
            setReaderModeState(newReaderModeState)
        }
    }

    lazy var urlTextField: URLTextField = .build { urlTextField in
        // Prevent the field from compressing the toolbar buttons on the 4S in landscape.
        urlTextField.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 250), for: .horizontal)
        urlTextField.accessibilityIdentifier = "url"
        urlTextField.accessibilityActionsSource = self
        urlTextField.font = UIConstants.DefaultChromeFont
        urlTextField.backgroundColor = .clear
        urlTextField.accessibilityLabel = .TabLocationAddressBarAccessibilityLabel
        urlTextField.font = UIFont.preferredFont(forTextStyle: .body)
        urlTextField.adjustsFontForContentSizeCategory = true

        // Remove the default drop interaction from the URL text field so that our
        // custom drop interaction on the BVC can accept dropped URLs.
        if let dropInteraction = urlTextField.textDropInteraction {
            urlTextField.removeInteraction(dropInteraction)
        }
    }

    private func setURLTextfieldPlaceholder(theme: Theme) {
        // Ecosia: Update Placeholder attributes
        // let attributes = [NSAttributedString.Key.foregroundColor: theme.colors.textSecondary]
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.legacyTheme.ecosia.secondaryText]
        urlTextField.attributedPlaceholder = NSAttributedString(string: .TabLocationURLPlaceholder,
                                                                attributes: attributes)
    }

    lazy var trackingProtectionButton: LockButton = .build { trackingProtectionButton in
        trackingProtectionButton.addTarget(self, action: #selector(self.didPressTPShieldButton(_:)), for: .touchUpInside)
        trackingProtectionButton.clipsToBounds = false
        trackingProtectionButton.accessibilityIdentifier = AccessibilityIdentifiers.Toolbar.trackingProtection
        trackingProtectionButton.showsLargeContentViewer = true
        trackingProtectionButton.largeContentImage = .templateImageNamed(StandardImageIdentifiers.Large.lock)
        trackingProtectionButton.imageView?.contentMode = .scaleAspectFit
        trackingProtectionButton.largeContentTitle = .TabLocationLockButtonLargeContentTitle
        trackingProtectionButton.accessibilityLabel = .TabLocationLockButtonAccessibilityLabel
    }

    lazy var shareButton: ShareButton = .build { shareButton in
        shareButton.addTarget(self, action: #selector(self.didPressShareButton(_:)), for: .touchUpInside)
        shareButton.clipsToBounds = false
        shareButton.contentHorizontalAlignment = .center
        shareButton.accessibilityIdentifier = AccessibilityIdentifiers.Toolbar.shareButton
        shareButton.accessibilityLabel = .TabLocationShareAccessibilityLabel
        shareButton.showsLargeContentViewer = true
        shareButton.largeContentImage = .templateImageNamed(ImageIdentifiers.share)
        shareButton.largeContentTitle = .TabLocationShareButtonLargeContentTitle
    }

    private lazy var shoppingButton: UIButton = .build { button in
        let image = UIImage(named: StandardImageIdentifiers.Large.shopping)

        button.addTarget(self, action: #selector(self.didPressShoppingButton(_:)), for: .touchUpInside)
        button.isHidden = true
        button.setImage(image?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.accessibilityLabel = .TabLocationShoppingAccessibilityLabel
        button.accessibilityIdentifier = AccessibilityIdentifiers.Toolbar.shoppingButton
        button.showsLargeContentViewer = true
        button.largeContentTitle = .TabLocationShoppingAccessibilityLabel
        button.largeContentImage = image
    }

    private lazy var readerModeButton: ReaderModeButton = .build { readerModeButton in
        readerModeButton.addTarget(self, action: #selector(self.tapReaderModeButton), for: .touchUpInside)
        readerModeButton.addGestureRecognizer(
            UILongPressGestureRecognizer(target: self,
                                         action: #selector(self.longPressReaderModeButton)))
        readerModeButton.isAccessibilityElement = true
        readerModeButton.isHidden = true
        readerModeButton.accessibilityLabel = .TabLocationReaderModeAccessibilityLabel
        readerModeButton.accessibilityIdentifier = AccessibilityIdentifiers.Toolbar.readerModeButton
        readerModeButton.accessibilityCustomActions = [
            UIAccessibilityCustomAction(
                name: .TabLocationReaderModeAddToReadingListAccessibilityLabel,
                target: self,
                selector: #selector(self.readerModeCustomAction))]
        readerModeButton.showsLargeContentViewer = true
        readerModeButton.largeContentTitle = .TabLocationReaderModeAccessibilityLabel
        readerModeButton.largeContentImage = .templateImageNamed("reader")
    }

    lazy var reloadButton: StatefulButton = {
        let reloadButton = StatefulButton(frame: .zero, state: .disabled)
        reloadButton.addTarget(self, action: #selector(tapReloadButton), for: .touchUpInside)
        reloadButton.addGestureRecognizer(
            UILongPressGestureRecognizer(target: self, action: #selector(longPressReloadButton)))
        reloadButton.imageView?.contentMode = .scaleAspectFit
        reloadButton.contentHorizontalAlignment = .center
        reloadButton.accessibilityLabel = .TabLocationReloadAccessibilityLabel
        reloadButton.accessibilityIdentifier = AccessibilityIdentifiers.Toolbar.reloadButton
        reloadButton.isAccessibilityElement = true
        reloadButton.translatesAutoresizingMaskIntoConstraints = false
        reloadButton.showsLargeContentViewer = true
        reloadButton.largeContentTitle = .TabLocationReloadAccessibilityLabel
        return reloadButton
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupNotifications(forObserver: self, observing: [.FakespotViewControllerDidDismiss, .FakespotViewControllerDidAppear])
        register(self, forTabEvents: .didGainFocus, .didToggleDesktopMode, .didChangeContentBlocking)
        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressLocation))
        longPressRecognizer.delegate = self

        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapLocation))
        tapRecognizer.delegate = self

        addGestureRecognizer(longPressRecognizer)
        addGestureRecognizer(tapRecognizer)

        let space1px = UIView.build()
        space1px.widthAnchor.constraint(equalToConstant: 1).isActive = true

        let subviews = [trackingProtectionButton, space1px, urlTextField, shoppingButton, readerModeButton, shareButton, reloadButton]
        contentView = UIStackView(arrangedSubviews: subviews)
        contentView.distribution = .fill
        contentView.alignment = .center
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.edges(equalTo: self)

        NSLayoutConstraint.activate([
            trackingProtectionButton.widthAnchor.constraint(equalToConstant: UX.buttonSize),
            trackingProtectionButton.heightAnchor.constraint(equalToConstant: UX.buttonSize),
            shoppingButton.widthAnchor.constraint(equalToConstant: UX.buttonSize),
            shoppingButton.heightAnchor.constraint(equalToConstant: UX.buttonSize),
            readerModeButton.widthAnchor.constraint(equalToConstant: UX.buttonSize),
            readerModeButton.heightAnchor.constraint(equalToConstant: UX.buttonSize),
            shareButton.heightAnchor.constraint(equalToConstant: UX.buttonSize),
            shareButton.widthAnchor.constraint(equalToConstant: UX.buttonSize),
            reloadButton.widthAnchor.constraint(equalToConstant: UX.buttonSize),
            reloadButton.heightAnchor.constraint(equalToConstant: UX.buttonSize),
        ])

        // Setup UIDragInteraction to handle dragging the location
        // bar for dropping its URL into other apps.
        let dragInteraction = UIDragInteraction(delegate: self)
        dragInteraction.allowsSimultaneousRecognitionDuringLift = true
        self.addInteraction(dragInteraction)

        menuBadge.add(toParent: contentView)
        menuBadge.show(false)

        // Ecosia: Update show/hide locker icon based on Firefox v128
        hideTrackingProtectionButton()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Accessibility

    private lazy var _accessibilityElements = [trackingProtectionButton, urlTextField, shoppingButton, readerModeButton, shareButton, reloadButton]

    override var accessibilityElements: [Any]? {
        get {
            return _accessibilityElements.filter { !$0.isHidden }
        }
        set {
            super.accessibilityElements = newValue
        }
    }

    func overrideAccessibility(enabled: Bool) {
        _accessibilityElements.forEach {
            $0.isAccessibilityElement = enabled
        }
    }

    // MARK: - User actions

    @objc
    func tapReaderModeButton() {
        delegate?.tabLocationViewDidTapReaderMode(self)
    }

    @objc
    func tapReloadButton() {
        delegate?.tabLocationViewDidTapReload(self)
    }

    @objc
    func longPressReaderModeButton(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            delegate?.tabLocationViewDidLongPressReaderMode(self)
        }
    }

    @objc
    func longPressReloadButton(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            delegate?.tabLocationViewDidLongPressReload(self)
        }
    }

    @objc
    func longPressLocation(_ recognizer: UITapGestureRecognizer) {
        if recognizer.state == .began {
            delegate?.tabLocationViewDidLongPressLocation(self)
        }
    }

    @objc
    func tapLocation(_ recognizer: UITapGestureRecognizer) {
        delegate?.tabLocationViewDidTapLocation(self)
    }

    @objc
    func didPressTPShieldButton(_ button: UIButton) {
        delegate?.tabLocationViewDidTapShield(self)
    }

    @objc
    func didPressShareButton(_ button: UIButton) {
        delegate?.tabLocationViewDidTapShare(self, button: shareButton)
    }

    @objc
    func didPressShoppingButton(_ button: UIButton) {
        button.isSelected = true
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .shoppingButton)
        store.dispatch(FakespotAction.pressedShoppingButton)
    }

    @objc
    func readerModeCustomAction() -> Bool {
        return delegate?.tabLocationViewDidLongPressReaderMode(self) ?? false
    }

    func updateShoppingButtonVisibility(for tab: Tab) {
        guard let url else {
            shoppingButton.isHidden = true
            return
        }
        let environment = featureFlags.isCoreFeatureEnabled(.useStagingFakespotAPI) ? FakespotEnvironment.staging : .prod
        let product = ShoppingProduct(url: url, client: FakespotClient(environment: environment))
        if product.product != nil && !tab.isPrivate {
            sendProductPageDetectedTelemetry()
        }

        let shouldHideButton = !product.isShoppingButtonVisible || tab.isPrivate
        shoppingButton.isHidden = shouldHideButton
        if !shouldHideButton {
            TelemetryWrapper.recordEvent(category: .action, method: .view, object: .shoppingButton)
            delegate?.tabLocationViewPresentCFR(at: shoppingButton)
            setReaderModeState(.unavailable)
        } else {
            setReaderModeState(.available)
        }
    }

    private func sendProductPageDetectedTelemetry() {
        TelemetryWrapper.recordEvent(category: .information,
                                     method: .view,
                                     object: .shoppingProductPageVisits)
    }

    private func handleShoppingAdsCacheURLChange(newURL: URL?) {
        guard  url?.displayURL != newURL,
               !shoppingButton.isHidden else { return }
        Task {
            await ProductAdsCache.shared.clearCache()
        }
    }

    private func updateTextWithURL() {
        if let host = url?.host, AppConstants.punyCode {
            urlTextField.text = url?.absoluteString.replacingOccurrences(of: host, with: host.asciiHostToUTF8())
        } else {
            urlTextField.text = url?.absoluteString
        }
        // remove https:// (the scheme) from the url when displaying
        if let scheme = url?.scheme, let range = url?.absoluteString.range(of: "\(scheme)://") {
            urlTextField.text = url?.absoluteString.replacingCharacters(in: range, with: "")
        }
    }

    func hideTrackingProtectionButton() {
        ensureMainThread {
            self.trackingProtectionButton.isHidden = true
        }
    }

    // Ecosia: Update show/hide locker icon based on Firefox v128
    func showTrackingProtectionButton(for url: URL?) {
        ensureMainThread {
            let isValidHttpUrlProtocol = self.isValidHttpUrlProtocol(url)
            let isReaderModeURL = url?.isReaderModeURL ?? false
            let isFxHomeUrl = url?.isFxHomeUrl ?? false
            if !isFxHomeUrl, !isReaderModeURL, isValidHttpUrlProtocol, self.trackingProtectionButton.isHidden {
                self.trackingProtectionButton.transform = UX.trackingProtectionxOffset
                self.trackingProtectionButton.alpha = 0
                self.trackingProtectionButton.isHidden = false
                UIView.animate(withDuration: UX.trackingProtectionAnimationDuration) {
                    self.trackingProtectionButton.alpha = 1
                    self.trackingProtectionButton.transform = .identity
                }
            }
            self.trackingProtectionButton.isHidden = !isValidHttpUrlProtocol || isReaderModeURL || isFxHomeUrl
        }
    }

    private func setTrackingProtection(theme: Theme) {
        var lockImage: UIImage?
        if !hasSecureContent {
            lockImage = UIImage(imageLiteralResourceName: StandardImageIdentifiers.Large.lockSlash)
        } else if let tintColor = trackingProtectionButton.tintColor {
            lockImage = UIImage(imageLiteralResourceName: StandardImageIdentifiers.Large.lock)
                .withTintColor(tintColor, renderingMode: .alwaysTemplate)
        }

        switch blockerStatus {
        case .blocking, .noBlockedURLs, .disabled:
            trackingProtectionButton.setImage(lockImage, for: .normal)
            trackingProtectionButton.accessibilityLabel = hasSecureContent ?
                .TabLocationETPOnSecureAccessibilityLabel : .TabLocationETPOnNotSecureAccessibilityLabel
        case .safelisted:
            if let smallDotImage = UIImage(systemName: ImageIdentifiers.circleFill)?.withTintColor(theme.colors.iconAccentBlue) {
                trackingProtectionButton.setImage(lockImage?.overlayWith(image: smallDotImage), for: .normal)
                trackingProtectionButton.accessibilityLabel = hasSecureContent ?
                    .TabLocationETPOffSecureAccessibilityLabel : .TabLocationETPOffNotSecureAccessibilityLabel
            }
        }
    }

    // Fixes: https://github.com/mozilla-mobile/firefox-ios/issues/17403
    private func hideButtons() {
        [shoppingButton, shareButton].forEach { $0.isHidden = true }
    }
}

// MARK: - Private
private extension TabLocationView {
    // Ecosia: Update show/hide locker icon based on Firefox v128
    // var isValidHttpUrlProtocol: Bool {
    func isValidHttpUrlProtocol(_ url: URL?) -> Bool {
        ["https", "http"].contains(url?.scheme ?? "")
    }

    func setReaderModeState(_ newReaderModeState: ReaderModeState) {
        let wasHidden = readerModeButton.isHidden
        self.readerModeButton.readerModeState = newReaderModeState

        readerModeButton.isHidden = shoppingButton.isHidden ? newReaderModeState == .unavailable : true
        // When the user turns on the reader mode we need to hide the trackingProtectionButton (according to 16400), we will hide it once the newReaderModeState == .active
        if newReaderModeState == .active {
            self.trackingProtectionButton.isHidden = true
        }

        if wasHidden != readerModeButton.isHidden {
            UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: nil)
            if !readerModeButton.isHidden {
                // Delay the Reader Mode accessibility announcement briefly to prevent interruptions.
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                    UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: String.ReaderModeAvailableVoiceOverAnnouncement)
                }
            }
        }
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            self.readerModeButton.alpha = newReaderModeState == .unavailable ? 0 : 1
        })
    }
}

extension TabLocationView: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .FakespotViewControllerDidDismiss:
            shoppingButton.isSelected = false
        case .FakespotViewControllerDidAppear:
            shoppingButton.isSelected = true
        default: break
        }
    }
}

extension TabLocationView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // When long pressing a button make sure the textfield's long press gesture is not triggered
        return !(otherGestureRecognizer.view is UIButton)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // If the longPressRecognizer is active, fail the tap recognizer to avoid conflicts.
        return gestureRecognizer == longPressRecognizer && otherGestureRecognizer == tapRecognizer
    }
}

extension TabLocationView: UIDragInteractionDelegate {
    func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        // Ensure we actually have a URL in the location bar and that the URL is not local.
        guard let url = self.url,
              !InternalURL.isValid(url: url),
              let itemProvider = NSItemProvider(contentsOf: url)
        else { return [] }

        TelemetryWrapper.recordEvent(category: .action, method: .drag, object: .locationBar)

        let dragItem = UIDragItem(itemProvider: itemProvider)
        return [dragItem]
    }

    func dragInteraction(_ interaction: UIDragInteraction, sessionWillBegin session: UIDragSession) {
        delegate?.tabLocationViewDidBeginDragInteraction(self)
    }
}

extension TabLocationView: AccessibilityActionsSource {
    func accessibilityCustomActionsForView(_ view: UIView) -> [UIAccessibilityCustomAction]? {
        if view === urlTextField {
            return delegate?.tabLocationViewLocationAccessibilityActions(self)
        }
        return nil
    }
}

// MARK: ThemeApplicable
extension TabLocationView: ThemeApplicable {
    func applyTheme(theme: Theme) {
        setURLTextfieldPlaceholder(theme: theme)
        // Ecosia: Update `urlTextField` theme
        // urlTextField.textColor = theme.colors.textPrimary
        urlTextField.textColor = UIColor.legacyTheme.ecosia.primaryText
        urlTextField.tintColor = .legacyTheme.ecosia.information

        readerModeButton.applyTheme(theme: theme)
        trackingProtectionButton.applyTheme(theme: theme)
        shareButton.applyTheme(theme: theme)
        reloadButton.applyTheme(theme: theme)
        // Ecosia: Update `menuBadge` color
        // menuBadge.badge.tintBackground(color: theme.colors.layer3)
        let color = LegacyThemeManager.instance.currentName == .dark ? UIColor(white: 0.3, alpha: 0.6): UIColor.legacyTheme.ecosia.primaryBackground
        menuBadge.badge.tintBackground(color: color)

        setTrackingProtection(theme: theme)
        shoppingButton.tintColor = theme.colors.textPrimary
        shoppingButton.setImage(UIImage(named: StandardImageIdentifiers.Large.shopping)?
            .withTintColor(theme.colors.actionPrimary),
                                for: .selected)
    }
}

/* Ecosia: Update show/hide locker icon based on Firefox v128
 extension TabLocationView: TabEventHandler {
 
 func tabDidChangeContentBlocking(_ tab: Tab) {
 updateBlockerStatus(forTab: tab)
 }
 
 private func updateBlockerStatus(forTab tab: Tab) {
 guard let blocker = tab.contentBlocker else { return }
 
 ensureMainThread { [self] in
 trackingProtectionButton.alpha = 1.0
 let themeManager: ThemeManager = AppContainer.shared.resolve()
 self.blockerStatus = blocker.status
 self.hasSecureContent = (tab.webView?.hasOnlySecureContent ?? false)
 setTrackingProtection(theme: themeManager.currentTheme)
 }
 }
 
 func tabDidGainFocus(_ tab: Tab) {
 updateBlockerStatus(forTab: tab)
 }
 }
 */

extension TabLocationView: TabEventHandler {
    func tabDidChangeContentBlocking(_ tab: Tab) {
        guard let blocker = tab.contentBlocker else { return }

        ensureMainThread { [self] in
            self.blockerStatus = blocker.status
        }
    }

    func tabDidGainFocus(_ tab: Tab) {
        guard let blocker = tab.contentBlocker else { return }

        ensureMainThread { [self] in
            self.showTrackingProtectionButton(for: tab.webView?.url)
            self.hasSecureContent = (tab.webView?.hasOnlySecureContent ?? false)
            self.blockerStatus = blocker.status
        }
    }
}
