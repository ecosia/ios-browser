// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct ToastTelemetry {
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func undoClosedSingleTab() {
        // Ecosia: Telemetry silenced via FakeGleanWrapper
        gleanWrapper.recordEvent(for: GleanMetrics.ToastsCloseSingleTab.undoTapped)
    }

    func undoClosedAllTabs() {
        // Ecosia: Telemetry silenced via FakeGleanWrapper
        gleanWrapper.recordEvent(for: GleanMetrics.ToastsCloseAllTabs.undoTapped)
    }
}
