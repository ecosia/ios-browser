// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Ecosia

// MARK: - Delegate

/// Whether a submission should route to the standard search pipeline or the
/// long-form AI chat. The omnibox flips into `.aiChat` once the input crosses
/// the configured threshold (see `NTPSearchBarView.UX.aiChatThreshold`).
enum NTPSearchBarSubmitMode {
    case search
    case aiChat
}

@MainActor
protocol NTPSearchBarDelegate: AnyObject {
    /// Called when the user commits a query (Return key or submit button).
    /// `mode` indicates whether the input should be treated as a search query
    /// or a long-form AI chat prompt.
    func ntpSearchBarDidSubmit(_ searchTerm: String, mode: NTPSearchBarSubmitMode)
    /// Called on every keystroke so the browser can feed suggestions.
    func ntpSearchBarTextDidChange(_ searchTerm: String)
    /// Called when the text field becomes first responder.
    func ntpSearchBarDidBeginEditing()
    /// Called when the text field resigns first responder for any reason
    /// (explicit cancel, tap-outside, keyboard drag-dismiss). The host may
    /// use it to update session-state telemetry but MUST NOT tear down the
    /// suggestions overlay here — a keyboard drag-dismiss should leave the
    /// list visible so the user can read it without the keyboard. Use
    /// `ntpSearchBarRequestsOverlayDismiss` for explicit overlay teardown.
    func ntpSearchBarDidCancel()
    /// Called when the user explicitly asks the omnibox UI to dismiss
    /// (tap-outside the pill, close-button tap, host view disappearing).
    /// The host is expected to tear down the suggestions overlay here.
    func ntpSearchBarRequestsOverlayDismiss()
}

/// Pill-shaped search input pinned to the bottom of the redesigned NTP. Replaces
/// the standard URL bar while the homepage is visible. The text input is a
/// `UITextView` so multi-line queries wrap inside the pill.
final class NTPSearchBarView: UIView, ThemeApplicable, Autocompletable {

    /// Resting size of the pill, fitting roughly two lines of text.
    static let minHeight: CGFloat = 110
    /// Cap on how tall the pill can grow before its content starts scrolling
    /// inside instead of pushing further upward.
    static let maxHeight: CGFloat = 250

    private enum UX {
        static let submitButtonSize: CGFloat = .ecosia.space._3l
        static let clearButtonSize: CGFloat = 20
        static let shadowOpacity: Float = 0.10
        static let shadowRadius: CGFloat = 12
        static let shadowOffset = CGSize(width: 0, height: 4)
        /// At/above this character count, submit routes to AI chat instead of
        /// the standard search pipeline.
        static let aiChatThreshold = 60
        /// Character count at which the remaining-character counter becomes
        /// visible.
        static let counterVisibleThreshold = 100
        /// Character count at which the counter flips into a warning tint
        /// (last 100 chars before the hard cap).
        static let counterWarningThreshold = 960
        /// Hard cap on input length. Further input is rejected.
        static let maxLength = 1060
        /// Once the input wraps past this many lines, the suggestions overlay
        /// is suppressed and the pill grows upward to fit the content.
        static let multilineThreshold = 2
        /// Padding between the textView and the pill's top edge.
        static let textPadding: CGFloat = .ecosia.space._m
        /// Vertical footprint of the bottom-controls row (submit button + its
        /// bottom inset). The textView is pinned just above this row so its
        /// content can never bleed into the submit / counter area.
        static var bottomRowHeight: CGFloat { submitButtonSize + .ecosia.space._1s }
        static var minTextHeight: CGFloat { minHeight - textPadding - bottomRowHeight }
        static var maxTextHeight: CGFloat { maxHeight - textPadding - bottomRowHeight }
    }

    weak var delegate: NTPSearchBarDelegate?

    private lazy var textView: UITextView = .build { tv in
        tv.font = .preferredFont(forTextStyle: .body)
        tv.adjustsFontForContentSizeCategory = true
        tv.backgroundColor = .clear
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.autocorrectionType = .no
        tv.autocapitalizationType = .none
        tv.spellCheckingType = .no
        tv.returnKeyType = .search
        tv.keyboardType = .webSearch
        tv.enablesReturnKeyAutomatically = true
        tv.accessibilityIdentifier = "NTPSearchBarTextField"
    }

