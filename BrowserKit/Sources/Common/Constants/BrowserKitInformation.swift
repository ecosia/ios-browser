// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Contains application information necessary for BrowserKit functionalities.
/// FIXME: FXIOS-13125 We should be able to mark this Sendable without mutable state
public final class BrowserKitInformation: @unchecked Sendable {
    // FIXME: FXIOS-13125 Shared state for the app should not be stored in the Common package.
    public static let shared = BrowserKitInformation()

    public var buildChannel: AppBuildChannel?
    public var nightlyAppVersion: String?
    public var sharedContainerIdentifier: String?
    // Ecosia: Lets the app tell BrowserKit its own environment name (e.g. "staging"/"production") for
    // Sentry tagging, without BrowserKit needing to know about Ecosia's Environment type. Firefox call
    // sites can leave this nil and keep their existing Nightly/Production tagging.
    public var environmentName: String?

    public func configure(buildChannel: AppBuildChannel,
                          nightlyAppVersion: String,
                          sharedContainerIdentifier: String,
                          // Ecosia: set environment name
                          environmentName: String? = nil) {
        self.buildChannel = buildChannel
        self.nightlyAppVersion = nightlyAppVersion
        self.sharedContainerIdentifier = sharedContainerIdentifier
        // Ecosia: set environment name
        self.environmentName = environmentName
    }
}
