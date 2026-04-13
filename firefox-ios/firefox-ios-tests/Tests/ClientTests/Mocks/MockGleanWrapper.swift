// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import UIKit
@testable import Client

final class MockGleanWrapper: GleanWrapper, @unchecked Sendable {
    var handleDeeplinkUrlCalled = 0
    var setUploadEnabledCalled = 0

    var savedHandleDeeplinkUrl: URL?
    var savedSetUploadIsEnabled: Bool?

    func handleDeeplinkUrl(url: URL) {
        handleDeeplinkUrlCalled += 1
        savedHandleDeeplinkUrl = url
    }

    func setUpload(isEnabled: Bool) {
        setUploadEnabledCalled += 1
        savedSetUploadIsEnabled = isEnabled
    }

    func enableTestingMode() {}

    var recordEventCalled = 0
    var recordEventNoExtraCalled = 0
    var incrementCounterCalled = 0
    var incrementLabeledCounterCalled = 0
    var recordLabelCalled = 0
    var recordStringCalled = 0
    var recordQuantityCalled = 0
    var recordUrlCalled = 0
    var recordDatetimeCalled = 0
    var submitPingCalled = 0
    var stopAndAccumulateCalled = 0
    var cancelTimingCalled = 0
    var savedLabel: String?
    var savedEvents: [Any] = []
    var savedExtras: [Any] = []
    var savedValues: [Any] = []
    var savedPing: Any?

    func recordEvent<ExtraObject>(for metric: EventMetricType<ExtraObject>,
                                  extras: EventExtras) where ExtraObject: EventExtras {
        recordEventCalled += 1
        savedEvents.append(metric)
        savedExtras.append(extras)
    }
    func recordEvent<NoExtras>(for metric: EventMetricType<NoExtras>) where NoExtras: EventExtras {
        recordEventNoExtraCalled += 1
        savedEvents.append(metric)
    }
    func incrementCounter(for metric: CounterMetricType) {
        incrementCounterCalled += 1
    }
    func recordString(for metric: StringMetricType, value: String) {
        recordStringCalled += 1
        savedEvents.append(metric)
        savedValues.append(value)
    }
    func incrementLabeledCounter(for metric: LabeledMetricType<CounterMetricType>, label: String) {
        incrementLabeledCounterCalled += 1
    }
    func setBoolean(for metric: BooleanMetricType, value: Bool) {}
    func recordQuantity(for metric: QuantityMetricType, value: Int64) {
        recordQuantityCalled += 1
    }
    func recordLabel(for metric: LabeledMetricType<StringMetricType>, label: String, value: String) {
        recordLabelCalled += 1
        savedLabel = label
    }
    func recordLabeledQuantity(for metric: LabeledMetricType<QuantityMetricType>, label: String, value: Int64) {}
    func recordUrl(for metric: UrlMetricType, value: URL) {
        recordUrlCalled += 1
    }
    func recordDatetime(for metric: DatetimeMetricType, value: Date) {
        recordDatetimeCalled += 1
    }
    func recordUUID(for metric: UuidMetricType, value: UUID) {}
    func incrementNumerator(for metric: RateMetricType, amount: Int32) {}
    func incrementDenominator(for metric: RateMetricType, amount: Int32) {}
    func startTiming(for metric: TimingDistributionMetricType) -> GleanTimerId { GleanTimerId(id: 0) }
    func cancelTiming(for metric: TimingDistributionMetricType, timerId: GleanTimerId) {
        cancelTimingCalled += 1
    }
    func stopAndAccumulateTiming(for metric: TimingDistributionMetricType, timerId: GleanTimerId) {
        stopAndAccumulateCalled += 1
    }
    func submit<ReasonCodesEnum>(ping: Ping<ReasonCodesEnum>) where ReasonCodesEnum: ReasonCodes {
        submitPingCalled += 1
        savedPing = ping
    }
}
