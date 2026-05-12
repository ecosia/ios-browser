// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import XCTest
@testable import Client

@MainActor
final class LaunchScreenViewModelTests: XCTestCase {
    // Ecosia: Remove MockGleanPlumbMessageManagerProtocol ref
    // private var messageManager: MockGleanPlumbMessageManagerProtocol!
    private var profile: MockProfile!
    private var delegate: MockLaunchFinishedLoadingDelegate!
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
        delegate = MockLaunchFinishedLoadingDelegate()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        // Ecosia: Remove MockGleanPlumbMessageManagerProtocol ref
        // messageManager = MockGleanPlumbMessageManagerProtocol()

        // Ecosia: PrefsKeys.NimbusFeatureTestsOverride removed in v147
    }

    override func tearDown() {
        super.tearDown()
        AppContainer.shared.reset()
        profile = nil
        // Ecosia: Remove MockGleanPlumbMessageManagerProtocol ref
        // messageManager = nil
        delegate = nil

        // Ecosia: PrefsKeys.NimbusFeatureTestsOverride removed in v147
    }

    func testLaunchDoesntCallLoadedIfNotStarted() {
        let subject = createSubject()
        subject.delegate = delegate

        XCTAssertEqual(delegate.launchBrowserCalled, 0)
        XCTAssertEqual(delegate.launchWithTypeCalled, 0)
    }
    /* Ecosia: Versioning is testes in a dedicated Ecosia test
    func testLaunchType_intro() async {
        let subject = createSubject()
        subject.delegate = delegate
        await subject.startLoading(appVersion: "112.0")

        guard case .intro = delegate.savedLaunchType else {
            XCTFail("Expected intro, but was \(String(describing: delegate.savedLaunchType))")
            return
        }
        XCTAssertEqual(delegate.launchBrowserCalled, 0)
        XCTAssertEqual(delegate.launchWithTypeCalled, 1)
    }

    func testLaunchType_update() async {
        profile.prefs.setString("112.0", forKey: PrefsKeys.AppVersion.Latest)
        profile.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)

        let subject = createSubject()
        subject.delegate = delegate
        await subject.startLoading(appVersion: "113.0")

        guard case .update = delegate.savedLaunchType else {
            XCTFail("Expected update, but was \(String(describing: delegate.savedLaunchType))")
            return
        }
        XCTAssertEqual(delegate.launchBrowserCalled, 0)
        XCTAssertEqual(delegate.launchWithTypeCalled, 1)
    }
     */

    /* Ecosia: Comment test with no mean to Launch survey
    func testLaunchType_survey() async {
        profile.prefs.setString("112.0", forKey: PrefsKeys.AppVersion.Latest)
        profile.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)
        let message = createMessage()
        messageManager.message = message

        let subject = createSubject()
        subject.delegate = delegate
        await subject.startLoading(appVersion: "112.0")

        guard case .survey = delegate.savedLaunchType else {
            XCTFail("Expected survey, but was \(String(describing: delegate.savedLaunchType))")
            return
        }
        XCTAssertEqual(delegate.launchBrowserCalled, 0)
        XCTAssertEqual(delegate.launchWithTypeCalled, 1)
    }
     */

    /* Ecosia: Versioning is testes in a dedicated Ecosia test
    func testSplashScreenExperiment_afterShown_returnsTrue() {

        let subject = createSubject()
        let value = subject.getSplashScreenExperimentHasShown()
        XCTAssertFalse(value)

        subject.setSplashScreenExperimentHasShown()

        let updatedValue = subject.getSplashScreenExperimentHasShown()
        XCTAssertTrue(updatedValue)
    }
     */

    // MARK: - Helpers
    private func createSubject(file: StaticString = #file,
                               line: UInt = #line) -> LaunchScreenViewModel {
        // Ecosia: OnboardingViewModel/OnboardingCardInfoModel removed in v147; use default onboardingModel
        let subject = LaunchScreenViewModel(windowUUID: windowUUID,
                                            profile: profile)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
    /* Ecosia: Remove MockGleanPlumbMessageManagerProtocol ref
    private func createMessage(
        for surface: MessageSurfaceId = .survey,
        action: String = "OPEN_NEW_TAB"
    ) -> GleanPlumbMessage {
        let metadata = GleanPlumbMessageMetaData(id: "",
                                                 impressions: 0,
                                                 dismissals: 0,
                                                 isExpired: false)

        return GleanPlumbMessage(id: "test-notification",
                                 data: MockNotificationMessageDataProtocol(surface: surface),
                                 action: action,
                                 triggerIfAll: [],
                                 exceptIfAny: [],
                                 style: MockStyleDataProtocol(),
                                 metadata: metadata)
    }
     */

    /* Ecosia: OnboardingViewModel, OnboardingCardInfoModel, OnboardingButtons, OnboardingButtonInfoModel
       and .forwardOneCard removed in v147
    func createOnboardingViewModel() -> OnboardingViewModel { ... }
    func createCard(index: Int) -> OnboardingCardInfoModel { ... }
    */
}
