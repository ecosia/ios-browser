// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol APNConsentViewModelProtocol {
    var listItems: [APNConsentListItem] { get }
    var title: String { get }
    var image: UIImage? { get }
    var ctaAllowButtonTitle: String { get }
    var ctaDenyButtonTitle: String { get }
}

extension APNConsentViewModelProtocol {
    
    var ctaAllowButtonTitle: String {
        "Allow push notifications"
    }
    
    var ctaDenyButtonTitle: String {
        "Not now"
    }
}
