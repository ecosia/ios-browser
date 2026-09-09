// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Gates AI-free searching: the Settings toggle, `ECNOAI` cookie sync,
/// Overviews exclusion, omnibox autorouting (`ar=1`), and omnibox AI surfaces.
public struct AIFreeSearchingFeatureFlag {

    private init() {}

    public static var isEnabled: Bool {
        Unleash.isEnabled(.aiFreeSearching)
    }
}
