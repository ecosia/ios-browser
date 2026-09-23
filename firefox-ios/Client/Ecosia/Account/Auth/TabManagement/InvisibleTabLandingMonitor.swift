// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Ecosia

/// Reports when an invisible auth tab has settled on its final page, from its URL and loading updates
@MainActor
final class InvisibleTabLandingMonitor {

    /// Grace period after loading stops, so a JS or form-post redirect can start the next load before we report
    static let defaultSettleDelay: TimeInterval = 0.5

    private let startURL: URL
    private let urlProvider: URLProvider
    private let settleDelay: TimeInterval
    private let onLanded: (URL) -> Void

    private var currentURL: URL
    private var isLoading = true
    private var isActive = false
    private var pendingLanding: Task<Void, Never>?

    init(startURL: URL,
         urlProvider: URLProvider,
         settleDelay: TimeInterval = InvisibleTabLandingMonitor.defaultSettleDelay,
         onLanded: @escaping (URL) -> Void) {
        self.startURL = startURL
        self.currentURL = startURL
        self.urlProvider = urlProvider
        self.settleDelay = settleDelay
        self.onLanded = onLanded
    }

    func start(isLoading: Bool) {
        isActive = true
        self.isLoading = isLoading
        evaluate()
    }

    func stop() {
        isActive = false
        cancelPendingLanding()
    }

    func urlChanged(to url: URL) {
        currentURL = url
        evaluate()
    }

    func loadingChanged(isLoading: Bool) {
        self.isLoading = isLoading
        evaluate()
    }

    /// Done once resting on an error page, or a www page other than the start page; Auth0 hops happen on another host.
    /// Sign-in is excluded because it can hand off to Auth0 client-side, so a pause there isn't final.
    static func hasLanded(on currentURL: URL, from startURL: URL, urlProvider: URLProvider) -> Bool {
        guard currentURL.host == urlProvider.root.host else { return false }
        let path = currentURL.path.lowercased()
        if urlProvider.errorPaths.contains(where: { $0.lowercased() == path }) { return true }
        return path != startURL.path.lowercased() && !path.hasPrefix(urlProvider.signInURL.path.lowercased())
    }

    private func evaluate() {
        cancelPendingLanding()

        guard isActive, !isLoading,
              Self.hasLanded(on: currentURL, from: startURL, urlProvider: urlProvider) else { return }

        let landedURL = currentURL
        let settleDelay = settleDelay
        pendingLanding = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(settleDelay * 1_000_000_000))
            guard !Task.isCancelled, let self, self.isActive else { return }
            self.isActive = false
            self.onLanded(landedURL)
        }
    }

    private func cancelPendingLanding() {
        pendingLanding?.cancel()
        pendingLanding = nil
    }
}
