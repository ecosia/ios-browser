// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class EnvironmentFetcherTests: XCTestCase {

    // A non-empty Main Bundle value takes precedence over the Process Info value.
    func testBundleValuePreferredWhenPresent() {
        XCTAssertEqual(
            EnvironmentFetcher.resolveValue(bundleValue: "from-bundle", processInfoValue: "from-env"),
            "from-bundle"
        )
    }

    // An empty Main Bundle value (e.g. an xcconfig variable left unset substitutes an
    // empty string into Info.plist) must be treated as absent so the Process Info
    // fallback is still reached. This is the regression that crashed every test
    // transitively constructing DefaultAuth0SettingsProvider. Tracked in MOB-4384.
    func testEmptyBundleValueFallsBackToProcessInfo() {
        XCTAssertEqual(
            EnvironmentFetcher.resolveValue(bundleValue: "", processInfoValue: "from-env"),
            "from-env"
        )
    }

    // A missing Main Bundle value falls back to the Process Info value.
    func testMissingBundleValueFallsBackToProcessInfo() {
        XCTAssertEqual(
            EnvironmentFetcher.resolveValue(bundleValue: nil, processInfoValue: "from-env"),
            "from-env"
        )
    }

    // When neither source provides a non-empty value, the result is nil.
    func testReturnsNilWhenNeitherSourceHasValue() {
        XCTAssertNil(EnvironmentFetcher.resolveValue(bundleValue: nil, processInfoValue: nil))
        XCTAssertNil(EnvironmentFetcher.resolveValue(bundleValue: "", processInfoValue: ""))
        XCTAssertNil(EnvironmentFetcher.resolveValue(bundleValue: "", processInfoValue: nil))
    }
}
