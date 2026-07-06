// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Ecosia

// MARK: - Delegate

@MainActor
protocol NTPSearchBarDelegate: AnyObject {
    /// Called when the user commits a query (Return key or submit button).
    /// Submissions always go through the standard search pipeline — the
    /// client doesn't attempt to infer "AI chat intent" from the input
    /// length or content.
    func ntpSearchBarDidSubmit(_ searchTerm: String)
    /// Called on every keystroke so the browser can feed suggestions.
    func ntpSearchBarTextDidChange(_ searchTerm: String)
    /// Called when the field needs SearchLoader reset without hiding the overlay
    /// (first edit after focus), matching `locationTextFieldNeedsSearchReset`.
    func ntpSearchBarNeedsSearchReset()
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
    /// (tap-outside the pill, host view disappearing).
    /// The host is expected to tear down the suggestions overlay here.
    func ntpSearchBarRequestsOverlayDismiss()
    /// While the suggestions overlay is visible, keyboard drag-dismiss should
    /// strip inline autocomplete without committing the full suggestion.
    func ntpSearchBarIsSuggestionsOverlayVisible() -> Bool
    /// Recompute suggestions scroll insets when the pill moves (keyboard or multi-line growth).
    func ntpSearchBarNeedsSuggestionsLayoutUpdate()
    /// Called when the user taps the upload / attachment button.
    func ntpSearchBarDidTapUpload()
    /// Called when attachments are added, removed, or finish uploading.
    func ntpSearchBarAttachmentsDidChange()
}

extension NTPSearchBarDelegate {
    func ntpSearchBarIsSuggestionsOverlayVisible() -> Bool { false }
    func ntpSearchBarNeedsSuggestionsLayoutUpdate() {}
    func ntpSearchBarAttachmentsDidChange() {}
}

/// Pill-shaped search input pinned to the bottom of the redesigned NTP. Replaces
/// the standard URL bar while the homepage is visible. The text input is a
/// `UITextView` so multi-line queries wrap inside the pill.
final class NTPSearchBarView: UIView, ThemeApplicable, Autocompletable, UIGestureRecognizerDelegate {

    /// Resting size of the pill, fitting roughly two lines of text.
    static let minHeight: CGFloat = 110
    /// Cap on how tall the pill can grow before its content starts scrolling
    /// inside instead of pushing further upward.
    static let maxHeight: CGFloat = 250

    private enum UX {
        static let submitButtonSize: CGFloat = .ecosia.space._3l
        /// Tappable footprint of the in-pill clear button. Matches the
        /// submit button so both controls present the same 40×40 hit
        /// target; the visible artwork is the smaller `clearCircleSize`.
        static let clearButtonSize: CGFloat = .ecosia.space._3l
        /// Visible diameter of the dark circle behind the clear-button's
        /// X glyph. The remaining 24pt of the button is a transparent
        /// hit-padding ring that catches taps just outside the artwork.
        static let clearCircleSize: CGFloat = 16
        /// Gap between the textView's trailing edge and the leading edge
        /// of the right-hand button column so typed text never collides
        /// with either button.
        static let textTrailingGap: CGFloat = .ecosia.space._1s
        static let shadowOpacity: Float = 0.10
        static let shadowRadius: CGFloat = 12
        static let shadowOffset = CGSize(width: 0, height: 4)
        /// Character count at which the remaining-character counter becomes
        /// visible.
        static let counterVisibleThreshold = 100
        /// Character count at which the counter flips into a warning tint
        /// (last 100 chars before the hard cap).
        static let counterWarningThreshold = 960
        /// Hard cap on input length. Further input is rejected.
        static let maxLength = 1060
        /// Padding between the textView and the pill's top edge.
        static let textPadding: CGFloat = .ecosia.space._m
        /// Vertical footprint of the bottom-controls row (submit button + its
        /// bottom inset). The textView is pinned just above this row so its
        /// content can never bleed into the submit / counter area.
        static var bottomRowHeight: CGFloat { submitButtonSize + .ecosia.space._1s }
        static var attachmentStripHeight: CGFloat { OmniboxAttachmentsStripView.UX.tileHeight + .ecosia.space._1s }
        static var minTextHeight: CGFloat { minHeight - textPadding - bottomRowHeight }
        static var maxTextHeight: CGFloat { maxHeight - textPadding - bottomRowHeight }
    }

