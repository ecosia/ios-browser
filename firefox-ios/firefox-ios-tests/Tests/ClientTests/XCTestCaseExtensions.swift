// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

extension XCTestCase {
    func wait(_ timeout: TimeInterval) {
        let expectation = XCTestExpectation(description: "Waiting for \(timeout) seconds")
        XCTWaiter().wait(for: [expectation], timeout: timeout)
    }

    func waitForCondition(timeout: TimeInterval = 10, condition: () -> Bool) {
        let timeoutTime = Date.timeIntervalSinceReferenceDate + timeout

        while !condition() {
            if Date.timeIntervalSinceReferenceDate > timeoutTime {
                XCTFail("Condition timed out")
                return
            }

            wait(0.1)
        }
    }

    /// Tracks an object for memory leaks by asserting it's deallocated after the test completes.
    @MainActor
    func trackForMemoryLeaks(_ object: AnyObject?, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak object] in
            XCTAssertNil(object, "Memory leak detected in \(file):\(line)")
        }
    }

    /// Unwraps un async method return value.
    ///
    /// It is a wrapper of XCTUnwrap. Since is not possible to do ```XCTUnwrap(await asyncMethod())```
    ///
    /// it has to be done always in two steps, this method make it one line for users.
    func unwrapAsync<T>(asyncMethod: () async throws -> T?) async throws -> T {
        let returnValue = try await asyncMethod()
        return try XCTUnwrap(returnValue)
    }
}
