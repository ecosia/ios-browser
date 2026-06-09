// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// MARK: - Input / Output

public struct FileUploadInput: Sendable {
    public let data: Data
    public let mimeType: String

    public init(data: Data, mimeType: String) {
        self.data = data
        self.mimeType = mimeType
    }
}

public struct FileUploadResult: Sendable {
    /// Index-aligned with the input array; `nil` means that file failed to upload.
    public let fileIds: [String?]
    public let errors: [Error]
}

// MARK: - Presign response

private struct PresignResponse: Decodable {
    let fileId: String
    let uploadURL: URL

    enum CodingKeys: String, CodingKey {
        case fileId = "file_id"
        case uploadURL = "upload_url"
    }
}

// MARK: - Service

/// Mirrors the web `file-upload-service.js` two-step presigned URL flow:
///   1. POST `www.{domain}/ai-chat/refresh` → sets EAIST Cloudflare WAF cookie in URLSession's
///      cookie storage (equivalent to the web's `refreshToken()` call)
///   2. POST `/v2/conversations/files/upload` → get `{ file_id, upload_url }`
///   3. PUT raw bytes → R2 presigned URL
///
/// **Pending backend change:** `setAuthNoOptOut` in `ai-search-worker` currently reads the EASC
/// session cookie for user auth. Mobile has no EASC cookie (native Auth0 login, not web).
/// The middleware needs a Bearer token fallback via `AUTH_WORKER.verifyAccessToken()`.
/// Until that lands, step 2 will return 401 for authenticated users.
public final class FileUploadService: Sendable {

    enum Error: Swift.Error {
        case network
        case eaistRefreshFailed
        case invalidPresignResponse
        case uploadFailed(statusCode: Int)
        case authenticationRequired
    }

    private let client: HTTPClient
    private let authenticationService: EcosiaAuthenticationService
    private let timeout: TimeInterval

    public init(
        client: HTTPClient = URLSessionHTTPClient(),
        authenticationService: EcosiaAuthenticationService = .shared,
        timeout: TimeInterval = 20
    ) {
        self.client = client
        self.authenticationService = authenticationService
        self.timeout = timeout
    }

    // MARK: - Public API

    /// Upload a single file. Returns the `file_id` on success.
    public func uploadFile(_ file: FileUploadInput) async throws -> String {
        try await refreshEAIST()
        let accessToken = try await validAccessToken()
        return try await uploadSingleFile(file, accessToken: accessToken)
    }

    /// Upload multiple files concurrently with a per-file timeout.
    ///
    /// Results are index-aligned with the input: each element is the `file_id` on success or
    /// `nil` on failure, so callers can map results back to their original file metadata by index.
    public func uploadFiles(_ files: [FileUploadInput]) async -> FileUploadResult {
        do {
            // TODO: Check that refresh token works on production
            // Web had to include it in web (was failing only on prod to fetch the presigned URL if no refresh was done first)
            try await refreshEAIST()
        } catch {
            return FileUploadResult(fileIds: Array(repeating: nil, count: files.count), errors: [error])
        }

        let accessToken: String
        do {
            accessToken = try await validAccessToken()
        } catch {
            return FileUploadResult(fileIds: Array(repeating: nil, count: files.count), errors: [error])
        }

        var fileIds = [String?](repeating: nil, count: files.count)
        var errors = [Swift.Error]()

        await withTaskGroup(of: (Int, Result<String, Swift.Error>).self) { group in
            for (index, file) in files.enumerated() {
                group.addTask {
                    do {
                        let fileId = try await withUploadTimeout(self.timeout) {
                            try await self.uploadSingleFile(file, accessToken: accessToken)
                        }
                        return (index, .success(fileId))
                    } catch {
                        return (index, .failure(error))
                    }
                }
            }

            for await (index, result) in group {
                switch result {
                case .success(let id):
                    fileIds[index] = id
                case .failure(let error):
                    errors.append(error)
                }
            }
        }

        return FileUploadResult(fileIds: fileIds, errors: errors)
    }

    // MARK: - Private

