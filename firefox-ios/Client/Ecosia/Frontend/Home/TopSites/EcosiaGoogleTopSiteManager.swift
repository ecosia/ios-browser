// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Storage

/// Ecosia: Replaces Firefox's GoogleTopSiteManager with a no-op so that
/// Google is never injected as a pinned tile on the NTP. Gmail is already
/// present as a regular (non-pinned) suggested site in DefaultSuggestedSites.
struct EcosiaGoogleTopSiteManager: GoogleTopSiteManagerProvider {
    var pinnedSiteData: Site? { nil }
    func shouldAddGoogleTopSite(hasSpace: Bool) -> Bool { false }
    func removeGoogleTopSite(site: Site) {}
}
