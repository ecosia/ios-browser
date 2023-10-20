// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WidgetKit
import Core

protocol InfoModelWidget {
    /// Write top sites to widgetkit
    static func writeWidgetKitTotalTrees()
}

final class WidgetInfoModelManager: InfoModelWidget {
        
    static func writeWidgetKitTotalTrees() {
        // save current total trees planted
        if #available(iOS 14.0, *) {
            // save current total trees planted
            WidgetKitInfoModel.save(model: WidgetKitInfoModel(totalTrees: Int(TreesProjection.shared.treesAt(.init()))))
            // Update widget timeline
            WidgetCenter.shared.reloadTimelines(ofKind: "Quick Actions - Medium With Counter")
        }
    }
}
