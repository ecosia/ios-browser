// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Glean
import Shared
import XCTest

@testable import Client

class WallpaperSettingsViewModelTests: XCTestCase {
    private var wallpaperManager: WallpaperManagerInterface!

    override func setUp() {
        super.setUp()

        wallpaperManager = WallpaperManagerMock()
        addWallpaperCollections()

    }

    override func tearDown() {
        wallpaperManager = nil
        super.tearDown()
    }

    func testInit_hasDefaultLayout() {
        let subject = createSubject()
        let expectedLayout: WallpaperSettingsViewModel.WallpaperSettingsLayout = .compact
        XCTAssertEqual(subject.sectionLayout, expectedLayout)
    }

    func testUpdateSectionLayout_hasRegularLayout() {
        let subject = createSubject()
        let expectedLayout: WallpaperSettingsViewModel.WallpaperSettingsLayout = .regular

        let landscapeTrait = MockTraitCollection(verticalSizeClass: .compact).getTraitCollection()

        subject.updateSectionLayout(for: landscapeTrait)

        XCTAssertEqual(subject.sectionLayout, expectedLayout)
    }

    func testNumberOfSections() {
        let subject = createSubject()

        XCTAssertEqual(subject.numberOfSections, 2)
    }

    func testNumberOfItemsInSection() {
        let subject = createSubject()

        XCTAssertEqual(subject.numberOfWallpapers(in: 0),
                       wallpaperManager.availableCollections[safe: 0]?.wallpapers.count)

        XCTAssertEqual(subject.numberOfWallpapers(in: 1),
                       wallpaperManager.availableCollections[safe: 1]?.wallpapers.count)
    }

    // Ecosia: Test collection without heading or subheading shows no title/description
    func testSectionHeaderViewModel_defaultCollectionWithoutHeadingOrSubheading() {
        let subject = createSubject()
        let headerViewModel = subject.sectionHeaderViewModel(for: 0) {
        }

        // Without heading/subheading in JSON, no title/description should be shown
        XCTAssertNil(headerViewModel?.title)
        XCTAssertNil(headerViewModel?.description)
        XCTAssertNil(headerViewModel?.buttonTitle) // No learn-more URL
    }

    // Ecosia: Test collection with learn-more URL shows button
    func testSectionHeaderViewModel_collectionWithLearnMoreURL() {
        let subject = createSubject()
        let headerViewModel = subject.sectionHeaderViewModel(for: 1) {
        }

        // Collection has learn-more URL, so button should be present
        XCTAssertNotNil(headerViewModel?.buttonTitle)
    }

    // Ecosia: Test that JSON heading and subheading are used when available
    func testSectionHeaderViewModel_usesJSONHeadingAndSubheading() {
        guard let mockManager = wallpaperManager as? WallpaperManagerMock else { return }

        // Add a collection with custom heading and subheading
        let customHeading = "Abstract Nature"
        let customSubheading = "Beautiful nature wallpapers"
        let wallpapers = [Wallpaper(id: "test",
                                    textColor: .green,
                                    cardColor: .green,
                                    logoTextColor: .green)]

        mockManager.mockAvailableCollections.append(
            WallpaperCollection(
                id: "custom-collection",
                learnMoreURL: "https://ecosia.org",
                availableLocales: nil,
                availability: nil,
                wallpapers: wallpapers,
                description: nil,
                heading: customHeading,
                subheading: customSubheading)
        )

        let subject = createSubject()
        let headerViewModel = subject.sectionHeaderViewModel(for: 2) {
        }

        // Verify that the custom heading and subheading from JSON are used
        XCTAssertEqual(headerViewModel?.title, customHeading)
        XCTAssertEqual(headerViewModel?.description, customSubheading)
        XCTAssertNotNil(headerViewModel?.buttonTitle)
    }

    // Ecosia: Test that heading can be shown independently without subheading
    func testSectionHeaderViewModel_headingWithoutSubheading() {
        guard let mockManager = wallpaperManager as? WallpaperManagerMock else { return }

        let customHeading = "Ecosia Projects"
        let wallpapers = [Wallpaper(id: "test",
                                    textColor: .green,
                                    cardColor: .green,
                                    logoTextColor: .green)]

        mockManager.mockAvailableCollections.append(
            WallpaperCollection(
                id: "heading-only-collection",
                learnMoreURL: "https://ecosia.org",
                availableLocales: nil,
                availability: nil,
                wallpapers: wallpapers,
                description: nil,
                heading: customHeading,
                subheading: nil)
        )

        let subject = createSubject()
        let headerViewModel = subject.sectionHeaderViewModel(for: 2) {
        }

        // Verify that only heading is shown, no subheading
        XCTAssertEqual(headerViewModel?.title, customHeading)
        XCTAssertNil(headerViewModel?.description)
    }

