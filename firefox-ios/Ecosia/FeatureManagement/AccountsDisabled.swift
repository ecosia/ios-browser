// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// Temporary feature flag (MOB-4484) that disables Accounts while App Store review issues are resolved.
/// Remove this type and its call sites when Accounts support is restored on affected devices.
public enum AccountsDisabled {

    /// When `true`, Accounts entry points and URL interception are disabled.
    public static var isActive: Bool {
        Unleash.isEnabled(.accountsDisabled)
    }
}
