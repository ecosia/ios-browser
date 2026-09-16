// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct PlanetPulseSelector: Sendable {
    private let calendar: Calendar

    public init(calendar: Calendar = .autoupdatingCurrent) {
        self.calendar = calendar
    }

    public func card(
        for mode: PlanetPulseMode,
        at date: Date,
        from cards: [PlanetPulseCard]
    ) -> PlanetPulseCard {
        let dayNumber = dayNumber(for: date)
        let kind = preferredKind(for: mode, dayNumber: dayNumber)
        let preferredCards = cards.filter { $0.kind == kind }

        if let card = select(from: preferredCards, dayNumber: dayNumber) {
            return card
        }

        if mode == .mixed {
            let alternateKind: PlanetPulseCardKind = kind == .action ? .insight : .action
            if let card = select(
                from: cards.filter { $0.kind == alternateKind },
                dayNumber: dayNumber
            ) {
                return card
            }
        }

        return fallback(for: kind)
    }

    public func startOfNextDay(after date: Date) -> Date {
        let startOfDay = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: 1, to: startOfDay)
            ?? date.addingTimeInterval(86_400)
    }

    private func preferredKind(
        for mode: PlanetPulseMode,
        dayNumber: Int
    ) -> PlanetPulseCardKind {
        switch mode {
        case .smallAction:
            return .action
        case .stayInformed:
            return .insight
        case .mixed:
            return dayNumber.isMultiple(of: 2) ? .action : .insight
        }
    }

    private func dayNumber(for date: Date) -> Int {
        let referenceDate = Date(timeIntervalSince1970: 0)
        let referenceDay = calendar.startOfDay(for: referenceDate)
        let selectedDay = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: referenceDay, to: selectedDay).day ?? 0
    }

    private func select(
        from cards: [PlanetPulseCard],
        dayNumber: Int
    ) -> PlanetPulseCard? {
        guard !cards.isEmpty else { return nil }
        let index = ((dayNumber % cards.count) + cards.count) % cards.count
        return cards[index]
    }

    private func fallback(for kind: PlanetPulseCardKind) -> PlanetPulseCard {
        switch kind {
        case .action:
            return PlanetPulseContent.fallbackAction
        case .insight:
            return PlanetPulseContent.fallbackInsight
        }
    }
}