    // Ecosia: Test that subheading can be shown independently without heading
    func testSectionHeaderViewModel_subheadingWithoutHeading() {
        guard let mockManager = wallpaperManager as? WallpaperManagerMock else { return }

        let customSubheading = "Lorem ipsum dolor sit amet"
        let wallpapers = [Wallpaper(id: "test",
                                    textColor: .green,
                                    cardColor: .green,
                                    logoTextColor: .green)]

        mockManager.mockAvailableCollections.append(
            WallpaperCollection(
                id: "subheading-only-collection",
                learnMoreURL: "https://ecosia.org",
                availableLocales: nil,
                availability: nil,
                wallpapers: wallpapers,
                description: nil,
                heading: nil,
                subheading: customSubheading)
        )

        let subject = createSubject()
        let headerViewModel = subject.sectionHeaderViewModel(for: 2) {
        }

        // Verify that only subheading is shown, no heading
        XCTAssertNil(headerViewModel?.title)
        XCTAssertEqual(headerViewModel?.description, customSubheading)
    }

    // Ecosia: Test that no title/description is shown when both are nil
    func testSectionHeaderViewModel_noFallbackWhenBothNil() {
        let subject = createSubject()
        let headerViewModel = subject.sectionHeaderViewModel(for: 0) {
        }

        // Verify that when heading/subheading are nil, nothing is shown (no fallback to localized strings)
        XCTAssertNil(headerViewModel?.title)
        XCTAssertNil(headerViewModel?.description)
    }

    func testDownloadAndSetWallpaper_downloaded_wallpaperIsSet() {
        guard let mockManager = wallpaperManager as? WallpaperManagerMock else { return }
        let subject = createSubject()
        let indexPath = IndexPath(item: 1, section: 0)

        subject.downloadAndSetWallpaper(at: indexPath) { result in
            XCTAssertEqual(subject.selectedIndexPath, indexPath)
            XCTAssertEqual(mockManager.setCurrentWallpaperCallCount, 1)
        }
    }

//    func testClickingCell_recordsWallpaperChange() {
//        wallpaperManager = WallpaperManager()
//        let subject = createSubject()
//
//        let expectation = self.expectation(description: "Download and set wallpaper")
//        subject.downloadAndSetWallpaper(at: IndexPath(item: 0, section: 0)) { _ in
//            self.testEventMetricRecordingSuccess(metric: GleanMetrics.WallpaperAnalytics.wallpaperSelected)
//            expectation.fulfill()
//        }
//
//        waitForExpectations(timeout: 5, handler: nil)
//    }

    func createSubject() -> WallpaperSettingsViewModel {
        let subject = WallpaperSettingsViewModel(wallpaperManager: wallpaperManager,
                                                 tabManager: MockTabManager(),
                                                 theme: LightTheme())
        trackForMemoryLeaks(subject)
        return subject
    }

    func addWallpaperCollections() {
        guard let mockManager = wallpaperManager as? WallpaperManagerMock else { return }

        var wallpapersForClassic: [Wallpaper] {
            var wallpapers = [Wallpaper]()
            wallpapers.append(Wallpaper(id: "fxDefault",
                                        textColor: .green,
                                        cardColor: .green,
                                        logoTextColor: .green))

            for _ in 0..<4 {
                wallpapers.append(Wallpaper(id: "fxAmethyst",
                                            textColor: .red,
                                            cardColor: .red,
                                            logoTextColor: .red))
            }

            return wallpapers
        }

        var wallpapersForOther: [Wallpaper] {
            var wallpapers = [Wallpaper]()
            for _ in 0..<6 {
                wallpapers.append(Wallpaper(id: "fxCerulean",
                                            textColor: .purple,
                                            cardColor: .purple,
                                            logoTextColor: .purple))
            }

            return wallpapers
        }

        mockManager.mockAvailableCollections = [
            WallpaperCollection(
                id: "classic-firefox",
                learnMoreURL: nil,
                availableLocales: nil,
                availability: nil,
                wallpapers: wallpapersForOther,
                description: nil,
                heading: nil,
                subheading: nil),
            WallpaperCollection(
                id: "otherCollection",
                learnMoreURL: "https://www.mozilla.com",
                availableLocales: nil,
                availability: nil,
                wallpapers: wallpapersForOther,
                description: nil,
                heading: nil,
                subheading: nil)
        ]
    }
}
