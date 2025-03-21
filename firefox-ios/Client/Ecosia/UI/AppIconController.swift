// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Ecosia

final class AppIconController: ThemedTableViewController {
    private let identifier = "appicons"

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Choose your App Icon"
        navigationItem.largeTitleDisplayMode = .never
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        EcosiaIcon.allCases.firstIndex { User.shared.currentAppIcon == $0 }.map {
            tableView.scrollToRow(at: .init(row: $0, section: 0), at: .middle, animated: true)
        }
    }

    override func tableView(_: UITableView, numberOfRowsInSection: Int) -> Int {
        EcosiaIcon.allCases.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? ThemedTableViewCell(style: .default, reuseIdentifier: identifier)
        let market = EcosiaIcon.allCases[cellForRowAt.row]
        cell.textLabel?.text = market.rawValue
        cell.accessoryType = User.shared.currentAppIcon == EcosiaIcon.allCases[cellForRowAt.row] ? .checkmark : .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        AppIconManager.updateAppIcon(to: EcosiaIcon.allCases[indexPath.row])
        User.shared.currentAppIcon = EcosiaIcon.allCases[indexPath.row]
        tableView.reloadData()
    }

    override func applyTheme() {
        super.applyTheme()
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        tableView.tintColor = theme.colors.ecosia.brandPrimary
        view.backgroundColor = theme.colors.ecosia.ntpBackground
    }
}
