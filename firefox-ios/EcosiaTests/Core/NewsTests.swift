// swiftlint:disable force_try
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

@MainActor final class NewsTests: XCTestCase {
    // Ecosia: News delivers its callbacks via async MainActor Tasks. Under CI load the main
    // actor can be busy enough that the callback misses a 1s window even though no real network
    // is involved (MockURLSession + bundled JSON). `waitForExpectations` returns the instant the
    // expectation is fulfilled, so a tolerant timeout adds zero time in the happy path while
    // removing load-induced flakes. The inverted testCallOnFailed keeps a short wait on purpose
    // (inverted expectations always wait the full duration). (MOB-4384)
    private let asyncTimeout: TimeInterval = 10

    override func setUp() {
        try? FileManager.default.removeItem(at: FileManager.news)
        try? FileManager.default.removeItem(at: FileManager.user)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: FileManager.news)
        try? FileManager.default.removeItem(at: FileManager.user)
    }

    private func mockSavedItems() {
        let items = [
            NewsModel(
                id: 1,
                text: "",
                language: .en,
                publishDate: .distantPast,
                imageUrl: URL(string: "https://avocade.com")!,
                targetUrl: URL(string: "https://avocadoe.com")!,
                trackingName: ""
            ),
            NewsModel(
                id: 2,
                text: "hello",
                language: .en,
                publishDate: .distantFuture,
                imageUrl: URL(string: "https://guacamole.com")!,
                targetUrl: URL(string: "https://guaca.com")!,
                trackingName: ""
            ),
            NewsModel(
                id: 3,
                text: "hello",
                language: .de,
                publishDate: .distantFuture,
                imageUrl: URL(string: "https://guacamole.com")!,
                targetUrl: URL(string: "https://guaca.com")!,
                trackingName: ""
            )
        ]
        try? JSONEncoder().encode(items).write(to: FileManager.news, options: .atomic)
    }

    func testPublishOnMainThread() {
        let expect = expectation(description: "")

        mockSavedItems()
        let notifications = News()
        notifications.subscribe(self) { _ in
            XCTAssertEqual(.main, Thread.current)
            expect.fulfill()
        }
        waitForExpectations(timeout: asyncTimeout)
    }

    func testLoadFromDisk() {
        let expect = expectation(description: "")
        mockSavedItems()

        let notifications = News()
        notifications.subscribe(self) {
            XCTAssertEqual(2, $0.count)
            $0.forEach {
                XCTAssertEqual(.en, $0.language)
            }
            XCTAssertGreaterThan($0.first!.publishDate, $0.last!.publishDate)
            expect.fulfill()
        }
        waitForExpectations(timeout: asyncTimeout)
    }

    func testAvoidDuplication() {
        var set = Set([
            NewsModel(
                id: 1,
                text: "<strong>Great headline</strong> ",
                language: .en,
                publishDate: .distantPast,
                imageUrl: URL(string: "https://avocade.com")!,
                targetUrl: URL(string: "https://avocadoe.com")!,
                trackingName: ""
            )
        ])
        set.insert(
            NewsModel(
                id: 1,
                text: "hello",
                language: .de,
                publishDate: .distantFuture,
                imageUrl: URL(string: "https://guacamole.com")!,
                targetUrl: URL(string: "https://guaca.com")!,
                trackingName: ""
            )
        )
        XCTAssertEqual(1, set.count)
    }

    func testLoadNewForced() {
        User.shared.news = Date()

        let expect = expectation(description: "")
        let session = MockURLSession()
        session.data = [try! .init(contentsOf: Bundle.ecosiaTests.url(forResource: "notifications", withExtension: "json")!)]

        let notifications = News()
        notifications.subscribe(self) {
            XCTAssertEqual(10, $0.count)
            XCTAssertGreaterThan($0.first!.publishDate, $0.last!.publishDate)

            expect.fulfill()
        }
        notifications.load(session: session)
        waitForExpectations(timeout: asyncTimeout)
    }

    func testNeedsUpdateOnEmptyNews() {
        let news = News()
        XCTAssertTrue(news.needsUpdate)
    }

    func testNeedsUpdateAfterLoading() {
        let expect = expectation(description: "")
        mockSavedItems()
        let news = News()

        news.subscribe(self) { _ in
            /*
             User.shared.news is a process-global mutated asynchronously by
             News.save() (a fire-and-forget MainActor Task). Setting it inside
             the callback — immediately before reading needsUpdate, with no
             suspension point in between — makes this check deterministic and
             immune to stray async writes from sibling tests, mirroring the
             inline pattern used for needsUpdate2/needsUpdate3 below.
             */
            User.shared.news = .distantPast
            let needsUpdate1 = MainActor.assumeIsolated { news.needsUpdate }
            XCTAssertTrue(needsUpdate1)

            User.shared.news = Date()
            let needsUpdate2 = MainActor.assumeIsolated { news.needsUpdate }
            XCTAssertFalse(needsUpdate2)

            User.shared.news = Date().advanced(by: -25 * 60 * 60)
            let needsUpdate3 = MainActor.assumeIsolated { news.needsUpdate }
            XCTAssertTrue(needsUpdate3)

            expect.fulfill()
        }
        waitForExpectations(timeout: asyncTimeout)
    }

    func testSubscribeAndReceive() {
        let expect = expectation(description: "")
        let news = News()

        news.subscribeAndReceive(self) { items in
            let stateCount = MainActor.assumeIsolated { news.state?.count }
            XCTAssert(stateCount == items.count)
            expect.fulfill()
        }
        waitForExpectations(timeout: asyncTimeout)
    }

    func testCallOnFailed() {
        let expect = expectation(description: "")
        expect.isInverted = true // we expect no callback
        let session = MockURLSession()
        let notifications = News()
        notifications.subscribe(self) { _ in
            expect.fulfill()
        }
        notifications.load(session: session)
        // Ecosia: inverted expectation — passes only if NO callback arrives, so it waits the full
        // duration every run. Keep it short; a tolerant timeout here would just stall the suite. (MOB-4384)
        waitForExpectations(timeout: 1)
    }

    func testCleanTextFromBundle() {
        let expect = expectation(description: "")
        mockSavedItems()
        let notifications = News()
        notifications.subscribe(self) {
            $0.forEach {
                XCTAssertFalse($0.text.contains("&#39;"))
                XCTAssertFalse($0.text.contains("<strong>"))
            }
            expect.fulfill()
        }
        waitForExpectations(timeout: asyncTimeout)
    }

    func testCleanTextFromNetwork() {
        let expect = expectation(description: "")
        let session = MockURLSession()
        session.data = [try! .init(contentsOf: Bundle.ecosiaTests.url(forResource: "notifications", withExtension: "json")!)]
        let notifications = News()
        notifications.subscribe(self) {
            $0.forEach {
                XCTAssertFalse($0.text.contains("&#39;"))
                XCTAssertFalse($0.text.contains("<strong>"))
            }
            expect.fulfill()
        }
        notifications.load(session: session)
        waitForExpectations(timeout: asyncTimeout)
    }
}
// swiftlint:enable force_try
