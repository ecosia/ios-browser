// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Security
@testable import Ecosia

final class EcosiaKeychainStorageTests: XCTestCase {

    var keychainStorage: EcosiaKeychainStorage!
    let testService = "test.ecosia.keychain"
    let testAccount = "test-account"
    let testData = "test-data".data(using: .utf8)!

    override func setUp() {
        super.setUp()
        keychainStorage = EcosiaKeychainStorage()
        // Clean up any existing test data
        cleanupTestKeychain()
    }

    override func tearDown() {
        cleanupTestKeychain()
        keychainStorage = nil
        super.tearDown()
    }

    // MARK: - Store Tests

    func testSetEntry_withValidData_returnsTrue() {
        // Arrange
        let data = testData
        let key = "test-key"

        // Act
        let result = keychainStorage.setEntry(data, forKey: key)

        // Assert
        XCTAssertTrue(result, "Storing valid data should return true")
    }

    func testSetEntry_withEmptyData_returnsTrue() {
        // Arrange
        let emptyData = Data()
        let key = "empty-key"

        // Act
        let result = keychainStorage.setEntry(emptyData, forKey: key)

        // Assert
        XCTAssertTrue(result, "Storing empty data should return true")
    }

    func testSetEntry_overwriteExistingData_returnsTrue() {
        // Arrange
        let originalData = "original-data".data(using: .utf8)!
        let updatedData = "updated-data".data(using: .utf8)!
        let key = "overwrite-key"

        // Store original data
        _ = keychainStorage.setEntry(originalData, forKey: key)

        // Act - Overwrite with updated data
        let result = keychainStorage.setEntry(updatedData, forKey: key)

        // Assert
        XCTAssertTrue(result, "Overwriting existing data should return true")

        // Verify the data was actually updated
        let retrievedData = keychainStorage.getEntry(forKey: key)
        XCTAssertEqual(retrievedData, updatedData, "Retrieved data should match updated data")
    }

    // MARK: - Retrieve Tests

    func testGetEntry_withStoredData_returnsCorrectData() {
        // Arrange
        let storedData = testData
        let key = "stored-key"
        _ = keychainStorage.setEntry(storedData, forKey: key)

        // Act
        let retrievedData = keychainStorage.getEntry(forKey: key)

        // Assert
        XCTAssertEqual(retrievedData, storedData, "Retrieved data should match stored data")
    }

    func testGetEntry_withNoStoredData_returnsNil() {
        // Arrange
        let key = "non-existent-key"

        // Act
        let retrievedData = keychainStorage.getEntry(forKey: key)

        // Assert
        XCTAssertNil(retrievedData, "Retrieving non-existent data should return nil")
    }

    func testGetEntry_afterDelete_returnsNil() {
        // Arrange
        let key = "delete-test-key"
        _ = keychainStorage.setEntry(testData, forKey: key)
        _ = keychainStorage.deleteEntry(forKey: key)

        // Act
        let retrievedData = keychainStorage.getEntry(forKey: key)

        // Assert
        XCTAssertNil(retrievedData, "Retrieving deleted data should return nil")
    }

    // MARK: - Delete Tests

    func testDeleteEntry_withStoredData_returnsTrue() {
        // Arrange
        let key = "delete-stored-key"
        _ = keychainStorage.setEntry(testData, forKey: key)

        // Act
        let result = keychainStorage.deleteEntry(forKey: key)

        // Assert
        XCTAssertTrue(result, "Deleting existing data should return true")
    }

    func testDeleteEntry_withNoStoredData_returnsTrue() {
        // Arrange
        let key = "non-existent-delete-key"

        // Act
        let result = keychainStorage.deleteEntry(forKey: key)

        // Assert
        XCTAssertTrue(result, "Deleting non-existent data should return true")
    }

    func testDeleteEntry_actuallyRemovesData() {
        // Arrange
        let key = "remove-test-key"
        _ = keychainStorage.setEntry(testData, forKey: key)

        // Act
        _ = keychainStorage.deleteEntry(forKey: key)

        // Assert
        let retrievedData = keychainStorage.getEntry(forKey: key)
        XCTAssertNil(retrievedData, "Data should be nil after deletion")
    }

    // MARK: - Integration Tests

    func testCompleteKeychainLifecycle_setGetDelete_worksCorrectly() {
        // Arrange
        let originalData = "lifecycle-test-data".data(using: .utf8)!
        let key = "lifecycle-key"

        // Act - Store
        let storeResult = keychainStorage.setEntry(originalData, forKey: key)

        // Assert - Store successful
        XCTAssertTrue(storeResult, "Store operation should succeed")

        // Act - Retrieve
        let retrievedData = keychainStorage.getEntry(forKey: key)

        // Assert - Retrieved correctly
        XCTAssertEqual(retrievedData, originalData, "Retrieved data should match stored data")

        // Act - Delete
        let deleteResult = keychainStorage.deleteEntry(forKey: key)

        // Assert - Delete successful
        XCTAssertTrue(deleteResult, "Delete operation should succeed")

        // Assert - Data actually deleted
        let dataAfterDelete = keychainStorage.getEntry(forKey: key)
        XCTAssertNil(dataAfterDelete, "Data should be nil after deletion")
    }

