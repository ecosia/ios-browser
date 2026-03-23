// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// MARK: - Model

/// Decoded response from the rotating-titles CDN endpoint.
///
/// Real JSON shape:
/// ```json
/// {
///   "version": 1,
///   "rotation": { "start_date": "2026-01-01", "frequency_days": 1 },
///   "order": [{ "category": "Product", "index": 0 }, ...],
///   "titles": {
///     "Product": [{ "en": "AI that answers to the planet", "de": "...", ... }],
///     ...
///   }
/// }
/// ```
public struct RotatingTitlesResponse: Decodable {
    public let version: Int
    public let rotation: RotationConfig
    public let order: [TitleOrder]
    public let titles: [String: [LocalizedTitle]]

    public struct RotationConfig: Decodable {
        public let startDate: String
        public let frequencyDays: Int

        enum CodingKeys: String, CodingKey {
            case startDate = "start_date"
            case frequencyDays = "frequency_days"
        }
    }

    public struct TitleOrder: Decodable {
        public let category: String
        public let index: Int
    }

    public typealias LocalizedTitle = [String: String]

    /// Returns titles in the CDN-defined order, localised to `languageCode`.
    /// Falls back to English when the language is not available for a given entry.
    public func orderedTitles(for languageCode: String) -> [String] {
        order.compactMap { entry in
            guard let categoryTitles = titles[entry.category],
                  entry.index < categoryTitles.count else { return nil }
            let localized = categoryTitles[entry.index]
            return localized[languageCode] ?? localized["en"]
        }
    }

    /// Returns the index into `orderedTitles` that corresponds to `date`, using the same
    /// deterministic algorithm as the web implementation so all clients show the same title
    /// on the same UTC day.
    ///
    /// Algorithm (mirrors web `getRotatingTitle`):
    ///   daysSinceEpoch = utcDayNumber(today) − utcDayNumber(startDate)
    ///   idx = ((daysSinceEpoch % count) + count) % count   ← safe modulo handles negatives
    public func startingIndex(for date: Date = Date(), count: Int) -> Int {
        guard count > 0 else { return 0 }
        let epoch = Self.utcDate(from: rotation.startDate) ?? Self.fallbackEpoch
        let daysSinceEpoch = Self.utcDayNumber(for: date) - Self.utcDayNumber(for: epoch)
        return ((daysSinceEpoch % count) + count) % count
    }

    // MARK: - UTC helpers (mirrors web utcDayNumber)

    /// Integer UTC day number (days since Unix epoch 1970-01-01), matching the web implementation.
    static func utcDayNumber(for date: Date) -> Int {
        Int(floor(date.timeIntervalSince1970 / 86400))
    }

    /// Parses an ISO-8601 date string ("2026-01-01") into a UTC midnight `Date`.
    static func utcDate(from string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: string)
    }

    /// Hard-coded fallback epoch used when the CDN `start_date` cannot be parsed.
    /// Kept in sync with the web constant `Date.UTC(2026, 0, 1)`.
    static var fallbackEpoch: Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 1
        components.timeZone = TimeZone(identifier: "UTC")
        return Calendar(identifier: .gregorian).date(from: components) ?? Date()
    }
}

// MARK: - Service

/// Serves the daily USP title following a simple two-path rule:
///   • CDN reachable  → show the correct title and persist it for future launches.
///   • CDN unreachable AND no persisted result → show the localized fallback.
///
/// Caching layers (in priority order):
///   1. In-memory (`sessionTitles`) — set once per session; returned instantly on repeat calls.
///   2. UserDefaults — ordered (non-rotated) titles + `start_date`, keyed per language code
///      so a locale change automatically triggers a fresh CDN fetch.
///   3. Localized fallback — a single string, only shown when both CDN and cache are absent.
@MainActor
public final class RotatingTitlesService {

    public static let shared = RotatingTitlesService()

    /// Shown only when the CDN is unreachable and no persisted cache exists.
    public static var fallbackTitles: [String] {
        [.localized(.ntpFallbackTitleSearchFindSave)]
    }

    private enum CacheKey {
        static func orderedTitles(language: String) -> String  { "ecosia.rotatingTitles.ordered.\(language)" }
        static func startDate(language: String) -> String      { "ecosia.rotatingTitles.startDate.\(language)" }
        static func cachedAt(language: String) -> String       { "ecosia.rotatingTitles.cachedAt.\(language)" }
        static func frequencyDays(language: String) -> String  { "ecosia.rotatingTitles.frequencyDays.\(language)" }
    }

    private var sessionTitles: [String]?
    private var inFlightTask: Task<[String], Never>?

    private init() {}

    // MARK: - Public API

