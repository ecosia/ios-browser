// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import Shared
@testable import Client

@MainActor
final class GleanUploadTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    func testGleanUploadIsDisabled() {
        XCTAssertFalse(TelemetryWrapper.isGleanUploadEnabled)
    }

    func testInitGlean_withEveryDataPreferenceOn_doesNotStartUsageReporting() {
        let fixture = UsageReportingFixture()
        fixture.profile.prefs.setBool(true, forKey: AppConstants.prefSendUsageData)
        fixture.profile.prefs.setBool(true, forKey: AppConstants.prefSendDailyUsagePing)
        let telemetry = TelemetryWrapper(gleanUsageReportingMetricsService: fixture.service)

        telemetry.initGlean(fixture.profile, searchEnginesManager: AppContainer.shared.resolve(), sendUsageData: true)
        fixture.postLifecycleNotifications()

        XCTAssertFalse(fixture.api.enabledValues.contains(true))
        XCTAssertEqual(fixture.api.submitPingCount, 0)
    }

    func testDisableUsageReporting_withoutStoredProfileId_sendsNothing() {
        let fixture = UsageReportingFixture()

        fixture.service.disableUsageReporting(deletionRequest: fixture.deletionRequest)

        XCTAssertEqual(fixture.deletionRequest.enableCount, 0)
        XCTAssertEqual(fixture.api.requestDataDeletionCount, 0)
        XCTAssertTrue(fixture.api.enabledValues.isEmpty)
    }

    func testDisableUsageReporting_withStoredProfileId_requestsDeletionOnce() {
        let fixture = UsageReportingFixture()
        fixture.profile.prefs.setString(UUID().uuidString, forKey: PrefsKeys.Usage.profileId)

        fixture.service.disableUsageReporting(deletionRequest: fixture.deletionRequest)
        fixture.service.disableUsageReporting(deletionRequest: fixture.deletionRequest)

        XCTAssertEqual(fixture.deletionRequest.enableCount, 1)
        XCTAssertEqual(fixture.api.requestDataDeletionCount, 1)
        XCTAssertEqual(fixture.api.enabledValues, [false])
        XCTAssertNil(fixture.profile.prefs.stringForKey(PrefsKeys.Usage.profileId))
    }

    func testDisableUsageReporting_neverSubmitsUsageReportingOnLifecycleChanges() {
        let fixture = UsageReportingFixture()
        fixture.profile.prefs.setString(UUID().uuidString, forKey: PrefsKeys.Usage.profileId)

        fixture.service.disableUsageReporting(deletionRequest: fixture.deletionRequest)
        fixture.postLifecycleNotifications()

        XCTAssertEqual(fixture.api.submitPingCount, 0)
    }

    func testGleanPendingPingsDirectory_isInsideGleanDataInApplicationSupport() throws {
        let directory = try XCTUnwrap(TelemetryWrapper.gleanPendingPingsDirectory)

        XCTAssertEqual(directory.lastPathComponent, "pending_pings")
        XCTAssertEqual(directory.deletingLastPathComponent().lastPathComponent, "glean_data")
        XCTAssertEqual(directory.deletingLastPathComponent().deletingLastPathComponent(),
                       FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first)
    }

    func testDiscardQueuedGleanPingsOnce_deletesQueuedPingsAndKeepsDeletionRequest() throws {
        let gleanData = try GleanDataFixture()
        let prefs = MockProfilePrefs()

        TelemetryWrapper.discardQueuedGleanPingsOnce(prefs: prefs, directory: gleanData.pendingPings)

        XCTAssertFalse(FileManager.default.fileExists(atPath: gleanData.pendingPings.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: gleanData.deletionRequestPing.path))
        XCTAssertEqual(prefs.boolForKey(TelemetryWrapper.discardedQueuedGleanPingsKey), true)
    }

    func testDiscardQueuedGleanPingsOnce_keepsPingsQueuedAfterTheFirstRun() throws {
        let gleanData = try GleanDataFixture()
        let prefs = MockProfilePrefs()
        TelemetryWrapper.discardQueuedGleanPingsOnce(prefs: prefs, directory: gleanData.pendingPings)
        let retriedPing = try gleanData.queuePing(named: "usage-deletion-request")

        TelemetryWrapper.discardQueuedGleanPingsOnce(prefs: prefs, directory: gleanData.pendingPings)

        XCTAssertTrue(FileManager.default.fileExists(atPath: retriedPing.path))
    }

    func testDiscardQueuedGleanPingsOnce_withoutQueuedPings_marksItDone() throws {
        let gleanData = try GleanDataFixture()
        try FileManager.default.removeItem(at: gleanData.pendingPings)
        let prefs = MockProfilePrefs()

        TelemetryWrapper.discardQueuedGleanPingsOnce(prefs: prefs, directory: gleanData.pendingPings)

        XCTAssertEqual(prefs.boolForKey(TelemetryWrapper.discardedQueuedGleanPingsKey), true)
    }
}

/// A `glean_data` folder in a temporary directory, removed when the fixture is released.
private final class GleanDataFixture {
    let root: URL
    let pendingPings: URL
    let deletionRequestPing: URL

    init() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        pendingPings = root.appendingPathComponent("glean_data/pending_pings", isDirectory: true)
        let deletionRequest = root.appendingPathComponent("glean_data/deletion_request", isDirectory: true)
        deletionRequestPing = deletionRequest.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: pendingPings, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: deletionRequest, withIntermediateDirectories: true)
        try Data("deletion-request".utf8).write(to: deletionRequestPing)
        _ = try queuePing(named: "usage-reporting")
        _ = try queuePing(named: "nimbus")
    }

    func queuePing(named name: String) throws -> URL {
        try FileManager.default.createDirectory(at: pendingPings, withIntermediateDirectories: true)
        let ping = pendingPings.appendingPathComponent(UUID().uuidString)
        try Data(name.utf8).write(to: ping)
        return ping
    }

    deinit {
        try? FileManager.default.removeItem(at: root)
    }
}

@MainActor
private struct UsageReportingFixture {
    let profile = MockProfile()
    let api = UsageReportingApiSpy()
    let deletionRequest = UsageDeletionRequestSpy()
    let notificationCenter = NotificationCenter()
    let service: GleanUsageReportingMetricsService

    init() {
        service = GleanUsageReportingMetricsService(
            profile: profile,
            lifecycleObserver: GleanLifecycleObserver(gleanUsageReportingApi: api,
                                                      notificationCenter: notificationCenter)
        )
    }

    func postLifecycleNotifications() {
        notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        notificationCenter.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
}

private final class UsageReportingApiSpy: GleanUsageReportingApi {
    var enabledValues: [Bool] = []
    var submitPingCount = 0
    var requestDataDeletionCount = 0

    func setEnabled(_ enabled: Bool) { enabledValues.append(enabled) }
    func setUsageReason(_ usageReason: UsageReason) {}
    func submitPing() { submitPingCount += 1 }
    func startTrackingDuration() {}
    func stopTrackingDuration() {}
    func requestDataDeletion() { requestDataDeletionCount += 1 }
}

private final class UsageDeletionRequestSpy: GleanUsageDeletionRequest {
    var enableCount = 0

    func enable() { enableCount += 1 }
}
