// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Ecosia

// MARK: - Delegate

@MainActor
protocol NTPSearchBarDelegate: AnyObject {
    /// Called when the user commits a search (Return key or submit button).
    func ntpSearchBarDidSubmit(_ searchTerm: String)
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

    static let height: CGFloat = 110

    private enum UX {
        static let submitButtonSize: CGFloat = .ecosia.space._3l
        static let shadowOpacity: Float = 0.10
        static let shadowRadius: CGFloat = 12
        static let shadowOffset = CGSize(width: 0, height: 4)
    }

    weak var delegate: NTPSearchBarDelegate?

    /// Fires whenever the field's first-responder state changes. Use this from
    /// the host (e.g. HomepageViewController) to drive focus-only chrome like
    /// the top-right close button.
    var onFocusChange: ((Bool) -> Void)?

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

    private var currentTheme: Theme?

    /// Current text content. Mirrors `textView.text` but lets callers drive
    /// programmatic changes (e.g. accepting a tapped suggestion).
    var text: String {
        get { textView.text ?? "" }
        set {
            textView.text = newValue
            placeholderLabel.isHidden = !newValue.isEmpty
            updateSubmitState(for: newValue)
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
        layer.shadowOpacity = UX.shadowOpacity
        layer.shadowRadius = UX.shadowRadius
        layer.shadowOffset = UX.shadowOffset
        layer.shadowColor = UIColor.black.cgColor

        addSubview(textView)
        addSubview(placeholderLabel)
        addSubview(submitButton)

        textView.delegate = self
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)

        // Tapping anywhere on the pill (including padding around the textView)
        // focuses the field — without this, only the small intrinsic-size textView
        // frame is tappable.
        let focusTap = UITapGestureRecognizer(target: self, action: #selector(focusTextView))
        focusTap.cancelsTouchesInView = false
        addGestureRecognizer(focusTap)

        NSLayoutConstraint.activate([
            // textView fills the entire pill — submit button floats over the
            // bottom-right corner.
            textView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .ecosia.space._m),
            textView.topAnchor.constraint(equalTo: topAnchor, constant: .ecosia.space._m),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.ecosia.space._m),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -.ecosia.space._m),

            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor),
            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor),
            placeholderLabel.trailingAnchor.constraint(equalTo: textView.trailingAnchor),

            // Submit button sits in the bottom-right corner of the pill,
            // floating over the textView.
            submitButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.ecosia.space._1s),
            submitButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -.ecosia.space._1s),
            submitButton.widthAnchor.constraint(equalToConstant: UX.submitButtonSize),
            submitButton.heightAnchor.constraint(equalToConstant: UX.submitButtonSize)
        ])
    }

    @objc private func focusTextView() {
        guard !textView.isFirstResponder else { return }
        textView.becomeFirstResponder()
    }

    // MARK: Actions

    @objc private func submitTapped() {
        let text = (textView.text ?? "").trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        textView.resignFirstResponder()
        delegate?.ntpSearchBarDidSubmit(text)
    }

    private func updateSubmitState(for text: String) {
        let hasContent = !text.trimmingCharacters(in: .whitespaces).isEmpty
        submitButton.isEnabled = hasContent
        applySubmitButtonColors()
    }

    private func applySubmitButtonColors() {
        guard let colors = currentTheme?.colors else { return }
        submitButton.backgroundColor = .clear
        submitButton.tintColor = submitButton.isEnabled
            ? colors.ecosia.textPrimary
            : colors.ecosia.textSecondary
    }

    // MARK: ThemeApplicable

    func applyTheme(theme: any Theme) {
        currentTheme = theme
        let colors = theme.colors

        backgroundColor = colors.ecosia.backgroundElevation2
        textView.textColor = colors.ecosia.textPrimary
        textView.tintColor = colors.ecosia.textPrimary
        placeholderLabel.textColor = colors.ecosia.textSecondary
        applySubmitButtonColors()
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
        onFocusChange?(true)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        delegate?.ntpSearchBarDidCancel()
        onFocusChange?(false)
    }

    func textViewDidChange(_ textView: UITextView) {
        let text = textView.text ?? ""
        placeholderLabel.isHidden = !text.isEmpty
        updateSubmitState(for: text)
        delegate?.ntpSearchBarTextDidChange(text)
    }

    func textView(_ textView: UITextView,
                  shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool {
        // Treat Return as submit instead of inserting a newline.
        if text == "\n" {
            submitTapped()
            return false
        }
        return true
    }
}
