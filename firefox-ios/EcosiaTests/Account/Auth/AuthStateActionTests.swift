// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Ecosia

final class AuthStateActionTests: XCTestCase {

    var testWindowUUID: WindowUUID!
    var testTimestamp: Date!

    override func setUp() {
        super.setUp()
        testWindowUUID = WindowUUID.XCTestDefaultUUID
        testTimestamp = Date()
    }

    override func tearDown() {
        testWindowUUID = nil
        testTimestamp = nil
        super.tearDown()
    }

    // MARK: - AuthStateAction Tests

    func testAuthStateActionInit_withAllParameters_setsAllProperties() {
        // Arrange
        let actionType = EcosiaAuthActionType.userLoggedIn
        let isLoggedIn = true
        let timestamp = testTimestamp!

        // Act
        let action = AuthStateAction(
            type: actionType,
            windowUUID: testWindowUUID,
            isLoggedIn: isLoggedIn,
            timestamp: timestamp
        )

        // Assert
        XCTAssertEqual(action.type, actionType, "Action type should match")
        XCTAssertEqual(action.windowUUID, testWindowUUID, "Window UUID should match")
        XCTAssertEqual(action.isLoggedIn, isLoggedIn, "IsLoggedIn should match")
        XCTAssertEqual(action.timestamp, timestamp, "Timestamp should match")
    }

    func testAuthStateActionInit_withDefaultTimestamp_setsCurrentTimestamp() {
        // Arrange
        let actionType = EcosiaAuthActionType.userLoggedOut
        let before = Date()

        // Act
        let action = AuthStateAction(
            type: actionType,
            windowUUID: testWindowUUID,
            isLoggedIn: false
        )
        let after = Date()

        // Assert
        XCTAssertEqual(action.type, actionType, "Action type should match")
        XCTAssertEqual(action.windowUUID, testWindowUUID, "Window UUID should match")
        XCTAssertEqual(action.isLoggedIn, false, "IsLoggedIn should match")
        XCTAssertTrue(action.timestamp >= before && action.timestamp <= after, "Timestamp should be set to current time")
    }

    func testAuthStateActionInit_withNilIsLoggedIn_setsToNil() {
        // Arrange
        let actionType = EcosiaAuthActionType.authStateLoaded

        // Act
        let action = AuthStateAction(
            type: actionType,
            windowUUID: testWindowUUID,
            isLoggedIn: nil
        )

        // Assert
        XCTAssertEqual(action.type, actionType, "Action type should match")
        XCTAssertEqual(action.windowUUID, testWindowUUID, "Window UUID should match")
        XCTAssertNil(action.isLoggedIn, "IsLoggedIn should be nil")
    }

    // MARK: - AuthWindowState Tests

    func testAuthWindowStateInit_withAllParameters_setsAllProperties() {
        // Arrange
        let windowUUID = testWindowUUID!
        let isLoggedIn = true
        let authStateLoaded = true
        let lastUpdated = testTimestamp!

        // Act
        let state = AuthWindowState(
            windowUUID: windowUUID,
            isLoggedIn: isLoggedIn,
            authStateLoaded: authStateLoaded,
            lastUpdated: lastUpdated
        )

        // Assert
        XCTAssertEqual(state.windowUUID, windowUUID, "Window UUID should match")
        XCTAssertEqual(state.isLoggedIn, isLoggedIn, "IsLoggedIn should match")
        XCTAssertEqual(state.authStateLoaded, authStateLoaded, "AuthStateLoaded should match")
        XCTAssertEqual(state.lastUpdated, lastUpdated, "LastUpdated should match")
    }

    func testAuthWindowStateInit_withDefaultLastUpdated_setsCurrentTimestamp() {
        // Arrange
        let windowUUID = testWindowUUID!
        let isLoggedIn = false
        let authStateLoaded = false
        let before = Date()

        // Act
        let state = AuthWindowState(
            windowUUID: windowUUID,
            isLoggedIn: isLoggedIn,
            authStateLoaded: authStateLoaded
        )
        let after = Date()

        // Assert
        XCTAssertEqual(state.windowUUID, windowUUID, "Window UUID should match")
        XCTAssertEqual(state.isLoggedIn, isLoggedIn, "IsLoggedIn should match")
        XCTAssertEqual(state.authStateLoaded, authStateLoaded, "AuthStateLoaded should match")
        XCTAssertTrue(state.lastUpdated >= before && state.lastUpdated <= after, "LastUpdated should be set to current time")
    }

    func testAuthWindowStateInit_withVariousStates_handlesAllCombinations() {
        // Test all possible combinations of isLoggedIn and authStateLoaded
        let combinations = [
            (true, true),
            (true, false),
            (false, true),
            (false, false)
        ]

        for (isLoggedIn, authStateLoaded) in combinations {
            // Arrange
            let windowUUID = WindowUUID()

            // Act
            let state = AuthWindowState(
                windowUUID: windowUUID,
                isLoggedIn: isLoggedIn,
                authStateLoaded: authStateLoaded
            )

            // Assert
            XCTAssertEqual(state.windowUUID, windowUUID, "Window UUID should match for combination \(isLoggedIn), \(authStateLoaded)")
            XCTAssertEqual(state.isLoggedIn, isLoggedIn, "IsLoggedIn should match for combination \(isLoggedIn), \(authStateLoaded)")
            XCTAssertEqual(state.authStateLoaded, authStateLoaded, "AuthStateLoaded should match for combination \(isLoggedIn), \(authStateLoaded)")
        }
    }

