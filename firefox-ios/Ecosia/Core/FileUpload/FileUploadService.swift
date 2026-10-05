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

/// Mirrors the web `file-upload-service.js` presigned URL flow:
///   1. POST `www.{domain}/ai-chat/refresh` → sets EAIST Cloudflare WAF cookie
///   2. POST `/v2/conversations/files/upload` → get `{ file_id, upload_url }`
///   3. PUT raw bytes → R2 presigned URL
///
/// There is no separate confirm step; `file_id` from the presign response is the upload handle.
public final class FileUploadService: Sendable {

    public enum Error: Swift.Error, LocalizedError, Equatable {
        case unexpectedResponse(UnexpectedResponse)
        case invalidPresignResponse
        case authenticationRequired
        case timedOut

        public var errorDescription: String? {
            switch self {
            case .unexpectedResponse(let unexpected):
                return unexpected.description
            case .invalidPresignResponse:
                return "Invalid presign response"
            case .authenticationRequired:
                return "Authentication required"
            case .timedOut:
                return "Upload timed out"
            }
        }
    }

    private let client: HTTPClient
    private let authenticationService: EcosiaAuthenticationService
    private let timeout: TimeInterval
    private let environment: Environment

    public init(
        client: HTTPClient = URLSessionHTTPClient(),
        authenticationService: EcosiaAuthenticationService = .shared,
        timeout: TimeInterval = 20,
        environment: Environment = .current
    ) {
        self.client = client
        self.authenticationService = authenticationService
        self.timeout = timeout
        self.environment = environment
    }

    /// Upload a single file. Returns the `file_id` on success.
    public func uploadFile(_ file: FileUploadInput) async throws -> String {
        log(.info, "Starting upload mimeType=\(file.mimeType) size=\(file.data.count)")
        do {
            try await refreshEAIST()
            let authSessionCookie = await FileUploadAuthCookieSync.syncAuthSessionCookieToSharedStorage()
            let accessToken = try await validAccessToken()
            FileUploadAuthDiagnostics.logAccessTokenScopes(
                accessToken,
                grantedScope: authenticationService.grantedScope
            )
            let fileId = try await withUploadTimeout(timeout) {
                try await self.uploadSingleFile(file, accessToken: accessToken, authSessionCookie: authSessionCookie)
            }
            log(.info, "Upload succeeded fileId=\(fileId)")
            return fileId
        } catch {
            log(.error, "Upload failed: \(error.localizedDescription)")
            throw error
        }
    }

