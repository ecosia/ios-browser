// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public enum SessionTransferTokenResult: Equatable, Sendable {
    case retrieved
    /// Transient failure (e.g. network), worth retrying later
    case unavailable
    /// Auth0 answered `invalid_grant`: the refresh token is revoked or expired, or the user was deleted
    case refreshTokenRejected
}
