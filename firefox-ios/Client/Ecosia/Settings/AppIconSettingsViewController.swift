// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Ecosia

/// Displays a list of available app icons and lets the user pick one.
final class AppIconSettingsViewController: SettingsTableViewController {

    private let iconManager: AppIconManager

    init(windowUUID: WindowUUID,
         iconManager: AppIconManager = .shared) {
        self.iconManager = iconManager
        super.init(style: .insetGrouped, windowUUID: windowUUID)
        title = .localized(.appIcon)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func generateSettings() -> [SettingSection] {
        let iconSettings: [Setting] = AppIcon.allCases.map { icon in
            AppIconSelectionSetting(
                icon: icon,
                isSelected: icon == iconManager.currentIcon,
                theme: themeManager.getCurrentTheme(for: windowUUID),
                delegate: self
            )
        }
        return [SettingSection(title: nil, children: iconSettings)]
    }
}

// MARK: - AppIconSelectionDelegate

protocol AppIconSelectionDelegate: AnyObject {
    func didSelect(icon: AppIcon)
}

extension AppIconSettingsViewController: AppIconSelectionDelegate {
    func didSelect(icon: AppIcon) {
        guard icon != iconManager.currentIcon else { return }
        // Deselect rows to end the table view interaction before the
        // system presents its icon-change confirmation alert.
        if let selected = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selected, animated: true)
        }
        iconManager.setIcon(icon) { [weak self] error in
            if let error {
                let alert = UIAlertController(
                    title: nil,
                    message: error.localizedDescription,
                    preferredStyle: .alert
                )
                alert.addAction(.init(title: .localized(.done), style: .default))
                self?.present(alert, animated: true)
                return
            }
            self?.settings = self?.generateSettings() ?? []
            self?.tableView.reloadData()
        }
    }
}

// MARK: - AppIconSelectionSetting

/// A single row in the icon picker list showing a checkmark for the active icon.
final class AppIconSelectionSetting: Setting {
    private let icon: AppIcon
    private let isSelected: Bool
    private weak var selectionDelegate: AppIconSelectionDelegate?

    init(icon: AppIcon,
         isSelected: Bool,
         theme: Theme,
         delegate: AppIconSelectionDelegate) {
        self.icon = icon
        self.isSelected = isSelected
        self.selectionDelegate = delegate
        let title = NSAttributedString(string: .localized(icon.localizedTitleKey))
        super.init(title: title)
        self.theme = theme
    }

    override var accessoryType: UITableViewCell.AccessoryType {
        isSelected ? .checkmark : .none
    }

    override var accessibilityIdentifier: String? {
        "appIcon_\(icon.rawValue)"
    }

    override func onClick(_ navigationController: UINavigationController?) {
        selectionDelegate?.didSelect(icon: icon)
    }

    override func onConfigureCell(_ cell: UITableViewCell, theme: Theme) {
        super.onConfigureCell(cell, theme: theme)
        let previewImage = UIImage(named: icon.previewImageName)
        cell.imageView?.image = previewImage
        cell.imageView?.layer.cornerRadius = 12
        cell.imageView?.clipsToBounds = true
    }
}
