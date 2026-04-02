// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// Ecosia: NTP embedded search bar — Approach 1 spike
// Demonstrates that a real text input can be embedded in the NTP and wired to the
// existing browser navigation infrastructure without duplicating toolbar logic.
//
// Approach: reuse existing URL bar browsing logic (openBrowser / searchSuggestions)
// but render a custom Ecosia-branded text field pinned to the bottom of the NTP.
//
// Out of scope for this spike:
// - Suggestions panel appearing above the bar (needs a custom overlay view)
// - Autocomplete within the text field
// - Proper keyboard avoidance (collection view bottom inset adjustment)

import UIKit
import Common

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

// MARK: - View

final class NTPSearchBarView: UIView, ThemeApplicable {

    private enum UX {
        static let cornerRadius: CGFloat = 16
        static let height: CGFloat = 52
        static let textFieldLeadingPadding: CGFloat = 16
        static let textFieldTrailingSpacing: CGFloat = 8
        static let submitButtonTrailingPadding: CGFloat = 10
        static let submitButtonSize: CGFloat = 32
        static let shadowOpacity: Float = 0.12
        static let shadowRadius: CGFloat = 10
        static let shadowOffset = CGSize(width: 0, height: 2)
    }

    weak var delegate: NTPSearchBarDelegate?

    private lazy var textField: UITextField = .build { field in
        field.returnKeyType = .search
        field.clearButtonMode = .whileEditing
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.font = UIFont.systemFont(ofSize: 16)
        field.accessibilityIdentifier = "NTPSearchBarTextField"
    }

    private lazy var submitButton: UIButton = .build { button in
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
        let image = UIImage(systemName: "arrow.up", withConfiguration: symbolConfig)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.layer.cornerRadius = UX.submitButtonSize / 2
        button.accessibilityLabel = "Search"
        button.accessibilityIdentifier = "NTPSearchBarSubmitButton"
    }

    // MARK: Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Setup

    private func setup() {
        layer.cornerRadius = UX.cornerRadius
        layer.shadowOpacity = UX.shadowOpacity
        layer.shadowRadius = UX.shadowRadius
        layer.shadowOffset = UX.shadowOffset
        layer.shadowColor = UIColor.black.cgColor

        addSubview(textField)
        addSubview(submitButton)

        textField.delegate = self
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.textFieldLeadingPadding),
            textField.centerYAnchor.constraint(equalTo: centerYAnchor),
            textField.trailingAnchor.constraint(equalTo: submitButton.leadingAnchor, constant: -UX.textFieldTrailingSpacing),

            submitButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.submitButtonTrailingPadding),
            submitButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            submitButton.widthAnchor.constraint(equalToConstant: UX.submitButtonSize),
            submitButton.heightAnchor.constraint(equalToConstant: UX.submitButtonSize)
        ])
    }

    // MARK: Actions

    @objc private func submitTapped() {
        let text = (textField.text ?? "").trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        textField.resignFirstResponder()
        delegate?.ntpSearchBarDidSubmit(text)
    }

    // MARK: ThemeApplicable

    func applyTheme(theme: any Theme) {
        backgroundColor = theme.colors.layer2
        textField.textColor = theme.colors.textPrimary
        textField.attributedPlaceholder = NSAttributedString(
            string: .FirefoxHomepage.SearchBar.PlaceholderTitle,
            attributes: [.foregroundColor: theme.colors.textSecondary]
        )
        submitButton.backgroundColor = theme.colors.ecosia.buttonBackgroundPrimary
    }
}

// MARK: - UITextFieldDelegate

extension NTPSearchBarView: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.ntpSearchBarDidBeginEditing()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        let text = textField.text ?? ""
        if text.trimmingCharacters(in: .whitespaces).isEmpty {
            delegate?.ntpSearchBarDidCancel()
        }
    }

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        let current = (textField.text ?? "") as NSString
        let updated = current.replacingCharacters(in: range, with: string)
        delegate?.ntpSearchBarTextDidChange(updated)
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        submitTapped()
        return true
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        delegate?.ntpSearchBarTextDidChange("")
        return true
    }
}