    private lazy var placeholderLabel: UILabel = .build { label in
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.text = String.localized(.askSearchBrowse)
        label.isUserInteractionEnabled = false
    }

    private lazy var submitButton: UIButton = .build { button in
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        let image = UIImage(systemName: "arrow.up", withConfiguration: symbolConfig)
        button.setImage(image, for: .normal)
        button.accessibilityLabel = String.localized(.search)
        button.accessibilityIdentifier = "NTPSearchBarSubmitButton"
        button.isEnabled = false
    }

    private lazy var counterLabel: UILabel = .build { label in
        label.font = .preferredFont(forTextStyle: .caption2)
        label.adjustsFontForContentSizeCategory = true
        label.isHidden = true
        label.accessibilityIdentifier = "NTPSearchBarCounterLabel"
    }

    /// In-pill clear button at the top-right of the omnibox. Visible only while
    /// the field has content — taps wipe the text without dropping focus.
    private lazy var clearButton: UIButton = .build { button in
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        let image = UIImage(systemName: "xmark", withConfiguration: symbolConfig)
        button.setImage(image, for: .normal)
        button.layer.cornerRadius = UX.clearButtonSize / 2
        button.accessibilityLabel = String.localized(.cancel)
        button.accessibilityIdentifier = "NTPSearchBarClearButton"
        button.isHidden = true
    }

    /// Fires whenever the text content changes (including programmatic clears).
    /// Use from the host to drive focus-only chrome that depends on having text
    /// — for example, the top-right close button.
    var onContentChange: ((String) -> Void)?

    /// Fires whenever the textView's first-responder state changes. Use from
    /// the host to drive focus-only chrome — for example, the active-state
    /// gradient backdrop behind the pill.
    var onFocusChange: ((Bool) -> Void)?

    private var currentTheme: Theme?
    private var currentSubmitMode: NTPSearchBarSubmitMode = .search
    private lazy var textViewHeightConstraint: NSLayoutConstraint =
        textView.heightAnchor.constraint(equalToConstant: UX.minTextHeight)

    /// True once the text wraps past `UX.multilineThreshold` lines. The host
    /// reads this in `ntpSearchBarTextDidChange` to suppress the suggestions
    /// overlay — once the user is composing a long-form prompt, the short-form
    /// suggestions are no longer useful.
    private(set) var isMultiline = false

    /// Current text content. Mirrors `textView.text` but lets callers drive
    /// programmatic changes (e.g. accepting a tapped suggestion).
    var text: String {
        get { textView.text ?? "" }
        set {
            let clamped = String(newValue.prefix(UX.maxLength))
            textView.text = clamped
            placeholderLabel.isHidden = !clamped.isEmpty
            updateSubmitState(for: clamped)
            updateCounter(for: clamped)
            updateClearButtonVisibility(for: clamped)
            updateLayoutForContent()
            onContentChange?(clamped)
        }
    }

