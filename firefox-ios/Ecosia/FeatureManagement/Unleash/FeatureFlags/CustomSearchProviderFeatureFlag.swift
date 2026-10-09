// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct CustomSearchProviderFeatureFlag {

    private init() {}

    public static var isEnabled: Bool {
        Unleash.isEnabled(.customSearchProvider)
    }

    /// Resolved router configuration, or the Ecosia-only one while the flag is off.
    /// Read this instead of pairing `isEnabled` with `SearchRouterConfiguration.current`.
    public static var config: SearchRouterConfig {
        guard isEnabled else { return .routerDisabled }
        return SearchRouterConfiguration.current
    }
}
