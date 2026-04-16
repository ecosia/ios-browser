// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import Foundation
import Shared
import Storage
import Sync
import XCTest

@testable import Client

import MozillaAppServices

public typealias ClientSyncManager = Client.SyncManager

open class ClientSyncManagerSpy: ClientSyncManager, @unchecked Sendable {
    open var isSyncing = false
    open var lastSyncFinishTime: Shared.Timestamp?
    open var syncDisplayState: SyncDisplayState?

    private var mockDeclinedEngines: [String]?
    private var mockEngineEnabled = false
    private var emptySyncResult = deferMaybe(SyncResult(status: .ok,
                                                        successful: [],
                                                        failures: [:],
                                                        persistedState: "",
                                                        declined: nil,
                                                        nextSyncAllowedAt: nil,
                                                        telemetryJson: nil))

    open func syncTabs() -> Deferred<Maybe<SyncResult>> { return emptySyncResult }
    open func syncHistory() -> Deferred<Maybe<SyncResult>> { return emptySyncResult }
    open func syncEverything(why: SyncReason) -> Success { return succeed() }
    open func updateCreditCardAutofillStatus(value: Bool) {}

    var syncNamedCollectionsCalled = 0
    open func syncNamedCollections(why: SyncReason, names: [String]) -> Deferred<Maybe<SyncResult>> {
        syncNamedCollectionsCalled += 1
        return emptySyncResult
    }
    open func syncPostSyncSettingsChange(why: SyncReason, names: [String]) {}
    open func reportOpenSyncSettingsMenuTelemetry() {}
    open func beginTimedSyncs() {}
    open func endTimedSyncs() {}
    open func applicationDidBecomeActive() {
        self.beginTimedSyncs()
    }
    open func applicationDidEnterBackground() {
        self.endTimedSyncs()
    }

    open func onAddedAccount() -> Success {
        return succeed()
    }
    open func onRemovedAccount() -> Success {
        return succeed()
    }
    open func checkCreditCardEngineEnablement() -> Bool {
        guard let mockDeclinedEngines = mockDeclinedEngines,
              !mockDeclinedEngines.isEmpty,
              mockDeclinedEngines.contains("creditcards") else {
            return mockEngineEnabled
        }
        return false
    }

    func setMockDeclinedEngines(_ engines: [String]?) {
        mockDeclinedEngines = engines
    }

    func setMockEngineEnabled(_ enabled: Bool) {
        mockEngineEnabled = enabled
    }
}

final class MockTabQueue: TabQueue, @unchecked Sendable {
    var queuedTabs = [ShareItem]()
    var getQueuedTabsCalled = 0
    var addToQueueCalled = 0
    var clearQueuedTabsCalled = 0

    func addToQueue(_ tab: ShareItem) -> Success {
        addToQueueCalled += 1
        return succeed()
    }

    func getQueuedTabs(completion: @MainActor @escaping ([ShareItem]) -> Void) {
        getQueuedTabsCalled += 1
        let tabs = queuedTabs
        Task { @MainActor in completion(tabs) }
    }

    func clearQueuedTabs() -> Success {
        clearQueuedTabsCalled += 1
        return succeed()
    }
}

class MockFiles: FileAccessor {
    var rootPath: String

    init() {
        let docPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        rootPath = (docPath as NSString).appendingPathComponent("testing")
    }
}

open class MockProfile: Client.Profile, @unchecked Sendable {
    public var rustFxA: Client.RustFirefoxAccounts {
        return Client.RustFirefoxAccounts.shared
    }

    // Read/Writeable properties for mocking

    public let files: FileAccessor
    public var syncManager: (any Client.SyncManager)?
    public var firefoxSuggest: RustFirefoxSuggestProtocol?

    fileprivate let name: String = "mockaccount"

    private let directory: String
    private let databasePrefix: String
    private var injectedPinnedSites: PinnedSites?

    init(databasePrefix: String = "mock",
         firefoxSuggest: RustFirefoxSuggestProtocol? = nil,
         injectedPinnedSites: PinnedSites? = nil) {
        files = MockFiles()
        syncManager = ClientSyncManagerSpy() as any Client.SyncManager
        self.databasePrefix = databasePrefix
        self.firefoxSuggest = firefoxSuggest
        self.injectedPinnedSites = injectedPinnedSites

        do {
            directory = try files.getAndEnsureDirectory()
        } catch {
            XCTFail("Could not create directory at root path: \(error)")
            fatalError("Could not create directory at root path: \(error)")
        }
    }

    public func localName() -> String {
        return name
    }

    public func reopen() {
        isShutdown = false

        database.reopenIfClosed()
        _ = logins.reopenIfClosed()
        _ = places.reopenIfClosed()
        _ = tabs.reopenIfClosed()
    }

    public func shutdown() {
        isShutdown = true

        database.forceClose()
        _ = logins.forceClose()
        _ = places.forceClose()
        _ = tabs.forceClose()
    }

    public var isShutdown = false

    public lazy var queue: TabQueue = {
        return MockTabQueue()
    }()

    public lazy var isChinaEdition: Bool = {
        return Locale.current.identifier == "zh_CN"
    }()

