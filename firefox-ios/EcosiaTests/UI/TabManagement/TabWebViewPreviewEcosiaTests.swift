// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import SiteImageView
@testable import Client

/// The preview shown while swiping across the address bar to a new tab: it stands for Ecosia's NTP,
/// so it shows Ecosia's logo, never Firefox's.
@MainActor
final class TabWebViewPreviewEcosiaTests: XCTestCase {

    func testNewTabPreview_showsEcosiaLogo() throws {
        let preview = TabWebViewPreview()

        preview.setScreenshot(nil)

        let favicon = try XCTUnwrap(faviconView(in: preview))
        XCTAssertFalse(favicon.isHidden)
        XCTAssertTrue(favicon.image.map(isEcosiaLogo) ?? false, "The new tab preview shows Ecosia's logo")
        XCTAssertFalse(favicon.image.map(isFirefoxLogo) ?? false, "The new tab preview never shows Firefox's logo")
    }

    func testNewTabPreview_thenWebsitePreview_resetsLogoScale() throws {
        let preview = TabWebViewPreview()
        preview.setScreenshot(nil)

        preview.setScreenshot(url: URL(string: "https://www.ecosia.org"))

        let favicon = try XCTUnwrap(faviconView(in: preview))
        XCTAssertEqual(favicon.transform, .identity, "A website's favicon keeps its size")
    }

    // MARK: - Helpers

    private func faviconView(in preview: TabWebViewPreview) -> FaviconImageView? {
        preview.subviews.compactMap { $0 as? FaviconImageView }.first
    }

    private func isEcosiaLogo(_ image: UIImage) -> Bool {
        isSameImage(image, UIImage(named: "ecosiaLogoLaunch"))
    }

    private func isFirefoxLogo(_ image: UIImage) -> Bool {
        isSameImage(image, UIImage(named: ImageIdentifiers.firefoxFavicon))
    }

    private func isSameImage(_ image: UIImage, _ other: UIImage?) -> Bool {
        guard let data = image.pngData(), let otherData = other?.pngData() else { return false }
        return data == otherData
    }
}
