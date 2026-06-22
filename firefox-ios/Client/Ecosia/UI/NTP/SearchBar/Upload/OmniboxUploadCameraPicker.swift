// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import AVFoundation
import UniformTypeIdentifiers
import Ecosia
import Shared

extension OmniboxUploadPickerCoordinator {
    func presentCameraPicker(from viewController: UIViewController) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            presentCameraUnavailableAlert(on: viewController)
            return
        }

        requestCameraAccessIfNeeded(from: viewController) { [weak self] granted in
            guard let self, granted else { return }
            self.showSystemCameraPicker(from: viewController)
        }
    }

    private func requestCameraAccessIfNeeded(from viewController: UIViewController,
                                             completion: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor in
                    if granted {
                        completion(true)
                    } else {
                        self.presentCameraAccessDeniedAlert(on: viewController)
                        completion(false)
                    }
                }
            }
        case .denied, .restricted:
            presentCameraAccessDeniedAlert(on: viewController)
            completion(false)
        @unknown default:
            completion(false)
        }
    }

    private func showSystemCameraPicker(from viewController: UIViewController) {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = OmniboxUploadCameraPickerUX.photoMediaTypes
        picker.cameraCaptureMode = .photo
        picker.delegate = self
        configurePopover(for: picker, from: viewController)
        viewController.present(picker, animated: true)
    }

    private func presentCameraAccessDeniedAlert(on viewController: UIViewController) {
        let alert = UIAlertController(
            title: String.localized(.uploadCameraAccessTitle),
            message: String.localized(.uploadCameraAccessMessage),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: String.localized(.cancel), style: .cancel))
        alert.addAction(UIAlertAction(title: .OpenSettingsString, style: .default) { _ in
            DefaultApplicationHelper().openSettings()
        })
        viewController.present(alert, animated: true)
    }

    private func presentCameraUnavailableAlert(on viewController: UIViewController) {
        let alert = UIAlertController(
            title: String.localized(.uploadCameraAccessTitle),
            message: String.localized(.uploadCameraUnavailableMessage),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: String.localized(.cancel), style: .cancel))
        viewController.present(alert, animated: true)
    }
}

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
