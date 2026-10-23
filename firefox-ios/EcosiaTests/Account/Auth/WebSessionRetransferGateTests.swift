// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia

@MainActor
final class WebSessionRetransferGateTests: XCTestCase {

    private var currentDate = Date(timeIntervalSince1970: 1_000_000)

    private func makeGate(maxAttempts: Int = 3) -> WebSessionRetransferGate {
        WebSessionRetransferGate(maxAttempts: maxAttempts,
                              attemptWindow: 15 * 60,
                              baseBackoff: 30,
                              now: { [unowned self] in self.currentDate })
    }

    func testRequestStart_firstAttempt_starts() {
        let gate = makeGate()

        XCTAssertEqual(gate.requestStart(), .start)
    }

    func testRequestStart_whileRunning_reportsAlreadyRunning() {
        let gate = makeGate()
        _ = gate.requestStart()

        XCTAssertEqual(gate.requestStart(), .alreadyRunning)
    }

    func testRequestStart_whileBlockingOperationRuns_isBlocked() {
        let gate = makeGate()
        gate.beginBlockingOperation()

        XCTAssertEqual(gate.requestStart(), .blocked)
    }

    func testRequestStart_afterBlockingOperationEnds_starts() {
        let gate = makeGate()
        gate.beginBlockingOperation()
        gate.endBlockingOperation()

        XCTAssertEqual(gate.requestStart(), .start)
    }

    func testRequestStart_withNestedBlockingOperations_staysBlockedUntilAllEnd() {
        let gate = makeGate()
        gate.beginBlockingOperation()
        gate.beginBlockingOperation()
        gate.endBlockingOperation()

        XCTAssertEqual(gate.requestStart(), .blocked)
    }

    func testRequestStart_rightAfterAnAttempt_backsOff() {
        let gate = makeGate()
        _ = gate.requestStart()
        gate.finish()
        currentDate += 10

        XCTAssertEqual(gate.requestStart(), .retryAfter(20))
    }

    func testRequestStart_backoffDoublesWithEachAttempt() {
        let gate = makeGate()
        _ = gate.requestStart()
        gate.finish()
        currentDate += 30
        _ = gate.requestStart()
        gate.finish()

        XCTAssertEqual(gate.requestStart(), .retryAfter(60))
    }

    func testRequestStart_afterBackoffElapses_starts() {
        let gate = makeGate()
        _ = gate.requestStart()
        gate.finish()
        currentDate += 30

        XCTAssertEqual(gate.requestStart(), .start)
    }

    func testRequestStart_whenAttemptsExhausted_reportsLimitReached() {
        let gate = makeGate(maxAttempts: 2)
        _ = gate.requestStart()
        gate.finish()
        currentDate += 30
        _ = gate.requestStart()
        gate.finish()
        currentDate += 600

        XCTAssertEqual(gate.requestStart(), .limitReached)
    }

    func testRequestStart_afterAttemptWindowPasses_startsAgain() {
        let gate = makeGate(maxAttempts: 1)
        _ = gate.requestStart()
        gate.finish()
        currentDate += 15 * 60

        XCTAssertEqual(gate.requestStart(), .start)
    }
}
