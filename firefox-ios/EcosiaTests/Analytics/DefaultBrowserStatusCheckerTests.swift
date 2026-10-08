// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia

// swiftlint:disable implicitly_unwrapped_optional
@MainActor
final class DefaultBrowserStatusCheckerTests: XCTestCase {
    private var defaults: UserDefaults!
    private var calendar: Calendar!
    private var now: Date!
    private var queryCount = 0
    private var queryResult: Result<Bool?, Error> = .success(true)

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: #file)
        defaults.removePersistentDomain(forName: #file)
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        now = ISO8601DateFormatter().date(from: "2026-01-15T10:00:00Z")
        queryCount = 0
        queryResult = .success(true)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: #file)
        defaults = nil
        super.tearDown()
    }

    func testFreshInstallDoesNotCheckOnFirstLaunchDay() {
        let sut = makeSUT(isFreshInstall: true)

        XCTAssertNil(sut.checkIfDue())
        advance(hours: 13)
        XCTAssertNil(sut.checkIfDue())
        XCTAssertEqual(queryCount, 0)
    }

    func testFreshInstallChecksOnTheDayAfterFirstLaunch() {
        let sut = makeSUT(isFreshInstall: true)
        _ = sut.checkIfDue()

        advance(hours: 14)

        XCTAssertEqual(sut.checkIfDue(), true)
        XCTAssertEqual(queryCount, 1)
    }

    func testExistingUserChecksRightAfterUpdate() {
        queryResult = .success(false)
        let sut = makeSUT(isFreshInstall: false)

        XCTAssertEqual(sut.checkIfDue(), false)
        XCTAssertEqual(queryCount, 1)
    }

    func testChecksAgainOnlyAfterSixMonths() {
        let sut = makeSUT(isFreshInstall: false)
        _ = sut.checkIfDue()

        now = calendar.date(byAdding: DateComponents(month: 6, second: -1), to: now)
        XCTAssertNil(sut.checkIfDue())

        advance(hours: 1)
        XCTAssertEqual(sut.checkIfDue(), true)
        XCTAssertEqual(queryCount, 2)
    }

    func testRateLimitedErrorDefersCheckUntilRetryDate() {
        let retryDate = calendar.date(byAdding: .day, value: 30, to: now)!
        queryResult = .failure(NSError(domain: "UIApplicationCategoryDefaultErrorDomain",
                                       code: 1,
                                       userInfo: [DefaultBrowserStatusChecker.retryAvailabilityDateKey: retryDate]))
        let sut = makeSUT(isFreshInstall: false)

        XCTAssertNil(sut.checkIfDue())
        queryResult = .success(true)
        now = calendar.date(byAdding: .day, value: 29, to: now)
        XCTAssertNil(sut.checkIfDue())

        now = retryDate
        XCTAssertEqual(sut.checkIfDue(), true)
        XCTAssertEqual(queryCount, 2)
    }

    func testUnavailableAPIKeepsCheckDue() {
        queryResult = .success(nil)
        let sut = makeSUT(isFreshInstall: false)

        XCTAssertNil(sut.checkIfDue())
        queryResult = .success(true)

        XCTAssertEqual(sut.checkIfDue(), true)
    }

    private func makeSUT(isFreshInstall: Bool) -> DefaultBrowserStatusChecker {
        DefaultBrowserStatusChecker(defaults: defaults,
                                    calendar: calendar,
                                    now: { [unowned self] in self.now },
                                    isFreshInstall: { isFreshInstall },
                                    queryIsDefault: { [unowned self] in
                                        self.queryCount += 1
                                        return try self.queryResult.get()
                                    })
    }

    private func advance(hours: Int) {
        now = calendar.date(byAdding: .hour, value: hours, to: now)
    }
}
// swiftlint:enable implicitly_unwrapped_optional
