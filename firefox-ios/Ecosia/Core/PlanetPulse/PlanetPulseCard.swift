// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public enum PlanetPulseMode: Equatable, Sendable {
    case smallAction
    case stayInformed
    case mixed
}

public enum PlanetPulseCardKind: Hashable, Sendable {
    case action
    case insight
}

public enum PlanetPulseDestination: Equatable, Sendable {
    case search(query: String)
    case article(URL)
}

public struct PlanetPulseCard: Equatable, Sendable {
    public let id: String
    public let kind: PlanetPulseCardKind
    public let title: String
    public let body: String
    public let callToAction: String
    public let destination: PlanetPulseDestination
    public let sourceName: String?
    public let publishedAt: Date?

    public init(
        id: String,
        kind: PlanetPulseCardKind,
        title: String,
        body: String,
        callToAction: String,
        destination: PlanetPulseDestination,
        sourceName: String? = nil,
        publishedAt: Date? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.body = body
        self.callToAction = callToAction
        self.destination = destination
        self.sourceName = sourceName
        self.publishedAt = publishedAt
    }
}
