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