    /// Upload multiple files concurrently with a per-file timeout.
    public func uploadFiles(_ files: [FileUploadInput]) async -> FileUploadResult {
        do {
            try await refreshEAIST()
        } catch {
            return FileUploadResult(fileIds: Array(repeating: nil, count: files.count), errors: [error])
        }

        let authSessionCookie = await FileUploadAuthCookieSync.syncAuthSessionCookieToSharedStorage()
        let accessToken: String
        do {
            accessToken = try await validAccessToken()
            FileUploadAuthDiagnostics.logAccessTokenScopes(
                accessToken,
                grantedScope: authenticationService.grantedScope
            )
        } catch {
            return FileUploadResult(fileIds: Array(repeating: nil, count: files.count), errors: [error])
        }

        var fileIds = [String?](repeating: nil, count: files.count)
        var errors = [Swift.Error]()
        let timeout = self.timeout

        await withTaskGroup(of: (Int, Result<String, Swift.Error>).self) { group in
            for (index, file) in files.enumerated() {
                group.addTask {
                    do {
                        let fileId = try await withUploadTimeout(timeout) {
                            try await self.uploadSingleFile(
                                file,
                                accessToken: accessToken,
                                authSessionCookie: authSessionCookie
                            )
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

    /// Staging API POSTs can be blocked by Cloudflare Access unless `CF_Authorization`
    /// is present in `HTTPCookieStorage`, even when service-token headers are set.
    private func ensureCloudflareAccessCookieForStagingAPI() async {
        guard environment == .staging else { return }
        await CloudflareAccessCookieBootstrap.syncAuthorizationCookieToWebView(environment: environment)
    }

    private func refreshEAIST() async throws {
        await ensureCloudflareAccessCookieForStagingAPI()
        let request = AIChatRefreshRequest()
        log(.info, "Refreshing EAIST cookie url=\(request.resolvedBaseURL.absoluteString)\(request.path)")

        let (_, response) = try await client.perform(request)
        guard let http = response, (200..<300).contains(http.statusCode) else {
            let unexpected = UnexpectedResponse(step: .refresh, response: response)
            log(.error, unexpected.description)
            throw Error.unexpectedResponse(unexpected)
        }
        log(.info, "EAIST refresh succeeded status=\(http.statusCode)")
    }

    private func validAccessToken() async throws -> String {
        try await authenticationService.renewCredentialsIfNeeded()
        guard let token = authenticationService.accessToken, !token.isEmpty else {
            log(.error, "No valid access token after renewal")
            throw Error.authenticationRequired
        }
        guard authenticationService.hasConversationScopes else {
            log(.error, "Access token missing conversation scopes")
            throw Error.authenticationRequired
        }
        log(.info, "Access token available (length=\(token.count))")
        return token
    }

    private func uploadSingleFile(
        _ file: FileUploadInput,
        accessToken: String,
        authSessionCookie: HTTPCookie?
    ) async throws -> String {
        let presign = try await fetchPresignedURL(accessToken: accessToken, authSessionCookie: authSessionCookie)
        try await putFile(file, to: presign.uploadURL)
        return presign.fileId
    }

    private func fetchPresignedURL(accessToken: String, authSessionCookie: HTTPCookie?) async throws -> PresignResponse {
        log(.info, "Requesting presigned URL (EASC attached=\(authSessionCookie != nil))")
        let request = FilePresignRequest(accessToken: accessToken, authSessionCookie: authSessionCookie)
        let (data, response) = try await client.perform(request)
        guard response?.statusCode == 200 else {
            let unexpected = UnexpectedResponse(step: .presign, response: response)
            log(.error, unexpected.description)
            throw Error.unexpectedResponse(unexpected)
        }

        guard let presign = try? JSONDecoder().decode(PresignResponse.self, from: data) else {
            // The body holds the signed upload URL, so only its size is logged.
            log(.error, "Failed to decode presign response (\(data.count) bytes)")
            throw Error.invalidPresignResponse
        }
        log(.info, "Got presigned URL fileId=\(presign.fileId) host=\(presign.uploadURL.host ?? "?")")
        return presign
    }

    private func putFile(_ file: FileUploadInput, to url: URL) async throws {
        log(.info, "PUT to presigned URL host=\(url.host ?? "unknown")")
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(file.mimeType, forHTTPHeaderField: "Content-Type")

        let (_, response) = try await URLSession.shared.upload(for: request, from: file.data)
        let httpResponse = response as? HTTPURLResponse
        guard let http = httpResponse, (200..<300).contains(http.statusCode) else {
            let unexpected = UnexpectedResponse(step: .put, response: httpResponse)
            log(.error, unexpected.description)
            throw Error.unexpectedResponse(unexpected)
        }
        log(.info, "PUT succeeded status=\(http.statusCode)")
    }

    private enum LogLevel {
        case info, error
    }

    private func log(_ level: LogLevel, _ message: String) {
        let formatted = "[FileUpload] \(message)"
        switch level {
        case .info:
            EcosiaLogger.network.info(formatted)
        case .error:
            EcosiaLogger.network.error(formatted)
        }
    }
}

// MARK: - Timeout helper

private func withUploadTimeout<T: Sendable>(
    _ timeout: TimeInterval,
    operation: @Sendable @escaping () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask { try await operation() }
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            throw FileUploadService.Error.timedOut
        }
        guard let result = try await group.next() else {
            throw FileUploadService.Error.timedOut
        }
        group.cancelAll()
        return result
    }
}
