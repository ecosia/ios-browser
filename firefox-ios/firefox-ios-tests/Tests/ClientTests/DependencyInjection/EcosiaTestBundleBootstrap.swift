// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

/// Ecosia (MOB-4384): One-time, bundle-level dependency bootstrap.
///
/// Only ~128 of ~312 ClientTests classes call
/// `DependencyHelperMock().bootstrapDependencies()` in their `setUp`. The remaining
/// ~184 never populate the global `AppContainer`, so any Firefox-core type they
/// (or background work / a Coordinator default argument) resolve via
/// `AppContainer.shared.resolve()` crashes with "No definition registered". Per-class
/// bootstrap cannot cover a whole 312-class bundle.
///
/// This type is the test bundle's `NSPrincipalClass` (wired in `Targets+Tests.swift`),
/// so XCTest instantiates it exactly once when the bundle loads — before any test. It
/// registers as an `XCTestObservation` and, in `testBundleWillStart`, runs the mock
/// bootstrap a single time. Combined with the never-reset behaviour in
/// `DependencyHelperMock`, every class in the bundle then always sees a fully populated,
/// correctly protocol-keyed container regardless of whether it bootstraps itself.
@objc(EcosiaTestBundleBootstrap)
final class EcosiaTestBundleBootstrap: NSObject, XCTestObservation {
    override init() {
        super.init()
        XCTestObservationCenter.shared.addTestObserver(self)
    }

    func testBundleWillStart(_ testBundle: Bundle) {
        // Must complete synchronously before the first test resolves anything.
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                DependencyHelperMock().bootstrapDependencies()
            }
        } else {
            DispatchQueue.main.sync {
                MainActor.assumeIsolated {
                    DependencyHelperMock().bootstrapDependencies()
                }
            }
        }
    }
}
