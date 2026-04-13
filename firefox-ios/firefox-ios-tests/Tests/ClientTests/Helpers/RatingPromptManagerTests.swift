// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MozillaAppServices
import Shared
import Storage
import StoreKit
import XCTest

@testable import Client

@MainActor
class RatingPromptManagerTests: XCTestCase, @unchecked Sendable {
    var urlOpenerSpy: URLOpenerSpy!
    var promptManager: RatingPromptManager!
    var mockProfile: MockProfile!
    var createdGuids: [String] = []
    var logger: CrashingMockLogger!
    var mockDispatchGroup: MockDispatchGroup!

    override func setUp() {
        super.setUp()

        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        urlOpenerSpy = URLOpenerSpy()
    }

    override func tearDown() {
        super.tearDown()

        createdGuids = []
        // Ecosia: reset() removed in v147
        promptManager = nil
        mockProfile?.shutdown()
        mockProfile = nil
        logger = nil
        urlOpenerSpy = nil
    }

    func testShouldShowPrompt_requiredAreFalse_returnsFalse() {
        setupEnvironment(numberOfSession: 0,
                         hasCumulativeDaysOfUse: false)
        promptManager.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 0)
    }

    func testShouldShowPrompt_requiredTrueWithoutOptional_returnsFalse() {
        setupEnvironment()
        promptManager.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 0)
    }

    /* Ecosia: isBrowserDefault removed in v147
    func testShouldShowPrompt_withRequiredRequirementsAndOneOptional_returnsTrue() { ... }
    */

    func testShouldShowPrompt_lessThanSession5_returnsFalse() {
        setupEnvironment(numberOfSession: 4,
                         hasCumulativeDaysOfUse: true,
                         isBrowserDefault: true)
        promptManager.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 0)
    }

    func testShouldShowPrompt_cumulativeDaysOfUseFalse_returnsFalse() {
        setupEnvironment(numberOfSession: 5,
                         hasCumulativeDaysOfUse: false,
                         isBrowserDefault: true)
        promptManager.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 0)
    }

    func testShouldShowPrompt_loggerHasCrashedInLastSession_returnsFalse() {
        setupEnvironment(isBrowserDefault: true)
        logger?.enableCrashOnLastLaunch = true

        promptManager.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 0)
    }

    /* Ecosia: isBrowserDefault removed in v147
    func testShouldShowPrompt_isBrowserDefaultTrue_returnsTrue() { ... }
    */

    /* Ecosia: isBrowserDefault, updateData, showRatingPromptIfNeeded(at:) removed in v147
    func testShouldShowPrompt_hasTPStrict_returnsTrue() { ... }
    func testShouldShowPrompt_hasNotMinimumMobileBookmarksCount_returnsFalse() { ... }
    func testShouldShowPrompt_hasMinimumMobileBookmarksCount_returnsTrue() { ... }
    func testShouldShowPrompt_hasOtherBookmarksCount_returnsFalse() { ... }
    func testShouldShowPrompt_has5FoldersInMobileBookmarks_returnsFalse() { ... }
    func testShouldShowPrompt_has5SeparatorsInMobileBookmarks_returnsFalse() { ... }
    func testShouldShowPrompt_hasRequestedTwoWeeksAgo_returnsTrue() { ... }
    */

    // MARK: Number of times asked

    /* Ecosia: showRatingPromptIfNeeded(at:) and isBrowserDefault removed in v147
    func testShouldShowPrompt_hasRequestedInTheLastTwoWeeks_returnsFalse() { ... }
    func testShouldShowPrompt_requestCountTwiceCountIsAtOne() { ... }
    */

    // MARK: App Store

    func testGoToAppStoreReview() {
        RatingPromptManager.goToAppStoreReview(with: urlOpenerSpy)

        XCTAssertEqual(urlOpenerSpy.openURLCount, 1)
        XCTAssertEqual(
            urlOpenerSpy.capturedURL?.absoluteString,
            "https://itunes.apple.com/app/id\(AppInfo.appStoreId)?action=write-review"
        )
    }
}

// MARK: - Places helpers

