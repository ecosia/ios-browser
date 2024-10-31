// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
@testable import Client

extension AnalyticsSpyTests {
    func setReadingList(url: String) {
        profileMock.readingList.createRecordWithURL(url, title: "test", addedBy: "test")
    }
    
    func setBookmark(url: String) {
        profileMock.places.createBookmark(parentGUID: BookmarkRoots.MobileFolderGUID, url: url, title: "test", position: 0)
    }
    
    func setPinnedSite(url: String) {
        _ = profileMock.pinnedSites.addPinnedTopSite(Site(url: url, title: "test"))
    }
}
