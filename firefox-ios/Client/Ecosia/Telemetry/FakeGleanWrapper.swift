// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

// Ecosia: Fake implementation of GleanWrapper that silences all Firefox telemetry
// This allows us to keep Firefox's telemetry code intact while preventing any actual telemetry collection.
// All Firefox telemetry calls will compile successfully but do nothing at runtime.
//
// Why this approach:
// - Keeps Firefox code unchanged (easier upgrades)
// - Centralizes telemetry control in one file
// - No need to comment out individual telemetry calls
// - New Firefox telemetry calls are automatically silenced
//
// See: TELEMETRY_SILENCING_STRATEGY.md for full documentation
struct FakeGleanWrapper: GleanWrapper {
    func handleDeeplinkUrl(url: URL) {
        // Ecosia: No-op
    }

    func setUpload(isEnabled: Bool) {
        // Ecosia: No-op
    }

    func enableTestingMode() {
        // Ecosia: No-op
    }

    // MARK: Glean Metrics - All no-ops

    func recordEvent<ExtraObject>(for metric: EventMetricType<ExtraObject>,
                                  extras: EventExtras) where ExtraObject: EventExtras {
        // Ecosia: No-op
    }

    func recordEvent<NoExtras>(for metric: EventMetricType<NoExtras>) where NoExtras: EventExtras {
        // Ecosia: No-op
    }

    func incrementCounter(for metric: CounterMetricType) {
        // Ecosia: No-op
    }

    func recordString(for metric: StringMetricType, value: String) {
        // Ecosia: No-op
    }

    func incrementLabeledCounter(for metric: LabeledMetricType<CounterMetricType>, label: String) {
        // Ecosia: No-op
    }

    func setBoolean(for metric: BooleanMetricType, value: Bool) {
        // Ecosia: No-op
    }

    func recordQuantity(for metric: QuantityMetricType, value: Int64) {
        // Ecosia: No-op
    }

    func recordLabel(for metric: LabeledMetricType<StringMetricType>, label: String, value: String) {
        // Ecosia: No-op
    }

    func recordLabeledQuantity(for metric: LabeledMetricType<QuantityMetricType>, label: String, value: Int64) {
        // Ecosia: No-op
    }

    func recordUrl(for metric: UrlMetricType, value: URL) {
        // Ecosia: No-op
    }

    func recordDatetime(for metric: DatetimeMetricType, value: Date) {
        // Ecosia: No-op
    }

    func recordUUID(for metric: UuidMetricType, value: UUID) {
        // Ecosia: No-op
    }

    func incrementNumerator(for metric: RateMetricType, amount: Int32) {
        // Ecosia: No-op
    }

    func incrementDenominator(for metric: RateMetricType, amount: Int32) {
        // Ecosia: No-op
    }

    // MARK: Timing Metrics - All no-ops

    func startTiming(for metric: TimingDistributionMetricType) -> GleanTimerId {
        // Ecosia: Return dummy timer ID (no actual timing happens)
        return GleanTimerId(id: 0)
    }

    func cancelTiming(for metric: TimingDistributionMetricType, timerId: GleanTimerId) {
        // Ecosia: No-op
    }

    func stopAndAccumulateTiming(for metric: TimingDistributionMetricType, timerId: GleanTimerId) {
        // Ecosia: No-op
    }

    // MARK: Pings - All no-ops

    func submit<ReasonCodesEnum>(ping: Ping<ReasonCodesEnum>) where ReasonCodesEnum: ReasonCodes {
        // Ecosia: No-op - no pings are submitted
    }
}
