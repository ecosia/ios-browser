// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import XCTest

/// The toolbar's translate button draws nothing when its image is missing from the asset
/// catalogs (MOB-5282: the 147 upgrade deleted `translateActive`, so a translated page
/// showed an empty button).
final class TranslationIconAssetTests: XCTestCase {
    private typealias IconState = TranslationConfiguration.IconState

    func testEveryTranslateIconState_hasAnImage() {
        for state in [IconState.inactive, .loading, .active] {
            for isNova in [false, true] {
                guard let name = state.buttonImageName(isNovaDesignEnabled: isNova) else {
                    // `.loading` shows a spinner instead of an image.
                    continue
                }
                XCTAssertNotNil(UIImage(named: name), "\(state), nova: \(isNova): no image named \(name)")
            }
        }
    }
}
