// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

// Note: There's also an EcosiaForceWallpaperRefresh in Ecosia debug settings
// (Client/Ecosia/Settings/EcosiaDebugSettings.swift)
// This Firefox version is kept separate for Firefox-style debug menu
@MainActor
class ForceWallpaperRefresh: HiddenSetting {
    override var title: NSAttributedString? {
        guard let theme else { return nil }
        return NSAttributedString(string: "Force wallpaper refresh",
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override var status: NSAttributedString? {
        guard let theme else { return nil }
        return NSAttributedString(string: "Clear cache & fetch latest metadata",
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textSecondary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let confirmAlert = AlertController(
            title: "Force Wallpaper Refresh?",
            message: "This will clear cached wallpaper data and fetch the latest metadata from the network.",
            preferredStyle: .alert
        )

        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        confirmAlert.addAction(UIAlertAction(title: "Refresh", style: .default) { _ in
            Task { @MainActor in
                // Reset metadata last checked date to force refresh
                UserDefaults.standard.removeObject(forKey: PrefsKeys.Wallpapers.MetadataLastCheckedDate)

                // Trigger wallpaper update
                await WallpaperManager().checkForUpdates()

                let successAlert = AlertController(
                    title: "Wallpaper Refresh Complete ✅",
                    message: "Metadata has been refreshed. Open a new tab to see updated wallpapers.",
                    preferredStyle: .alert
                )
                navigationController?.topViewController?.present(successAlert, animated: true) {
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        successAlert.dismiss(animated: true)
                    }
                }
            }
        })

        navigationController?.topViewController?.present(confirmAlert, animated: true)
    }
}