    // MARK: - EcosiaAuthActionType Tests

    func testEcosiaAuthActionTypeRawValues_haveCorrectStringValues() {
        // Test all enum cases have correct raw values
        XCTAssertEqual(EcosiaAuthActionType.authStateLoaded.rawValue, "authStateLoaded")
        XCTAssertEqual(EcosiaAuthActionType.userLoggedIn.rawValue, "userLoggedIn")
        XCTAssertEqual(EcosiaAuthActionType.userLoggedOut.rawValue, "userLoggedOut")
    }

    func testEcosiaAuthActionTypeCaseIterable_containsAllCases() {
        // Arrange
        let expectedCases: [EcosiaAuthActionType] = [
            .authStateLoaded,
            .userLoggedIn,
            .userLoggedOut
        ]

        // Act
        let allCases = EcosiaAuthActionType.allCases

        // Assert
        XCTAssertEqual(allCases.count, expectedCases.count, "Should have correct number of cases")
        
        for expectedCase in expectedCases {
            XCTAssertTrue(allCases.contains(expectedCase), "Should contain case \(expectedCase)")
        }
    }

    func testEcosiaAuthActionTypeInit_fromRawValue_worksCorrectly() {
        // Test initialization from raw values
        XCTAssertEqual(EcosiaAuthActionType(rawValue: "authStateLoaded"), .authStateLoaded)
        XCTAssertEqual(EcosiaAuthActionType(rawValue: "userLoggedIn"), .userLoggedIn)
        XCTAssertEqual(EcosiaAuthActionType(rawValue: "userLoggedOut"), .userLoggedOut)
        XCTAssertNil(EcosiaAuthActionType(rawValue: "invalidValue"), "Should return nil for invalid raw value")
    }

    // MARK: - State Immutability Tests

    func testAuthWindowState_isImmutable() {
        // Arrange
        let windowUUID = testWindowUUID!
        let state = AuthWindowState(
            windowUUID: windowUUID,
            isLoggedIn: true,
            authStateLoaded: true,
            lastUpdated: testTimestamp!
        )

        // Act - Try to access properties (should not crash)
        let retrievedWindowUUID = state.windowUUID
        let retrievedIsLoggedIn = state.isLoggedIn
        let retrievedAuthStateLoaded = state.authStateLoaded
        let retrievedLastUpdated = state.lastUpdated

        // Assert
        XCTAssertEqual(retrievedWindowUUID, windowUUID, "Window UUID should be accessible")
        XCTAssertEqual(retrievedIsLoggedIn, true, "IsLoggedIn should be accessible")
        XCTAssertEqual(retrievedAuthStateLoaded, true, "AuthStateLoaded should be accessible")
        XCTAssertEqual(retrievedLastUpdated, testTimestamp!, "LastUpdated should be accessible")
    }

    func testAuthStateAction_isImmutable() {
        // Arrange
        let action = AuthStateAction(
            type: .userLoggedIn,
            windowUUID: testWindowUUID,
            isLoggedIn: true,
            timestamp: testTimestamp!
        )

        // Act - Try to access properties (should not crash)
        let retrievedType = action.type
        let retrievedWindowUUID = action.windowUUID
        let retrievedIsLoggedIn = action.isLoggedIn
        let retrievedTimestamp = action.timestamp

        // Assert
        XCTAssertEqual(retrievedType, .userLoggedIn, "Type should be accessible")
        XCTAssertEqual(retrievedWindowUUID, testWindowUUID, "Window UUID should be accessible")
        XCTAssertEqual(retrievedIsLoggedIn, true, "IsLoggedIn should be accessible")
        XCTAssertEqual(retrievedTimestamp, testTimestamp!, "Timestamp should be accessible")
    }

    // MARK: - Edge Cases Tests

    func testAuthStateAction_withExtremeTimestamps_handlesCorrectly() {
        // Test with past timestamp
        let pastTimestamp = Date(timeIntervalSince1970: 0)
        let pastAction = AuthStateAction(
            type: .authStateLoaded,
            windowUUID: testWindowUUID,
            isLoggedIn: true,
            timestamp: pastTimestamp
        )
        
        XCTAssertEqual(pastAction.timestamp, pastTimestamp, "Should handle past timestamp")
        
        // Test with future timestamp
        let futureTimestamp = Date(timeIntervalSince1970: 2147483647) // Max 32-bit timestamp
        let futureAction = AuthStateAction(
            type: .authStateLoaded,
            windowUUID: testWindowUUID,
            isLoggedIn: true,
            timestamp: futureTimestamp
        )
        
        XCTAssertEqual(futureAction.timestamp, futureTimestamp, "Should handle future timestamp")
    }