private extension RatingPromptManagerTests {
    func createFolders(folderCount: Int, withRoot root: String, file: StaticString = #filePath, line: UInt = #line) {
        (1...folderCount).forEach { index in
            mockProfile.places.createFolder(
                parentGUID: root,
                title: "Folder \(index)",
                position: nil
            ).uponQueue(.main) { guid in
                guard let guid = guid.successValue else {
                    XCTFail("CreateFolder method did not return GUID", file: file, line: line)
                    return
                }
                self.createdGuids.append(guid)
            }
        }

        // Make sure the folders we create are deleted at the end of the test
        addTeardownBlock { [weak self] in
            self?.createdGuids.forEach { guid in
                _ = self?.mockProfile.places.deleteBookmarkNode(guid: guid)
            }
        }
    }

    func createSeparators(
        separatorCount: Int,
        withRoot root: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        (1...separatorCount).forEach { index in
            mockProfile.places.createSeparator(parentGUID: root, position: nil).uponQueue(.main) { guid in
                guard let guid = guid.successValue else {
                    XCTFail("CreateFolder method did not return GUID", file: file, line: line)
                    return
                }
                self.createdGuids.append(guid)
            }
        }

        // Make sure the separators we create are deleted at the end of the test
        addTeardownBlock { [weak self] in
            self?.createdGuids.forEach { guid in
                _ = self?.mockProfile.places.deleteBookmarkNode(guid: guid)
            }
        }
    }

    func createBookmarks(bookmarkCount: Int, withRoot root: String) {
        (1...bookmarkCount).forEach { index in
            let bookmark = ShareItem(url: "http://www.example.com/\(index)", title: "Example \(index)")
            _ = mockProfile.places.createBookmark(parentGUID: root,
                                                  url: bookmark.url,
                                                  title: bookmark.title,
                                                  position: nil).value
        }

        // Make sure the bookmarks we create are deleted at the end of the test
        addTeardownBlock { [weak self] in
            self?.deleteBookmarks(bookmarkCount: bookmarkCount)
        }
    }

    func deleteBookmarks(bookmarkCount: Int) {
        (1...bookmarkCount).forEach { index in
            _ = mockProfile.places.deleteBookmarksWithURL(url: "http://www.example.com/\(index)")
        }
    }

    /* Ecosia: updateData(dataLoadingCompletion:) removed in v147
    func updateData(expectedRatingPromptOpenCount: Int, ...) { ... }
    */
}

// MARK: - Setup helpers

private extension RatingPromptManagerTests {
    func setupEnvironment(numberOfSession: Int32 = 5,
                          hasCumulativeDaysOfUse: Bool = true,
                          isBrowserDefault: Bool = false,
                          functionName: String = #function) {
        mockProfile = MockProfile(databasePrefix: functionName)
        mockProfile.reopen()

        mockProfile.prefs.setInt(numberOfSession, forKey: PrefsKeys.Session.Count)
        setupPromptManager(hasCumulativeDaysOfUse: hasCumulativeDaysOfUse)
        // Ecosia: isBrowserDefault removed in v147 — ignored
    }

    func setupPromptManager(hasCumulativeDaysOfUse: Bool) {
        // Ecosia: RatingPromptManager API changed in v147
        // Old: RatingPromptManager(profile:daysOfUseCounter:logger:group:)
        // New: RatingPromptManager(prefs:crashTracker:logger:userDefaults:)
        logger = CrashingMockLogger()
        let crashTracker = MockCrashTracker()
        promptManager = RatingPromptManager(prefs: mockProfile.prefs,
                                            crashTracker: crashTracker,
                                            logger: logger)
    }

    func createSite(number: Int) -> Site {
        let site = Site(url: "http://s\(number)ite\(number).com/foo", title: "A \(number)")
        site.id = number
        site.guid = "abc\(number)def"

        return site
    }

    var ratingPromptOpenCount: Int {
        UserDefaults.standard.object(
            forKey: RatingPromptManager.UserDefaultsKey.keyRatingPromptRequestCount.rawValue
        ) as? Int ?? 0
    }
}

// MARK: - CrashingMockLogger
class CrashingMockLogger: Logger, @unchecked Sendable {
    func setup(sendCrashReports: Bool) {}
    func copyLogsToDocuments() {}
    func logCustomError(error: Error) {}
    func deleteCachedLogFiles() {}

    var enableCrashOnLastLaunch = false
    var crashedLastLaunch: Bool {
        return enableCrashOnLastLaunch
    }
}

// MARK: - URLOpenerSpy
class URLOpenerSpy: URLOpenerProtocol {
    var capturedURL: URL?
    var openURLCount = 0
    func open(_ url: URL) {
        capturedURL = url
        openURLCount += 1
    }
}
