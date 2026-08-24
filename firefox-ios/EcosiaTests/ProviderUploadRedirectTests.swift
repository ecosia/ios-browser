// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Ecosia
import XCTest
@testable import Client

@MainActor
final class ProviderUploadRedirectTests: XCTestCase {

    func testConfirmingDeliversTheDestinationAfterDismissal() {
        let state = NTPOmniboxSheetState()
        var received: URL?
        state.presentProviderUploadRedirect(provider: .chatgpt) { received = $0 }

        XCTAssertTrue(state.showProviderUploadRedirect)

        state.handleProviderUploadRedirectConfirmed()
        XCTAssertFalse(state.showProviderUploadRedirect)
        // Deferred so the navigation does not fight the sheet dismissal.
        XCTAssertNil(received)

        state.handleProviderUploadRedirectDismissed()
        XCTAssertEqual(received, SearchProvider.chatgpt.fileUploadDestination)
    }

    func testDismissingWithoutConfirmingDeliversNothing() {
        let state = NTPOmniboxSheetState()
        var received: URL?
        state.presentProviderUploadRedirect(provider: .perplexity) { received = $0 }

        state.showProviderUploadRedirect = false
        state.handleProviderUploadRedirectDismissed()

        XCTAssertNil(received)
    }

    func testGoogleRedirectsToGeminiRatherThanSearch() {
        let state = NTPOmniboxSheetState()
        var received: URL?
        state.presentProviderUploadRedirect(provider: .google) { received = $0 }

        state.handleProviderUploadRedirectConfirmed()
        state.handleProviderUploadRedirectDismissed()

        XCTAssertEqual(received?.host, "gemini.google.com")
    }

    func testEveryThirdPartyProviderResolvesADestination() {
        for provider in SearchProvider.allCases where provider != .ecosia {
            let state = NTPOmniboxSheetState()
            var received: URL?
            state.presentProviderUploadRedirect(provider: provider) { received = $0 }

            state.handleProviderUploadRedirectConfirmed()
            state.handleProviderUploadRedirectDismissed()

            XCTAssertNotNil(received, "\(provider) resolved no upload destination")
        }
    }

    /// Ecosia uploads in-app, so it has no destination and the callback must not fire.
    func testEcosiaHasNothingToRedirectTo() {
        let state = NTPOmniboxSheetState()
        var received: URL?
        state.presentProviderUploadRedirect(provider: .ecosia) { received = $0 }

        state.handleProviderUploadRedirectConfirmed()
        state.handleProviderUploadRedirectDismissed()

        XCTAssertNil(received)
    }

    func testCallbackIsClearedAfterDelivery() {
        let state = NTPOmniboxSheetState()
        var deliveries = 0
        state.presentProviderUploadRedirect(provider: .duckduckgo) { _ in deliveries += 1 }

        state.handleProviderUploadRedirectConfirmed()
        state.handleProviderUploadRedirectDismissed()
        state.handleProviderUploadRedirectDismissed()

        XCTAssertEqual(deliveries, 1)
    }
}
