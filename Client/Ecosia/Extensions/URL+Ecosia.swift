// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

extension URL {

    public var isHTTPS: Bool {
        scheme == "https"
    }
    
    /// This computed var is utilized to determine whether a Website is considered secure from the Ecosia's perspective
    /// We use it mainly to define the UI that tells the user that the currently visited website is secure
    public var isSecure: Bool {
        isHTTPS || isReaderModeURL
    }
}
