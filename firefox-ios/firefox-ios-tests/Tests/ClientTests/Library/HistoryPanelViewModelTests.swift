// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MozillaAppServices
import Shared
import Storage
import XCTest

@testable import Client

@MainActor
class HistoryPanelViewModelTests: XCTestCase, @unchecked Sendable {
    var subject: HistoryPanelViewModel!
    var profile: MockProfile!

    override func setUp() {
        super.setUp()

        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile(databasePrefix: "HistoryPanelViewModelTest")
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        profile.reopen()
        subject = HistoryPanelViewModel(profile: profile)
    }

    override func tearDown() {
        super.tearDown()

        AppContainer.shared.reset()
        clear(profile: profile)
        profile.shutdown()
        profile = nil
        subject = nil
    }

    func testHistorySectionTitle() {
        HistoryPanelViewModel.Sections.allCases.forEach({ section in
            switch section {
            case .lastHour:
                XCTAssertEqual(section.title, .LibraryPanel.Sections.LastHour)
            case .lastTwentyFourHours:
                XCTAssertEqual(section.title, .LibraryPanel.Sections.LastTwentyFourHours)
            case .lastSevenDays:
                XCTAssertEqual(section.title, .LibraryPanel.Sections.LastSevenDays)
            case .lastFourWeeks:
                XCTAssertEqual(section.title, .LibraryPanel.Sections.LastFourWeeks)
            case .older:
                XCTAssertEqual(section.title, .LibraryPanel.Sections.Older)
            case .additionalHistoryActions, .searchResults:
                XCTAssertNil(section.title)
            }
        })
    }

    func testFetchHistory_WithResults() {
        setupSiteVisits()

        fetchHistory { success in
            MainActor.assumeIsolated {
                XCTAssertTrue(success)
                XCTAssertFalse(self.subject.dateGroupedSites.isEmpty)
                XCTAssertFalse(self.subject.visibleSections.isEmpty)
            }
        }
    }

    func testFetchHistoryFail_WithFetchInProgress() {
        subject.isFetchInProgress = true

        fetchHistory { success in
            MainActor.assumeIsolated {
                XCTAssertFalse(success)
            }
        }
    }

    func testPerformSearch_ForNoResults() {
        fetchSearchHistory(searchTerm: "moz") { hasResults in
            MainActor.assumeIsolated {
                XCTAssertFalse(hasResults)
                XCTAssertEqual(self.subject.searchResultSites.count, 0)
            }
        }
    }

    func testPerformSearch_WithResults() {
        setupSiteVisits()

        fetchSearchHistory(searchTerm: "moz") { hasResults in
            MainActor.assumeIsolated {
                XCTAssertTrue(hasResults)
                XCTAssertEqual(self.subject.searchResultSites.count, 2)
            }
        }
    }

    func testEmptyStateText_ForSearch() {
        subject.isSearchInProgress = true
        XCTAssertEqual(subject.emptyStateText, .LibraryPanel.History.NoHistoryResult)
    }

    func testEmptyStateText_ForHistoryResults() {
        subject.isSearchInProgress = false
        XCTAssertEqual(subject.emptyStateText, .HistoryPanelEmptyStateTitle)
    }

    func testShouldShowEmptyState_ForEmptySearch() {
        setupSiteVisits()
        subject.isSearchInProgress = true

        fetchSearchHistory(searchTerm: "") { hasResults in
            MainActor.assumeIsolated {
                XCTAssertFalse(self.subject.shouldShowEmptyState(searchText: ""))
            }
        }
    }

    func testShouldShowEmptyState_ForNoResultSearch() {
        setupSiteVisits()
        subject.isSearchInProgress = true

        fetchSearchHistory(searchTerm: "ui") { hasResults in
            MainActor.assumeIsolated {
                XCTAssertTrue(self.subject.shouldShowEmptyState(searchText: "ui"))
            }
        }
    }

