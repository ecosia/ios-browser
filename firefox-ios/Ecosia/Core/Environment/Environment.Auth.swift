// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public extension Environment {
    struct Auth: Equatable {
        let id: String
        let secret: String
    }

    var auth: Auth? {
        switch self {
        case .staging:
            let keyId = "CF_ACCESS_CLIENT_ID"
            let keySecret = "CF_ACCESS_CLIENT_SECRET"

            guard let id = EnvironmentFetcher.valueFromMainBundleOrProcessInfo(forKey: keyId),
                  let secret = EnvironmentFetcher.valueFromMainBundleOrProcessInfo(forKey: keySecret) else { return nil }
            return Auth(id: id, secret: secret)

        default:
            return nil
        }
    }
}