    /// Calls `www.{domain}/ai-chat/refresh` to obtain the EAIST Cloudflare WAF cookie.
    ///
    /// The response sets the `EAIST` cookie on `*.ecosia.org`; URLSession stores it in
    /// `HTTPCookieStorage.shared` and includes it automatically on subsequent API requests.
    /// This is the direct equivalent of the web's `refreshToken()` call, added in
    /// https://github.com/ecosia/core/commit/5bc6a6cca6de20f2d9526d9dfe9701a20d8a0d1b
    /// to fix the same missing-cookie failure on web extensions.
    private func refreshEAIST() async throws {
        let url = Environment.current.urlProvider.aiChatRefresh
        EcosiaLogger.network.info("[FileUpload] Refreshing EAIST cookie at \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpBody = Data("{}".utf8)

        let (_, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            EcosiaLogger.network.error("[FileUpload] EAIST refresh failed: status=\(statusCode)")
            throw Error.eaistRefreshFailed
        }
        EcosiaLogger.network.info("[FileUpload] EAIST refresh succeeded: status=\(http.statusCode)")
    }

    private func validAccessToken() async throws -> String {
        try await authenticationService.renewCredentialsIfNeeded()
        guard let token = authenticationService.accessToken, !token.isEmpty else {
            EcosiaLogger.network.error("[FileUpload] No valid access token after renewal")
            throw Error.authenticationRequired
        }
        return token
    }

    private func uploadSingleFile(_ file: FileUploadInput, accessToken: String) async throws -> String {
        EcosiaLogger.network.info("[FileUpload] Uploading file: mimeType=\(file.mimeType), size=\(file.data.count) bytes")
        let presign = try await fetchPresignedURL(accessToken: accessToken)
        try await putFile(file, to: presign.uploadURL)
        EcosiaLogger.network.info("[FileUpload] Upload complete: fileId=\(presign.fileId)")
        return presign.fileId
    }

    private func fetchPresignedURL(accessToken: String) async throws -> PresignResponse {
        EcosiaLogger.network.info("[FileUpload] Requesting presigned URL")
        let request = FilePresignRequest(accessToken: accessToken)
        let (data, response) = try await client.perform(request)
        let statusCode = response?.statusCode ?? -1

        switch statusCode {
        case 200:
            break
        case 401, 403:
            EcosiaLogger.network.error("[FileUpload] Presign unauthorized: status=\(statusCode)")
            throw Error.authenticationRequired
        default:
            EcosiaLogger.network.error("[FileUpload] Presign failed: status=\(statusCode)")
            throw Error.network
        }

        guard let presign = try? JSONDecoder().decode(PresignResponse.self, from: data) else {
            EcosiaLogger.network.error("[FileUpload] Failed to decode presign response")
            throw Error.invalidPresignResponse
        }
        EcosiaLogger.network.info("[FileUpload] Got presigned URL: fileId=\(presign.fileId)")
        return presign
    }

    /// PUT raw bytes to the R2 presigned URL.
    ///
    /// Uses `URLSession` directly — NOT `HTTPClient` — so that staging-only Cloudflare Zero
    /// Trust headers are not injected into this external (R2/S3) request.
    /// The presigned URL already embeds all required auth via signed query parameters.
    private func putFile(_ file: FileUploadInput, to url: URL) async throws {
        EcosiaLogger.network.info("[FileUpload] PUT to presigned URL: \(url.host ?? "unknown")")
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(file.mimeType, forHTTPHeaderField: "Content-Type")

        let (_, response) = try await URLSession.shared.upload(for: request, from: file.data)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            EcosiaLogger.network.error("[FileUpload] PUT failed: status=\(statusCode)")
            throw Error.uploadFailed(statusCode: statusCode)
        }
        EcosiaLogger.network.info("[FileUpload] PUT succeeded: status=\(http.statusCode)")
    }
}

// MARK: - Timeout helper

/// Races the operation against a deadline, mirrors web's per-file `AbortController + setTimeout`.
private func withUploadTimeout<T: Sendable>(
    _ timeout: TimeInterval,
    operation: @Sendable @escaping () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask { try await operation() }
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            throw CancellationError()
        }
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}
