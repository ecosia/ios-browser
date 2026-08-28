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
        Unleash.clearInstanceModel()
        try? FileManager.default.removeItem(at: FileManager.user)
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

    private func setFlagEnabled(_ enabled: Bool) {
        let toggle = Unleash.Toggle(
            name: Unleash.Toggle.Name.aiFreeSearching.rawValue,
            enabled: enabled,
            variant: Unleash.Variant(name: "", enabled: false, payload: nil)
        )
        Unleash.model = Unleash.Model(toggles: Set([toggle]))
    }
}
