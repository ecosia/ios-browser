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

    /// The custom claim key for the account creation timestamp.
    /// Set via an Auth0 Post-Login Action: ``api.idToken.setCustomClaim(`${CUSTOM_CLAIM_NAMESPACE}/created_at`, event.user.created_at);``
    private static let createdAtClaim = "https://ecosia.org/created_at"

    /// A UTC calendar used for same-day comparisons.
    private static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// Determines whether this login represents a new account or an existing sign-in.
    ///
    /// Compares the `https://ecosia.org/created_at` custom claim (account creation time) with
    /// the current date. If the account was created on the same UTC calendar day,
    /// the account is considered new. This accommodates delays caused by e-mail verification
    /// while still distinguishing new from returning users.
    var accountOrigin: AccountOrigin {
        guard let jwt = try? decode(jwt: idToken),
              let createdAtString = jwt[Self.createdAtClaim].string,
              let createdAt = Self.iso8601Formatter.date(from: createdAtString) else {
            return .existingAccount
        }

        let sameDay = Self.utcCalendar.isDate(createdAt, inSameDayAs: Date())
        return sameDay ? .newAccount : .existingAccount
    }

    /// ISO 8601 formatter configured to handle fractional seconds (e.g. `2026-03-04T10:44:47.942Z`).
    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
