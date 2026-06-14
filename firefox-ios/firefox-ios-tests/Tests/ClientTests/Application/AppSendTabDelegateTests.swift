// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

@preconcurrency
@MainActor
final class AppFxACommandsTests: XCTestCase {
    private var applicationStateProvider: MockApplicationStateProvider!
    private var applicationHelper: MockApplicationHelper!

    override func setUp() {
        super.setUp()
        self.applicationStateProvider = MockApplicationStateProvider()
        self.applicationHelper = MockApplicationHelper()
    }

    override func tearDown() {
        super.tearDown()
        self.applicationStateProvider = nil
        self.applicationHelper = nil
    }

    func testOpenSendTabs_inactiveState_doesntCallDeeplink() {
        applicationStateProvider.applicationState = .inactive
        let url = URL(string: "https://mozilla.com")!
        let subject = createSubject()
        subject.openSendTabs(for: [url])

        XCTAssertEqual(applicationHelper.openURLCalled, 0)
    }

    func testOpenSendTabs_backgroundState_doesntCallDeeplink() {
        applicationStateProvider.applicationState = .background
        let url = URL(string: "https://mozilla.com")!
        let subject = createSubject()
        subject.openSendTabs(for: [url])

        XCTAssertEqual(applicationHelper.openURLCalled, 0)
    }

    func testOpenSendTabs_activeWithOneURL_callsDeeplink() {
        let url = URL(string: "https://mozilla.com")!
        let subject = createSubject()
        subject.openSendTabs(for: [url])

        XCTAssertEqual(applicationHelper.openURLCalled, 1)
        let expectedURL = URL(string: URL.mozInternalScheme + "://open-url?url=\(url)")!
        XCTAssertEqual(applicationHelper.lastOpenURL, expectedURL)
    }

    func testOpenSendTabs_activeWithMultipleURLs_callsDeeplink() {
        let url = URL(string: "https://mozilla.com")!
        let subject = createSubject()
        subject.openSendTabs(for: [url, url, url])

        XCTAssertEqual(applicationHelper.openURLCalled, 3)
    }

    // MARK: - Close Remote Tabs Tests

    // Ecosia: closeTabs(for:) records closeTabsCalled asynchronously. The original tests asserted after a
    // fixed `DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)` — a 0.1s window that is far too tight
    // under CI load and flaked ("0 is not equal to 1": the async work hadn't landed by the deadline). Poll
    // for the condition with a tolerant timeout instead; it returns as soon as the work completes, so it
    // adds zero time in the happy path. (MOB-4384)
    private func waitForCloseTabs(timeout: TimeInterval = 5) async {
        let deadline = Date().addingTimeInterval(timeout)
        while applicationHelper.closeTabsCalled < 1, Date() < deadline {
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
    }

    func testCloseSendTabs_activeWithOneURL_callsDeeplink() async {
        let url = URL(string: "https://mozilla.com")!
        let subject = createSubject()
        subject.closeTabs(for: [url])
        await waitForCloseTabs()
        XCTAssertEqual(applicationHelper.closeTabsCalled, 1)
    }

    func testCloseSendTabs_activeWithMultipleURLs_callsDeeplink() async {
        let url1 = URL(string: "https://example.com")!
        let url2 = URL(string: "https://example.com/1")!
        let url3 = URL(string: "https://example.com/2")!
        let subject = createSubject()
        subject.closeTabs(for: [url1, url2, url3])
        await waitForCloseTabs()
        XCTAssertEqual(applicationHelper.closeTabsCalled, 1)
    }

    // MARK: - Helper methods

    func createSubject() -> AppFxACommandsDelegate {
        let subject = AppFxACommandsDelegate(app: applicationStateProvider,
                                             applicationHelper: applicationHelper)
        trackForMemoryLeaks(subject)
        return subject
    }
}

// MARK: MockApplicationStateProvider
final class MockApplicationStateProvider: ApplicationStateProvider, @unchecked Sendable {
    var applicationState: UIApplication.State = .active
}
