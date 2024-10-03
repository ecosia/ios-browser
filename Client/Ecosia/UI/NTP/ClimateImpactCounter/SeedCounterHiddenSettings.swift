// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Foundation

final class AddOneSeed: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(
            string: "Debug: Add One Seed",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.legacyTheme.tableView.rowText]
        )
    }

    override var status: NSAttributedString? {
        let seedsCollected = SeedProgressManager.loadSeedsCollected()
        let level = SeedProgressManager.loadLevel()
        return NSAttributedString(
            string: "Seeds: \(seedsCollected) | Level: \(level)",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.legacyTheme.tableView.rowText]
        )
    }

    override func onClick(_ navigationController: UINavigationController?) {
        // Add 1 seed to the counter
        SeedProgressManager.addSeeds(1)
        settings.tableView.reloadData()
    }
}

final class AddFiveSeeds: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Add Five Seeds", attributes: [NSAttributedString.Key.foregroundColor: UIColor.legacyTheme.tableView.rowText])
    }

    override var status: NSAttributedString? {
        let seedsCollected = SeedProgressManager.loadSeedsCollected()
        let level = SeedProgressManager.loadLevel()
        return NSAttributedString(string: "Seeds: \(seedsCollected) | Level: \(level)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.legacyTheme.tableView.rowText])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        SeedProgressManager.addSeeds(5)
        settings.tableView.reloadData()
    }
}

final class ResetSeedCounter: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Reset Seed Counter", attributes: [NSAttributedString.Key.foregroundColor: UIColor.legacyTheme.tableView.rowText])
    }

    override var status: NSAttributedString? {
        let seedsCollected = SeedProgressManager.loadSeedsCollected()
        let level = SeedProgressManager.loadLevel()
        return NSAttributedString(string: "Seeds: \(seedsCollected) | Level: \(level)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.legacyTheme.tableView.rowText])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        SeedProgressManager.resetCounter()
        settings.tableView.reloadData()
    }
}