    // MARK: Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isFirstResponder: Bool {
        textView.isFirstResponder
    }

    override func resignFirstResponder() -> Bool {
        textView.resignFirstResponder()
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        textView.becomeFirstResponder()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateTextExclusionPath()
    }

    /// Carves out the area occupied by the clear button so wrapping text flows
    /// around it instead of running underneath. Only takes effect while the
    /// button is visible — empty pills keep the full text width.
    private func updateTextExclusionPath() {
        guard !clearButton.isHidden, clearButton.bounds != .zero else {
            textView.textContainer.exclusionPaths = []
            return
        }
        let buttonFrame = textView.convert(clearButton.frame, from: clearButton.superview)
        // Pad the exclusion zone slightly so descenders don't kiss the glyph.
        let excluded = buttonFrame.insetBy(dx: -.ecosia.space._1s, dy: -.ecosia.space._2s)
        textView.textContainer.exclusionPaths = [UIBezierPath(rect: excluded)]
    }

    // MARK: Setup

    private func setup() {
        layer.cornerRadius = .ecosia.borderRadius._1l
        layer.borderWidth = 1
        layer.shadowOpacity = UX.shadowOpacity
        layer.shadowRadius = UX.shadowRadius
        layer.shadowOffset = UX.shadowOffset
        layer.shadowColor = UIColor.black.cgColor

        addSubview(textView)
        addSubview(placeholderLabel)
        addSubview(submitButton)
        addSubview(counterLabel)
        addSubview(clearButton)

        textView.delegate = self
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)

        // Tapping anywhere on the pill (including padding around the textView)
        // focuses the field — without this, only the small intrinsic-size textView
        // frame is tappable.
        let focusTap = UITapGestureRecognizer(target: self, action: #selector(focusTextView))
        focusTap.cancelsTouchesInView = false
        addGestureRecognizer(focusTap)

        // Swipe-down on the pill dismisses the keyboard — pairs with the
        // suggestions list's interactive dismiss for a consistent gesture
        // anywhere on the omnibox surface.
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeDown))
        swipeDown.direction = .down
        addGestureRecognizer(swipeDown)

        NSLayoutConstraint.activate([
            // textView occupies the upper region of the pill. Its bottom is
            // pinned to the submit button's top so wrapped text physically
            // cannot enter the bottom-row area (where submit + counter live)
            // — guaranteeing no overlap regardless of content length or
            // Dynamic Type scaling.
            textView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.textPadding),
            textView.topAnchor.constraint(equalTo: topAnchor, constant: UX.textPadding),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.textPadding),
            textView.bottomAnchor.constraint(equalTo: submitButton.topAnchor),
            textViewHeightConstraint,

            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor),
            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor),
            placeholderLabel.trailingAnchor.constraint(equalTo: textView.trailingAnchor),

            // Submit button sits in the bottom-right corner of the pill,
            // floating over the textView.
            submitButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.ecosia.space._1s),
            submitButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -.ecosia.space._1s),
            submitButton.widthAnchor.constraint(equalToConstant: UX.submitButtonSize),
            submitButton.heightAnchor.constraint(equalToConstant: UX.submitButtonSize),

            // Character counter sits inline with the submit button on its
            // leading side — its trailing edge aligns flush with the submit
            // button's leading edge with a small gap.
            counterLabel.trailingAnchor.constraint(equalTo: submitButton.leadingAnchor, constant: -.ecosia.space._1s),
            counterLabel.centerYAnchor.constraint(equalTo: submitButton.centerYAnchor),
            counterLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: .ecosia.space._m),

            // Clear-text button sits in the top-right of the pill, floating
            // over the textView. Horizontally centered with the submit
            // button so the two right-hand controls stack on the same axis.
            // Hidden until the user has content.
            clearButton.topAnchor.constraint(equalTo: topAnchor, constant: .ecosia.space._m),
            clearButton.centerXAnchor.constraint(equalTo: submitButton.centerXAnchor),
            clearButton.widthAnchor.constraint(equalToConstant: UX.clearButtonSize),
            clearButton.heightAnchor.constraint(equalToConstant: UX.clearButtonSize)
        ])
    }

    @objc private func focusTextView() {
        guard !textView.isFirstResponder else { return }
        textView.becomeFirstResponder()
    }

    @objc private func handleSwipeDown() {
        guard textView.isFirstResponder else { return }
        textView.resignFirstResponder()
    }

    // MARK: Actions

    @objc private func submitTapped() {
        let text = (textView.text ?? "").trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        textView.resignFirstResponder()
        delegate?.ntpSearchBarDidSubmit(text, mode: currentSubmitMode)
    }

    @objc private func clearTapped() {
        // Wipe the text but keep focus so the user can keep typing without
        // re-tapping the pill.
        textView.text = ""
        placeholderLabel.isHidden = false
        updateSubmitState(for: "")
        updateCounter(for: "")
        updateClearButtonVisibility(for: "")
        updateLayoutForContent()
        delegate?.ntpSearchBarTextDidChange("")
        onContentChange?("")
    }

    /// Recomputes the textView height (and therefore the pill height) and the
    /// `isMultiline` flag from the current content. The pill grows from
    /// `minHeight` up to `maxHeight`; past the cap the textView starts
    /// scrolling internally instead of pushing further upward.
    private func updateLayoutForContent() {
        let lineHeight = textView.font?.lineHeight ?? 22
        // contentSize includes textContainerInset on top + bottom — strip
        // those out before counting lines so the threshold matches the
        // visible text rather than the reserved bottom-row spacer.
        let inset = textView.textContainerInset
        let contentHeight = textView.contentSize.height
        let textOnlyHeight = max(0, contentHeight - inset.top - inset.bottom)
        let lineCount = max(1, Int((textOnlyHeight / lineHeight).rounded()))
        isMultiline = lineCount > UX.multilineThreshold

        let clamped = min(UX.maxTextHeight, max(UX.minTextHeight, contentHeight))
        if textViewHeightConstraint.constant != clamped {
            textViewHeightConstraint.constant = clamped
        }
        // The textView always has scrolling enabled so the explicit height
        // constraint drives layout. Internal scrolling kicks in naturally
        // once the content exceeds `maxTextHeight`.
    }

    private func updateSubmitState(for text: String) {
        let hasContent = !text.trimmingCharacters(in: .whitespaces).isEmpty
        submitButton.isEnabled = hasContent
        currentSubmitMode = Self.submitMode(for: text)
        applySubmitButtonColors()
    }

    private static func submitMode(for text: String) -> NTPSearchBarSubmitMode {
        text.count >= UX.aiChatThreshold ? .aiChat : .search
    }

    private func updateCounter(for text: String) {
        let count = text.count
        let visible = count >= UX.counterVisibleThreshold
        counterLabel.isHidden = !visible
        guard visible else { return }
        let remaining = max(0, UX.maxLength - count)
        let isWarning = count >= UX.counterWarningThreshold
        counterLabel.attributedText = composeCounterText(remaining: remaining, isWarning: isWarning)
        applyCounterColor()
    }

    /// Builds the counter label content. In the warning band (last 100 chars
    /// before the cap) the text is prefixed with an SF-Symbol exclamation
    /// triangle so the limit is unmissable.
    private func composeCounterText(remaining: Int, isWarning: Bool) -> NSAttributedString {
        let phrase = String(format: String.localized(.charactersLeft), remaining)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: counterLabel.font ?? UIFont.preferredFont(forTextStyle: .caption2)
        ]
        let result = NSMutableAttributedString()
        if isWarning {
            let symbolConfig = UIImage.SymbolConfiguration(textStyle: .caption2)
            if let icon = UIImage(systemName: "exclamationmark.triangle",
                                  withConfiguration: symbolConfig)?
                .withRenderingMode(.alwaysTemplate) {
                let attachment = NSTextAttachment()
                attachment.image = icon
                result.append(NSAttributedString(attachment: attachment))
                result.append(NSAttributedString(string: " ", attributes: attributes))
            }
        }
        result.append(NSAttributedString(string: phrase, attributes: attributes))
        return result
    }

    private func updateClearButtonVisibility(for text: String) {
        let shouldShow = !text.isEmpty
        clearButton.isHidden = !shouldShow
        setNeedsLayout()
    }

    private func applyCounterColor() {
        guard let colors = currentTheme?.colors else { return }
        let count = (textView.text ?? "").count
        // Once we cross into the last 100 chars of the budget, flip the
        // counter into a warning tint so the cap is unmissable. The tint is
        // applied to both the text and the warning-triangle attachment glyph.
        let color = count >= UX.counterWarningThreshold
            ? colors.ecosia.stateError
            : colors.ecosia.textSecondary
        counterLabel.textColor = color
        counterLabel.tintColor = color
    }

    private func applySubmitButtonColors() {
        guard let colors = currentTheme?.colors else { return }
        submitButton.layer.cornerRadius = UX.submitButtonSize / 2
        submitButton.layer.masksToBounds = true
        if submitButton.isEnabled {
            // The featured background is grellow in both themes, so the
            // icon must stay dark in both. `buttonContentSecondary` resolves
            // to white in dark mode (white-on-grellow is illegible); the
            // `Static` variant keeps the dark glyph in both modes — matching
            // the design-system primary CTA pattern used by Welcome / Sign-in.
            // The 1pt border in the same featured color is part of the
            // design-system button spec for consistency with other CTAs.
            submitButton.backgroundColor = colors.ecosia.buttonBackgroundFeatured
            submitButton.tintColor = colors.ecosia.buttonContentSecondaryStatic
            submitButton.layer.borderWidth = 1
            submitButton.layer.borderColor = colors.ecosia.buttonBackgroundFeatured.cgColor
        } else {
            submitButton.backgroundColor = .clear
            submitButton.tintColor = colors.ecosia.textSecondary
            submitButton.layer.borderWidth = 0
            submitButton.layer.borderColor = nil
        }
    }

    // MARK: ThemeApplicable

    func applyTheme(theme: any Theme) {
        currentTheme = theme
        let colors = theme.colors

        backgroundColor = colors.ecosia.backgroundElevation2
        textView.textColor = colors.ecosia.textPrimary
        textView.tintColor = colors.ecosia.textPrimary
        placeholderLabel.textColor = colors.ecosia.textSecondary
        applyBorderColor()
        applySubmitButtonColors()
        applyCounterColor()
        // Clear button: dark filled pill with a light glyph, matching the
        // Figma design.
        clearButton.backgroundColor = colors.ecosia.textPrimary
        clearButton.tintColor = colors.ecosia.backgroundElevation2
    }

    /// Swaps the pill border between the resting `borderDecorative` token and
    /// the focused `formBorderPrimaryActive` token. Called from the textView
    /// focus delegate methods and on each theme change.
    private func applyBorderColor() {
        guard let colors = currentTheme?.colors else { return }
        let token = textView.isFirstResponder
            ? colors.ecosia.formBorderPrimaryActive
            : colors.ecosia.borderDecorative
        layer.borderColor = token.cgColor
    }

    // MARK: Autocompletable

    /// Inline gray-text URL completion is not supported by the multi-line
    /// `UITextView` field. Suggestions still flow through the overlay.
    func setAutocompleteSuggestion(_ suggestion: String?) {}
}

