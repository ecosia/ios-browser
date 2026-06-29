// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Photos
import PhotosUI
import UniformTypeIdentifiers
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
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] newStatus in
                Task { @MainActor in
                    if OmniboxUploadPhotoLibraryAuthorization.isAccessGranted(for: newStatus) {
                        onGranted()
                    } else {
                        self?.presentPhotoLibraryAccessDeniedAlert(on: viewController)
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
        let remainingSlots = delegate?.omniboxUploadRemainingAttachmentSlots
            ?? OmniboxUploadPhotoPickerUX.maxSelectionCount
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = min(OmniboxUploadPhotoPickerUX.maxSelectionCount, remainingSlots)
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
        guard !results.isEmpty else { return }

        let existingAttachmentCount = OmniboxUploadFileSelectionValidator.maxFileCount
            - (delegate?.omniboxUploadRemainingAttachmentSlots ?? OmniboxUploadFileSelectionValidator.maxFileCount)
        let validationErrors = OmniboxUploadFileSelectionValidator.validateSelectionCount(
            selectedCount: results.count,
            existingAttachmentCount: existingAttachmentCount
        )

        let remainingSlots = delegate?.omniboxUploadRemainingAttachmentSlots
            ?? OmniboxUploadFileSelectionValidator.maxFileCount
        let acceptedResults = Array(results.prefix(remainingSlots))

        let pendingItems = acceptedResults.map { result in
            let fileName = result.itemProvider.suggestedName ?? "photo.jpg"
            let typeIdentifier = result.itemProvider.registeredTypeIdentifiers.first ?? UTType.jpeg.identifier
            return OmniboxUploadPendingItem(fileName: fileName, layout: .image) {
                try await Self.loadPhoto(from: result.itemProvider,
                                         fileName: fileName,
                                         typeIdentifier: typeIdentifier)
            }
        }
        delegate?.omniboxUploadDidFinishPicking(items: pendingItems, validationErrors: validationErrors)
    }

    private static func loadPhoto(from itemProvider: NSItemProvider,
                                  fileName: String,
                                  typeIdentifier: String) async throws -> OmniboxUploadLocalPayload {
        if itemProvider.canLoadObject(ofClass: UIImage.self) {
            let image = try await loadUIImage(from: itemProvider)
            guard let data = image.jpegData(compressionQuality: 0.92) else {
                throw OmniboxUploadPayloadError.unreadable
            }
            return try OmniboxUploadPayloadLoader.loadImage(
                data: data,
                fileName: fileName,
                mimeType: UTType.jpeg.preferredMIMEType ?? "image/jpeg"
            )
        }

        return try await withCheckedThrowingContinuation { continuation in
            itemProvider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let data else {
                    continuation.resume(throwing: OmniboxUploadPayloadError.unreadable)
                    return
                }
                do {
                    let mimeType = UTType(typeIdentifier)?.preferredMIMEType ?? "image/jpeg"
                    let payload = try OmniboxUploadPayloadLoader.loadImage(
                        data: data,
                        fileName: fileName,
                        mimeType: mimeType
                    )
                    continuation.resume(returning: payload)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func loadUIImage(from itemProvider: NSItemProvider) async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let image = object as? UIImage else {
                    continuation.resume(throwing: OmniboxUploadPayloadError.unreadable)
                    return
                }
                continuation.resume(returning: image)
            }
        }
    }
}
