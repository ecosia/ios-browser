// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A protocol defining the requirements for an object that provides What's New data.
///
/// Types conforming to `WhatsNewDataProvider` are responsible for
/// fetching or generating an array of `WhatsNewItem` objects. These objects
/// represent individual features or updates that are new in a given app version.
///
/// - Throws: An error if the data cannot be fetched or generated.
///
protocol WhatsNewDataProvider {
    /// Fetches or generates an array of `WhatsNewItem` objects.
    ///
    /// Implement this method to specify how What's New items should be
    /// retrieved or generated. For example, this could involve fetching
    /// data from a server or reading it from a local data store.
    ///
    /// - Returns: An array of `WhatsNewItem` objects that encapsulate individual features or updates.
    /// - Throws: An error if data retrieval or generation fails.
    func getData() throws -> [WhatsNewItem]
}
