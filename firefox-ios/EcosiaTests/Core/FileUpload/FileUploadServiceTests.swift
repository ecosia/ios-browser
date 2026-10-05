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
    private func respond(refreshStatus: Int, presignStatus: Int) {
        client.executeBeforeResponse = { [unowned self] in
            let statusCode = client.requests.count == 1 ? refreshStatus : presignStatus
            client.response = HTTPURLResponse(
                url: URL(string: "https://api.ecosia.org")!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )
        }
    }
}
