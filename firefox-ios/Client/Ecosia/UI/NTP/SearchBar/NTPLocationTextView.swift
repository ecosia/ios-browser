// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared

/// Multiline text input for the NTP omnibox with URL-bar autocomplete behaviour
/// ported from `LocationTextField` (marked-text suffix, hidden caret, backspace
/// drops only the completion, submit/tap commits the full match).
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
    private var pendingFullSuggestion: String?
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
            let query = self.normalizeString(self.textWithoutSuggestion() ?? "")
            self.autocompleteDelegate?.locationTextView(self, didEnterText: query)
        }
    }

    var hasActiveAutocomplete: Bool {
        markedTextRange != nil
    }

    override var accessibilityValue: String? {
        get { pendingFullSuggestion ?? text }
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
            _ = removeCompletion()
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
            _ = removeCompletion()
            return
        }

        let suggestionText = String(suggestion.dropFirst(normalized.count))
        isSettingMarkedText = true
        setMarkedText(suggestionText, selectedRange: NSRange())
        pendingFullSuggestion = suggestion
        isSettingMarkedText = false
        hideCursor = true
        forceResetCursor()
    }

    func applyCompletion() {
        if let pendingFullSuggestion {
            let committed = pendingFullSuggestion
            _ = removeCompletion()
            text = committed
            hideCursor = false
            selectedTextRange = textRange(from: endOfDocument, to: endOfDocument)
            return
        }

        let committed = text ?? ""
        let didRemoveCompletion = removeCompletion()
        text = committed
        hideCursor = false
        if didRemoveCompletion {
            selectedTextRange = textRange(from: endOfDocument, to: endOfDocument)
        }
    }

    func clearText() {
        text = ""
        _ = removeCompletion()
        autocompleteDelegate?.locationTextView(self, didEnterText: "")
    }

    func setTextWithoutSearching(_ value: String) {
        text = value
        hideCursor = markedTextRange != nil
        _ = removeCompletion()
    }

    // MARK: - UITextInput

    override func deleteBackward() {
        lastReplacement = ""
        hideCursor = false

        guard markedTextRange == nil else {
            _ = removeCompletion()
            forceResetCursor()
            return
        }

        super.deleteBackward()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with: UIEvent?) {
        guard isFirstResponder else {
            super.touchesBegan(touches, with: with)
            return
        }
        applyCompletion()
        super.touchesBegan(touches, with: with)
    }

    override func caretRect(for position: UITextPosition) -> CGRect {
        hideCursor ? .zero : super.caretRect(for: position)
    }

    override func setMarkedText(_ markedText: String?, selectedRange: NSRange) {
        isSettingMarkedText = true
        _ = removeCompletion()
        super.setMarkedText(markedText, selectedRange: selectedRange)
        isSettingMarkedText = false
    }

    // MARK: - Editing notifications

    @objc
    func editingChanged() {
        guard !isSettingMarkedText else { return }

        hideCursor = markedTextRange != nil

        let isKeyboardReplacingText = lastReplacement != nil
        if isKeyboardReplacingText, markedTextRange == nil {
            notifyTextChanged?()
        } else {
            hideCursor = false
        }
    }

    func willChange(range: NSRange, replacement: String) {
        if lastReplacement == nil {
            autocompleteDelegate?.locationTextViewNeedsSearchReset(self)
        }
        lastReplacement = replacement
    }

    func didEndEditing() {
        lastReplacement = nil
        selectedTextRange = nil
    }

    // MARK: - Private

    @discardableResult
    private func removeCompletion() -> Bool {
        guard markedTextRange != nil else { return false }

        pendingFullSuggestion = nil
        hideCursor = false
        unmarkText()
        return true
    }

    private func textWithoutSuggestion() -> String? {
        // Marked autocomplete is provisional; committed text is the typed prefix.
        text
    }

    private func normalizeString(_ string: String) -> String {
        string.lowercased().stringByTrimmingLeadingCharactersInSet(CharacterSet.whitespaces)
    }

    private func forceResetCursor() {
        selectedTextRange = nil
        selectedTextRange = textRange(from: endOfDocument, to: endOfDocument)
    }
}
