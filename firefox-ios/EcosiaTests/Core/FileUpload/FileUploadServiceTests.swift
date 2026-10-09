// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Auth0
@testable import Ecosia

@MainActor
final class FileUploadServiceTests: XCTestCase {
    private static let conversationScope = "openid profile email read:conversations write:conversations"
    private static let file = FileUploadInput(data: Data("file".utf8), mimeType: "text/plain")

    private let client = HTTPClientMock()
    private let auth0Provider = MockAuth0Provider()

    func testPresignUnauthorized_throwsUnexpectedPresignResponse() async throws {
        let service = makeSignedInService(scope: Self.conversationScope)
        respond(refreshStatus: 204, presignStatus: 401)

        do {
            _ = try await service.uploadFile(Self.file)
            XCTFail("Expected the upload to fail")
        } catch FileUploadService.Error.unexpectedResponse(let response) {
            XCTAssertEqual(response.step, .presign)
            XCTAssertEqual(response.statusCode, 401)
        }
    }

    func testPresignForbidden_throwsUnexpectedPresignResponse() async throws {
        let service = makeSignedInService(scope: Self.conversationScope)
        respond(refreshStatus: 204, presignStatus: 403)

        do {
            _ = try await service.uploadFile(Self.file)
            XCTFail("Expected the upload to fail")
        } catch FileUploadService.Error.unexpectedResponse(let response) {
            XCTAssertEqual(response.step, .presign)
            XCTAssertEqual(response.statusCode, 403)
        }
    }

    func testRefreshForbidden_throwsUnexpectedRefreshResponseWithoutRequestingPresign() async throws {
        let service = makeSignedInService(scope: Self.conversationScope)
        respond(
            refreshStatus: 403,
            presignStatus: 200,
            refreshHeaders: ["cf-ray": "a44466c57d1e1a62-HAM", "Content-Type": "application/json"]
        )

        do {
            _ = try await service.uploadFile(Self.file)
            XCTFail("Expected the upload to fail")
        } catch FileUploadService.Error.unexpectedResponse(let response) {
            XCTAssertEqual(response.step, .refresh)
            XCTAssertEqual(response.statusCode, 403)
            XCTAssertEqual(response.rayID, "a44466c57d1e1a62-HAM")
            XCTAssertEqual(response.contentType, "application/json")
            XCTAssertEqual(client.requests.count, 1)
        }
    }

    func testPresignedUploadFailure_throwsUnexpectedPutResponse() async throws {
        URLProtocol.registerClass(PresignedUploadStub.self)
        defer { URLProtocol.unregisterClass(PresignedUploadStub.self) }
        PresignedUploadStub.statusCode = 500
        PresignedUploadStub.headers = ["cf-ray": "a45b07659cec62ca-HAM", "Content-Type": "application/xml"]
        let service = makeSignedInService(scope: Self.conversationScope)
        respond(
            refreshStatus: 204,
            presignStatus: 200,
            presignBody: Data(#"{"file_id":"file-1","upload_url":"https://\#(PresignedUploadStub.host)/file-1"}"#.utf8)
        )

        do {
            _ = try await service.uploadFile(Self.file)
            XCTFail("Expected the upload to fail")
        } catch FileUploadService.Error.unexpectedResponse(let response) {
            XCTAssertEqual(response.step, .put)
            XCTAssertEqual(response.statusCode, 500)
            XCTAssertEqual(response.rayID, "a45b07659cec62ca-HAM")
            XCTAssertEqual(response.contentType, "application/xml")
        }
    }

    func testMissingAccessToken_throwsAuthenticationRequiredWithoutRequestingPresign() async throws {
        auth0Provider.hasStoredCredentials = false
        let service = makeService()
        respond(refreshStatus: 204, presignStatus: 200)

        do {
            _ = try await service.uploadFile(Self.file)
            XCTFail("Expected the upload to fail")
        } catch FileUploadService.Error.authenticationRequired {
            XCTAssertEqual(client.requests.count, 1)
        }
    }

    func testMissingConversationScopes_throwsAuthenticationRequiredWithoutRequestingPresign() async throws {
        let service = makeSignedInService(scope: "openid profile email")
        respond(refreshStatus: 204, presignStatus: 200)

        do {
            _ = try await service.uploadFile(Self.file)
            XCTFail("Expected the upload to fail")
        } catch FileUploadService.Error.authenticationRequired {
            XCTAssertEqual(client.requests.count, 1)
        }
    }

    private func makeSignedInService(scope: String) -> FileUploadService {
        auth0Provider.hasStoredCredentials = true
        auth0Provider.mockCredentials = Credentials(
            accessToken: "mock-access-token",
            tokenType: "Bearer",
            idToken: "mock-id-token",
            refreshToken: "mock-refresh-token",
            expiresIn: Date().addingTimeInterval(3600),
            scope: scope
        )
        return makeService()
    }

    /// Production skips the staging Cloudflare Access bootstrap, which would make a real network call.
    private func makeService() -> FileUploadService {
        let authenticationService = EcosiaAuthenticationService(auth0Provider: auth0Provider)
        authenticationService.skipUserInfoFetch = true
        return FileUploadService(client: client, authenticationService: authenticationService, environment: .production)
    }

    /// The first request is the EAIST refresh, the second the presign.
    private func respond(
        refreshStatus: Int,
        presignStatus: Int,
        refreshHeaders: [String: String] = [:],
        presignBody: Data = Data()
    ) {
        client.executeBeforeResponse = { [unowned self] in
            let isRefresh = client.requests.count == 1
            client.data = isRefresh ? Data() : presignBody
            client.response = HTTPURLResponse(
                url: URL(string: "https://api.ecosia.org")!,
                statusCode: isRefresh ? refreshStatus : presignStatus,
                httpVersion: nil,
                headerFields: isRefresh ? refreshHeaders : nil
            )
        }
    }
}

/// Answers the presigned PUT, which goes through `URLSession.shared` rather than the injected client.
private final class PresignedUploadStub: URLProtocol {
    static let host = "r2.upload.test"
    nonisolated(unsafe) static var statusCode = 500
    nonisolated(unsafe) static var headers: [String: String] = [:]

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == host
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url,
              let response = HTTPURLResponse(
                url: url,
                statusCode: Self.statusCode,
                httpVersion: nil,
                headerFields: Self.headers
              ) else { return }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
