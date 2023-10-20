// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared

struct WidgetKitInfoModel: Codable {
    var totalTrees: Int = 0

    static let userDefaults = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier)!

    static func save(model: WidgetKitInfoModel) {
        userDefaults.removeObject(forKey: PrefsKeys.WidgetKitInfoModelKey)
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(model) {
            userDefaults.set(encoded, forKey: PrefsKeys.WidgetKitInfoModelKey)
        }
    }

    static func get() -> WidgetKitInfoModel {
        if let userDefaultsModel = userDefaults.object(forKey: PrefsKeys.WidgetKitInfoModelKey) as? Data {
            do {
                let jsonDecoder = JSONDecoder()
                let model = try jsonDecoder.decode(WidgetKitInfoModel.self, from: userDefaultsModel)
                return model
            } catch {
                print("Error occured")
            }
        }
        return WidgetKitInfoModel()
    }
}
