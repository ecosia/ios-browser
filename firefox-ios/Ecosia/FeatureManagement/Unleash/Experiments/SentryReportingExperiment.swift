// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Gates Sentry crash reporting, for a gradual/budget-controlled rollout. Note: Unleash's own fetch
/// happens asynchronously later in app launch than Sentry's original setup call site, so Sentry setup
/// is deferred entirely to `AppLaunchUtil.setUpCrashReportingIfEnabled()`, called from `AppDelegate`
/// after `FeatureManagement.fetchConfiguration()` resolves.
/// `public` — unlike the other `Experiment` types here, this one is read from `AppLaunchUtil` in the
/// `Client` target (a different module), not just from within `Ecosia` itself.
public struct SentryReportingExperiment {

    private init() {}

    public static var isEnabled: Bool {
        Unleash.isEnabled(.sentryReporting)
    }
}
