// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// Queries Apple's default-browser API on a sparse schedule, since iOS only answers a few times a year.
@MainActor
public final class DefaultBrowserStatusChecker {
    static let nextCheckDateKey = "ecosiaDefaultBrowserStatusNextCheckDateKey"
    static let retryAvailabilityDateKey = "UIApplicationCategoryDefaultRetryAvailabilityDateErrorKey"
    static let checkInterval = DateComponents(month: 6)

    public static let shared = DefaultBrowserStatusChecker()

    private let defaults: UserDefaults
    private let calendar: Calendar
    private let now: () -> Date
    private let isFreshInstall: () -> Bool
    private let queryIsDefault: @MainActor () throws -> Bool?

    init(defaults: UserDefaults = .standard,
         calendar: Calendar = .current,
         now: @escaping () -> Date = Date.init,
         isFreshInstall: @escaping () -> Bool = { EcosiaInstallType.get() == .fresh },
         queryIsDefault: @escaping @MainActor () throws -> Bool? = DefaultBrowserStatusChecker.querySystem) {
        self.defaults = defaults
        self.calendar = calendar
        self.now = now
        self.isFreshInstall = isFreshInstall
        self.queryIsDefault = queryIsDefault
    }

    /// Returns whether Ecosia is the default browser when a check is due and the system answers, `nil` otherwise.
    public func checkIfDue() -> Bool? {
        let currentDate = now()
        guard currentDate >= nextCheckDate(relativeTo: currentDate) else { return nil }

        do {
            guard let isDefault = try queryIsDefault() else { return nil }
            schedule(calendar.date(byAdding: Self.checkInterval, to: currentDate))
            return isDefault
        } catch {
            let retryDate = (error as NSError).userInfo[Self.retryAvailabilityDateKey] as? Date
            schedule(retryDate ?? calendar.date(byAdding: .day, value: 1, to: currentDate))
            return nil
        }
    }

    private func nextCheckDate(relativeTo currentDate: Date) -> Date {
        if let stored = defaults.object(forKey: Self.nextCheckDateKey) as? Date {
            return stored
        }
        // New users are checked the day after their first launch; existing users right after updating.
        let firstCheck = isFreshInstall()
            ? calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: currentDate)) ?? currentDate
            : currentDate
        schedule(firstCheck)
        return firstCheck
    }

    private func schedule(_ date: Date?) {
        guard let date else { return }
        defaults.set(date, forKey: Self.nextCheckDateKey)
    }

    private static func querySystem() throws -> Bool? {
        guard #available(iOS 18.2, *) else { return nil }
        return try UIApplication.shared.isDefault(.webBrowser)
    }
}
