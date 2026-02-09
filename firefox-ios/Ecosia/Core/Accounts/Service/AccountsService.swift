// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol AccountsServiceProtocol {
    func registerVisit(accessToken: String) async throws -> AccountVisitResponse
}

public final class AccountsService: AccountsServiceProtocol {

    enum Error: Swift.Error {
        case network
        case invalidResponse
        case decodingError(String)
        case authenticationRequired
        case unauthorized
    }

    private let client: HTTPClient
    private let authenticationService: EcosiaAuthenticationService

    public init(client: HTTPClient = URLSessionHTTPClient(),
                authenticationService: EcosiaAuthenticationService = EcosiaAuthenticationService.shared) {
        self.client = client
        self.authenticationService = authenticationService
    }

    public func registerVisit(accessToken: String) async throws -> AccountVisitResponse {
        EcosiaLogger.accounts.info("🌱 [SEEDS-API] registerVisit() called")
        
        do {
            let response = try await performVisitRequest(accessToken: accessToken)
            EcosiaLogger.accounts.info("🌱 [SEEDS-API] registerVisit() completed successfully")
            return response
        } catch Error.unauthorized {
            EcosiaLogger.auth.info("🌱 [SEEDS-API] Access token expired, attempting to renew credentials")
            do {
                try await authenticationService.renewCredentialsIfNeeded()
                EcosiaLogger.auth.info("🌱 [SEEDS-API] Credentials renewed, retrying visit request")
            } catch {
                EcosiaLogger.auth.error("🌱 [SEEDS-API] Failed to renew credentials: \(error)")
                throw Error.authenticationRequired
            }

            guard let refreshedToken = authenticationService.accessToken, !refreshedToken.isEmpty else {
                EcosiaLogger.auth.error("🌱 [SEEDS-API] Renewed credentials do not expose an access token")
                throw Error.authenticationRequired
            }

            let response = try await performVisitRequest(accessToken: refreshedToken)
            EcosiaLogger.accounts.info("🌱 [SEEDS-API] registerVisit() completed successfully (after token renewal)")
            return response
        }
    }

    private func performVisitRequest(accessToken: String) async throws -> AccountVisitResponse {
        let request = AccountVisitRequest(accessToken: accessToken)

        EcosiaLogger.network.info("🌱 [SEEDS-API] Making accounts visit request to: \(request.baseURL.absoluteString)\(request.path)")
        
        #if DEBUG
        // Log first few characters of access token for debugging
        let tokenPrefix = String(accessToken.prefix(20))
        EcosiaLogger.network.debug("🌱 [SEEDS-API] [DEBUG-ONLY] Access token prefix: \(tokenPrefix)...")
        #endif

        let (data, response) = try await client.perform(request)

        guard let response else {
            EcosiaLogger.network.error("🌱 [SEEDS-API] Accounts visit request failed: No response received")
            throw Error.network
        }

        EcosiaLogger.network.info("🌱 [SEEDS-API] Accounts visit response: status=\(response.statusCode), dataSize=\(data.count) bytes")

        switch response.statusCode {
        case 200:
            EcosiaLogger.network.info("🌱 [SEEDS-API] ✅ Request successful (200)")
            break
        case 401:
            EcosiaLogger.network.error("🌱 [SEEDS-API] ❌ Unauthorized (401): Invalid or expired access token")
            throw Error.unauthorized
        case 403:
            EcosiaLogger.network.error("🌱 [SEEDS-API] ❌ Forbidden (403): Valid token but insufficient permissions - check scopes")
            throw Error.unauthorized // We can treat 403 same as 401 for now
        default:
            EcosiaLogger.network.error("🌱 [SEEDS-API] ❌ Request failed with status: \(response.statusCode)")
            throw Error.network
        }

        do {
            EcosiaLogger.network.info("🌱 [SEEDS-API] Decoding response data...")
            
            #if DEBUG
            // Log raw JSON for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                EcosiaLogger.network.debug("🌱 [SEEDS-API] [DEBUG-ONLY] Raw response JSON: \(responseString)")
            }
            #endif
            
            let decodedResponse = try JSONDecoder().decode(AccountVisitResponse.self, from: data)
            
            EcosiaLogger.network.info("🌱 [SEEDS-API] ✅ Response decoded successfully")
            EcosiaLogger.network.info("🌱 [SEEDS-API] Summary: seeds=\(decodedResponse.seeds.totalAmount), seedsModified=\(decodedResponse.seeds.isModified), level=\(decodedResponse.growthPoints.level.number), levelUp=\(decodedResponse.didLevelUp)")
            
            return decodedResponse
        } catch {
            EcosiaLogger.network.error("🌱 [SEEDS-API] ❌ Response decoding failed: \(error.localizedDescription)")
            if let responseString = String(data: data, encoding: .utf8) {
                EcosiaLogger.network.error("🌱 [SEEDS-API] Raw response data: \(responseString)")
            }
            throw Error.decodingError(error.localizedDescription)
        }
    }
}
