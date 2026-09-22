// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

class EcosiaAppIconTest: XCTestCase {

    func test_DisplayNames_areSet() throws {
        for specificAppIcon in AppIcon.allCases {
            let displayName = EcosiaAppIcon.displayName(icon: specificAppIcon)
            XCTAssert(displayName.isEmpty == false)
        }
    }

    func test_imageSet_AssetNames_areSet() throws {
        for specificAppIcon in AppIcon.allCases {
            let imageSetAssetName = EcosiaAppIcon.imageSetAssetName(icon: specificAppIcon)
            XCTAssert(imageSetAssetName.isEmpty == false)
            XCTAssertFalse(imageSetAssetName.contains("AppIcon"))
        }
    }

    func test_AppIcon_assetNames_areSet() throws {
        for specificAppIcon in AppIcon.allCases {
            let appIconAssetName = EcosiaAppIcon.appIconAssetName(icon: specificAppIcon)

            if specificAppIcon == AppIcon.ecosiaLight {
                XCTAssertNil(appIconAssetName)
                continue
            }

            XCTAssert(appIconAssetName!.isEmpty == false)
            XCTAssertTrue(appIconAssetName!.hasSuffix("AppIcon"))
        }
    }

    func test_defaultAppIcon_isSetTo_EcosiaLight() throws {
        let defaultAppIcon = EcosiaAppIcon.defaultAppIcon()
        XCTAssert(defaultAppIcon == AppIcon.ecosiaLight)
    }
}
