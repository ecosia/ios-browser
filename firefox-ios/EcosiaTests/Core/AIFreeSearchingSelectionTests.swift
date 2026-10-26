// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class AIFreeSearchingSelectionTests: XCTestCase {

    override func setUp() {
        super.setUp()
        User.shared.aiFreeSearching = nil
        User.shared.aiOverviews = true
        Unleash.clearInstanceModel()
        // Drain async `searchSettingsChanged` posts from the assignments above
        // so tests that count notifications start from a clean slate.
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
    }

    override func tearDown() {
        super.tearDown()
        User.shared.aiFreeSearching = nil
        User.shared.aiOverviews = true
        User.shared.selectedSearchEngineID = SearchProvider.ecosia.rawValue
        Unleash.clearInstanceModel()
        try? FileManager.default.removeItem(at: FileManager.user)
        // Drain here too, or this suite's posts land in whichever suite counts
        // `searchSettingsChanged` next.
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
    }

    func testIsActiveRequiresFlagAndToggle() {
        setFlagEnabled(false)
        XCTAssertFalse(AIFreeSearchingSelection.isActive)
        XCTAssertTrue(AIFreeSearchingSelection.allowsOmniboxAI)

        User.shared.aiFreeSearching = true
        XCTAssertFalse(AIFreeSearchingSelection.isActive, "Toggle alone is not enough")
        XCTAssertTrue(AIFreeSearchingSelection.allowsOmniboxAI)

        User.shared.aiFreeSearching = nil
        setFlagEnabled(true)
        XCTAssertFalse(AIFreeSearchingSelection.isActive, "Flag alone is not enough")
        XCTAssertTrue(AIFreeSearchingSelection.allowsOmniboxAI)

        User.shared.aiFreeSearching = true
        XCTAssertTrue(AIFreeSearchingSelection.isActive)
        XCTAssertFalse(AIFreeSearchingSelection.allowsOmniboxAI)
    }

    /// The Overviews row is greyed out while AI-free is on, so its value is carried
    /// unchanged and web applies the exclusion where Overviews are rendered.
    func testSetEnabledLeavesOverviewsAlone() {
        setFlagEnabled(true)
        User.shared.aiOverviews = true

        AIFreeSearchingSelection.setEnabled(true)

        XCTAssertEqual(User.shared.aiFreeSearching, true)
        XCTAssertTrue(AIFreeSearchingSelection.isActive)
        XCTAssertTrue(User.shared.aiOverviews)
    }

    func testTogglingAIFreeOffAndOnNeverTouchesOverviews() {
        setFlagEnabled(true)
        User.shared.aiOverviews = true

        AIFreeSearchingSelection.setEnabled(true)
        AIFreeSearchingSelection.setEnabled(false)
        AIFreeSearchingSelection.setEnabled(nil)

        XCTAssertTrue(User.shared.aiOverviews)
    }

    func testSearchSettingsChangedFiresOnToggle() {
        setFlagEnabled(true)
        var count = 0
        let observer = NotificationCenter.default.addObserver(
            forName: .searchSettingsChanged,
            object: nil,
            queue: .main
        ) { _ in
            count += 1
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        AIFreeSearchingSelection.setEnabled(true)

        let deadline = Date().addingTimeInterval(3)
        while count < 1 && Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
        XCTAssertEqual(count, 1, "Expected searchSettingsChanged when enabling AI-free searching")
    }

    func testSearchSettingsChangedFiresWhenMarkingExplicitOff() {
        setFlagEnabled(true)
        var count = 0
        let observer = NotificationCenter.default.addObserver(
            forName: .searchSettingsChanged,
            object: nil,
            queue: .main
        ) { _ in
            count += 1
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        AIFreeSearchingSelection.setEnabled(false)

        let deadline = Date().addingTimeInterval(3)
        while count < 1 && Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
        XCTAssertEqual(count, 1, "Explicit off must fire searchSettingsChanged so ECNOAI=false is written")
    }

    // MARK: - Browser AI (replaces Firefox's AI controls hub)

    func testIsAvailableRequiresFlag() {
        setFlagEnabled(false)
        XCTAssertFalse(AIFreeSearchingSelection.isAvailable)

        setFlagEnabled(true)
        XCTAssertTrue(AIFreeSearchingSelection.isAvailable)
    }

    func testIsAvailableIsFalseWithACustomSearchProvider() {
        setFlags(aiFreeSearching: true, customSearchProvider: true)
        User.shared.selectedSearchEngineID = SearchProvider.ecosia.rawValue
        XCTAssertTrue(AIFreeSearchingSelection.isAvailable, "Ecosia is still the provider")

        User.shared.selectedSearchEngineID = SearchProvider.perplexity.rawValue
        XCTAssertFalse(AIFreeSearchingSelection.isAvailable)
    }

    func testBlocksBrowserAIRequiresAvailableAndToggleOn() {
        setFlagEnabled(true)
        XCTAssertFalse(AIFreeSearchingSelection.blocksBrowserAI, "Never set")

        AIFreeSearchingSelection.setEnabled(false)
        XCTAssertFalse(AIFreeSearchingSelection.blocksBrowserAI)

        AIFreeSearchingSelection.setEnabled(true)
        XCTAssertTrue(AIFreeSearchingSelection.blocksBrowserAI)

        setFlagEnabled(false)
        XCTAssertFalse(AIFreeSearchingSelection.blocksBrowserAI, "Flag off hides the toggle")
    }

    /// A user who turned AI-free on, then picked another provider, can no longer see the
    /// toggle, so it must not keep summaries and translations hidden.
    func testBlocksBrowserAIIsFalseOnceTheToggleIsHidden() {
        setFlags(aiFreeSearching: true, customSearchProvider: true)
        AIFreeSearchingSelection.setEnabled(true)
        XCTAssertTrue(AIFreeSearchingSelection.blocksBrowserAI)

        User.shared.selectedSearchEngineID = SearchProvider.perplexity.rawValue

        XCTAssertTrue(AIFreeSearchingSelection.isActive, "The search preference itself is kept")
        XCTAssertFalse(AIFreeSearchingSelection.blocksBrowserAI)
    }

    private func setFlagEnabled(_ enabled: Bool) {
        setFlags(aiFreeSearching: enabled, customSearchProvider: false)
    }

    private func setFlags(aiFreeSearching: Bool, customSearchProvider: Bool) {
        let toggles: [(Unleash.Toggle.Name, Bool)] = [
            (.aiFreeSearching, aiFreeSearching),
            (.customSearchProvider, customSearchProvider)
        ]
        Unleash.model = Unleash.Model(toggles: Set(toggles.map { name, enabled in
            Unleash.Toggle(
                name: name.rawValue,
                enabled: enabled,
                variant: Unleash.Variant(name: "", enabled: false, payload: nil)
            )
        }))
    }
}
