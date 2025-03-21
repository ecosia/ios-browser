// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import XCTest
@testable import Client

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

        UserDefaults.standard.set(true, forKey: PrefsKeys.NimbusFeatureTestsOverride)
    }

    override func tearDown() {
        super.tearDown()
        AppContainer.shared.reset()
        profile = nil
        // Ecosia: Remove MockGleanPlumbMessageManagerProtocol ref
        // messageManager = nil
        delegate = nil

        UserDefaults.standard.set(false, forKey: PrefsKeys.NimbusFeatureTestsOverride)
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
        let onboardingModel = createOnboardingViewModel()

        let subject = LaunchScreenViewModel(windowUUID: windowUUID,
                                            profile: profile,
                                            // Ecosia: Remove MockGleanPlumbMessageManagerProtocol ref
                                            // messageManager: messageManager,
                                            onboardingModel: onboardingModel)
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

    func createOnboardingViewModel() -> OnboardingViewModel {
        let cards: [OnboardingCardInfoModel] = [
            createCard(index: 1),
            createCard(index: 2)
        ]

        return OnboardingViewModel(cards: cards,
                                   isDismissable: true)
    }

    func createCard(index: Int) -> OnboardingCardInfoModel {
        let buttons = OnboardingButtons(primary: OnboardingButtonInfoModel(title: "Button title \(index)",
                                                                           action: .forwardOneCard))
        return OnboardingCardInfoModel(cardType: .basic,
                                       name: "Name \(index)",
                                       order: index,
                                       title: "Title \(index)",
                                       body: "Body \(index)",
                                       link: nil,
                                       buttons: buttons,
                                       multipleChoiceButtons: [],
                                       onboardingType: .upgrade,
                                       a11yIdRoot: "A11y id \(index)",
                                       imageID: "Image id \(index)",
                                       instructionsPopup: nil)
    }
}