    private(set) var attachments: [OmniboxAttachment] = []
    var hasAttachments: Bool { !attachments.isEmpty }
    var hasReadyAttachments: Bool { attachments.contains(where: \.isReady) }
    var allAttachmentsReady: Bool {
        !attachments.isEmpty && attachments.allSatisfy(\.isReady)
    }

    var hasUploadingAttachments: Bool {
        attachments.contains(where: \.isLoading)
    }

    /// Recomputes whether the submit button should be enabled.
    func refreshSubmitButtonState() {
        updateSubmitState(for: textView.text ?? "")
    }

    weak var delegate: NTPSearchBarDelegate?

    private lazy var attachmentsStrip: OmniboxAttachmentsStripView = {
        let strip = OmniboxAttachmentsStripView()
        strip.translatesAutoresizingMaskIntoConstraints = false
        strip.isHidden = true
        strip.onRemoveAttachment = { [weak self] id in
            self?.handleRemoveAttachment(id: id)
        }
        return strip
    }()

    private var previewImages: [UUID: UIImage] = [:]
    var onRemoveAttachment: ((UUID) -> Void)?

    private lazy var textView: NTPLocationTextView = {
        let tv = NTPLocationTextView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.autocompleteDelegate = self
        tv.accessibilityIdentifier = "NTPSearchBarTextField"
        return tv
    }()

    private lazy var placeholderLabel: UILabel = .build { label in
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.text = String.localized(.askSearchBrowse)
        label.isUserInteractionEnabled = false
    }

    private lazy var submitButton: UIButton = .build { button in
        let image = UIImage.ecosia(named: "arrow-up")?.withRenderingMode(.alwaysTemplate)
        button.setImage(image, for: .normal)
        button.accessibilityLabel = String.localized(.search)
        button.accessibilityIdentifier = "NTPSearchBarSubmitButton"
        button.isEnabled = false
    }

    private lazy var uploadButton: EcosiaOmniboxUploadButton = .build { _ in }

    private lazy var counterLabel: UILabel = .build { label in
        label.font = .preferredFont(forTextStyle: .caption2)
        label.adjustsFontForContentSizeCategory = true
        label.isHidden = true
        label.accessibilityIdentifier = "NTPSearchBarCounterLabel"
    }

    /// In-pill clear button at the top-right of the omnibox. Visible only
    /// while the field has content — taps wipe the text without dropping
    /// focus. The button itself is the 40×40 hit target with no rendered
    /// content; `clearButtonCircle` and `clearButtonGlyph` are siblings
    /// inside it that draw the visible disc and the X glyph respectively.
    /// We don't use `setImage` because the resulting `imageView`'s z-order
    /// relative to other subviews is unreliable across iOS versions/button
    /// configuration modes — using an explicit `UIImageView` keeps the X
    /// guaranteed to sit on top of the disc.
    private lazy var clearButton: UIButton = .build { button in
        button.accessibilityLabel = String.localized(.cancel)
        button.accessibilityIdentifier = "NTPSearchBarClearButton"
        button.isHidden = true
    }

    /// Visible 16×16 disc inside the clear button. Rendered behind the X
    /// glyph so it acts as the glyph's background pill, while the
    /// surrounding 40×40 button frame stays transparent for hit testing.
    private lazy var clearButtonCircle: UIView = .build { circle in
        circle.layer.cornerRadius = UX.clearCircleSize / 2
        circle.isUserInteractionEnabled = false
    }

