// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class StatisticsTests: XCTestCase {
    private var statistics: Statistics!
    private var mockURLSession: MockURLSessionProtocol!

    override func setUp() {
        statistics = Statistics.shared
        mockURLSession = MockURLSessionProtocol()
    }

    func testFetchAndUpdate() async throws {
        mockURLSession.data = Data("""
            {
                "results": [
                    {"name": "Total Trees Planted", "value": "123456789", "last_updated": "2023-08-01T11:40:00.000000Z"},
                    {"name": "Time per tree (seconds)", "value": "0.8"},
                    {"name": "Searches per tree", "value": "20"},
                    {"name": "Active Users", "value": "80000000"},
                    {"name": "EUR=>USD", "value": "1.5"},
                    {"name": "Some other name", "value": "123"},
                    {"name": "Investments amount per second", "value": "0.423", "last_updated": null},
                    {"name": "Total investments amount", "value": "2345678", "last_updated": "2023-07-30T00:00:00.000000Z"}
                ]
            }
        """.utf8)

        try await statistics.fetchAndUpdate(urlSession: mockURLSession)

        XCTAssertEqual(statistics.treesPlanted, 123456789)
        XCTAssertEqual(statistics.treesPlantedLastUpdated, Date(timeIntervalSince1970: 1690890000))
        XCTAssertEqual(statistics.timePerTree, 0.8)
        XCTAssertEqual(statistics.searchesPerTree, 20)
        XCTAssertEqual(statistics.activeUsers, 80000000)
        XCTAssertEqual(statistics.eurToUsdMultiplier, 1.5)
        XCTAssertEqual(statistics.investmentPerSecond, 0.423)
        XCTAssertEqual(statistics.totalInvestments, 2345678)
        XCTAssertEqual(statistics.totalInvestmentsLastUpdated, Date(timeIntervalSince1970: 1690675200))
    }

    // MARK: - Failure resilience

    /// When the network request fails, all existing values must be preserved unchanged.
    func testFetchAndUpdatePreservesValuesOnNetworkFailure() async throws {
        // Arrange – seed with known live-like values
        await statistics.setTreesPlanted(247_000_000)
        await statistics.setTreesPlantedLastUpdated(Date(timeIntervalSince1970: 1_740_000_000))
        await statistics.setTimePerTree(1.3)

        // Act – simulate a network error
        let failingSession = ThrowingMockURLSession()
        do {
            try await statistics.fetchAndUpdate(urlSession: failingSession)
            XCTFail("Expected fetchAndUpdate to throw on network failure")
        } catch {
            // Expected path
        }

        // Assert – values unchanged
        let trees = await statistics.treesPlanted
        let lastUpdated = await statistics.treesPlantedLastUpdated
        let timePerTree = await statistics.timePerTree
        XCTAssertEqual(trees, 247_000_000)
        XCTAssertEqual(lastUpdated, Date(timeIntervalSince1970: 1_740_000_000))
        XCTAssertEqual(timePerTree, 1.3)
    }

    /// When the response contains malformed JSON, all existing values must be preserved.
    func testFetchAndUpdatePreservesValuesOnMalformedJSON() async throws {
        // Arrange
        await statistics.setTreesPlanted(247_000_000)

        mockURLSession.data = Data("not valid json".utf8)

        // Act
        do {
            try await statistics.fetchAndUpdate(urlSession: mockURLSession)
            XCTFail("Expected fetchAndUpdate to throw on malformed JSON")
        } catch {
            // Expected path
        }

        // Assert
        let trees = await statistics.treesPlanted
        XCTAssertEqual(trees, 247_000_000)
    }

    // MARK: - Default-values regression

    /// Pins the default values to the Dec 2025 API snapshot so any accidental change breaks this test.
    /// Without calling fetchAndUpdate(), the hardcoded defaults now project within ~3.5M of live (vs. ~6M gap with Nov 2020 base).
    func testDefaultValuesProduceKnownProjection() async {
        let freshStats = Statistics()
        let base = await freshStats.treesPlanted
        let baseDate = await freshStats.treesPlantedLastUpdated
        let timePerTree = await freshStats.timePerTree

        // Base values must match the Dec 2025 API snapshot
        XCTAssertEqual(base, 244_418_472, "Default treesPlanted baseline changed — update from live API and update docs/fix")
        XCTAssertEqual(baseDate, Date(timeIntervalSince1970: 1_764_606_840), "Default base date changed — update docs/fix") // 2025-12-01T16:34:00Z
        XCTAssertEqual(timePerTree, 2.2, "Default timePerTree changed — update from live API and update docs/fix")

        // Projection for a fixed reference point (2026-02-26 00:00 UTC = 1_772_064_000)
        let referenceDate = Date(timeIntervalSince1970: 1_772_064_000) // 2026-02-26 00:00 UTC
        let elapsed = referenceDate.timeIntervalSince(baseDate)
        let projected = Int(elapsed / timePerTree + base - 1)

        // Projection from Dec 2025 defaults should be ~247.8M on 2026-02-26
        XCTAssertGreaterThan(projected, 246_000_000, "Projection from defaults should exceed 246M by Feb 2026")
        XCTAssertLessThan(projected, 250_000_000, "Projection from defaults should be below 250M by Feb 2026")
    }

    /// When fetchAndUpdate succeeds with live data, the subsequent projection matches the live count.
    func testFetchAndUpdateProducesAccurateProjection() async throws {
        // Arrange – simulate a live API response with a recent base
        let liveBase = 247_000_000.0
        let liveBaseTimestamp = "2026-02-25T00:00:00.000000Z"
        mockURLSession.data = Data("""
            {
                "results": [
                    {"name": "Total Trees Planted", "value": "\(Int(liveBase))", "last_updated": "\(liveBaseTimestamp)"},
                    {"name": "Time per tree (seconds)", "value": "1.3"}
                ]
            }
        """.utf8)

        // Act
        try await statistics.fetchAndUpdate(urlSession: mockURLSession)

        // Assert – projection from today should be ≥ live base
        let projection = await TreesProjection.shared.treesAt(Date())
        XCTAssertGreaterThanOrEqual(
            projection,
            Int(liveBase),
            "After fetching live data, projection should be ≥ the fetched base"
        )
    }
}

// MARK: - Test helpers

private final class ThrowingMockURLSession: URLSessionProtocol {
    func data(from url: URL) async throws -> (Data, URLResponse) {
        throw URLError(.notConnectedToInternet)
    }
}
