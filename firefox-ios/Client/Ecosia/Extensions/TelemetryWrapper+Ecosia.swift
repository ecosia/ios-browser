// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension TelemetryWrapper {
    /// Off for every install. An install that uploaded before sends Glean's one-off `deletion-request` on its next launch.
    static let isGleanUploadEnabled = false
}
