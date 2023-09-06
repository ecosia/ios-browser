// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Core

struct WhatsNewJSONDataProvider: WhatsNewDataProvider {
    
    let jsonData: Data?
    private struct WhatsNewItemRoot: Decodable {
        let items: [RemoteWhatsNewItem]
    }

    private struct RemoteWhatsNewItem: Decodable {
        let imageURL: URL
        let title: String
        let subtitle: String
    }

    func getData() throws -> [WhatsNewItem] {
        guard let jsonData else { return [] }
                
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let root = try decoder.decode(WhatsNewItemRoot.self, from: jsonData)
            return root.items.map {
                WhatsNewItem(imageURL: $0.imageURL,
                                        title: $0.title,
                                        subtitle: $0.subtitle)
            }
        } catch {
            print("Error decoding JSON: \(error)")
            return []
        }
    }
}
