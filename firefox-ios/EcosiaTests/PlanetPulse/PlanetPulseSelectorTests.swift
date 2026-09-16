// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class PlanetPulseSelectorTests: XCTestCase {
    func testSmallActionSelectsOnlyActionCards() {
        // Given
        let selector = PlanetPulseSelector(calendar: utcCalendar)
        let cards = [card(id: "insight", kind: .insight), card(id: "action", kind: .action)]

        // When
        let result = selector.card(for: .smallAction, at: referenceDate, from: cards)

        // Then
        XCTAssertEqual(result.kind, .action)
    }

    func testStayInformedSelectsOnlyInsightCards() {
        // Given
        let selector = PlanetPulseSelector(calendar: utcCalendar)
        let cards = [card(id: "action", kind: .action), card(id: "insight", kind: .insight)]

        // When
        let result = selector.card(for: .stayInformed, at: referenceDate, from: cards)

        // Then
        XCTAssertEqual(result.kind, .insight)
    }

    func testMixedAlternatesKindOnConsecutiveDays() {
        // Given
        let selector = PlanetPulseSelector(calendar: utcCalendar)
        let cards = [card(id: "action", kind: .action), card(id: "insight", kind: .insight)]
        let nextDate = utcCalendar.date(byAdding: .day, value: 1, to: referenceDate)

        // When
        let first = selector.card(for: .mixed, at: referenceDate, from: cards)
        let second = nextDate.map { selector.card(for: .mixed, at: $0, from: cards) }

        // Then
        XCTAssertNotNil(second)
        XCTAssertNotEqual(first.kind, second?.kind)
    }

    func testSelectionIsDeterministicForTheSameInputs() {
        // Given
        let selector = PlanetPulseSelector(calendar: utcCalendar)
        let cards = [
            card(id: "action-1", kind: .action),
            card(id: "action-2", kind: .action)
        ]

        // When
        let first = selector.card(for: .smallAction, at: referenceDate, from: cards)
        let second = selector.card(for: .smallAction, at: referenceDate, from: cards)

        // Then
        XCTAssertEqual(first, second)
    }

    func testEmptyCatalogUsesModeSpecificFallback() {
        // Given
        let selector = PlanetPulseSelector(calendar: utcCalendar)

        // When
        let action = selector.card(for: .smallAction, at: referenceDate, from: [])
        let insight = selector.card(for: .stayInformed, at: referenceDate, from: [])

        // Then
        XCTAssertEqual(action.kind, .action)
        XCTAssertEqual(insight.kind, .insight)
    }

    func testSelectionUsesTheInjectedCalendarDayBoundary() {
        // Given
        var losAngelesCalendar = Calendar(identifier: .gregorian)
        losAngelesCalendar.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .current
        let selector = PlanetPulseSelector(calendar: losAngelesCalendar)
        let cards = [
            card(id: "action-1", kind: .action),
            card(id: "action-2", kind: .action)
        ]
        let earlyUTC = date("2026-01-02T01:00:00Z")
        let laterUTC = date("2026-01-02T07:00:00Z")

        // When
        let earlyCard = selector.card(for: .smallAction, at: earlyUTC, from: cards)
        let laterCard = selector.card(for: .smallAction, at: laterUTC, from: cards)

        // Then
        XCTAssertEqual(earlyCard, laterCard)
    }

    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }

    private var referenceDate: Date {
        date("2026-01-15T12:00:00Z")
    }

    private func date(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value) ?? Date(timeIntervalSince1970: 0)
    }

    private func card(id: String, kind: PlanetPulseCardKind) -> PlanetPulseCard {
        PlanetPulseCard(
            id: id,
            kind: kind,
            title: id,
            body: id,
            callToAction: id,
            destination: .search(query: id)
        )
    }
}
