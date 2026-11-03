// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
// Ecosia: This file contains Firefox's telemetry code which is kept intact for easier upgrades.
// Calls through GleanWrapper are no-ops (FakeGleanWrapper), and Glean never uploads (`TelemetryWrapper.isGleanUploadEnabled`).

import Foundation
import Glean

struct HistoryDeletionUtilityTelemetry {
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func clearedHistory(_ dateOption: HistoryDeletionUtilityDateOptions) {
        let timeframeExtra = GleanMetrics.LibraryHistoryPanel.ClearedHistoryExtra(timeframe: dateOption.rawValue)
        gleanWrapper.recordEvent(for: GleanMetrics.LibraryHistoryPanel.clearedHistory, extras: timeframeExtra)
    }
}
