// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SnapshotTesting
import XCTest
import SwiftUI
import Common
import Shared
import Storage
import Ecosia
import SiteImageView
@testable import Client

final class HomepageComponentTests: SnapshotBaseTests {

    private let commonWidth: CGFloat = 375
    private let topSiteCellSize = CGSize(width: 100, height: 120)
    private let englishOnlyLocales = [Locale(identifier: "en")]

    func testNTPHeaderLogo() {
        SnapshotTestHelper.assertSnapshot(
            initializingWith: { self.makeHeaderLogoHostingController() },
            locales: englishOnlyLocales
        )
    }

    func testEcosiaCustomizeButton() {
        SnapshotTestHelper.assertSnapshot(
            initializingWith: { self.makeCustomizeButtonHostingController() },
            locales: englishOnlyLocales
        )
    }

    @available(iOS 16, *)
    func testEcosiaAccountNavButton_loggedOut() {
        prepareLoggedOutAccountState()

        SnapshotTestHelper.assertSnapshot(
            initializingWith: { self.makeAccountNavButtonHostingController() },
            locales: englishOnlyLocales,
            wait: 0.3
        )
    }

    func testNTPImpactCell_withImpactRows() {
        SnapshotTestHelper.assertSnapshot(
            initializingWith: { self.makeConfiguredImpactCell() },
            locales: englishOnlyLocales,
            themes: [.light],
            wait: 0.5,
            precision: 0.97
        )
    }

    func testNTPSearchBar_resting() {
        // Upload button visibility follows FileUploadFeatureFlag; lower precision tolerates either layout.
        SnapshotTestHelper.assertSnapshot(
            initializingWith: { self.makeConfiguredSearchBar() },
            precision: 0.90
        )
    }

    func testATopSiteItemCell_pinned() {
        SnapshotTestHelper.assertSnapshot(
            initializingWith: { self.makeConfiguredPinnedTopSiteCell() },
            locales: englishOnlyLocales,
            wait: 1.5,
            precision: 0.97,
            testName: "testTopSiteItemCell_pinned"
        )
    }
}

// MARK: - View builders

private extension HomepageComponentTests {

    func makeHeaderLogoHostingController() -> UIViewController {
        makeNTPHeaderSnapshotHostingController(
            content: { NTPHeaderLogoView() },
            size: CGSize(width: commonWidth, height: 72)
        )
    }

    func makeCustomizeButtonHostingController() -> UIViewController {
        makeNTPHeaderSnapshotHostingController(
            content: { EcosiaCustomizeButton(onTap: {}) },
            size: CGSize(width: 72, height: 72)
        )
    }

    @available(iOS 16, *)
    func makeAccountNavButtonHostingController() -> UIViewController {
        makeNTPHeaderSnapshotHostingController(
            content: {
                EcosiaAccountNavButton(
                    seedCount: UserDefaultsSeedProgressManager.maxSeedsForLoggedOutUsers,
                    enableAnimation: false,
                    showSeedSparkles: false,
                    windowUUID: .snapshotTestDefaultUUID,
                    onTap: {}
                )
            },
            size: CGSize(width: 160, height: 72)
        )
    }

    func makeNTPHeaderSnapshotHostingController<Content: View>(
        @ViewBuilder content: () -> Content,
        size: CGSize
    ) -> UIViewController {
        let background = Color(uiColor: Self.ntpSnapshotBackgroundColor)
        let root = ZStack {
            background
            content()
        }
        .frame(width: size.width, height: size.height)

        let controller = UIHostingController(rootView: root)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = Self.ntpSnapshotBackgroundColor
        return controller
    }

    func makeConfiguredImpactCell() -> UIView {
        let container = NTPImpactCellSnapshotContainerView(
            width: commonWidth,
            backgroundColor: Self.ntpSnapshotBackgroundColor
        )
        container.configure(
            rows: ImpactCellSnapshotFixture.rows,
            title: ImpactCellSnapshotFixture.rotatingTitle,
            theme: themeManager.getCurrentTheme(for: .snapshotTestDefaultUUID)
        )
        return container
    }

