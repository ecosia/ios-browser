// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol AccountsProviderProtocol {
    func registerVisit(accessToken: String) async throws -> AccountVisitResponse
}

public struct AccountsProvider: AccountsProviderProtocol {

    public let accountsService: AccountsServiceProtocol
    private let useMockData: Bool

    public init(
        accountsService: AccountsServiceProtocol = AccountsService(),
        useMockData: Bool = false
    ) {
        self.accountsService = accountsService
        self.useMockData = useMockData
    }

    /// Registers a user visit and returns current balance.
    /// This endpoint automatically handles visit-based use cases and returns the current balance,
    /// including indicating if it has changed as a result of this call.
    /// - Parameter accessToken: Valid Auth0-issued JWT access token
    public func registerVisit(accessToken: String) async throws -> AccountVisitResponse {
        if useMockData {
            EcosiaLogger.accounts.info("Using mock response for testing")
            return createMockResponse()
        } else {
            return try await accountsService.registerVisit(accessToken: accessToken)
        }
    }

    // MARK: - Mock Response Generation

    private func createMockResponse() -> AccountVisitResponse {
        let currentBalance = 42 // Default mock balance
        let increment = Int.random(in: 1...5) // Random increment for testing

        return AccountVisitResponse(
            balance: AccountVisitResponse.Balance(
                amount: currentBalance + increment,
                updatedAt: ISO8601DateFormatter().string(from: Date()),
                isModified: true
            ),
            previousBalance: AccountVisitResponse.PreviousBalance(
                amount: currentBalance
            )
        )
    }
}
