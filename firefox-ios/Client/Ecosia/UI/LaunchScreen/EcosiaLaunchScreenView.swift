// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// LaunchScreen is the EcosiaLaunchScreen.xib we show at launch, but loaded programmatically
public class EcosiaLaunchScreenView: UIView {
    private static let viewName = "EcosiaLaunchScreen"

    public class func fromNib() -> UIView {
        return Bundle.main.loadNibNamed(EcosiaLaunchScreenView.viewName,
                                        owner: nil,
                                        options: nil)![0] as! UIView
    }
}
