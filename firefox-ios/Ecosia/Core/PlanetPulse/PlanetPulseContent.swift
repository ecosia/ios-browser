// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public enum PlanetPulseContent {
    public static var cards: [PlanetPulseCard] {
        [
            cityTrees,
            undergroundForest,
            cerrado,
            impactMilestone,
            wildfireRecovery,
            useLeftovers,
            repairBeforeReplacing,
            lighterTrip,
            plantForwardMeal,
            coolerWash,
            borrowBeforeBuying
        ]
    }

    public static var fallbackAction: PlanetPulseCard {
        useLeftovers
    }

    public static var fallbackInsight: PlanetPulseCard {
        undergroundForest
    }

    private static var cityTrees: PlanetPulseCard {
        PlanetPulseCard(
            id: "city-trees-cooling",
            kind: .insight,
            title: .localized(.planetPulseCityTreesTitle),
            body: .localized(.planetPulseCityTreesBody),
            callToAction: .localized(.planetPulseCityTreesCTA),
            destination: article(
                "https://blog.ecosia.org/cities-need-trees-to-survive-the-heat/",
                fallbackQuery: .localized(.planetPulseCityTreesQuery)
            ),
            sourceName: "Ecosia",
            publishedAt: date(year: 2026, month: 8, day: 12)
        )
    }

    private static var undergroundForest: PlanetPulseCard {
        PlanetPulseCard(
            id: "underground-forest",
            kind: .insight,
            title: .localized(.planetPulseUndergroundForestTitle),
            body: .localized(.planetPulseUndergroundForestBody),
            callToAction: .localized(.planetPulseUndergroundForestCTA),
            destination: article(
                "https://blog.ecosia.org/growing-a-forest-without-planting-trees/",
                fallbackQuery: .localized(.planetPulseUndergroundForestQuery)
            ),
            sourceName: "Ecosia",
            publishedAt: date(year: 2026, month: 1, day: 28)
        )
    }

    private static var cerrado: PlanetPulseCard {
        PlanetPulseCard(
            id: "cerrado-corridor",
            kind: .insight,
            title: .localized(.planetPulseCerradoTitle),
            body: .localized(.planetPulseCerradoBody),
            callToAction: .localized(.planetPulseCerradoCTA),
            destination: article(
                "https://blog.ecosia.org/restoring-the-worlds-most-biodiverse-savanna/",
                fallbackQuery: .localized(.planetPulseCerradoQuery)
            ),
            sourceName: "Ecosia",
            publishedAt: date(year: 2026, month: 4, day: 7)
        )
    }

    private static var impactMilestone: PlanetPulseCard {
        PlanetPulseCard(
            id: "trees-milestone",
            kind: .insight,
            title: .localized(.planetPulseMilestoneTitle),
            body: .localized(.planetPulseMilestoneBody),
            callToAction: .localized(.planetPulseMilestoneCTA),
            destination: article(
                "https://blog.ecosia.org/250-million-trees/",
                fallbackQuery: .localized(.planetPulseMilestoneQuery)
            ),
            sourceName: "Ecosia",
            publishedAt: date(year: 2026, month: 4, day: 22)
        )
    }

    private static var wildfireRecovery: PlanetPulseCard {
        PlanetPulseCard(
            id: "wildfire-recovery",
            kind: .insight,
            title: .localized(.planetPulseWildfireTitle),
            body: .localized(.planetPulseWildfireBody),
            callToAction: .localized(.planetPulseWildfireCTA),
            destination: article(
                "https://blog.ecosia.org/portugal-wildfire-recovery-on-community-land/",
                fallbackQuery: .localized(.planetPulseWildfireQuery)
            ),
            sourceName: "Ecosia",
            publishedAt: date(year: 2026, month: 6, day: 24)
        )
    }

    private static var useLeftovers: PlanetPulseCard {
        actionCard(
            id: "use-leftovers",
            title: .planetPulseLeftoversTitle,
            body: .planetPulseLeftoversBody,
            callToAction: .planetPulseLeftoversCTA,
            query: .planetPulseLeftoversQuery
        )
    }

    private static var repairBeforeReplacing: PlanetPulseCard {
        actionCard(
            id: "repair-before-replacing",
            title: .planetPulseRepairTitle,
            body: .planetPulseRepairBody,
            callToAction: .planetPulseRepairCTA,
            query: .planetPulseRepairQuery
        )
    }

    private static var lighterTrip: PlanetPulseCard {
        actionCard(
            id: "lighter-trip",
            title: .planetPulseTripTitle,
            body: .planetPulseTripBody,
            callToAction: .planetPulseTripCTA,
            query: .planetPulseTripQuery
        )
    }

    private static var plantForwardMeal: PlanetPulseCard {
        actionCard(
            id: "plant-forward-meal",
            title: .planetPulseMealTitle,
            body: .planetPulseMealBody,
            callToAction: .planetPulseMealCTA,
            query: .planetPulseMealQuery
        )
    }

    private static var coolerWash: PlanetPulseCard {
        actionCard(
            id: "cooler-wash",
            title: .planetPulseWashTitle,
            body: .planetPulseWashBody,
            callToAction: .planetPulseWashCTA,
            query: .planetPulseWashQuery
        )
    }

    private static var borrowBeforeBuying: PlanetPulseCard {
        actionCard(
            id: "borrow-before-buying",
            title: .planetPulseBorrowTitle,
            body: .planetPulseBorrowBody,
            callToAction: .planetPulseBorrowCTA,
            query: .planetPulseBorrowQuery
        )
    }

    private static func actionCard(
        id: String,
        title: String.Key,
        body: String.Key,
        callToAction: String.Key,
        query: String.Key
    ) -> PlanetPulseCard {
        PlanetPulseCard(
            id: id,
            kind: .action,
            title: .localized(title),
            body: .localized(body),
            callToAction: .localized(callToAction),
            destination: .search(query: .localized(query))
        )
    }

    private static func article(_ value: String, fallbackQuery: String) -> PlanetPulseDestination {
        guard let url = URL(string: value) else {
            return .search(query: fallbackQuery)
        }
        return .article(url)
    }

    private static func date(year: Int, month: Int, day: Int) -> Date? {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day
        return components.date
    }
}
