// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Shared

protocol FindInPageBarDelegate: AnyObject {
    func findInPage(_ findInPage: FindInPageBar, didTextChange text: String)
    func findInPage(_ findInPage: FindInPageBar, didFindPreviousWithText text: String)
    func findInPage(_ findInPage: FindInPageBar, didFindNextWithText text: String)
    func findInPageDidPressClose(_ findInPage: FindInPageBar)
}

// Ecosia: Custom FindInPage UI
//private struct FindInPageUX {
//    static let ButtonColor = UIColor.black
//    static let MatchCountColor = UIColor.Photon.Grey40
//    static let MatchCountFont = UIConstants.DefaultChromeFont
//    static let SearchTextColor = UIColor.Photon.Orange60
//    static let SearchTextFont = UIConstants.DefaultChromeFont
//    static let TopBorderColor = UIColor.Photon.Grey20
//}

class FindInPageBar: UIView {
    weak var delegate: FindInPageBarDelegate?
    fileprivate let searchView = UIView()
    fileprivate let searchText = UITextField()
    fileprivate let matchCountView = UILabel()
    fileprivate let previousButton = UIButton()
    fileprivate let nextButton = UIButton()
    fileprivate let closeButton = UIButton()
    fileprivate let topBorder = UIView()

    private static let savedTextKey = "findInPageSavedTextKey"
    // Ecosia: Custom FindInPage UI
    private let barHeight: CGFloat = 60
    private let searchViewTopBottomSpacing: CGFloat = 8

    var currentResult = 0 {
        didSet {
            if totalResults > 500 {
                matchCountView.text = "\(currentResult)/500+"
            } else {
                matchCountView.text = "\(currentResult)/\(totalResults)"
            }
        }
    }

    var totalResults = 0 {
        didSet {
            if totalResults > 500 {
                matchCountView.text = "\(currentResult)/500+"
            } else {
                matchCountView.text = "\(currentResult)/\(totalResults)"
            }
            previousButton.isEnabled = totalResults > 1
            nextButton.isEnabled = previousButton.isEnabled
        }
    }

    var text: String? {
        get {
            return searchText.text
        }

        set {
            searchText.text = newValue
            didTextChange(searchText)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupViews()

        self.snp.makeConstraints { make in
            make.height.equalTo(barHeight)
        }
        
        searchView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(searchViewTopBottomSpacing)
            make.bottom.equalToSuperview().inset(searchViewTopBottomSpacing)
        }
        
        searchText.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        searchText.setContentHuggingPriority(.defaultLow, for: .horizontal)
        searchText.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        matchCountView.snp.makeConstraints { make in
            make.leading.equalTo(searchText.snp.trailing)
            make.trailing.equalToSuperview().inset(13)
            make.centerY.equalToSuperview()
        }
        matchCountView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        matchCountView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        previousButton.snp.makeConstraints { make in
            make.leading.equalTo(searchView.snp.trailing).offset(14)
            make.centerY.equalToSuperview()
        }

        nextButton.snp.makeConstraints { make in
            make.leading.equalTo(previousButton.snp.trailing).offset(29)
            make.centerY.equalToSuperview()
        }

        closeButton.snp.makeConstraints { make in
            make.leading.equalTo(nextButton.snp.trailing).offset(14)
            make.trailing.equalToSuperview().inset(14)
            make.trailing.centerY.equalToSuperview()
        }

        topBorder.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.left.right.top.equalToSuperview()
        }
        