    /// X glyph rendered on top of `clearButtonCircle`. Tinted via the
    /// template-rendered image; we leave hit-testing disabled so taps fall
    /// through to the enclosing `clearButton`.
    private lazy var clearButtonGlyph: UIImageView = .build { glyph in
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 9, weight: .semibold)
        glyph.image = UIImage(systemName: "xmark", withConfiguration: symbolConfig)?
            .withRenderingMode(.alwaysTemplate)
        glyph.contentMode = .center
        glyph.isUserInteractionEnabled = false
    }

    /// Fires whenever the text content changes (including programmatic clears).
    /// Use from the host to drive layout that depends on pill height changes.
    var onContentChange: ((String) -> Void)?

    /// Fires whenever the textView's first-responder state changes. Use from
    /// the host to drive focus-only chrome — for example, the active-state
    /// gradient backdrop behind the pill.
    var onFocusChange: ((Bool) -> Void)?

    private var currentTheme: Theme?
    private lazy var textViewHeightConstraint: NSLayoutConstraint =
        textView.heightAnchor.constraint(equalToConstant: UX.minTextHeight)
    private lazy var textViewTopConstraint: NSLayoutConstraint =
        textView.topAnchor.constraint(equalTo: topAnchor, constant: UX.textPadding)

    /// Current text content. Mirrors `textView.text` but lets callers drive
    /// programmatic changes (e.g. accepting a tapped suggestion).
    var text: String {
        get { textView.text ?? "" }
        set {
            let clamped = String(newValue.prefix(UX.maxLength))
            textView.setTextWithoutSearching(clamped)
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

    // MARK: Setup

    private func setup() {
        layer.cornerRadius = .ecosia.borderRadius._1l
        layer.borderWidth = 1
        layer.shadowOpacity = UX.shadowOpacity
        layer.shadowRadius = UX.shadowRadius
        layer.shadowOffset = UX.shadowOffset
        layer.shadowColor = UIColor.black.cgColor

        addSubview(attachmentsStrip)
        addSubview(textView)
        addSubview(placeholderLabel)
        addSubview(uploadButton)
        addSubview(submitButton)
        addSubview(counterLabel)
        addSubview(clearButton)
        // Layered inside `clearButton`: the disc paints the dark
        // background, the glyph draws the X on top. Both have user
        // interaction disabled so taps fall through to the button.
        clearButton.addSubview(clearButtonCircle)
        clearButton.addSubview(clearButtonGlyph)

        textView.delegate = self
        uploadButton.addTarget(self, action: #selector(uploadTapped), for: .touchUpInside)
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)

        // Tapping anywhere on the pill (including padding around the textView)
        // focuses the field — without this, only the small intrinsic-size textView
        // frame is tappable.
        let focusTap = UITapGestureRecognizer(target: self, action: #selector(focusTextView))
        focusTap.cancelsTouchesInView = false
        focusTap.delegate = self
        addGestureRecognizer(focusTap)

        // Swipe-down on the pill dismisses the keyboard — pairs with the
        // suggestions list's interactive dismiss for a consistent gesture
        // anywhere on the omnibox surface.
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeDown))
        swipeDown.direction = .down
        addGestureRecognizer(swipeDown)

        NSLayoutConstraint.activate([
            attachmentsStrip.topAnchor.constraint(equalTo: topAnchor, constant: UX.textPadding),
            attachmentsStrip.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.textPadding),
            attachmentsStrip.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.textPadding),
            attachmentsStrip.heightAnchor.constraint(equalToConstant: OmniboxAttachmentsStripView.UX.tileHeight),

            textView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.textPadding),
            textViewTopConstraint,
            textView.trailingAnchor.constraint(equalTo: submitButton.leadingAnchor, constant: -UX.textTrailingGap),
            textView.bottomAnchor.constraint(equalTo: submitButton.topAnchor),
            textViewHeightConstraint,

            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor),
            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor),
            placeholderLabel.trailingAnchor.constraint(equalTo: textView.trailingAnchor),

            // Upload button sits in the bottom-left corner of the pill.
            uploadButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .ecosia.space._1s),
            uploadButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -.ecosia.space._1s),
            uploadButton.widthAnchor.constraint(equalToConstant: UX.submitButtonSize),
            uploadButton.heightAnchor.constraint(equalToConstant: UX.submitButtonSize),

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
            counterLabel.leadingAnchor.constraint(greaterThanOrEqualTo: uploadButton.trailingAnchor,
                                                  constant: .ecosia.space._1s),

            // Clear-text button sits in the top-right of the pill — its
            // 40×40 hit target is symmetric to the submit button's 8pt
            // inset from the pill's bottom-right corner, with the 16×16
            // visible disc centred inside. Hidden until the user has content.
            clearButton.topAnchor.constraint(equalTo: topAnchor, constant: .ecosia.space._1s),
            clearButton.centerXAnchor.constraint(equalTo: submitButton.centerXAnchor),
            clearButton.widthAnchor.constraint(equalToConstant: UX.clearButtonSize),
            clearButton.heightAnchor.constraint(equalToConstant: UX.clearButtonSize),

            clearButtonCircle.centerXAnchor.constraint(equalTo: clearButton.centerXAnchor),
            clearButtonCircle.centerYAnchor.constraint(equalTo: clearButton.centerYAnchor),
            clearButtonCircle.widthAnchor.constraint(equalToConstant: UX.clearCircleSize),
            clearButtonCircle.heightAnchor.constraint(equalToConstant: UX.clearCircleSize),

            clearButtonGlyph.centerXAnchor.constraint(equalTo: clearButton.centerXAnchor),
            clearButtonGlyph.centerYAnchor.constraint(equalTo: clearButton.centerYAnchor)
        ])

        uploadButton.isHidden = !FileUploadFeatureFlag.isEnabled
    }

    @objc private func focusTextView() {
        guard !textView.isFirstResponder else { return }
        textView.becomeFirstResponder()
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var view: UIView? = touch.view
        while let current = view {
            if current === uploadButton || current === submitButton || current === clearButton {
                return false
            }
            if current === attachmentsStrip || current.isDescendant(of: attachmentsStrip) {
                return false
            }
            if current === self { break }
            view = current.superview
        }
        return true
    }

    @objc private func handleSwipeDown() {
        guard textView.isFirstResponder else { return }
        textView.resignFirstResponder()
    }

    // MARK: Actions

    @objc private func uploadTapped() {
        delegate?.ntpSearchBarDidTapUpload()
    }

    @objc private func submitTapped() {
        textView.commitPendingSuggestionIfValid()
        let text = (textView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard canSubmit(text: text) else { return }
        textView.resignFirstResponder()
        delegate?.ntpSearchBarDidSubmit(text)
    }

    func readyChatFiles() -> [AIChatFileQuery] {
        attachments.compactMap(\.chatFileQuery)
    }

    func addAttachment(_ attachment: OmniboxAttachment) {
        attachments.append(attachment)
        refreshAttachmentsStrip()
    }

    func removeAttachment(id: UUID) {
        attachments.removeAll { $0.id == id }
        previewImages.removeValue(forKey: id)
        refreshAttachmentsStrip()
    }

    func updateAttachment(id: UUID,
                          fileName: String,
                          layout: OmniboxAttachment.Layout,
                          state: OmniboxAttachment.State,
                          previewImages: [UUID: UIImage]) {
        guard let index = attachments.firstIndex(where: { $0.id == id }) else { return }
        self.previewImages = previewImages
        attachments[index] = OmniboxAttachment(id: id, fileName: fileName, layout: layout, state: state)
        refreshAttachmentsStrip()
    }

    func setAttachments(_ attachments: [OmniboxAttachment], previewImages: [UUID: UIImage]) {
        self.attachments = attachments
        self.previewImages = previewImages
        refreshAttachmentsStrip()
    }

    private func handleRemoveAttachment(id: UUID) {
        onRemoveAttachment?(id)
    }

    private func refreshAttachmentsStrip() {
        attachmentsStrip.setAttachments(attachments, previewImages: previewImages)
        let hasStrip = !attachments.isEmpty
        attachmentsStrip.isHidden = !hasStrip
        textViewTopConstraint.constant = hasStrip
            ? UX.textPadding + UX.attachmentStripHeight
            : UX.textPadding
        updateSubmitState(for: textView.text ?? "")
        updateLayoutForContent()
        delegate?.ntpSearchBarAttachmentsDidChange()
        delegate?.ntpSearchBarNeedsSuggestionsLayoutUpdate()
    }

    private func canSubmit(text: String) -> Bool {
        let hasText = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        guard hasText else { return false }
        guard hasAttachments else { return true }
        return allAttachmentsReady
    }

    private func updateSubmitState(for text: String) {
        let enabled = canSubmit(text: text)
        submitButton.isEnabled = enabled
        if hasAttachments {
            if hasUploadingAttachments {
                submitButton.accessibilityHint = String.localized(.uploadSubmitWaitingForUpload)
            } else if !allAttachmentsReady {
                submitButton.accessibilityHint = String.localized(.uploadSubmitUploadFailed)
            } else {
                submitButton.accessibilityHint = nil
            }
        } else {
            submitButton.accessibilityHint = nil
        }
        applySubmitButtonColors()
    }

    @objc private func clearTapped() {
        // Wipe the text but keep focus so the user can keep typing without
        // re-tapping the pill.
        textView.clearText()
        placeholderLabel.isHidden = false
        updateSubmitState(for: "")
        updateCounter(for: "")
        updateClearButtonVisibility(for: "")
        updateLayoutForContent()
        onContentChange?("")
    }

    /// Recomputes the textView height (and therefore the pill height) from
    /// the current content. The pill grows from `minHeight` up to `maxHeight`;
    /// past the cap the textView starts scrolling internally instead of
    /// pushing further upward.
    private func updateLayoutForContent() {
        let contentHeight = textView.contentSize.height
        let maxTextHeight = UX.maxTextHeight - (hasAttachments ? UX.attachmentStripHeight : 0)
        let clamped = min(maxTextHeight, max(UX.minTextHeight, contentHeight))
        if textViewHeightConstraint.constant != clamped {
            textViewHeightConstraint.constant = clamped
        }
        // The textView always has scrolling enabled so the explicit height
        // constraint drives layout. Internal scrolling kicks in naturally
        // once the content exceeds `maxTextHeight`.
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
        placeholderLabel.textColor = colors.ecosia.textSecondary
        textView.applyTheme(
            markedTextStyle: [.backgroundColor: colors.ecosia.backgroundTertiary],
            textColor: colors.ecosia.textPrimary,
            tintColor: colors.ecosia.textPrimary
        )
        applyBorderColor()
        applySubmitButtonColors()
        applyCounterColor()
        uploadButton.applyTheme(theme: theme)
        attachmentsStrip.applyTheme(theme: theme)
        // Clear button: dark filled pill with a light glyph, matching the
        // Figma design.
        // Only the inner 16×16 disc carries the dark fill; the surrounding
        // 40×40 button frame stays transparent so it doesn't read as a
        // larger pill. The X glyph is its own `UIImageView` (template
        // rendered), so the tint lives on the glyph directly rather than
        // travelling through the button's internal imageView.
        clearButton.backgroundColor = .clear
        clearButtonCircle.backgroundColor = colors.ecosia.textPrimary
        clearButtonGlyph.tintColor = colors.ecosia.backgroundElevation2
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

    func setAutocompleteSuggestion(_ suggestion: String?) {
        textView.setAutocompleteSuggestion(suggestion)
        refreshChromeFromTextView()
    }

    private func refreshChromeFromTextView() {
        let text = textView.text ?? ""
        let hasVisibleContent = !text.isEmpty || textView.hasInlineCompletion
        placeholderLabel.isHidden = hasVisibleContent
        updateSubmitState(for: text)
        updateCounter(for: text)
        updateClearButtonVisibility(for: text)
        updateLayoutForContent()
        onContentChange?(text)
    }
}

// MARK: - NTPLocationTextViewDelegate

extension NTPSearchBarView: NTPLocationTextViewDelegate {
    func locationTextView(_ textView: NTPLocationTextView, didEnterText text: String) {
        refreshChromeFromTextView()
        delegate?.ntpSearchBarTextDidChange(text)
    }

    func locationTextViewNeedsSearchReset(_ textView: NTPLocationTextView) {
        delegate?.ntpSearchBarNeedsSearchReset()
    }
}

// MARK: - UITextViewDelegate

extension NTPSearchBarView: @MainActor @preconcurrency UITextViewDelegate {

    func textViewDidBeginEditing(_ textView: UITextView) {
        applyBorderColor()
        onFocusChange?(true)
        delegate?.ntpSearchBarDidBeginEditing()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        (textView as? NTPLocationTextView)?.didEndEditing()
        if delegate?.ntpSearchBarIsSuggestionsOverlayVisible() == true {
            (textView as? NTPLocationTextView)?.stripInlineAutocomplete()
        } else {
            (textView as? NTPLocationTextView)?.commitPendingSuggestionIfValid()
        }
        refreshChromeFromTextView()
        applyBorderColor()
        onFocusChange?(false)
        delegate?.ntpSearchBarDidCancel()
    }

    func textViewDidChange(_ textView: UITextView) {
        (textView as? NTPLocationTextView)?.editingChanged()
        refreshChromeFromTextView()
    }

    func textView(_ textView: UITextView,
                  shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool {
        // Treat Return as submit instead of inserting a newline.
        if text == "\n" {
            submitTapped()
            return false
        }

        if let locationTextView = textView as? NTPLocationTextView,
           !locationTextView.willChange(range: range, replacement: text) {
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
