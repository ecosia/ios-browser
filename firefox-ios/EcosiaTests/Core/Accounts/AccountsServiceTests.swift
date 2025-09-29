// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class AccountsServiceTests: XCTestCase {

    private var mockHTTPClient: HTTPClientMock!
    private var accountsService: AccountsService!

    override func setUp() {
        super.setUp()
        mockHTTPClient = HTTPClientMock()
        accountsService = AccountsService(client: mockHTTPClient)
    }

    func testRegisterVisit_Success() async throws {
        // Arrange
        let expectedResponse = AccountVisitResponse(
            balance: AccountVisitResponse.Balance(
                amount: 5,
                updatedAt: "2024-12-07T10:50:26Z",
                isModified: true
            ),
            previousBalance: AccountVisitResponse.PreviousBalance(amount: 4)
        )
        let responseData = try JSONEncoder().encode(expectedResponse)
        mockHTTPClient.data = responseData
        mockHTTPClient.response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        // Act
        let response = try await accountsService.registerVisit(accessToken: "test-access-token")

        // Assert
        XCTAssertEqual(response.balance.amount, 5)
        XCTAssertEqual(response.balance.isModified, true)
        XCTAssertEqual(response.previousBalance?.amount, 4)
        XCTAssertEqual(response.balanceIncrement, 1)
        XCTAssertEqual(mockHTTPClient.requests.count, 1)

        let request = mockHTTPClient.requests.first as? AccountVisitRequest
        XCTAssertNotNil(request)
        XCTAssertEqual(request?.additionalHeaders?["Authorization"], "Bearer test-access-token")
    }

    func testRegisterVisit_NetworkError() async throws {
        // Arrange
        mockHTTPClient.response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )

        // Act & Assert
        do {
            _ = try await accountsService.registerVisit(accessToken: "test-access-token")
            XCTFail("Expected network error")
        } catch AccountsService.Error.network {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testBalanceIncrement_NoChange() {
        // Arrange
        let response = AccountVisitResponse(
            balance: AccountVisitResponse.Balance(
                amount: 5,
                updatedAt: "2024-12-07T10:50:26Z",
                isModified: false
            ),
            previousBalance: AccountVisitResponse.PreviousBalance(amount: 5)
        )

        // Act & Assert
        XCTAssertNil(response.balanceIncrement)
    }

    func testBalanceIncrement_WithChange() {
        // Arrange
        let response = AccountVisitResponse(
            balance: AccountVisitResponse.Balance(
                amount: 8,
                updatedAt: "2024-12-07T10:50:26Z",
                isModified: true
            ),
            previousBalance: AccountVisitResponse.PreviousBalance(amount: 5)
        )

        // Act & Assert
        XCTAssertEqual(response.balanceIncrement, 3)
    }

    func testRegisterVisit_UnauthorizedError() async throws {
        // Arrange
        mockHTTPClient.response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )

        // Act & Assert
        do {
            _ = try await accountsService.registerVisit(accessToken: "invalid-token")
            XCTFail("Expected unauthorized error")
        } catch AccountsService.Error.unauthorized {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
