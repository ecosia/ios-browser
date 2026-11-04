// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MozillaAppServices
@testable import Client

final class ExperimentsRemoteRecipesTests: XCTestCase {
    private let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    private let nimbusErrors = NimbusErrorRecorder()

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
        try super.tearDownWithError()
    }

    func testLocalRemoteSettingsService_readsRecipesFromLocalFolderOnly() throws {
        try writeLocalRecipe(Self.rolloutRecipe)
        let nimbus = makeNimbus()

        fetchAndApplyExperiments(nimbus)

        XCTAssertEqual(nimbus.getActiveExperiments().map(\.slug), ["test-rollout"])
    }

    func testDisableRemoteExperiments_preventsRecipesFromApplying() throws {
        try writeLocalRecipe(Self.rolloutRecipe)
        let nimbus = makeNimbus()

        Experiments.disableRemoteExperiments(for: nimbus)
        fetchAndApplyExperiments(nimbus)

        XCTAssertFalse(nimbus.isFetchEnabled())
        XCTAssertTrue(nimbus.getActiveExperiments().isEmpty)
        XCTAssertTrue(nimbusErrors.errors.isEmpty, "\(nimbusErrors.errors)")
    }

    func testDisableRemoteExperiments_unenrolsExistingEnrolments() throws {
        try writeLocalRecipe(Self.rolloutRecipe)
        let nimbus = makeNimbus()
        fetchAndApplyExperiments(nimbus)
        XCTAssertEqual(nimbus.getActiveExperiments().map(\.slug), ["test-rollout"])

        Experiments.disableRemoteExperiments(for: nimbus)

        XCTAssertTrue(nimbus.getActiveExperiments().isEmpty)
        XCTAssertTrue(nimbusErrors.errors.isEmpty, "\(nimbusErrors.errors)")
        let nextLaunch = makeNimbus()
        XCTAssertTrue(nextLaunch.getActiveExperiments().isEmpty)
        XCTAssertFalse(nextLaunch.isFetchEnabled())
    }

    func testDisableRemoteExperiments_clearsStoredRecipesThatDidNotEnrol() throws {
        try writeLocalRecipe(Self.rolloutRecipe.replacingOccurrences(of: #""targeting": "true""#,
                                                                     with: #""targeting": "false""#))
        let nimbus = makeNimbus()
        fetchAndApplyExperiments(nimbus)
        XCTAssertTrue(nimbus.getActiveExperiments().isEmpty)
        XCTAssertEqual(nimbus.getAvailableExperiments().map(\.slug), ["test-rollout"])

        Experiments.disableRemoteExperiments(for: nimbus)

        XCTAssertTrue(nimbus.getAvailableExperiments().isEmpty)
        XCTAssertTrue(nimbusErrors.errors.isEmpty, "\(nimbusErrors.errors)")
    }

    func testDisableRemoteExperiments_unenrolsBundledFirstRunRecipes() throws {
        let bundledRecipes = directory.appendingPathComponent("initial_experiments.json")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data(#"{"data": [\#(Self.rolloutRecipe)]}"#.utf8).write(to: bundledRecipes)
        let nimbus = makeNimbus(initialExperiments: bundledRecipes)
        XCTAssertEqual(nimbus.getActiveExperiments().map(\.slug), ["test-rollout"])

        Experiments.disableRemoteExperiments(for: nimbus)

        XCTAssertTrue(nimbus.getActiveExperiments().isEmpty)
        XCTAssertTrue(nimbusErrors.errors.isEmpty, "\(nimbusErrors.errors)")
    }

    private var dbPath: String { directory.appendingPathComponent("nimbus.db").path }

    private func writeLocalRecipe(_ recipe: String) throws {
        let recipesDirectory = directory.appendingPathComponent("nimbus-recipes", isDirectory: true)
        try FileManager.default.createDirectory(at: recipesDirectory, withIntermediateDirectories: true)
        try Data(recipe.utf8).write(to: recipesDirectory.appendingPathComponent("rollout.json"))
    }

    private func makeNimbus(initialExperiments: URL? = nil) -> NimbusInterface {
        let nimbusErrors = nimbusErrors
        return NimbusBuilder(dbPath: dbPath)
            .with(errorReporter: { nimbusErrors.record($0) })
            .with(initialExperiments: initialExperiments)
            .isFirstRun(initialExperiments != nil)
            .build(appInfo: NimbusAppSettings(appName: "firefox_ios", channel: "release"),
                   remoteSettingsService: Experiments.localRemoteSettingsService(nimbusDBPath: dbPath))
    }

    private func fetchAndApplyExperiments(_ nimbus: NimbusInterface) {
        nimbus.fetchExperiments()
        nimbus.waitForFetchQueue()
        nimbus.applyPendingExperiments().waitUntilFinished()
    }

    private static let rolloutRecipe = """
    {
      "schemaVersion": "1.12.0",
      "slug": "test-rollout",
      "appName": "firefox_ios",
      "appId": "org.mozilla.ios.Firefox",
      "channel": "release",
      "userFacingName": "Test rollout",
      "userFacingDescription": "Test rollout",
      "isEnrollmentPaused": false,
      "isRollout": true,
      "bucketConfig": {
        "randomizationUnit": "nimbus_id",
        "namespace": "test-rollout",
        "start": 0,
        "count": 10000,
        "total": 10000
      },
      "featureIds": ["test-feature"],
      "branches": [
        {
          "slug": "treatment",
          "ratio": 1,
          "features": [{ "featureId": "test-feature", "enabled": true, "value": {} }]
        }
      ],
      "targeting": "true",
      "startDate": null,
      "endDate": null,
      "proposedEnrollment": 7,
      "referenceBranch": "treatment"
    }
    """
}

private final class NimbusErrorRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var recorded: [Error] = []

    var errors: [Error] { lock.withLock { recorded } }

    func record(_ error: Error) {
        lock.withLock { recorded.append(error) }
    }
}
