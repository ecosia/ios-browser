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
        profile = makeProfile()
        DependencyHelperMock().bootstrapDependencies(injectedProfile: profile)
    }

    override func tearDown() {
        profile.shutdown()
        profile = nil
        DependencyHelperMock().reset()
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

    var isSwipingTabsEnabled: Bool { false }
    var userInterfaceIdiom: UIUserInterfaceIdiom { .phone }

    @MainActor
    var isReduceTransparencyEnabled: Bool { !isBlurring }

    @MainActor
    var glassEffectAlpha: CGFloat { isBlurring ? 0 : 1 }

    @MainActor
    var novaToolbarGlassEffectAlpha: CGFloat { glassEffectAlpha }

    func shouldShowNavigationToolbar(for traitCollection: UITraitCollection) -> Bool { true }
    func shouldShowTabStrip(for traitCollection: UITraitCollection) -> Bool { false }

    @MainActor
    func shouldBlur() -> Bool { isBlurring }
}
