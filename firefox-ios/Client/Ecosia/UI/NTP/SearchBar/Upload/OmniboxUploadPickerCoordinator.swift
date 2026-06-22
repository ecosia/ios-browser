// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Ecosia

/// Presents system pickers for omnibox upload sources.
/// Photo, camera, and file integrations are added in MOB-4583, MOB-4584, and MOB-4585.
@MainActor
final class OmniboxUploadPickerCoordinator: NSObject {
    weak var presentingViewController: UIViewController?
    weak var delegate: OmniboxUploadPickerDelegate?

    var popoverSourceView: UIView?

    func presentPicker(for option: OmniboxUploadOption,
                       from viewController: UIViewController,
                       sourceView: UIView?) {
        presentingViewController = viewController
        popoverSourceView = sourceView

        switch option {
        case .photos:
            break // TODO: MOB-4583
        case .camera:
            break // TODO: MOB-4584
        case .files:
            presentFilesPicker(from: viewController)
        }
    }

    func configurePopover(for viewController: UIViewController, from presenter: UIViewController) {
        guard let popover = viewController.popoverPresentationController,
              let sourceView = popoverSourceView,
              presenter.traitCollection.horizontalSizeClass == .regular else { return }
        popover.sourceView = sourceView
        popover.sourceRect = sourceView.bounds
        popover.permittedArrowDirections = [.down, .up]
    }
}
