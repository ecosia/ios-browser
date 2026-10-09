// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Auth0 Universal Login screen hint passed via the `screen_hint` authorize parameter.
public enum AuthScreenHint: String, Sendable {
    case login
    case signUp = "signup"
}
