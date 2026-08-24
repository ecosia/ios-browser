// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Ecosia
import XCTest
@testable import Client

final class ChatModePromptEnhancementTests: XCTestCase {

    private let query = "why do leaves change colour"

    // MARK: - Suffixes

    func testStandardCarriesNoSuffix() {
        XCTAssertNil(OmniboxChatMode.standard.promptSuffix)
    }

    func testAdvancedModesCarryASuffix() {
        for mode in OmniboxChatMode.allCases where mode != .standard {
            XCTAssertNotNil(mode.promptSuffix, "\(mode) has no prompt suffix")
        }
    }

    /// The leading space separates the instruction from the user's prompt.
    func testSuffixesStartWithASpace() {
        for mode in OmniboxChatMode.allCases {
            guard let suffix = mode.promptSuffix else { continue }
            XCTAssertTrue(suffix.hasPrefix(" "), "\(mode) suffix does not start with a space")
            XCTAssertFalse(suffix.hasPrefix("  "), "\(mode) suffix starts with two spaces")
        }
    }

    func testSuffixesAreDistinct() {
        let suffixes = OmniboxChatMode.allCases.compactMap(\.promptSuffix)
        XCTAssertEqual(Set(suffixes).count, suffixes.count)
    }

    // MARK: - Mode availability

    func testConversationalProvidersDropTheStandardMode() {
        for provider in SearchProvider.allCases where provider.isAINative {
            let modes = OmniboxChatMode.modes(for: provider)
            XCTAssertFalse(modes.contains(.standard), "\(provider) still offers a standard mode")
            XCTAssertEqual(modes.count, OmniboxChatMode.allCases.count - 1)
        }
    }

    func testSearchProvidersOfferEveryMode() {
        for provider in SearchProvider.allCases where !provider.isAINative {
            XCTAssertEqual(OmniboxChatMode.modes(for: provider), OmniboxChatMode.allCases)
        }
    }

    // MARK: - Applied to destinations

    func testThirdPartyDestinationAppendsTheSuffixToTheQuery() throws {
        let suffix = try XCTUnwrap(OmniboxChatMode.thinkLonger.promptSuffix)
        let prompt = try XCTUnwrap(queryParameter(for: .chatgpt, mode: .thinkLonger))

        XCTAssertEqual(prompt, query + suffix)
    }

    func testEveryThirdPartyProviderAppliesPromptEnhancement() throws {
        let suffix = try XCTUnwrap(OmniboxChatMode.learning.promptSuffix)

        for provider in SearchProvider.allCases where provider != .ecosia {
            let prompt = try XCTUnwrap(queryParameter(for: provider, mode: .learning))
            XCTAssertEqual(prompt, query + suffix, "\(provider) did not apply the suffix")
        }
    }

    func testStandardModeLeavesTheQueryUntouched() throws {
        XCTAssertEqual(try queryParameter(for: .duckduckgo, mode: .standard), query)
        XCTAssertEqual(try queryParameter(for: .duckduckgo, mode: nil), query)
    }

    /// Ecosia uses backend mode flags, so its prompt must stay clean.
    func testEcosiaUsesQueryItemsRatherThanPromptEnhancement() throws {
        let items = try queryItems(for: .ecosia, mode: .thinkLonger)

        XCTAssertEqual(items["q"], query)
        XCTAssertEqual(items["t"], "1")
    }

    func testEcosiaAndThirdPartiesNeverBothCarryModeFlags() throws {
        let ecosiaItems = try queryItems(for: .ecosia, mode: .displaySources)
        XCTAssertEqual(ecosiaItems["m"], "2")

        let chatgptItems = try queryItems(for: .chatgpt, mode: .displaySources)
        XCTAssertNil(chatgptItems["m"])
        XCTAssertNil(chatgptItems["t"])
    }

    // MARK: - Helpers

    private func queryItems(for provider: SearchProvider,
                            mode: OmniboxChatMode?) throws -> [String: String] {
        let destination = SearchProviderAIRouting.aiDestinationURL(for: provider,
                                                                   query: query,
                                                                   origin: .omnibox,
                                                                   mode: mode)
        let url = try XCTUnwrap(destination)
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        return Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).compactMap { item in
            item.value.map { (item.name, $0) }
        })
    }

    private func queryParameter(for provider: SearchProvider,
                                mode: OmniboxChatMode?) throws -> String? {
        try queryItems(for: provider, mode: mode)["q"]
    }
}
