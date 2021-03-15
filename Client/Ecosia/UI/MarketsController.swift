/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Core
import UIKit

final class Markets {
    static private (set) var all: [Market] = {
        return (try? JSONDecoder().decode([Market].self, from: Data(contentsOf: Bundle.main.url(forResource: "markets", withExtension: "json")!))) ?? []
    } ()

    static var current: String? {
        Markets.all.first { User.shared.marketCode == $0.id }.map {
            $0.name
        }
    }
}

final class MarketsController: ThemedTableViewController {
    private let identifier = "market"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.theme.ecosia.primaryBackground
        navigationItem.title = .localized(.searchRegion)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Markets.all.firstIndex { User.shared.marketCode == $0.id }.map {
            tableView.scrollToRow(at: .init(row: $0, section: 0), at: .middle, animated: true)
        }
    }

    override func tableView(_: UITableView, numberOfRowsInSection: Int) -> Int {
        Markets.all.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? ThemedTableViewCell(style: .default, reuseIdentifier: identifier)
        cell.textLabel!.text = Markets.all[cellForRowAt.row].name
        cell.textLabel!.textColor = UIColor.theme.tableView.rowText
        cell.accessoryType = User.shared.marketCode == Markets.all[cellForRowAt.row].id ? .checkmark : .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt: IndexPath) {
        guard Markets.all[didSelectRowAt.row].id != User.shared.marketCode else { return }
        User.shared.marketCode = Markets.all[didSelectRowAt.row].id
        tableView.reloadData()
        Analytics.shared.market(User.shared.marketCode.rawValue)
        Goodall.shared.refresh()
    }
}
