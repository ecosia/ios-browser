// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

// Ecosia: Moved here out of `GleanLifecycleObserverTests.swift`. `DependencyHelperMock` needs it, and
// EcosiaTests compiles `ClientTests/Mocks/*.swift` (not the whole ClientTests tree), so leaving the
// mock inside a test file would either fail to resolve or force EcosiaTests to run upstream's Glean
// lifecycle tests a second time.
final class MockGleanUsageReportingMetricsService: GleanUsageReportingMetricsService {}
