// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import XCTest

@testable import Client

// Ecosia: the wallpapers feature must never be user-facing; these tests guard against regressions.
class WallpaperManagerTests: XCTestCase {
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: PrefsKeys.Wallpapers.ThumbnailsAvailable)
        super.tearDown()
    }

    func test_canSettingsBeShown_isFalse() {
        // Given a manager with no locally cached wallpaper thumbnails
        UserDefaults.standard.removeObject(forKey: PrefsKeys.Wallpapers.ThumbnailsAvailable)
        let subject = WallpaperManager()

        // When checking whether settings can be shown
        // Then they must never be shown
        XCTAssertFalse(subject.canSettingsBeShown)
    }

    func test_canSettingsBeShown_isFalse_evenWhenThumbnailsAreLocallyCached() {
        // Given a manager where thumbnails happen to already be available locally
        // (e.g. cached from before the feature was disabled)
        UserDefaults.standard.set(true, forKey: PrefsKeys.Wallpapers.ThumbnailsAvailable)
        let subject = WallpaperManager()

        // When checking whether settings can be shown
        // Then they must still never be shown
        XCTAssertFalse(subject.canSettingsBeShown)
    }
}
