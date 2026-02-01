// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

protocol GleanWrapper: Sendable {
    func handleDeeplinkUrl(url: URL)
    func setUpload(isEnabled: Bool)
    func enableTestingMode()

    // MARK: Glean Metrics

    func recordEvent<ExtraObject>(for metric: EventMetricType<ExtraObject>,
                                  extras: EventExtras) where ExtraObject: EventExtras
    func recordEvent<NoExtras>(for metric: EventMetricType<NoExtras>) where NoExtras: EventExtras
    func incrementCounter(for metric: CounterMetricType)
    func recordString(for metric: StringMetricType, value: String)
    func incrementLabeledCounter(for metric: LabeledMetricType<CounterMetricType>, label: String)
    func setBoolean(for metric: BooleanMetricType, value: Bool)
    func recordQuantity(for metric: QuantityMetricType, value: Int64)
    func recordLabel(for metric: LabeledMetricType<StringMetricType>, label: String, value: String)
    func recordLabeledQuantity(for metric: LabeledMetricType<QuantityMetricType>, label: String, value: Int64)
    func recordUrl(for metric: UrlMetricType, value: URL)
    func recordDatetime(for metric: DatetimeMetricType, value: Date)
    func recordUUID(for metric: UuidMetricType, value: UUID)

    func incrementNumerator(for metric: RateMetricType, amount: Int32)
    func incrementDenominator(for metric: RateMetricType, amount: Int32)

    // MARK: Timing Metrics
    /// You should nullify any references to the timer after stopping it
    func startTiming(for metric: TimingDistributionMetricType) -> GleanTimerId
    func cancelTiming(for metric: TimingDistributionMetricType,
                      timerId: GleanTimerId)
    func stopAndAccumulateTiming(for metric: TimingDistributionMetricType,
                                 timerId: GleanTimerId)

    // MARK: Pings

    func submit<ReasonCodesEnum>(ping: Ping<ReasonCodesEnum>) where ReasonCodesEnum: ReasonCodes
}

/// Glean wrapper to abstract Glean from our application
struct DefaultGleanWrapper: GleanWrapper {
    // Ecosia: Shared instance for dependency injection
    static let shared = DefaultGleanWrapper()
    
    private let glean: Glean
    // Ecosia: Use FakeGleanWrapper to silence all Firefox telemetry
    // This allows us to keep Firefox's telemetry code intact while preventing any actual data collection
    private let fakeWrapper = FakeGleanWrapper()

    init(glean: Glean = Glean.shared) {
        self.glean = glean
    }

    // Ecosia: All methods below delegate to NoOpGleanWrapper (no-op) instead of real Glean implementation
    // This centralizes telemetry silencing in one place, making Firefox upgrades easier
    
    func handleDeeplinkUrl(url: URL) {
        fakeWrapper.handleDeeplinkUrl(url: url)
    }

    func setUpload(isEnabled: Bool) {
        fakeWrapper.setUpload(isEnabled: isEnabled)
    }

    func enableTestingMode() {
        fakeWrapper.enableTestingMode()
    }

    // MARK: Glean Metrics

    func recordEvent<ExtraObject>(
        for metric: EventMetricType<ExtraObject>,
        extras: EventExtras
    ) where ExtraObject: EventExtras {
        fakeWrapper.recordEvent(for: metric, extras: extras)
    }

    func recordEvent<NoExtras>(for metric: EventMetricType<NoExtras>) where NoExtras: EventExtras {
        fakeWrapper.recordEvent(for: metric)
    }

    func incrementCounter(for metric: CounterMetricType) {
        fakeWrapper.incrementCounter(for: metric)
    }

    func recordString(for metric: StringMetricType, value: String) {
        fakeWrapper.recordString(for: metric, value: value)
    }

    func incrementLabeledCounter(for metric: LabeledMetricType<CounterMetricType>, label: String) {
        fakeWrapper.incrementLabeledCounter(for: metric, label: label)
    }

    func setBoolean(for metric: BooleanMetricType, value: Bool) {
        fakeWrapper.setBoolean(for: metric, value: value)
    }

    func recordQuantity(for metric: QuantityMetricType, value: Int64) {
        fakeWrapper.recordQuantity(for: metric, value: value)
    }

    func recordLabel(for metric: LabeledMetricType<StringMetricType>, label: String, value: String) {
        fakeWrapper.recordLabel(for: metric, label: label, value: value)
    }

    func recordLabeledQuantity(for metric: LabeledMetricType<QuantityMetricType>, label: String, value: Int64) {
        fakeWrapper.recordLabeledQuantity(for: metric, label: label, value: value)
    }

    func recordUrl(for metric: UrlMetricType, value: URL) {
        fakeWrapper.recordUrl(for: metric, value: value)
    }

    func recordDatetime(for metric: DatetimeMetricType, value: Date) {
        fakeWrapper.recordDatetime(for: metric, value: value)
    }

    func recordUUID(for metric: UuidMetricType, value: UUID) {
        fakeWrapper.recordUUID(for: metric, value: value)
    }

    // MARK: RateMetricType

    func incrementNumerator(for metric: RateMetricType, amount: Int32) {
        fakeWrapper.incrementNumerator(for: metric, amount: amount)
    }

    func incrementDenominator(for metric: RateMetricType, amount: Int32) {
        fakeWrapper.incrementDenominator(for: metric, amount: amount)
    }

    // MARK: MeasurementTelemetry

    func startTiming(for metric: TimingDistributionMetricType) -> GleanTimerId {
        return fakeWrapper.startTiming(for: metric)
    }

    func cancelTiming(for metric: TimingDistributionMetricType,
                      timerId: GleanTimerId) {
        fakeWrapper.cancelTiming(for: metric, timerId: timerId)
    }

    func stopAndAccumulateTiming(for metric: TimingDistributionMetricType,
                                 timerId: GleanTimerId) {
        fakeWrapper.stopAndAccumulateTiming(for: metric, timerId: timerId)
    }

    // MARK: Pings

    func submit<ReasonCodesEnum>(ping: Ping<ReasonCodesEnum>) where ReasonCodesEnum: ReasonCodes {
        fakeWrapper.submit(ping: ping)
    }
}