    func testShouldShowEmptyState_ForNoHistory() {
        subject.isSearchInProgress = false

        fetchHistory { _ in
            MainActor.assumeIsolated {
                XCTAssertTrue(self.subject.shouldShowEmptyState())
            }
        }
    }

    func testCollapseSection() {
        setupSiteVisits()
        XCTAssertTrue(subject.hiddenSections.isEmpty)

        fetchHistory { _ in
            MainActor.assumeIsolated {
                self.subject.collapseSection(sectionIndex: 1)
                XCTAssertEqual(self.subject.hiddenSections.count, 1)
                // Starts at 0, removing the Additional section
                XCTAssertTrue(self.subject.isSectionCollapsed(sectionIndex: 0))
                XCTAssertTrue(self.subject.hiddenSections.contains(where: { $0 == .lastHour }))
            }
        }
    }

    func testExpandSection() {
        setupSiteVisits()
        XCTAssertTrue(subject.hiddenSections.isEmpty)

        fetchHistory { _ in
            MainActor.assumeIsolated {
                self.subject.collapseSection(sectionIndex: 1)
                XCTAssertEqual(self.subject.hiddenSections.count, 1)
                // Starts at 0, removing the Additional section
                XCTAssertTrue(self.subject.isSectionCollapsed(sectionIndex: 0))
                XCTAssertTrue(self.subject.hiddenSections.contains(where: { $0 == .lastHour }))

                self.subject.collapseSection(sectionIndex: 1)
                XCTAssertTrue(self.subject.hiddenSections.isEmpty)
                XCTAssertFalse(self.subject.isSectionCollapsed(sectionIndex: 1))
            }
        }
    }

    func testRemoveAllData() {
        setupSiteVisits()
        XCTAssertTrue(subject.hiddenSections.isEmpty)

        fetchHistory { _ in
            MainActor.assumeIsolated {
                self.subject.removeAllData()

                XCTAssertEqual(self.subject.currentFetchOffset, 0)
                XCTAssertTrue(self.subject.dateGroupedSites.isEmpty)
                XCTAssertTrue(self.subject.visibleSections.isEmpty)
            }
        }
    }

    // MARK: - Deletion

    func testDeleteGroup_ForLastHour() {
        setupSiteVisits()

        fetchHistory { _ in
            MainActor.assumeIsolated {
                XCTAssertEqual(self.subject.visibleSections[0], .lastHour)
                self.subject.deleteGroupsFor(dateOption: .lastHour)
                XCTAssertEqual(self.subject.visibleSections.count, 0)
            }
        }
    }

    // MARK: - Setup
    private func setupSiteVisits() {
        addSiteVisit(profile, url: "http://mozilla.org/", title: "Mozilla internet")
        addSiteVisit(profile, url: "http://mozilla.dev.org/", title: "Internet dev")
        addSiteVisit(profile, url: "https://apple.com/", title: "Apple")
    }

    private func addSiteVisit(_ profile: MockProfile, url: String, title: String) {
        let visitObservation = VisitObservation(url: url, title: title, visitType: .link)
        let result = profile.places.applyObservation(visitObservation: visitObservation)

        XCTAssertEqual(true, result.value.isSuccess, "Site added: \(url).")
    }

    private func clear(profile: MockProfile) {
        let result = profile.places.deleteEverythingHistory()
        XCTAssertTrue(result.value.isSuccess, "History cleared.")
    }

    private func fetchHistory(completion: @escaping @Sendable (Bool) -> Void) {
        let expectation = self.expectation(description: "Wait for history")

        subject.reloadData { success in
            MainActor.assumeIsolated {
                XCTAssertNotNil(success)
                completion(success)
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5)
    }

    private func fetchSearchHistory(searchTerm: String,
                                    completion: @escaping @Sendable (Bool) -> Void) {
        let expectation = self.expectation(description: "Wait for history search")

        subject.performSearch(term: searchTerm) { hasResults in
            MainActor.assumeIsolated {
                XCTAssertNotNil(hasResults)
                completion(hasResults)
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5)
    }
}
