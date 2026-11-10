// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Rotates the NTP wallpaper through `wallpapers`, moving to the next one every `interval`.
///
/// The current wallpaper is worked out from the clock, so every window shows the same one
/// and it carries over app restarts. Periods are counted in local time, so a one-day interval
/// changes the wallpaper at local midnight.
@MainActor
final class WallpaperRotation {
    static let didRotate = Notification.Name("EcosiaWallpaperRotationDidRotate")

    static let daily: TimeInterval = 24 * 60 * 60

    private let wallpapers: [Wallpaper]
    private let interval: TimeInterval
    private let now: () -> Date
    private let timeZone: TimeZone
    private let notificationCenter: NotificationCenter
    private var timer: Timer?

    init(
        wallpapers: [Wallpaper],
        interval: TimeInterval,
        now: @escaping () -> Date = Date.init,
        timeZone: TimeZone = .current,
        notificationCenter: NotificationCenter = .default
    ) {
        self.wallpapers = wallpapers
        self.interval = interval
        self.now = now
        self.timeZone = timeZone
        self.notificationCenter = notificationCenter
    }

    var currentWallpaper: Wallpaper? {
        guard !wallpapers.isEmpty else { return nil }
        let index = period(at: now()) % wallpapers.count
        return wallpapers[index]
    }

    var nextRotationDate: Date {
        let date = now()
        let nextPeriodStart = TimeInterval(period(at: date) + 1) * interval
        return Date(timeIntervalSinceReferenceDate: nextPeriodStart - localOffset(at: date))
    }

    /// Posts `didRotate` now and at the start of every following period.
    func start() {
        guard timer == nil else { return }
        scheduleNextRotation()
        postDidRotate()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        postDidRotate()
    }

    private func period(at date: Date) -> Int {
        let localTime = date.timeIntervalSinceReferenceDate + localOffset(at: date)
        return Int((localTime / interval).rounded(.down))
    }

    private func localOffset(at date: Date) -> TimeInterval {
        TimeInterval(timeZone.secondsFromGMT(for: date))
    }

    private func scheduleNextRotation() {
        let timer = Timer(fire: nextRotationDate, interval: 0, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.rotate()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func rotate() {
        scheduleNextRotation()
        postDidRotate()
    }

    private func postDidRotate() {
        notificationCenter.post(name: Self.didRotate, object: self)
    }
}
