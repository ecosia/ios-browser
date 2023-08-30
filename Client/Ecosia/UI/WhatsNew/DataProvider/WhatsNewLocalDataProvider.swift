// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct LocalDataProvider: DataProvider {
    
    private let items: [WhatsNewItem] = [
        WhatsNewItem(imageURL: Bundle.main.url(forResource: "tree", withExtension: "pdf"),
                     title: .localized(.whatsNewFirstItemTitle),
                     subtitle: .localized(.whatsNewFirstItemDescription)),
        WhatsNewItem(imageURL: Bundle.main.url(forResource: "customisation", withExtension: "pdf"),
                     title: .localized(.whatsNewSecondItemTitle),
                     subtitle: .localized(.whatsNewSecondItemDescription)),
    ]
    
    func fetchData() throws -> [WhatsNewItem] {
        items
    }
}
