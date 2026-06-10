// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared

/// Multiline NTP omnibox with `LocationTextField`-style inline URL completion
/// (marked-text suffix). UITextView commits marked text on backspace instead of
/// removing it, so we reset `text` to the stored user-typed prefix.
@MainActor
protocol NTPLocationTextViewDelegate: AnyObject {
    func locationTextView(_ textView: NTPLocationTextView, didEnterText text: String)
    func locationTextViewNeedsSearchReset(_ textView: NTPLocationTextView)
}

final class NTPLocationTextView: UITextView {
    weak var autocompleteDelegate: NTPLocationTextViewDelegate?

    private var lastReplacement: String?
    private var hideCursor = false
    private var isSettingMarkedText = false
    private var isExplicitCommit = false
    private var pendingFullSuggestion: String?
    /// Text the user typed before the inline suffix was shown; used to recover
    /// when UITextView commits marked text on backspace.
    private var userTypedText = ""
    private var notifyTextChanged: (() -> Void)?

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        font = .preferredFont(forTextStyle: .body)
        adjustsFontForContentSizeCategory = true
        backgroundColor = .clear
        textContainerInset = .zero
        textContainer.lineFragmentPadding = 0
        autocorrectionType = .no
        autocapitalizationType = .none
        spellCheckingType = .no
        returnKeyType = .search
        keyboardType = .webSearch
        enablesReturnKeyAutomatically = true
        textContentType = .URL

