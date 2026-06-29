// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Ecosia

@MainActor
protocol OmniboxAttachmentUploadDelegate: AnyObject {
    func omniboxAttachmentsDidChange()
}

/// Loads picker selections, shows loading tiles, uploads files, and updates the omnibox strip.
@MainActor
final class OmniboxAttachmentUploadCoordinator {

    weak var searchBar: NTPSearchBarView?
    weak var delegate: OmniboxAttachmentUploadDelegate?

    private let uploadService: FileUploadService
    private var tasks: [UUID: Task<Void, Never>] = [:]
    private var previewImages: [UUID: UIImage] = [:]

    init(uploadService: FileUploadService = FileUploadService()) {
        self.uploadService = uploadService
    }

    func processPendingItems(_ items: [OmniboxUploadPendingItem]) {
        guard let searchBar else { return }

        let remainingSlots = OmniboxUploadFileSelectionValidator.maxFileCount - searchBar.attachments.count
        guard remainingSlots > 0 else { return }

        for item in items.prefix(remainingSlots) {
            let attachment = OmniboxAttachment(
                fileName: item.fileName,
                layout: item.layout,
                state: .loading
            )
            searchBar.addAttachment(attachment)

            let attachmentID = attachment.id
            tasks[attachmentID] = Task { [weak self] in
                await self?.loadAndUpload(attachmentID: attachmentID, item: item)
            }
        }

        delegate?.omniboxAttachmentsDidChange()
    }

    func removeAttachment(id: UUID) {
        tasks[id]?.cancel()
        tasks.removeValue(forKey: id)
        previewImages.removeValue(forKey: id)
        searchBar?.removeAttachment(id: id)
        delegate?.omniboxAttachmentsDidChange()
    }

    func clearAttachments() {
        tasks.values.forEach { $0.cancel() }
        tasks.removeAll()
        previewImages.removeAll()
        searchBar?.setAttachments([], previewImages: [:])
        delegate?.omniboxAttachmentsDidChange()
    }

    private func loadAndUpload(attachmentID: UUID, item: OmniboxUploadPendingItem) async {
        guard let searchBar else { return }

        do {
            let payload = try await item.load()
            guard !Task.isCancelled else { return }

            if let previewImage = payload.previewImage {
                previewImages[attachmentID] = previewImage
            }

            searchBar.updateAttachment(
                id: attachmentID,
                fileName: payload.fileName,
                layout: payload.layout,
                state: .loading,
                previewImages: previewImages
            )
            delegate?.omniboxAttachmentsDidChange()

            let fileId = try await uploadWithRetry(
                payload: payload,
                attachmentID: attachmentID
            )
            guard !Task.isCancelled else { return }

            searchBar.updateAttachment(
                id: attachmentID,
                fileName: payload.fileName,
                layout: payload.layout,
                state: .ready(byteCount: payload.data.count, fileId: fileId, mimeType: payload.mimeType),
                previewImages: previewImages
            )
            EcosiaLogger.network.info("[FileUpload] Attachment \(attachmentID) ready fileId=\(fileId)")
            delegate?.omniboxAttachmentsDidChange()
        } catch {
            guard !Task.isCancelled else { return }
            EcosiaLogger.network.error(
                "[FileUpload] Attachment \(attachmentID) failed: \(error.localizedDescription)"
            )
            searchBar.updateAttachment(
                id: attachmentID,
                fileName: item.fileName,
                layout: item.layout,
                state: .failed,
                previewImages: previewImages
            )
            delegate?.omniboxAttachmentsDidChange()
        }

        tasks.removeValue(forKey: attachmentID)
    }

    private func uploadWithRetry(payload: OmniboxUploadLocalPayload,
                                 attachmentID: UUID,
                                 attempts: Int = 2) async throws -> String {
        var lastError: Error?
        for attempt in 1...attempts {
            do {
                return try await uploadService.uploadFile(
                    FileUploadInput(data: payload.data, mimeType: payload.mimeType)
                )
            } catch {
                lastError = error
                EcosiaLogger.network.error(
                    "[FileUpload] Attachment \(attachmentID) attempt \(attempt)/\(attempts) failed: \(error.localizedDescription)"
                )
                guard attempt < attempts else { break }
                try await Task.sleep(nanoseconds: 500_000_000)
            }
        }
        guard let lastError else {
            throw OmniboxUploadPayloadError.unreadable
        }
        throw lastError
    }
}
