// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Common
import XCTest

/// Firefox icons that Ecosia's build shows but its asset catalogs once lacked. `UIImage(named:)`
/// returns nil for a missing asset and the row or button just draws no icon (MOB-5309: the 147
/// upgrade left out `summarizerLarge`, so "Summarize page" had none). Names Ecosia never shows are
/// in `EcosiaUpgrade/tools/missing-image-assets.allow`; `missing_image_assets.py` checks every name.
final class ImageIdentifierAssetTests: XCTestCase {
    func testIconsEcosiaShows_haveAnAsset() {
        let names = [
            // Page menu: "Summarize page".
            StandardImageIdentifiers.Large.summarizer,
            // Page menu: the "Protections" header button, on and off.
            StandardImageIdentifiers.Small.shieldCheckmarkFill,
            StandardImageIdentifiers.Small.shieldSlashFillMulticolor,
            // Page menu, "More": "Remove from shortcuts" and "Save as PDF".
            StandardImageIdentifiers.Large.pinFill,
            StandardImageIdentifiers.Large.saveFile,
            // Bookmarks: the "…" button on each row and the "New folder" row in Edit Bookmark.
            StandardImageIdentifiers.Large.ellipsis,
            StandardImageIdentifiers.Large.newFolder
        ]
        for name in names {
            XCTAssertNotNil(UIImage(named: name), "no image named \(name)")
        }
    }
}
