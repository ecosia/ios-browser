// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Glean
import Shared
import XCTest

@testable import Client

@MainActor
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

    // Ecosia: Test collection without description shows no description
    func testSectionHeaderViewModel_defaultCollectionWithoutDescription() {
        let subject = createSubject()
        let headerViewModel = subject.sectionHeaderViewModel(for: 0) {
        }
        XCTAssertNotNil(headerViewModel?.title)
        XCTAssertNil(headerViewModel?.description)
        XCTAssertNil(headerViewModel?.buttonTitle)
    }

    // Ecosia: Test collection with learn-more URL shows button
    func testSectionHeaderViewModel_collectionWithLearnMoreURL() {
        let subject = createSubject()
        let headerViewModel = subject.sectionHeaderViewModel(for: 1) {
        }
        XCTAssertNotNil(headerViewModel?.buttonTitle)
    }

    // Ecosia: Test that heading and description are used when available
    func testSectionHeaderViewModel_usesJSONHeadingAndDescription() {
        guard let mockManager = wallpaperManager as? WallpaperManagerMock else { return }

        let customDescription = "Beautiful nature wallpapers"
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
                description: customDescription,
                heading: "Abstract Nature")
        )

        let subject = createSubject()
        let headerViewModel = subject.sectionHeaderViewModel(for: 2) {
        }
        XCTAssertNotNil(headerViewModel?.title)
        XCTAssertNotNil(headerViewModel?.description)
        XCTAssertNotNil(headerViewModel?.buttonTitle)
    }

    // Ecosia: Test that heading can be shown independently without description
    func testSectionHeaderViewModel_headingWithoutDescription() {
        guard let mockManager = wallpaperManager as? WallpaperManagerMock else { return }

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
                heading: "Ecosia Projects")
        )

        let subject = createSubject()
        let headerViewModel = subject.sectionHeaderViewModel(for: 2) {
        }
        XCTAssertNotNil(headerViewModel?.title)
        XCTAssertNil(headerViewModel?.description)
    }

    // Ecosia: Test that description can be shown independently without heading
    func testSectionHeaderViewModel_descriptionWithoutHeading() {
        guard let mockManager = wallpaperManager as? WallpaperManagerMock else { return }

        let customDescription = "Lorem ipsum dolor sit amet"
        let wallpapers = [Wallpaper(id: "test",
                                    textColor: .green,
                                    cardColor: .green,
                                    logoTextColor: .green)]

        mockManager.mockAvailableCollections.append(
            WallpaperCollection(
                id: "description-only-collection",
                learnMoreURL: "https://ecosia.org",
                availableLocales: nil,
                availability: nil,
                wallpapers: wallpapers,
                description: customDescription,
                heading: nil)
        )

        let subject = createSubject()
        let headerViewModel = subject.sectionHeaderViewModel(for: 2) {
        }
        XCTAssertNotNil(headerViewModel?.title)
        XCTAssertNotNil(headerViewModel?.description)
    }

    // Ecosia: Test that no description is shown when it is nil
    func testSectionHeaderViewModel_noDescriptionWhenNil() {
        let subject = createSubject()
        let headerViewModel = subject.sectionHeaderViewModel(for: 0) {
        }
        XCTAssertNotNil(headerViewModel?.title)
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

    func createSubject() -> WallpaperSettingsViewModel {
        let subject = WallpaperSettingsViewModel(wallpaperManager: wallpaperManager,
                                                 tabManager: MockTabManager(),
                                                 theme: LightTheme(),
                                                 windowUUID: WindowUUID())
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
                heading: nil),
            WallpaperCollection(
                id: "otherCollection",
                learnMoreURL: "https://www.mozilla.com",
                availableLocales: nil,
                availability: nil,
                wallpapers: wallpapersForOther,
                description: nil,
                heading: nil)
        ]
    }
}