    public lazy var certStore: CertStore = {
        return CertStore()
    }()

    @MainActor
    public lazy var searchEnginesManager: SearchEnginesManager = {
        return SearchEnginesManager(prefs: self.prefs, files: self.files)
    }()

    public lazy var remoteSettingsService: RemoteSettingsService = {
        let config = RemoteSettingsConfig2(server: .prod, bucketName: "main", appContext: nil)
        return RemoteSettingsService(storageDir: directory, config: config)
    }()

    public lazy var prefs: Prefs = {
        return MockProfilePrefs()
    }()

    public lazy var autofill: RustAutofill = {
        let autofillDbPath = URL(
            fileURLWithPath: directory,
            isDirectory: true
        ).appendingPathComponent("autofill.db").path
        return RustAutofill(databasePath: autofillDbPath)
    }()

    public lazy var readingList: ReadingList = {
        return SQLiteReadingList(db: self.readingListDB)
    }()

    public lazy var recentlyClosedTabs: ClosedTabsStore = {
        return ClosedTabsStore(prefs: self.prefs)
    }()

    public lazy var logins: RustLogins = {
        let newLoginsDatabasePath = URL(
            fileURLWithPath: directory,
            isDirectory: true
        ).appendingPathComponent("\(databasePrefix)_loginsPerField.db").path
        try? files.remove("\(databasePrefix)_loginsPerField.db")

        let logins = RustLogins(databasePath: newLoginsDatabasePath)
        _ = logins.reopenIfClosed()

        return logins
    }()

    lazy var database: BrowserDB = {
        BrowserDB(filename: "\(databasePrefix).db", schema: BrowserSchema(), files: files)
    }()

    lazy var readingListDB: BrowserDB = {
        BrowserDB(filename: "\(databasePrefix)_ReadingList.db", schema: ReadingListSchema(), files: files)
    }()

    public lazy var places: RustPlaces = {
        let placesDatabasePath = URL(
            fileURLWithPath: directory,
            isDirectory: true
        ).appendingPathComponent("\(databasePrefix)_places.db").path
        try? files.remove("\(databasePrefix)_places.db")

        let places = RustPlaces(databasePath: placesDatabasePath)
        _ = places.reopenIfClosed()

        return places
    }()

    public lazy var tabs: RustRemoteTabs = {
        let tabsDbPath = URL(
            fileURLWithPath: directory,
            isDirectory: true
        ).appendingPathComponent("\(databasePrefix)_tabs.db").path
        let tabs = RustRemoteTabs(databasePath: tabsDbPath)

        return tabs
    }()

    fileprivate lazy var legacyPlaces: PinnedSites = {
        BrowserDBSQLite(database: self.database, prefs: MockProfilePrefs())
    }()

    public lazy var pinnedSites: PinnedSites = {
        injectedPinnedSites ?? legacyPlaces
    }()

    public func hasSyncAccount(completion: @escaping (Bool) -> Void) {
        completion(hasSyncableAccountMock)
    }

    public func hasAccount() -> Bool {
        return hasSyncableAccountMock
    }

    var hasSyncableAccountMock = true
    public func hasSyncableAccount() -> Bool {
        return hasSyncableAccountMock
    }

    public func flushAccount() {}

    public func removeAccount() {
        _ = self.syncManager?.onRemovedAccount()
    }

    public func getCachedClientsAndTabs() -> Deferred<Maybe<[ClientAndTabs]>> {
        return deferMaybe(mockClientAndTabs)
    }

    public func getClientsAndTabs() -> Deferred<Maybe<[ClientAndTabs]>> {
        return deferMaybe([])
    }

    var mockClientAndTabs = [ClientAndTabs]()

    public func getCachedClientsAndTabs(completion: @escaping @Sendable ([ClientAndTabs]?) -> Void) {
        completion(mockClientAndTabs)
    }

    public func getClientsAndTabs(completion: @escaping @Sendable ([ClientAndTabs]?) -> Void) {
        completion(mockClientAndTabs)
    }

    public func cleanupHistoryIfNeeded() {}

    public func storeTabs(_ tabs: [RemoteTab]) -> Deferred<Maybe<Int>> {
        return deferMaybe(0)
    }

    public func storeAndSyncTabs(_ tabs: [RemoteTab]) -> Deferred<Maybe<Int>> {
        return deferMaybe(0)
    }

    public func addTabToCommandQueue(_ deviceId: String, url: URL) {}
    public func removeTabFromCommandQueue(_ deviceId: String, url: URL) {}
    public func flushTabCommands(toDeviceId: String?) {}

    public func updateCredentialIdentities() -> Deferred<Result<Void, Error>> {
        return Deferred(value: .success(()))
    }

    public func clearCredentialStore() -> Deferred<Result<Void, Error>> {
        return Deferred(value: .success(()))
    }

    public func sendItem(_ item: ShareItem, toDevices devices: [RemoteDevice]) -> Success {
        return succeed()
    }

    public func setCommandArrived() {
        return
    }

    public func pollCommands(forcePoll: Bool) {
        return
    }

    public func hasSyncedLogins() -> Deferred<Maybe<Bool>> {
        return deferMaybe(true)
    }
}
