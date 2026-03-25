// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI
import UIKit

extension Bundle {
    public static var ecosia: Bundle {
        Bundle(identifier: "com.ecosia.framework.Ecosia")!
    }
}

extension UIImage {
    /// Loads a named image from the Ecosia framework bundle.
    public static func ecosia(named name: String, with configuration: UIImage.Configuration? = nil) -> UIImage? {
        UIImage(named: name, in: .ecosia, with: configuration)
    }
}

extension SwiftUI.Image {
    /// Loads a named image from the Ecosia framework bundle.
    public static func ecosia(_ name: String) -> SwiftUI.Image {
        SwiftUI.Image(name, bundle: .ecosia)
    }
}