    func testMultipleKeys_independentStorage_worksCorrectly() {
        // Arrange
        let key1 = "key-1"
        let key2 = "key-2"
        let data1 = "data-for-key-1".data(using: .utf8)!
        let data2 = "data-for-key-2".data(using: .utf8)!

        // Act - Store data for both keys
        let store1Result = keychainStorage.setEntry(data1, forKey: key1)
        let store2Result = keychainStorage.setEntry(data2, forKey: key2)

        // Assert - Both stores successful
        XCTAssertTrue(store1Result, "Store for key 1 should succeed")
        XCTAssertTrue(store2Result, "Store for key 2 should succeed")

        // Act - Retrieve data for both keys
        let retrieved1 = keychainStorage.getEntry(forKey: key1)
        let retrieved2 = keychainStorage.getEntry(forKey: key2)

        // Assert - Each key has its own data
        XCTAssertEqual(retrieved1, data1, "Key 1 should have its own data")
        XCTAssertEqual(retrieved2, data2, "Key 2 should have its own data")
        XCTAssertNotEqual(retrieved1, retrieved2, "Keys should have different data")

        // Act - Delete key 1 data
        _ = keychainStorage.deleteEntry(forKey: key1)

        // Assert - Key 1 data deleted, key 2 data remains
        let retrieved1AfterDelete = keychainStorage.getEntry(forKey: key1)
        let retrieved2AfterDelete = keychainStorage.getEntry(forKey: key2)

        XCTAssertNil(retrieved1AfterDelete, "Key 1 data should be deleted")
        XCTAssertEqual(retrieved2AfterDelete, data2, "Key 2 data should remain")
    }

    func testMultipleKeychainInstances_independentStorage_worksCorrectly() {
        // Arrange
        let keychain1 = EcosiaKeychainStorage(service: "service-1")
        let keychain2 = EcosiaKeychainStorage(service: "service-2")
        let key = "shared-key"
        let data1 = "data-for-service-1".data(using: .utf8)!
        let data2 = "data-for-service-2".data(using: .utf8)!

        // Act - Store data in both keychains
        let store1Result = keychain1.setEntry(data1, forKey: key)
        let store2Result = keychain2.setEntry(data2, forKey: key)

        // Assert - Both stores successful
        XCTAssertTrue(store1Result, "Store for keychain 1 should succeed")
        XCTAssertTrue(store2Result, "Store for keychain 2 should succeed")

        // Act - Retrieve data from both keychains
        let retrieved1 = keychain1.getEntry(forKey: key)
        let retrieved2 = keychain2.getEntry(forKey: key)

        // Assert - Each keychain has its own data
        XCTAssertEqual(retrieved1, data1, "Keychain 1 should have its own data")
        XCTAssertEqual(retrieved2, data2, "Keychain 2 should have its own data")
        XCTAssertNotEqual(retrieved1, retrieved2, "Keychains should have different data")

        // Cleanup
        _ = keychain1.deleteEntry(forKey: key)
        _ = keychain2.deleteEntry(forKey: key)
    }

    // MARK: - Edge Cases Tests

    func testSetEntry_withLargeData_worksCorrectly() {
        // Arrange
        let largeData = Data(repeating: 0x42, count: 10000) // 10KB of data
        let key = "large-data-key"

        // Act
        let storeResult = keychainStorage.setEntry(largeData, forKey: key)

        // Assert - Store successful
        XCTAssertTrue(storeResult, "Storing large data should succeed")

        // Act - Retrieve
        let retrievedData = keychainStorage.getEntry(forKey: key)

        // Assert - Retrieved correctly
        XCTAssertEqual(retrievedData, largeData, "Large data should be retrieved correctly")
    }

    func testSetEntry_withSpecialCharactersInKey_worksCorrectly() {
        // Arrange
        let specialKey = "key.with-special_chars@123!#$%"
        let testData = "special-test-data".data(using: .utf8)!

        // Act
        let storeResult = keychainStorage.setEntry(testData, forKey: specialKey)

        // Assert - Store successful
        XCTAssertTrue(storeResult, "Storing with special characters should succeed")

        // Act - Retrieve
        let retrievedData = keychainStorage.getEntry(forKey: specialKey)

        // Assert - Retrieved correctly
        XCTAssertEqual(retrievedData, testData, "Data with special characters should be retrieved correctly")

        // Cleanup
        _ = keychainStorage.deleteEntry(forKey: specialKey)
    }

    // MARK: - Helper Methods

    private func cleanupTestKeychain() {
        // Clean up test data to avoid interference between tests
        _ = keychainStorage.deleteEntry(forKey: "test-key")
        _ = keychainStorage.deleteEntry(forKey: "empty-key")
        _ = keychainStorage.deleteEntry(forKey: "overwrite-key")
        _ = keychainStorage.deleteEntry(forKey: "stored-key")
        _ = keychainStorage.deleteEntry(forKey: "delete-test-key")
        _ = keychainStorage.deleteEntry(forKey: "delete-stored-key")
        _ = keychainStorage.deleteEntry(forKey: "non-existent-delete-key")
        _ = keychainStorage.deleteEntry(forKey: "remove-test-key")
        _ = keychainStorage.deleteEntry(forKey: "lifecycle-key")
        _ = keychainStorage.deleteEntry(forKey: "key-1")
        _ = keychainStorage.deleteEntry(forKey: "key-2")
        _ = keychainStorage.deleteEntry(forKey: "large-data-key")
    }
}
