// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Thread-safe statistics manager using actor isolation
/// Based on [Swift Concurrency Agent Skill](https://github.com/AvdLee/Swift-Concurrency-Agent-Skill) actor patterns
public actor Statistics {
    public struct Response: Decodable {
        var results: [Result]
    }
    public struct Result: Decodable {
        var name: String
        var value: String
        var lastUpdated: String?

        enum StatisticName: String, Decodable {
            case treesPlanted = "Total Trees Planted"
            case timePerTree = "Time per tree (seconds)"
            case searchesPerTree = "Searches per tree"
            case activeUsers = "Active Users"
            case eurToUsdMultiplier = "EUR=>USD"
            case investmentPerSecond = "Investments amount per second"
            case totalInvestments = "Total investments amount"
        }

        func statisticName() -> StatisticName? { StatisticName(rawValue: name) }

        func doubleValue() -> Double? { Double(value) }

        func lastUpdatedDate() -> Date? {
            guard let dateString = lastUpdated else { return nil }
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return formatter.date(from: dateString)
        }
    }

    public static let shared = Statistics()
    // Ecosia: defaults updated from live API on 2026-02-26 (previously Nov 2020 hardcoded values)
    public internal(set) var treesPlanted = Double(244_418_472)                                    // "2025-12-01T16:34:00.0Z"
    public internal(set) var treesPlantedLastUpdated = Date(timeIntervalSince1970: 1_764_606_840)  // 2025-12-01T16:34:00Z
    public internal(set) var timePerTree = Double(2.2)
    public internal(set) var searchesPerTree = Double(50)
    public internal(set) var activeUsers = Double(20000000)
    public internal(set) var eurToUsdMultiplier = Double(1.08)
    public internal(set) var investmentPerSecond = Double(0.25)
    public internal(set) var totalInvestments = Double(88_666_760)                                 // "2024-10-08T00:00:00.000000Z"
    public internal(set) var totalInvestmentsLastUpdated = Date(timeIntervalSince1970: 1_728_345_600) // 2024-10-08T00:00:00Z

    init() { }

    // MARK: - Test Helpers
    // Internal setters for testing purposes
    internal func setTotalInvestments(_ value: Double) {
        totalInvestments = value
    }

    internal func setTotalInvestmentsLastUpdated(_ date: Date) {
        totalInvestmentsLastUpdated = date
    }

    internal func setInvestmentPerSecond(_ value: Double) {
        investmentPerSecond = value
    }

    internal func setTreesPlanted(_ value: Double) {
        treesPlanted = value
    }

    internal func setTreesPlantedLastUpdated(_ date: Date) {
        treesPlantedLastUpdated = date
    }

    internal func setTimePerTree(_ value: Double) {
        timePerTree = value
    }

    public func fetchAndUpdate(urlSession: URLSessionProtocol = URLSession.shared) async throws {
        let (data, _) = try await urlSession.data(from: EcosiaEnvironment.current.urlProvider.statistics)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(Response.self, from: data)
        response.results.forEach { statistic in
            switch statistic.statisticName() {
            case .treesPlanted:
                if let value = statistic.doubleValue(),
                    let date = statistic.lastUpdatedDate() {
                    treesPlanted = value
                    treesPlantedLastUpdated = date
                }
            case .timePerTree: timePerTree = statistic.doubleValue() ?? timePerTree
            case .searchesPerTree: searchesPerTree = statistic.doubleValue() ?? searchesPerTree
            case .activeUsers: activeUsers = statistic.doubleValue() ?? activeUsers
            case .eurToUsdMultiplier: eurToUsdMultiplier = statistic.doubleValue() ?? eurToUsdMultiplier
            case .investmentPerSecond: investmentPerSecond = statistic.doubleValue() ?? investmentPerSecond
            case .totalInvestments:
                if let value = statistic.doubleValue(),
                    let date = statistic.lastUpdatedDate() {
                    totalInvestments = value
                    totalInvestmentsLastUpdated = date
                }
            case nil: break
            }
        }
    }
}
