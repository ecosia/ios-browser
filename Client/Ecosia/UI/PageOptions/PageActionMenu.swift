// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

class PageActionMenu: UIViewController {

    struct UX {
        static let Spacing: CGFloat = 16
        static let EmptyHeader = "EmptyHeader"
        static let CellName = "PageActionCell"
        static let RowHeight: CGFloat = 50
    }

    // MARK: - Variables
    private var tableView = UITableView(frame: .zero, style: .insetGrouped)
    let viewModel: PhotonActionSheetViewModel

    // MARK: - Init

    init(viewModel: PhotonActionSheetViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)

        title = viewModel.title
        modalPresentationStyle = viewModel.modalStyle
        tableView.estimatedRowHeight = UX.RowHeight
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        view.accessibilityIdentifier = "Action Sheet"
        setupConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        applyTheme()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UX.CellName)
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: UX.EmptyHeader)
        tableView.sectionHeaderHeight = UX.Spacing
        tableView.sectionFooterHeight = 0

        tableView.accessibilityIdentifier = "Context Menu"
        tableView.translatesAutoresizingMaskIntoConstraints = false
    }

    // MARK: - Setup

    private func setupConstraints() {
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension PageActionMenu: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.actions.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.actions[section].count
    }

    func tableView(_ tableView: UITableView, hasFullWidthSeparatorForRowAtIndexPath indexPath: IndexPath) -> Bool {
        return false
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UX.CellName, for: indexPath)
        cell.backgroundColor = .theme.ecosia.ntpImpactBackground
        let actions = viewModel.actions[indexPath.section][indexPath.row]
        let item = actions.items.first!

        cell.textLabel?.text = item.currentTitle
        cell.detailTextLabel?.text = item.text

        cell.accessibilityIdentifier = item.iconString ?? item.accessibilityId
        cell.accessibilityLabel = item.currentTitle


        if let iconName = item.iconString {
            cell.imageView?.image = UIImage(named: iconName)
            //setupActionName(action: item, name: iconName)
        } else {
            cell.imageView?.image = nil
        }
        return cell
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let actions = viewModel.actions[indexPath.section][indexPath.row]
        let item = actions.items.first!
        dismiss(animated: true) {
            if let handler = item.tapHandler {
                handler(item)
            }
        }
    }
}

// MARK: - NotificationThemeable
extension PageActionMenu: NotificationThemeable {

    func applyTheme() {
        tableView.reloadData()
        tableView.backgroundColor = .theme.ecosia.ntpBackground
    }
}