    func makeConfiguredSearchBar() -> NTPSearchBarView {
        let searchBar = NTPSearchBarView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: commonWidth,
                height: NTPSearchBarView.minHeight
            )
        )
        searchBar.applyTheme(theme: themeManager.getCurrentTheme(for: .snapshotTestDefaultUUID))
        searchBar.setNeedsLayout()
        searchBar.layoutIfNeeded()
        return searchBar
    }

    func makeConfiguredPinnedTopSiteCell() -> TopSiteItemCell {
        let site = Site.createPinnedSite(
            fromSite: Site.createBasicSite(
                url: "https://www.ecosia.org",
                title: "Ecosia"
            )
        )
        let topSite = TopSite(site: site)
        let cell = TopSiteItemCell(frame: CGRect(origin: .zero, size: topSiteCellSize))
        cell.configure(
            topSite,
            position: 0,
            theme: themeManager.getCurrentTheme(for: .snapshotTestDefaultUUID),
            textColor: nil
        )
        cell.imageView.manuallySetImage(Self.snapshotFaviconPlaceholder)
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        return cell
    }
}

// MARK: - Auth state

private extension HomepageComponentTests {

    func prepareLoggedOutAccountState() {
        UserDefaultsSeedProgressManager.resetLocalSeedProgress()
        UserDefaultsSeedProgressManager.addSeeds(
            UserDefaultsSeedProgressManager.maxSeedsForLoggedOutUsers
        )
    }

    static let ntpSnapshotBackgroundColor = UIColor(red: 0.08, green: 0.18, blue: 0.12, alpha: 1)

    static let snapshotFaviconPlaceholder: UIImage = {
        let size = CGSize(width: 32, height: 32)
        return UIGraphicsImageRenderer(size: size).image { context in
            UIColor(red: 0.22, green: 0.62, blue: 0.32, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }()
}

// MARK: - Impact cell snapshot fixture

/// Fixed copy and counters so impact-cell references do not drift with live data or locale formatting.
private enum ImpactCellSnapshotFixture {
    static let rotatingTitle = "Search. Find. Save the planet."

    static let rows: [NTPImpactSnapshotRow] = [
        NTPImpactSnapshotRow(
            info: .totalTrees(value: 200_356_458),
            title: "200,356,458",
            subtitle: "trees planted by Ecosia",
            buttonTitle: nil
        ),
        NTPImpactSnapshotRow(
            info: .totalInvested(value: 89_942_822),
            title: "€89,942,822",
            subtitle: "dedicated to climate action",
            buttonTitle: nil
        )
    ]
}

// MARK: - Impact cell snapshot container

/// Hosts `NTPImpactCell` on the NTP dark-green backdrop with portrait traits so impact
/// rows stack vertically (not the landscape side-by-side layout).
private final class NTPImpactCellSnapshotContainerView: UIView {

    private let impactCell: NTPImpactCell

    init(width: CGFloat, backgroundColor: UIColor) {
        impactCell = NTPImpactCell(frame: CGRect(x: 0, y: 0, width: width, height: 0))
        super.init(frame: CGRect(x: 0, y: 0, width: width, height: 0))
        self.backgroundColor = backgroundColor
        addSubview(impactCell)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var traitCollection: UITraitCollection {
        UITraitCollection(traitsFrom: [
            super.traitCollection,
            UITraitCollection(verticalSizeClass: .regular),
            UITraitCollection(horizontalSizeClass: .compact),
            UITraitCollection(userInterfaceIdiom: .phone)
        ])
    }

    func configure(
        rows: [NTPImpactSnapshotRow],
        title: String,
        theme: Theme
    ) {
        impactCell.configureForSnapshot(
            rows: rows,
            title: title,
            theme: theme
        )
        layoutPortraitFit()
    }

    func configure(
        items: [ClimateImpactInfo],
        title: String?,
        theme: Theme
    ) {
        impactCell.configure(
            items: items,
            title: title,
            delegate: nil,
            theme: theme
        )
        layoutPortraitFit()
    }

    private func layoutPortraitFit() {
        let fittedHeight = impactCell.systemLayoutSizeFitting(
            CGSize(width: bounds.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        impactCell.frame = CGRect(x: 0, y: 0, width: bounds.width, height: fittedHeight)
        impactCell.setNeedsLayout()
        impactCell.layoutIfNeeded()

        frame = CGRect(x: 0, y: 0, width: bounds.width, height: fittedHeight)
    }
}
