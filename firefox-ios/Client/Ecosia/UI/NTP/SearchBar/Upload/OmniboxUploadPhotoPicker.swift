// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import PhotosUI
import UniformTypeIdentifiers
import Ecosia

enum OmniboxUploadPhotoPickerUX {
    static let maxSelectionCount = 5
}

extension OmniboxUploadPickerCoordinator {
    func presentPhotoPicker(from viewController: UIViewController) {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = OmniboxUploadPhotoPickerUX.maxSelectionCount
        configuration.filter = .images

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        configurePopover(for: picker, from: viewController)
        viewController.present(picker, animated: true)
    }
}

extension OmniboxUploadPickerCoordinator: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard !results.isEmpty else { return }

        let acceptedResults = Array(results.prefix(OmniboxUploadPhotoPickerUX.maxSelectionCount))

        // Load bytes while the picker callback is still active — the item provider can expire later.
        Task { @MainActor [weak self] in
            guard let self else { return }

            var pendingItems: [OmniboxUploadPendingItem] = []
            for result in acceptedResults {
                let fileName = result.itemProvider.suggestedName
                    ?? OmniboxUploadPayloadLoader.uniqueJPEGFileName(prefix: "photo")
                let typeIdentifier = result.itemProvider.registeredTypeIdentifiers.first ?? UTType.jpeg.identifier
                let payload = try? await Task.detached(priority: .userInitiated) {
                    try await Self.loadPhoto(
                        from: result.itemProvider,
                        fileName: fileName,
                        typeIdentifier: typeIdentifier
                    )
                }.value
                guard let payload else { continue }

                let captured = payload
                pendingItems.append(
                    OmniboxUploadPendingItem(fileName: captured.fileName, layout: captured.layout) {
                        captured
                    }
                )
            }

            guard !pendingItems.isEmpty else { return }
            delegate?.omniboxUploadDidPickPendingItems(pendingItems)
        }
    }

    private static func loadPhoto(from itemProvider: NSItemProvider,
                                  fileName: String,
                                  typeIdentifier: String) async throws -> OmniboxUploadLocalPayload {
        if let payload = try? await loadRawPhoto(
            from: itemProvider,
            fileName: fileName,
            typeIdentifier: typeIdentifier
        ) {
            return payload
        }

        let image = try await loadUIImage(from: itemProvider)
        guard let data = image.jpegData(compressionQuality: 0.92) else {
            throw OmniboxUploadPayloadError.unreadable
        }
        let jpegFileName = OmniboxUploadPayloadLoader.normalizedJPEGFileName(from: fileName)
        return try OmniboxUploadPayloadLoader.loadImage(
            data: data,
            fileName: jpegFileName,
            mimeType: UTType.jpeg.preferredMIMEType ?? "image/jpeg"
        )
    }

    private static func loadRawPhoto(from itemProvider: NSItemProvider,
                                     fileName: String,
                                     typeIdentifier: String) async throws -> OmniboxUploadLocalPayload {
        let data = try await loadData(from: itemProvider, typeIdentifier: typeIdentifier)
        let mimeType = UTType(typeIdentifier)?.preferredMIMEType ?? "image/jpeg"
        return try OmniboxUploadPayloadLoader.loadImage(
            data: data,
            fileName: fileName,
            mimeType: mimeType
        )
    }

    private static func loadData(from itemProvider: NSItemProvider,
                                 typeIdentifier: String) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            itemProvider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let data else {
                    continuation.resume(throwing: OmniboxUploadPayloadError.unreadable)
                    return
                }
                continuation.resume(returning: data)
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
