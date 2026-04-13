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
    var savedEvents: [Any] = []
    var savedExtras: [Any] = []

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
    func incrementCounter(for metric: CounterMetricType) {}
    func recordString(for metric: StringMetricType, value: String) {}
    func incrementLabeledCounter(for metric: LabeledMetricType<CounterMetricType>, label: String) {}
    func setBoolean(for metric: BooleanMetricType, value: Bool) {}
    func recordQuantity(for metric: QuantityMetricType, value: Int64) {}
    func recordLabel(for metric: LabeledMetricType<StringMetricType>, label: String, value: String) {}
    func recordLabeledQuantity(for metric: LabeledMetricType<QuantityMetricType>, label: String, value: Int64) {}
    func recordUrl(for metric: UrlMetricType, value: URL) {}
    func recordDatetime(for metric: DatetimeMetricType, value: Date) {}
    func recordUUID(for metric: UuidMetricType, value: UUID) {}
    func incrementNumerator(for metric: RateMetricType, amount: Int32) {}
    func incrementDenominator(for metric: RateMetricType, amount: Int32) {}
    func startTiming(for metric: TimingDistributionMetricType) -> GleanTimerId { GleanTimerId(id: 0) }
    func cancelTiming(for metric: TimingDistributionMetricType, timerId: GleanTimerId) {}
    func stopAndAccumulateTiming(for metric: TimingDistributionMetricType, timerId: GleanTimerId) {}
    func submit<ReasonCodesEnum>(ping: Ping<ReasonCodesEnum>) where ReasonCodesEnum: ReasonCodes {}
}
