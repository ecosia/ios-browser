// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import UniformTypeIdentifiers
import Ecosia

extension OmniboxUploadPickerCoordinator {
    func presentFilesPicker(from viewController: UIViewController) {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: OmniboxUploadFileSelectionValidator.pickerContentTypes,
            asCopy: true
        )
        picker.delegate = self
        picker.allowsMultipleSelection = true
        configurePopover(for: picker, from: viewController)
        viewController.present(picker, animated: true)
    }
}

extension OmniboxUploadPickerCoordinator: UIDocumentPickerDelegate {
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        controller.dismiss(animated: true)

        let validationResult = OmniboxUploadFileSelectionValidator.validate(
            urls: urls,
            existingAttachmentCount: delegate?.omniboxUploadExistingAttachmentCount ?? 0
        )

        let pendingItems = validationResult.acceptedURLs.map { url in
            let ext = url.pathExtension.lowercased()
            let layout: OmniboxAttachment.Layout = OmniboxUploadFileSelectionValidator.imageExtensions.contains(ext)
                ? .image
                : .file
            return OmniboxUploadPendingItem(fileName: url.lastPathComponent, layout: layout) {
                try await OmniboxUploadPayloadLoader.loadFile(from: url)
            }
        }

        delegate?.omniboxUploadDidFinishPicking(
            items: pendingItems,
            validationErrors: validationResult.validationErrors
        )
    }
}
