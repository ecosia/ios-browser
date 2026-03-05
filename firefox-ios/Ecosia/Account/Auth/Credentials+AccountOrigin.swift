// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Auth0
import JWTDecode

/// Indicates whether the user logged in to an existing account or created a new one.
public enum AccountOrigin: Equatable, Sendable {
    /// The user created a new account during this authentication session.
    case newAccount
    /// The user signed in to a pre-existing account.
    case existingAccount
}

extension Credentials {

    /// The maximum number of seconds between `created_at` and `iat` for the account
    /// to be considered newly created. For new accounts, these timestamps are nearly identical
    /// since the token is issued moments after account creation.
    private static let newAccountThresholdSeconds: TimeInterval = 30

    /// The custom claim key for the account creation timestamp.
    /// Set via an Auth0 Post-Login Action: ``api.idToken.setCustomClaim(`${CUSTOM_CLAIM_NAMESPACE}/created_at`, event.user.created_at);``
    private static let createdAtClaim = "https://ecosia.org/created_at"

    /// Determines whether this login represents a new account or an existing sign-in.
    ///
    /// Compares the `https://ecosia.org/created_at` custom claim (account creation time) with
    /// `iat` (token issue time) from the ID token. For a newly created account,
    /// these timestamps will be within seconds of each other.
    var accountOrigin: AccountOrigin {
        guard let jwt = try? decode(jwt: idToken),
              let createdAtString = jwt[Self.createdAtClaim].string,
              let createdAt = Self.iso8601Formatter.date(from: createdAtString),
              let issuedAt = jwt.issuedAt else { // TODO: Handle e-mail verification case
            return .existingAccount
        }

        let difference = abs(issuedAt.timeIntervalSince(createdAt))
        return difference <= Self.newAccountThresholdSeconds ? .newAccount : .existingAccount
    }

    /// ISO 8601 formatter configured to handle fractional seconds (e.g. `2026-03-04T10:44:47.942Z`).
    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
