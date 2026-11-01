// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MozillaAppServices
@testable import Client

final class ExperimentsRemoteRecipesTests: XCTestCase {
    private let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
        try super.tearDownWithError()
    }

    func testLocalRemoteSettingsService_readsRecipesFromLocalFolderOnly() throws {
        let nimbus = try makeNimbus(withLocalRecipe: Self.rolloutRecipe)

        fetchAndApplyExperiments(nimbus)

        XCTAssertEqual(nimbus.getActiveExperiments().map(\.slug), ["test-rollout"])
    }

    func testDisableRemoteExperiments_preventsRecipesFromApplying() throws {
        let nimbus = try makeNimbus(withLocalRecipe: Self.rolloutRecipe)

        Experiments.disableRemoteExperiments(for: nimbus)
        fetchAndApplyExperiments(nimbus)

        XCTAssertFalse(nimbus.isFetchEnabled())
        XCTAssertTrue(nimbus.getActiveExperiments().isEmpty)
    }

    private func makeNimbus(withLocalRecipe recipe: String) throws -> NimbusInterface {
        let dbPath = directory.appendingPathComponent("nimbus.db").path
        let recipesDirectory = directory.appendingPathComponent("nimbus-recipes", isDirectory: true)
        try FileManager.default.createDirectory(at: recipesDirectory, withIntermediateDirectories: true)
        try Data(recipe.utf8).write(to: recipesDirectory.appendingPathComponent("rollout.json"))

        return NimbusBuilder(dbPath: dbPath)
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
