// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Common
import Shared
import XCTest

@MainActor
final class StatusBarOverlayReduceTransparencyTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var profile: MockProfile!
    private let theme = LightTheme()

    override func setUp() {
        super.setUp()
        profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
    }

    override func tearDown() {
        profile.shutdown()
        profile = nil
        super.tearDown()
    }

    func testOnHomepage_withoutBlur_isClear() throws {
        let subject = createSubject(shouldBlur: false)

        subject.resetState(isHomepage: true)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor.alpha, 0)
    }

    func testOnWebpage_withoutBlur_isOpaque() throws {
        let subject = createSubject(shouldBlur: false)

        subject.resetState(isHomepage: false)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor.alpha, 1)
    }

    private func createSubject(shouldBlur: Bool) -> StatusBarOverlay {
        let subject = StatusBarOverlay(frame: .zero,
                                       notificationCenter: MockNotificationCenter(),
                                       toolbarHelper: ToolbarHelperStub(isBlurring: shouldBlur))
        subject.applyTheme(theme: theme)
        trackForMemoryLeaks(subject)
        return subject
    }
}

private struct ToolbarHelperStub: ToolbarHelperInterface {
    let isBlurring: Bool

    var isToolbarRefactorEnabled: Bool { true }
    var isToolbarTranslucencyEnabled: Bool { true }
    var isToolbarTranslucencyRefactorEnabled: Bool { true }
    var isSwipingTabsEnabled: Bool { false }
    var userInterfaceIdiom: UIUserInterfaceIdiom { .phone }
    var isReduceTransparencyEnabled: Bool { !isBlurring }
    var glassEffectAlpha: CGFloat { isBlurring ? 0 : 1 }

    func shouldShowNavigationToolbar(for traitCollection: UITraitCollection) -> Bool { true }
    func shouldShowTopTabs(for traitCollection: UITraitCollection) -> Bool { false }
    func shouldBlur() -> Bool { isBlurring }
    func backgroundAlpha() -> CGFloat { isBlurring ? 0.85 : 1 }
}