    /// Returns today's title for the current device language.
    /// Resolution order: in-memory → UserDefaults cache → CDN (cached on success) → fallback.
    public func titles(session: URLSession = .shared, date: Date = Date()) async -> [String] {
        if let cached = sessionTitles { return cached }

        // Deduplicate concurrent callers.
        if let ongoing = inFlightTask { return await ongoing.value }

        let task = Task<[String], Never> { [weak self] in
            guard let self else { return Self.fallbackTitles }
            return await self.resolve(session: session, date: date)
        }
        inFlightTask = task
        let result = await task.value
        inFlightTask = nil
        return result
    }

    /// Clears both the in-memory and all persisted caches.
    public func invalidate() {
        sessionTitles = nil
        inFlightTask?.cancel()
        inFlightTask = nil
        let defaults = UserDefaults.standard
        defaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix("ecosia.rotatingTitles.") }
            .forEach { defaults.removeObject(forKey: $0) }
    }

    // MARK: - Resolution

    private func resolve(session: URLSession, date: Date) async -> [String] {
        let languageCode = Language.current.rawValue

        // 1. Persisted cache — valid only if it hasn't exceeded the CDN's frequency_days TTL.
        if let ordered = loadOrderedTitles(language: languageCode), !isCacheExpired(language: languageCode, date: date) {
            let startDate = loadStartDate(language: languageCode)
            let result = Self.applyRotation(to: ordered, startDate: startDate, date: date)
            sessionTitles = result
            return result
        }

        // 2. CDN — persist on success, fall back on failure.
        if let result = await fetchFromCDN(session: session, languageCode: languageCode, date: date) {
            sessionTitles = result
            return result
        }

        return Self.fallbackTitles
    }

    private func fetchFromCDN(session: URLSession, languageCode: String, date: Date) async -> [String]? {
        let url = EcosiaEnvironment.current.urlProvider.rotatingTitles
        guard let (data, _) = try? await session.data(from: url),
              let response = try? JSONDecoder().decode(RotatingTitlesResponse.self, from: data)
        else { return nil }

        let ordered = response.orderedTitles(for: languageCode)
        guard !ordered.isEmpty else { return nil }

        persist(ordered: ordered, startDate: response.rotation.startDate, frequencyDays: response.rotation.frequencyDays, language: languageCode)
        return Self.applyRotation(to: ordered, startDate: response.rotation.startDate, date: date)
    }

    // MARK: - UserDefaults

    private func loadOrderedTitles(language: String) -> [String]? {
        UserDefaults.standard.array(forKey: CacheKey.orderedTitles(language: language)) as? [String]
    }

    private func loadStartDate(language: String) -> String? {
        UserDefaults.standard.string(forKey: CacheKey.startDate(language: language))
    }

    private func persist(ordered: [String], startDate: String, frequencyDays: Int, language: String) {
        let defaults = UserDefaults.standard
        defaults.set(ordered, forKey: CacheKey.orderedTitles(language: language))
        defaults.set(startDate, forKey: CacheKey.startDate(language: language))
        defaults.set(Date(), forKey: CacheKey.cachedAt(language: language))
        defaults.set(frequencyDays, forKey: CacheKey.frequencyDays(language: language))
    }

    /// Returns `true` when the cache is older than the CDN-specified `frequency_days`.
    /// A missing timestamp is treated as expired so stale caches from before this logic
    /// was introduced are always refreshed.
    private func isCacheExpired(language: String, date: Date) -> Bool {
        guard let cachedAt = UserDefaults.standard.object(forKey: CacheKey.cachedAt(language: language)) as? Date
        else { return true }
        let frequencyDays = UserDefaults.standard.integer(forKey: CacheKey.frequencyDays(language: language))
        let ttlDays = frequencyDays > 0 ? frequencyDays : 1
        let secondsPerDay: TimeInterval = 86_400
        return date.timeIntervalSince(cachedAt) >= Double(ttlDays) * secondsPerDay
    }

    // MARK: - Rotation

    /// Rotates `array` so the element at `index` becomes the first element.
    static func rotate<T>(_ array: [T], by index: Int) -> [T] {
        guard array.count > 1, index > 0 else { return array }
        let safe = index % array.count
        return Array(array[safe...]) + Array(array[..<safe])
    }

    /// Returns `fallbackTitles` unchanged (single entry — rotation is a no-op).
    public static func rotatedFallback(for date: Date = Date()) -> [String] { fallbackTitles }

    private static func applyRotation(to ordered: [String], startDate: String?, date: Date) -> [String] {
        let epoch = startDate.flatMap { RotatingTitlesResponse.utcDate(from: $0) }
                 ?? RotatingTitlesResponse.fallbackEpoch
        let daysSinceEpoch = RotatingTitlesResponse.utcDayNumber(for: date)
                           - RotatingTitlesResponse.utcDayNumber(for: epoch)
        let count = ordered.count
        let idx = ((daysSinceEpoch % count) + count) % count
        return rotate(ordered, by: idx)
    }
}
