// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Photos
import PhotosUI
import Ecosia
import Shared

extension OmniboxUploadPickerCoordinator {
    func presentPhotoPicker(from viewController: UIViewController) {
        requestPhotoLibraryAccessIfNeeded(from: viewController) { [weak self] in
            self?.showSystemPhotoPicker(from: viewController)
        }
    }

    private func requestPhotoLibraryAccessIfNeeded(from viewController: UIViewController,
                                                   onGranted: @escaping @MainActor () -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            onGranted()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                Task { @MainActor in
                    if OmniboxUploadPhotoLibraryAuthorization.isAccessGranted(for: newStatus) {
                        onGranted()
                    } else {
                        self.presentPhotoLibraryAccessDeniedAlert(on: viewController)
                    }
                }
            }
        case .denied, .restricted:
            presentPhotoLibraryAccessDeniedAlert(on: viewController)
        @unknown default:
            break
        }
    }

    private func showSystemPhotoPicker(from viewController: UIViewController) {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = OmniboxUploadPhotoPickerUX.maxSelectionCount
        configuration.filter = .images

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        configurePopover(for: picker, from: viewController)
        viewController.present(picker, animated: true)
    }

    private func presentPhotoLibraryAccessDeniedAlert(on viewController: UIViewController) {
        let alert = UIAlertController(
            title: String.localized(.uploadPhotoLibraryAccessTitle),
            message: String.localized(.uploadPhotoLibraryAccessMessage),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: String.localized(.cancel), style: .cancel))
        alert.addAction(UIAlertAction(title: .OpenSettingsString, style: .default) { _ in
            DefaultApplicationHelper().openSettings()
        })
        viewController.present(alert, animated: true)
    }
}

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