        notifyTextChanged = debounce(0.1) { [weak self] in
            guard let self, self.isFirstResponder else { return }
            let query = self.normalizeString(self.text ?? "")
            self.autocompleteDelegate?.locationTextView(self, didEnterText: query)
        }
    }

    var hasInlineCompletion: Bool {
        markedTextRange != nil || pendingFullSuggestion != nil
    }

    override var accessibilityValue: String? {
        get {
            if let pending = pendingFullSuggestion, isPendingSuggestionStillValid(for: pending) {
                return pending
            }
            return text
        }
        set { super.accessibilityValue = newValue }
    }

    func applyTheme(markedTextStyle: [NSAttributedString.Key: Any], textColor: UIColor, tintColor: UIColor) {
        self.markedTextStyle = markedTextStyle
        self.textColor = textColor
        self.tintColor = tintColor
    }

    func setAutocompleteSuggestion(_ suggestion: String?) {
        guard let suggestion else {
            hideCursor = false
            removeInlineCompletion()
            return
        }

        let searchText = text ?? ""

        guard isFirstResponder, markedTextRange == nil else {
            hideCursor = false
            return
        }

        let normalized = normalizeString(searchText)
        guard suggestion.hasPrefix(normalized), normalized.count < suggestion.count else {
            hideCursor = false
            removeInlineCompletion()
            return
        }

        userTypedText = searchText
        let suggestionText = String(suggestion.dropFirst(normalized.count))
        isSettingMarkedText = true
        super.setMarkedText(suggestionText, selectedRange: NSRange())
        pendingFullSuggestion = suggestion
        isSettingMarkedText = false
        hideCursor = true
        forceResetCursor()
    }

    /// Intercepts backspace before the change is applied. Returns `false` when
    /// the delete was handled by reverting to the user-typed prefix only.
    @discardableResult
    func willChange(range: NSRange, replacement: String) -> Bool {
        if lastReplacement == nil {
            autocompleteDelegate?.locationTextViewNeedsSearchReset(self)
        }
        lastReplacement = replacement

        if replacement.isEmpty, hasInlineCompletion {
            revertToUserTypedTextOnly()
            scheduleRevertToUserTypedTextOnly()
            return false
        }

        return true
    }

    func commitPendingSuggestionIfValid() {
        guard let pending = pendingFullSuggestion,
              isPendingSuggestionStillValid(for: pending) else {
            removeInlineCompletion()
            return
        }

        isExplicitCommit = true
        removeInlineCompletion()
        text = pending
        userTypedText = pending
        hideCursor = false
        selectedTextRange = textRange(from: endOfDocument, to: endOfDocument)
        isExplicitCommit = false
    }

    func clearText() {
        text = ""
        userTypedText = ""
        removeInlineCompletion()
        autocompleteDelegate?.locationTextView(self, didEnterText: "")
    }

    func setTextWithoutSearching(_ value: String) {
        text = value
        userTypedText = value
        removeInlineCompletion()
    }

    // MARK: - UITextInput

    override func deleteBackward() {
        lastReplacement = ""
        hideCursor = false

        if hasInlineCompletion {
            revertToUserTypedTextOnly()
            scheduleRevertToUserTypedTextOnly()
            return
        }

        super.deleteBackward()
    }

    override func caretRect(for position: UITextPosition) -> CGRect {
        hideCursor ? .zero : super.caretRect(for: position)
    }

    override func setMarkedText(_ markedText: String?, selectedRange: NSRange) {
        guard !isSettingMarkedText else {
            super.setMarkedText(markedText, selectedRange: selectedRange)
            return
        }
        isSettingMarkedText = true
        removeInlineCompletion()
        super.setMarkedText(markedText, selectedRange: selectedRange)
        isSettingMarkedText = false
    }

    // MARK: - Editing notifications

    @objc
    func editingChanged() {
        guard !isSettingMarkedText else { return }

        if revertAccidentalAutocompleteCommitIfNeeded() {
            return
        }

        discardStalePendingSuggestionIfNeeded()

        hideCursor = markedTextRange != nil

        let isKeyboardReplacingText = lastReplacement != nil
        if isKeyboardReplacingText, markedTextRange == nil {
            userTypedText = text ?? ""
            notifyTextChanged?()
        } else if !isKeyboardReplacingText {
            hideCursor = false
        }
    }

    func didEndEditing() {
        lastReplacement = nil
        selectedTextRange = nil
    }

    // MARK: - Private

    private func removeInlineCompletion() {
        pendingFullSuggestion = nil
        hideCursor = false
        if markedTextRange != nil {
            unmarkText()
        }
    }

    /// Drops the highlighted suffix by forcing visible text back to what the
    /// user typed — UITextView does not reliably honour `unmarkText()` alone.
    private func revertToUserTypedTextOnly() {
        isSettingMarkedText = true
        pendingFullSuggestion = nil
        hideCursor = false
        if markedTextRange != nil {
            unmarkText()
        }
        text = userTypedText
        forceResetCursor()
        isSettingMarkedText = false
    }

    /// UITextView may commit marked text after `shouldChangeTextIn` returns false.
    private func scheduleRevertToUserTypedTextOnly() {
        let typedSnapshot = userTypedText
        DispatchQueue.main.async { [weak self] in
            guard let self, self.text != typedSnapshot else { return }
            self.isSettingMarkedText = true
            self.pendingFullSuggestion = nil
            self.hideCursor = false
            if self.markedTextRange != nil {
                self.unmarkText()
            }
            self.text = typedSnapshot
            self.forceResetCursor()
            self.isSettingMarkedText = false
        }
    }

    /// Returns true when editing was corrected and callers should skip further handling.
    @discardableResult
    private func revertAccidentalAutocompleteCommitIfNeeded() -> Bool {
        guard !isExplicitCommit else { return false }

        let isBackspace = lastReplacement?.isEmpty == true
        let shouldRevert = (isBackspace && hasInlineCompletion) || shouldRevertCommittedAutocomplete()
        guard shouldRevert else { return false }

        revertToUserTypedTextOnly()
        scheduleRevertToUserTypedTextOnly()
        return true
    }

    private func shouldRevertCommittedAutocomplete() -> Bool {
        guard let pending = pendingFullSuggestion,
              !userTypedText.isEmpty,
              let current = text else {
            return false
        }

        let normalizedCurrent = normalizeString(current)
        let normalizedTyped = normalizeString(userTypedText)
        let normalizedPending = normalizeString(pending)
        return normalizedCurrent == normalizedPending && normalizedTyped != normalizedPending
    }

    private func discardStalePendingSuggestionIfNeeded() {
        guard pendingFullSuggestion != nil,
              markedTextRange == nil,
              !isPendingSuggestionStillValid() else {
            return
        }
        pendingFullSuggestion = nil
    }

    private func isPendingSuggestionStillValid(for suggestion: String? = nil) -> Bool {
        guard let suggestion = suggestion ?? pendingFullSuggestion,
              let typed = text else {
            return false
        }

        let normalizedTyped = normalizeString(typed)
        let normalizedSuggestion = normalizeString(suggestion)
        return normalizedSuggestion.hasPrefix(normalizedTyped)
            && normalizedTyped.count < normalizedSuggestion.count
    }

    private func normalizeString(_ string: String) -> String {
        string.lowercased().stringByTrimmingLeadingCharactersInSet(CharacterSet.whitespaces)
    }

    private func forceResetCursor() {
        selectedTextRange = nil
        selectedTextRange = textRange(from: endOfDocument, to: endOfDocument)
    }
}
