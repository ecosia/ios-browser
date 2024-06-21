// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

struct IconChooserViewController: UIViewControllerRepresentable {
    @EnvironmentObject var model: AppIconChooserModel

    func makeUIViewController(context: Context) -> UIViewController {
        let contentView = ContentView().environmentObject(model)
        return UIHostingController(rootView: contentView)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No update needed for this example
    }
}

extension UIViewController {
    static func makeIconChooserViewController() -> UIViewController {
        let model = AppIconChooserModel() // Initialize your model
        let contentView = IconChooserViewController().environmentObject(model)
        let vc = UIHostingController(rootView: contentView)
        vc.title = "Update App Icon"
        return vc
    }
}