// MARK: - UITextViewDelegate

extension NTPSearchBarView: @MainActor @preconcurrency UITextViewDelegate {

    func textViewDidBeginEditing(_ textView: UITextView) {
        applyBorderColor()
        onFocusChange?(true)
        delegate?.ntpSearchBarDidBeginEditing()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        applyBorderColor()
        onFocusChange?(false)
        delegate?.ntpSearchBarDidCancel()
    }

    func textViewDidChange(_ textView: UITextView) {
        let text = textView.text ?? ""
        placeholderLabel.isHidden = !text.isEmpty
        updateSubmitState(for: text)
        updateCounter(for: text)
        updateClearButtonVisibility(for: text)
        // Update layout BEFORE notifying the host so it can read
        // `isMultiline` from `ntpSearchBarTextDidChange` and decide whether
        // to suppress the suggestions overlay.
        updateLayoutForContent()
        delegate?.ntpSearchBarTextDidChange(text)
        onContentChange?(text)
    }

    func textView(_ textView: UITextView,
                  shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool {
        // Treat Return as submit instead of inserting a newline.
        if text == "\n" {
            submitTapped()
            return false
        }
        // Hard cap. Block edits that would push past `maxLength` — typing past
        // the cap is rejected outright, and an oversize paste is dropped (we
        // don't silently truncate to avoid mangling the user's clipboard).
        let current = (textView.text ?? "") as NSString
        let resultingLength = current.length - range.length + (text as NSString).length
        if resultingLength > UX.maxLength {
            return false
        }
        return true
    }
}