        // Ecosia: Make custom UI response to display theme change
        NotificationCenter.default.addObserver(self, selector: #selector(setupViews), name: .DisplayThemeChanged, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Ecosia: Custom FindInPage UI
    @objc private func setupViews() {
        backgroundColor = .theme.ecosia.secondaryBackground
        
        searchView.backgroundColor = .theme.ecosia.tertiaryBackground
        searchView.layer.cornerRadius = (barHeight - 2*searchViewTopBottomSpacing)/2
        addSubview(searchView)

        searchText.addTarget(self, action: #selector(didTextChange), for: .editingChanged)
        searchText.textColor = .theme.ecosia.primaryText
        searchText.font = .preferredFont(forTextStyle: .body)
        searchText.placeholder = .localized(.findInPage)
        searchText.autocapitalizationType = .none
        searchText.autocorrectionType = .no
        searchText.inputAssistantItem.leadingBarButtonGroups = []
        searchText.inputAssistantItem.trailingBarButtonGroups = []
        searchText.enablesReturnKeyAutomatically = true
        searchText.returnKeyType = .search
        searchText.accessibilityIdentifier = "FindInPage.searchField"
        searchText.delegate = self
        searchView.addSubview(searchText)

        matchCountView.textColor = .theme.ecosia.secondaryText
        matchCountView.font = .preferredFont(forTextStyle: .footnote)
        matchCountView.textAlignment = .right
        matchCountView.isHidden = true
        matchCountView.accessibilityIdentifier = "FindInPage.matchCount"
        searchView.addSubview(matchCountView)
        
        previousButton.setImage(UIImage(named: "find_previous")?.withRenderingMode(.alwaysTemplate), for: .normal)
        previousButton.tintColor = .theme.ecosia.primaryIcon
        previousButton.isEnabled = false
        previousButton.accessibilityLabel = .FindInPagePreviousAccessibilityLabel
        previousButton.addTarget(self, action: #selector(didFindPrevious), for: .touchUpInside)
        previousButton.accessibilityIdentifier = "FindInPage.find_previous"
        addSubview(previousButton)

        nextButton.setImage(UIImage(named: "find_next")?.withRenderingMode(.alwaysTemplate), for: .normal)
        nextButton.tintColor = .theme.ecosia.primaryIcon
        nextButton.isEnabled = false
        nextButton.accessibilityLabel = .FindInPageNextAccessibilityLabel
        nextButton.addTarget(self, action: #selector(didFindNext), for: .touchUpInside)
        nextButton.accessibilityIdentifier = "FindInPage.find_next"
        addSubview(nextButton)

        closeButton.setTitle(.localized(.done), for: .normal)
        closeButton.setTitleColor(.theme.ecosia.primaryButton, for: .normal)
        closeButton.accessibilityLabel = .FindInPageDoneAccessibilityLabel
        closeButton.addTarget(self, action: #selector(didPressClose), for: .touchUpInside)
        closeButton.accessibilityIdentifier = "FindInPage.close"
        addSubview(closeButton)

        topBorder.backgroundColor = .theme.ecosia.border
        addSubview(topBorder)
    }

    @discardableResult override func becomeFirstResponder() -> Bool {
        searchText.becomeFirstResponder()
        return super.becomeFirstResponder()
    }

    @objc fileprivate func didFindPrevious(_ sender: UIButton) {
        delegate?.findInPage(self, didFindPreviousWithText: searchText.text ?? "")
    }

    @objc fileprivate func didFindNext(_ sender: UIButton) {
        delegate?.findInPage(self, didFindNextWithText: searchText.text ?? "")
    }

    @objc fileprivate func didTextChange(_ sender: UITextField) {
        matchCountView.isHidden = searchText.text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true
        saveSearchText(searchText.text)
        delegate?.findInPage(self, didTextChange: searchText.text ?? "")
    }

    @objc fileprivate func didPressClose(_ sender: UIButton) {
        delegate?.findInPageDidPressClose(self)
    }

    private func saveSearchText(_ searchText: String?) {
        guard let text = searchText, !text.isEmpty else { return }
        UserDefaults.standard.set(text, forKey: FindInPageBar.savedTextKey)
    }

    static var retrieveSavedText: String? {
        return UserDefaults.standard.object(forKey: FindInPageBar.savedTextKey) as? String
    }
}

extension FindInPageBar: UITextFieldDelegate {
    // Keyboard with a .search returnKeyType doesn't dismiss when return pressed. Handle this manually.
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == "\n" {
            textField.resignFirstResponder()
            return false
        }
        return true
    }
}
