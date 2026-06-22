// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import PhotosUI
import UniformTypeIdentifiers
import Common
import Ecosia

@MainActor
final class OmniboxUploadPickerCoordinator: NSObject {
    weak var presentingViewController: UIViewController?
    weak var delegate: OmniboxUploadPickerDelegate?

    private var popoverSourceView: UIView?

    func presentPicker(for option: OmniboxUploadOption,
                       from viewController: UIViewController,
                       sourceView: UIView?) {
        presentingViewController = viewController
        popoverSourceView = sourceView

        switch option {
        case .photos:
            presentPhotoPicker(from: viewController)
        case .camera:
            presentCameraPicker(from: viewController)
        case .files:
            presentFilesPicker(from: viewController)
        }
    }

    private func presentPhotoPicker(from viewController: UIViewController) {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 0
        configuration.filter = .any(of: [.images, .videos])

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        configurePopover(for: picker, from: viewController)
        viewController.present(picker, animated: true)
    }

    private func presentCameraPicker(from viewController: UIViewController) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        configurePopover(for: picker, from: viewController)
        viewController.present(picker, animated: true)
    }

    private func presentFilesPicker(from viewController: UIViewController) {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
        picker.delegate = self
        picker.allowsMultipleSelection = true
        configurePopover(for: picker, from: viewController)
        viewController.present(picker, animated: true)
    }

    private func configurePopover(for viewController: UIViewController, from presenter: UIViewController) {
        guard let popover = viewController.popoverPresentationController,
              let sourceView = popoverSourceView,
              presenter.traitCollection.horizontalSizeClass == .regular else { return }
        popover.sourceView = sourceView
        popover.sourceRect = sourceView.bounds
        popover.permittedArrowDirections = [.down, .up]
    }
}

// MARK: - PHPickerViewControllerDelegate

extension OmniboxUploadPickerCoordinator: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        let items = results.map { result in
            OmniboxUploadItem(
                source: .photos,
                fileName: result.itemProvider.suggestedName ?? "photo",
                contentTypeIdentifier: result.itemProvider.registeredTypeIdentifiers.first
            )
        }
        guard !items.isEmpty else { return }
        delegate?.omniboxUploadDidSelect(items: items)
    }
}

// MARK: - UIImagePickerControllerDelegate

extension OmniboxUploadPickerCoordinator: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)

        let fileName: String
        if let url = info[.imageURL] as? URL {
            fileName = url.lastPathComponent
        } else {
            fileName = "camera-photo"
        }

        delegate?.omniboxUploadDidSelect(items: [
            OmniboxUploadItem(source: .camera, fileName: fileName, contentTypeIdentifier: UTType.image.identifier)
        ])
    }
}

// MARK: - UIDocumentPickerDelegate

extension OmniboxUploadPickerCoordinator: UIDocumentPickerDelegate {
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        controller.dismiss(animated: true)

        let items = urls.map { url in
            OmniboxUploadItem(
                source: .files,
                fileName: url.lastPathComponent,
                contentTypeIdentifier: UTType(filenameExtension: url.pathExtension)?.identifier
            )
        }
        guard !items.isEmpty else { return }
        delegate?.omniboxUploadDidSelect(items: items)
    }
}
