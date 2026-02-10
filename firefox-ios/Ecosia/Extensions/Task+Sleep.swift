// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension Task where Success == Never, Failure == Never {
    /// Sleep for a given duration in seconds, with iOS 15 compatibility
    /// When iOS 16+ becomes minimum, this can be replaced with Task.sleep(for: .seconds())
    static func sleep(duration: TimeInterval) async throws {
        if #available(iOS 16.0, *) {
            try await Task.sleep(for: .seconds(duration))
        } else {
            try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
        }
    }
}
