// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
//

import Foundation
import CoreData

extension SeedProgressEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SeedProgressEntity> {
        return NSFetchRequest<SeedProgressEntity>(entityName: "ProgressEntity")
    }

    @NSManaged public var level: Int16
    @NSManaged public var seedsCollected: Int16
    @NSManaged public var lastAppOpenDate: Date?

}

extension SeedProgressEntity : Identifiable {

}
