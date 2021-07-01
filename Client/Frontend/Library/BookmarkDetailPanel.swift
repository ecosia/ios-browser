/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage
import Shared
import XCGLogger
import Core

private let log = Logger.browserLogger

private let BookmarkDetailFieldCellIdentifier = "BookmarkDetailFieldCellIdentifier"
private let BookmarkDetailFolderCellIdentifier = "BookmarkDetailFolderCellIdentifier"

private struct BookmarkDetailPanelUX {
    static let FieldRowHeight: CGFloat = 58
    static let FolderIconSize = CGSize(width: 20, height: 20)
    static let IndentationWidth: CGFloat = 20
    static let MinIndentedContentWidth: CGFloat = 100
}

class BookmarkDetailPanelError: MaybeErrorType {
    public var description = "Unable to save BookmarkNode."
}

class BookmarkDetailPanel: SiteTableViewController {
    enum BookmarkDetailSection: Int, CaseIterable {
        case fields
    }

    enum BookmarkDetailFieldsRow: Int {
        case title
        case url
    }

    // Non-editable field(s) that all BookmarkNodes have.
    var bookmarkItemOrFolderTitle: String?
    var bookmarkItemPosition: Int?

    // Editable field(s) that only BookmarkItems have.
    var bookmarkItemURL: String?

    var isNew: Bool {
        return bookmarkItemPosition == nil
    }

    private var maxIndentationLevel: Int {
        return Int(floor((view.frame.width - BookmarkDetailPanelUX.MinIndentedContentWidth) / BookmarkDetailPanelUX.IndentationWidth))
    }

    init(profile: Profile, bookmarkItemPosition: Int?) {
        self.bookmarkItemPosition = bookmarkItemPosition

        super.init(profile: profile)

        self.tableView.accessibilityIdentifier = "Bookmark Detail"
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.register(TextFieldTableViewCell.self, forCellReuseIdentifier: BookmarkDetailFieldCellIdentifier)
        self.tableView.register(OneLineTableViewCell.self, forCellReuseIdentifier: BookmarkDetailFolderCellIdentifier)

        if let index = bookmarkItemPosition, index < profile.places.items.count {
            let page = profile.places.items[index]
            bookmarkItemOrFolderTitle = page.title
            bookmarkItemURL = page.urlString
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel) { _ in
            self.navigationController?.popViewController(animated: true)
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save) { _ in
            _ = self.save()
            self.navigationController?.popViewController(animated: true)
            if self.isNew, let bookmarksPanel = self.navigationController?.visibleViewController as? BookmarksPanel {
                bookmarksPanel.didAddBookmarkNode()
            }
        }

        if isNew {
            bookmarkItemURL = "https://"
        }

        updateSaveButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Focus the keyboard on the first text field.
        if let firstTextFieldCell = tableView.visibleCells.first(where: { $0 is TextFieldTableViewCell }) as? TextFieldTableViewCell {
            firstTextFieldCell.textField.becomeFirstResponder()
        }
    }

    override func applyTheme() {
        super.applyTheme()

        if let current = navigationController?.visibleViewController as? Themeable, current !== self {
            current.applyTheme()
        }

        tableView.backgroundColor = UIColor.theme.tableView.headerBackground
    }

    override func reloadData() {
        // Can be called while app backgrounded and the db closed, don't try to reload the data source in this case
        tableView.reloadData()
    }

    func updateSaveButton() {
        let url = URL(string: bookmarkItemURL ?? "")
        navigationItem.rightBarButtonItem?.isEnabled = url?.schemeIsValid == true && url?.host != nil
    }

    func save() -> Error? {
        guard let bookmarkItemURL = self.bookmarkItemURL, let url = URL(string: bookmarkItemURL) else {
            return BookmarkDetailPanelError()
        }

        let page = Core.Page(url: url, title: bookmarkItemOrFolderTitle ?? bookmarkItemURL)
        if isNew {
            profile.places.add(page)
        } else if let index = bookmarkItemPosition {
            profile.places.update(page, index: index)
        }
        return nil
    }

    // MARK: UITableViewDataSource | UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return BookmarkDetailSection.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Handle Title/URL editable field cells.
        guard let cell = tableView.dequeueReusableCell(withIdentifier: BookmarkDetailFieldCellIdentifier, for: indexPath) as? TextFieldTableViewCell else {
            return super.tableView(tableView, cellForRowAt: indexPath)
        }

        cell.delegate = self

        switch indexPath.row {
        case BookmarkDetailFieldsRow.title.rawValue:
            cell.titleLabel.text = Strings.BookmarkDetailFieldTitle
            cell.textField.text = bookmarkItemOrFolderTitle
            cell.textField.autocapitalizationType = .sentences
            cell.textField.keyboardType = .default
            return cell
        case BookmarkDetailFieldsRow.url.rawValue:
            cell.titleLabel.text = Strings.BookmarkDetailFieldURL
            cell.textField.text = bookmarkItemURL
            cell.textField.autocapitalizationType = .none
            cell.textField.keyboardType = .URL
            return cell
        default:
            return super.tableView(tableView, cellForRowAt: indexPath) // Should not happen.
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.section == BookmarkDetailSection.fields.rawValue else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }

        return BookmarkDetailPanelUX.FieldRowHeight
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as? SiteTableViewHeader
        header?.showBorder(for: .top, section != 0)
    }
}

extension BookmarkDetailPanel: TextFieldTableViewCellDelegate {
    func textFieldTableViewCell(_ textFieldTableViewCell: TextFieldTableViewCell, didChangeText text: String) {
        guard let indexPath = tableView.indexPath(for: textFieldTableViewCell) else {
            return
        }

        switch indexPath.row {
        case BookmarkDetailFieldsRow.title.rawValue:
            bookmarkItemOrFolderTitle = text
        case BookmarkDetailFieldsRow.url.rawValue:
            bookmarkItemURL = text
            updateSaveButton()
        default:
            log.warning("Received didChangeText: for a cell with an IndexPath that should not exist.")
        }
    }
}
