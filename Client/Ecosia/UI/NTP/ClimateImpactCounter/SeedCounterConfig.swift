// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct SeedCounterConfig {
    let sparklesAnimationDuration: Double
    let levels: [SeedLevel]

    struct SeedLevel: Codable {
        let level: Int
        let requiredSeeds: Int
    }
}

extension SeedCounterConfig: Decodable {}