    func testAuthWindowState_withExtremeTimestamps_handlesCorrectly() {
        // Test with past timestamp
        let pastTimestamp = Date(timeIntervalSince1970: 0)
        let pastState = AuthWindowState(
            windowUUID: testWindowUUID,
            isLoggedIn: true,
            authStateLoaded: true,
            lastUpdated: pastTimestamp
        )
        
        XCTAssertEqual(pastState.lastUpdated, pastTimestamp, "Should handle past timestamp")
        
        // Test with future timestamp
        let futureTimestamp = Date(timeIntervalSince1970: 2147483647) // Max 32-bit timestamp
        let futureState = AuthWindowState(
            windowUUID: testWindowUUID,
            isLoggedIn: true,
            authStateLoaded: true,
            lastUpdated: futureTimestamp
        )
        
        XCTAssertEqual(futureState.lastUpdated, futureTimestamp, "Should handle future timestamp")
    }

    // MARK: - Multiple Window Tests

    func testAuthStateAction_withDifferentWindowUUIDs_maintainsCorrectAssociation() {
        // Arrange
        let windowUUID1 = WindowUUID()
        let windowUUID2 = WindowUUID()
        let windowUUID3 = WindowUUID()

        // Act
        let action1 = AuthStateAction(type: .userLoggedIn, windowUUID: windowUUID1, isLoggedIn: true)
        let action2 = AuthStateAction(type: .userLoggedOut, windowUUID: windowUUID2, isLoggedIn: false)
        let action3 = AuthStateAction(type: .authStateLoaded, windowUUID: windowUUID3, isLoggedIn: nil)

        // Assert
        XCTAssertEqual(action1.windowUUID, windowUUID1, "Action 1 should have correct window UUID")
        XCTAssertEqual(action2.windowUUID, windowUUID2, "Action 2 should have correct window UUID")
        XCTAssertEqual(action3.windowUUID, windowUUID3, "Action 3 should have correct window UUID")
        
        XCTAssertNotEqual(action1.windowUUID, action2.windowUUID, "Different actions should have different window UUIDs")
        XCTAssertNotEqual(action2.windowUUID, action3.windowUUID, "Different actions should have different window UUIDs")
        XCTAssertNotEqual(action1.windowUUID, action3.windowUUID, "Different actions should have different window UUIDs")
    }

    func testAuthWindowState_withDifferentWindowUUIDs_maintainsCorrectAssociation() {
        // Arrange
        let windowUUID1 = WindowUUID()
        let windowUUID2 = WindowUUID()
        let windowUUID3 = WindowUUID()

        // Act
        let state1 = AuthWindowState(windowUUID: windowUUID1, isLoggedIn: true, authStateLoaded: true)
        let state2 = AuthWindowState(windowUUID: windowUUID2, isLoggedIn: false, authStateLoaded: false)
        let state3 = AuthWindowState(windowUUID: windowUUID3, isLoggedIn: true, authStateLoaded: false)

        // Assert
        XCTAssertEqual(state1.windowUUID, windowUUID1, "State 1 should have correct window UUID")
        XCTAssertEqual(state2.windowUUID, windowUUID2, "State 2 should have correct window UUID")
        XCTAssertEqual(state3.windowUUID, windowUUID3, "State 3 should have correct window UUID")
        
        XCTAssertNotEqual(state1.windowUUID, state2.windowUUID, "Different states should have different window UUIDs")
        XCTAssertNotEqual(state2.windowUUID, state3.windowUUID, "Different states should have different window UUIDs")
        XCTAssertNotEqual(state1.windowUUID, state3.windowUUID, "Different states should have different window UUIDs")
    }

    // MARK: - Performance Tests

    func testAuthStateAction_performanceWithManyInstances() {
        // Arrange
        let windowUUIDs = (0..<1000).map { _ in WindowUUID() }
        
        // Act
        let startTime = Date()
        let actions = windowUUIDs.map { windowUUID in
            AuthStateAction(type: .userLoggedIn, windowUUID: windowUUID, isLoggedIn: true)
        }
        let endTime = Date()
        
        // Assert
        XCTAssertEqual(actions.count, 1000, "Should create 1000 actions")
        XCTAssertLessThan(endTime.timeIntervalSince(startTime), 1.0, "Should create actions quickly")
    }

    func testAuthWindowState_performanceWithManyInstances() {
        // Arrange
        let windowUUIDs = (0..<1000).map { _ in WindowUUID() }
        
        // Act
        let startTime = Date()
        let states = windowUUIDs.map { windowUUID in
            AuthWindowState(windowUUID: windowUUID, isLoggedIn: true, authStateLoaded: true)
        }
        let endTime = Date()
        
        // Assert
        XCTAssertEqual(states.count, 1000, "Should create 1000 states")
        XCTAssertLessThan(endTime.timeIntervalSince(startTime), 1.0, "Should create states quickly")
    }
} 