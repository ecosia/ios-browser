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
    /// Called when editing ends without a submission (e.g. tap outside).
    func ntpSearchBarDidCancel()
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
        static let clearButtonSize: CGFloat = 24
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
        /// Padding between the textView and the pill's top/bottom edges.
        static let textPadding: CGFloat = .ecosia.space._m
        static var minTextHeight: CGFloat { minHeight - 2 * textPadding }
        static var maxTextHeight: CGFloat { maxHeight - 2 * textPadding }
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

    private var currentTheme: Theme?
    private var currentSubmitMode: NTPSearchBarSubmitMode = .search
    private var textViewHeightConstraint: NSLayoutConstraint!

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

        textViewHeightConstraint = textView.heightAnchor.constraint(equalToConstant: UX.minTextHeight)
        NSLayoutConstraint.activate([
            // textView fills the entire pill — submit button floats over the
            // bottom-right corner.
            textView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.textPadding),
            textView.topAnchor.constraint(equalTo: topAnchor, constant: UX.textPadding),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.textPadding),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.textPadding),
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

            // Character counter sits in the bottom-left of the pill and only
            // appears once the user nears the hard cap.
            counterLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .ecosia.space._m),
            counterLabel.centerYAnchor.constraint(equalTo: submitButton.centerYAnchor),
            counterLabel.trailingAnchor.constraint(lessThanOrEqualTo: submitButton.leadingAnchor, constant: -.ecosia.space._s),

            // Clear-text button sits in the top-right of the pill, floating
            // over the textView. Hidden until the user has content.
            clearButton.topAnchor.constraint(equalTo: topAnchor, constant: .ecosia.space._1s),
            clearButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.ecosia.space._1s),
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
        // contentSize is reliable here — `textContainerInset` and
        // `lineFragmentPadding` are both zero, so it matches the used rect.
        let contentHeight = textView.contentSize.height
        let lineCount = max(1, Int((contentHeight / lineHeight).rounded()))
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
        counterLabel.text = "\(count)/\(UX.maxLength)"
        applyCounterColor()
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
        // counter into a warning tint so the cap is unmissable.
        counterLabel.textColor = count >= UX.counterWarningThreshold
            ? colors.ecosia.stateError
            : colors.ecosia.textSecondary
    }

    private func applySubmitButtonColors() {
        guard let colors = currentTheme?.colors else { return }
        submitButton.layer.cornerRadius = UX.submitButtonSize / 2
        submitButton.layer.masksToBounds = true
        if submitButton.isEnabled {
            submitButton.backgroundColor = colors.ecosia.buttonBackgroundFeatured
            submitButton.tintColor = colors.ecosia.buttonContentSecondary
        } else {
            submitButton.backgroundColor = .clear
            submitButton.tintColor = colors.ecosia.textSecondary
        }
    }

    // MARK: ThemeApplicable

    func applyTheme(theme: any Theme) {
        currentTheme = theme
        let colors = theme.colors

        backgroundColor = colors.ecosia.backgroundElevation2
        layer.borderColor = colors.ecosia.borderDecorative.cgColor
        textView.textColor = colors.ecosia.textPrimary
        textView.tintColor = colors.ecosia.textPrimary
        placeholderLabel.textColor = colors.ecosia.textSecondary
        applySubmitButtonColors()
        applyCounterColor()
        // Clear button: dark filled pill with a light glyph, matching the
        // Figma design.
        clearButton.backgroundColor = colors.ecosia.textPrimary
        clearButton.tintColor = colors.ecosia.backgroundElevation2
    }

    // MARK: Autocompletable

    /// Inline gray-text URL completion is not supported by the multi-line
    /// `UITextView` field. Suggestions still flow through the overlay.
    func setAutocompleteSuggestion(_ suggestion: String?) {}
}

// MARK: - UITextViewDelegate

extension NTPSearchBarView: @MainActor @preconcurrency UITextViewDelegate {

    func textViewDidBeginEditing(_ textView: UITextView) {
        delegate?.ntpSearchBarDidBeginEditing()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
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
