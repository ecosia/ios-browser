// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SnapshotTesting
import XCTest
import Common
import Shared
import Core
import MozillaAppServices
@testable import Client

class NTPComponentTests: XCTestCase {
    
    private var profile: MockProfile!
    private let commonWidth = 375
    
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
    }
    
    override func tearDown() {
        super.tearDown()
        AppContainer.shared.reset()
        profile = nil
    }
    
    func testNTPNewsCell() {
        do {
            let mockNews = try createMockNewsModel()
            let cell = NTPNewsCell(frame: CGRect(x: 0, y: 0, width: commonWidth, height: 100))
            cell.configure(mockNews!, images: Images(.init(configuration: .ephemeral)), row: 0, totalCount: 1)
            assertSnapshot(of: cell, as: .image)
        } catch {
            XCTFail("Failed to create mock NewsModel: \(error)")
        }
    }
    
    func testNTPLibraryCell() {
        let cell = NTPLibraryCell(frame: CGRect(x: 0, y: 0, width: commonWidth, height: 100))
        assertSnapshot(of: cell, as: .image)
    }
    
    func testNTPBookmarkNudgeCell() {
        let cell = NTPBookmarkNudgeCell(frame: CGRect(x: 0, y: 0, width: commonWidth, height: 200))
        assertSnapshot(of: cell, as: .image)
    }
    
    func testNTPReferralMultipleInvitesCell() {
        impactInfoReferralCellWithInvites(2)
    }
    
    func testNTPReferralSingleInviteCell() {
        impactInfoReferralCellWithInvites(1)
    }
    
    func testNTPTotalTreesCell() {
        let cell = NTPImpactCell(frame: CGRect(x: 0, y: 0, width: commonWidth, height: 100))
        let viewModel = NTPImpactCellViewModel(referrals: Referrals(), theme: EcosiaLightTheme())
        let mockInfoItemSection: ClimateImpactInfo = .totalTrees(value: 200356458)
        cell.configure(items: [mockInfoItemSection])
        cell.layoutIfNeeded()
        assertSnapshot(of: cell, as: .image)
    }
    
    func testNTPTotalInvecstedCell() {
        let cell = NTPImpactCell(frame: CGRect(x: 0, y: 0, width: commonWidth, height: 100))
        let viewModel = NTPImpactCellViewModel(referrals: Referrals(), theme: EcosiaLightTheme())
        let mockInfoItemSection: ClimateImpactInfo = .totalInvested(value: 89942822)
        cell.configure(items: [mockInfoItemSection])
        cell.layoutIfNeeded()
        assertSnapshot(of: cell, as: .image)
    }
    
    func testNTPCustomizationCell() {
        let cell = NTPCustomizationCell(frame: CGRect(x: 0, y: 0, width: commonWidth, height: 100))
        assertSnapshot(of: cell, as: .image)
    }
    
    func testNTPAboutFinancialReportsEcosiaCell() {
        aboutCellForSection(.financialReports)
    }
    
    func testNTPAboutPrivacyEcosiaCell() {
        aboutCellForSection(.privacy)
    }
    
    func testNTPAboutTreesEcosiaCell() {
        aboutCellForSection(.trees)
    }
}

extension NTPComponentTests {
    
    private func aboutCellForSection(_ aboutEcosiaSection: AboutEcosiaSection) {
        let cell = NTPAboutEcosiaCell(frame: CGRect(x: 0, y: 0, width: commonWidth, height: 240))
        let viewModel = NTPAboutEcosiaCellViewModel(theme: EcosiaLightTheme())
        cell.configure(section: aboutEcosiaSection, viewModel: viewModel)
        let sectionTitle = aboutEcosiaSection.title.lowercased().replacingOccurrences(of: " ", with: "_")
        assertSnapshot(of: cell, as: .image, testName: "testNTPAboutSection_\(sectionTitle)")
    }
    
    private func impactInfoReferralCellWithInvites(_ invites: Int) {
        let cell = NTPImpactCell(frame: CGRect(x: 0, y: 0, width: commonWidth, height: 100))
        let viewModel = NTPImpactCellViewModel(referrals: Referrals(), theme: EcosiaLightTheme())
        let mockInfoItemSection: ClimateImpactInfo = .referral(value: invites)
        cell.configure(items: [mockInfoItemSection])
        let invitesTestNameString = invites > 1 ? "multiple_invites" : "single_invite"
        assertSnapshot(of: cell, as: .image, testName: "testNTPReferralInvitesCell_\(invitesTestNameString)")
    }
    
    private func createMockNewsModel() throws -> NewsModel? {
        let currentTimestamp = Date().timeIntervalSince1970
        let jsonString = """
        {
            "id": 123,
            "text": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            "language": "en",
            "publishDate": \(currentTimestamp),
            "imageUrl": "https://example.com/image.jpg",
            "targetUrl": "https://example.com/news",
            "trackingName": "example_news_tracking"
        }
        """
        let jsonData = Data(jsonString.utf8)
        let decoder = JSONDecoder()

        // Custom date decoding strategy if needed
        decoder.dateDecodingStrategy = .secondsSince1970
        return try decoder.decode(NewsModel.self, from: jsonData)
    }}
