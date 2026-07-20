// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Ecosia

@MainActor
protocol OmniboxAttachmentUploadDelegate: AnyObject {
    func omniboxAttachmentsDidChange()
    func omniboxUploadDidEncounterValidationErrors(_ errors: Set<OmniboxUploadValidationError>)
}

extension OmniboxAttachmentUploadDelegate {
    func omniboxUploadDidEncounterValidationErrors(_ errors: Set<OmniboxUploadValidationError>) {}
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
        if remainingSlots <= 0 {
            delegate?.omniboxUploadDidEncounterValidationErrors([.tooManyFiles])
            return
        }

        let acceptedItems = Array(items.prefix(remainingSlots))
        let countErrors = OmniboxUploadFileSelectionValidator.validateSelectionCount(
            selectedCount: items.count,
            existingAttachmentCount: searchBar.attachments.count
        )
        if !countErrors.isEmpty {
            delegate?.omniboxUploadDidEncounterValidationErrors(countErrors)
        }

        for item in acceptedItems {
            let attachment = OmniboxAttachment(
                fileName: item.fileName,
                layout: item.layout,
                state: .loading
            )
            searchBar.addAttachment(attachment)
            Analytics.shared.fileUploadInitiated(
                fileType: Analytics.fileUploadFileType(fromFileName: item.fileName)
            )

            let attachmentID = attachment.id
            tasks[attachmentID] = Task { @MainActor [weak self] in
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
        defer { tasks.removeValue(forKey: attachmentID) }
        guard let searchBar else { return }

        var displayFileName = item.fileName
        var displayLayout = item.layout
        var displayMimeType: String?

        do {
            let payload = try await item.loadPayload()
            guard !Task.isCancelled else { return }

            displayFileName = payload.fileName
            displayLayout = payload.layout
            displayMimeType = payload.mimeType

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
            Analytics.shared.fileUploadCompleted(
                fileType: Analytics.fileUploadFileType(
                    fromFileName: payload.fileName,
                    mimeType: payload.mimeType
                ),
                fileSizeKb: Analytics.fileUploadSizeKb(byteCount: payload.data.count)
            )
            EcosiaLogger.network.info("[FileUpload] Attachment \(attachmentID) ready fileId=\(fileId)")
            delegate?.omniboxAttachmentsDidChange()
        } catch let error as OmniboxUploadPayloadError where error == .fileTooLarge {
            guard !Task.isCancelled else { return }
            trackUploadFailure(errorType: .tooLarge, fileName: displayFileName, mimeType: displayMimeType)
            searchBar.removeAttachment(id: attachmentID)
            previewImages.removeValue(forKey: attachmentID)
            delegate?.omniboxUploadDidEncounterValidationErrors([.fileTooLarge])
            delegate?.omniboxAttachmentsDidChange()
        } catch {
            guard !Task.isCancelled else { return }
            EcosiaLogger.network.error(
                "[FileUpload] Attachment \(attachmentID) failed: \(error.localizedDescription)"
            )
            trackUploadFailure(for: error, fileName: displayFileName, mimeType: displayMimeType)
            if error is OmniboxUploadPayloadError {
                searchBar.removeAttachment(id: attachmentID)
                previewImages.removeValue(forKey: attachmentID)
                delegate?.omniboxUploadDidEncounterValidationErrors([.uploadFailed])
            } else {
                searchBar.updateAttachment(
                    id: attachmentID,
                    fileName: displayFileName,
                    layout: displayLayout,
                    state: .failed,
                    previewImages: previewImages
                )
                delegate?.omniboxUploadDidEncounterValidationErrors([.uploadFailed])
            }
            delegate?.omniboxAttachmentsDidChange()
        }
    }

    private func trackUploadFailure(for error: Error, fileName: String, mimeType: String?) {
        if let serviceError = error as? FileUploadService.Error {
            // Only `timeout` is in the tracking-plan `error_type` enum for
            // service failures; other network/auth/API errors are omitted.
            guard serviceError == .timedOut else { return }
            trackUploadFailure(errorType: .timeout, fileName: fileName, mimeType: mimeType)
            return
        }
        if error is OmniboxUploadPayloadError {
            trackUploadFailure(errorType: .parseFailed, fileName: fileName, mimeType: mimeType)
        }
    }

    private func trackUploadFailure(errorType: Analytics.Property.FileUploadErrorType,
                                    fileName: String,
                                    mimeType: String?) {
        Analytics.shared.fileUploadFailed(
            errorType: errorType,
            fileType: Analytics.fileUploadFileType(fromFileName: fileName, mimeType: mimeType)
        )
    }

    private func uploadWithRetry(payload: OmniboxUploadLocalPayload,
                                 attachmentID: UUID,
                                 attempts: Int = 2) async throws -> String {
        if OmniboxUploadDebugSimulation.shouldSimulateUploadAPIFailure {
            EcosiaLogger.network.info("[FileUpload] Debug: simulating upload API failure")
            throw NSError(
                domain: "EcosiaDebug",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Debug: Simulated file upload API error"]
            )
        }

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
