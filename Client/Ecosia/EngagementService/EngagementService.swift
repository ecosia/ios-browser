import Foundation
import Core
import BrazeKit
import BrazeUI

final class ClientEngagementService {
    
    private init() {}
    
    static let shared = ClientEngagementService()
//    private let service  = EngagementService(provider: BrazeTest())
    private var braze: Braze? = nil
    private var parameters: [String: Any] = [:]
    private(set) var notificationAuthorizationStatus: UNAuthorizationStatus?
    
    var identifier: String? {
        parameters["id"] as? String
    }
    
    func initialize(parameters: [String: Any]) async {
        do {
            try await initializeBraze(parameters: parameters)
            self.parameters = parameters
            await retrieveUserCurrentNotificationAuthStatus()
        } catch {
            debugPrint(error)
        }
    }
    
    func presentNextQueuedMessage() {
//        service.provider.presentNextQueuedMessage()
    }

    func logCustomEvent(name: String) {
        self.braze?.logCustomEvent(name: name)
    }
    
    func registerDeviceToken(_ deviceToken: Data) {
        braze?.notifications.register(deviceToken: deviceToken)
        Task.detached(priority: .medium) { [weak self] in
            await self?.updateID(self?.parameters["id"] as? String)
        }
    }
    
    func requestAPNConsent(notificationCenterDelegate: UNUserNotificationCenterDelegate,
                           completionHandler: @escaping (Bool, Swift.Error?) -> Void) {
        UIApplication.shared.registerForRemoteNotifications()
        let notificationCenter = makeNotificationCenter(notificationCenterDelegate: notificationCenterDelegate)
        notificationCenter.requestAuthorization(options: [.badge, .sound, .alert]) { granted, error in
//            #if DEBUG
            print("Notification authorization, granted: \(granted), error: \(String(describing: error))")
//            #endif
            completionHandler(granted, error)
        }
    }
    
    func requestAPNConsent(notificationCenterDelegate: UNUserNotificationCenterDelegate) async throws -> Bool {
        await UIApplication.shared.registerForRemoteNotifications()
        let notificationCenter = makeNotificationCenter(notificationCenterDelegate: notificationCenterDelegate)
        return try await notificationCenter.requestAuthorization()
    }
    
    public func refreshAPNRegistrationIfNeeded(notificationCenterDelegate: UNUserNotificationCenterDelegate) async {
        let notificationCenter = UNUserNotificationCenter.current()
        let currentSettings = await notificationCenter.notificationSettings()
        switch currentSettings.authorizationStatus {
            case .authorized,
                .ephemeral,
                .provisional:
                _ = try? await requestAPNConsent(notificationCenterDelegate: notificationCenterDelegate)
            default:
                break
        }
    }
}

// MARK: - Helpers

extension ClientEngagementService {
    
    func initializeAndRefreshNotificationRegistration(notificationCenterDelegate: UNUserNotificationCenterDelegate) async {
        await initialize(parameters: ["id": User.shared.analyticsId.uuidString])
        await refreshAPNRegistrationIfNeeded(notificationCenterDelegate: notificationCenterDelegate)
    }
    
    func retrieveUserCurrentNotificationAuthStatus() async {
        let notificationCenter = UNUserNotificationCenter.current()
        let currentSettings = await notificationCenter.notificationSettings()
        notificationAuthorizationStatus = currentSettings.authorizationStatus
    }
}

extension ClientEngagementService {
    @MainActor
    func initializeBraze(parameters: [String: Any]) throws {
        self.braze = Braze(configuration: try getBrazeConfiguration())
        let inAppMessageUI = BrazeInAppMessageUI()
        inAppMessageUI.delegate = self
        self.braze?.inAppMessagePresenter = inAppMessageUI
        self.parameters = parameters
        Task.detached(priority: .medium) { [weak self] in
            await self?.updateID(self?.parameters["id"] as? String)
        }
    }
    
    enum Error: Swift.Error {
        case invalidConfiguration
        case generic(description: String)
    }
    
    private static var apiKey = EnvironmentFetcher.valueFromMainBundleOrProcessInfo(forKey: "BRAZE_API_KEY") ?? ""
    
    func getBrazeConfiguration(apiKey: String = ClientEngagementService.apiKey,
                               environment: Environment = Environment.current) throws -> Braze.Configuration {

        guard !apiKey.isEmpty else { throw Error.invalidConfiguration }
        
        let brazeConfiguration = Braze.Configuration(apiKey: apiKey, endpoint: "sdk.fra-02.braze.eu")//environment.urlProvider.brazeEndpoint)
//        #if DEBUG
        brazeConfiguration.logger.level = .debug
//        #endif
        brazeConfiguration.triggerMinimumTimeInterval = 5
        return brazeConfiguration
    }
    
    private func updateID(_ id: String?) async {
        guard let id else { return }
//        #if DEBUG
        print("📣🆔 Braze Identifier Updating To: \(id)")
//        #endif
        let brazeID = await braze?.user.id()
        guard id != brazeID else { return }
        braze?.changeUser(userId: id)
    }
    
    private func makeNotificationCenter(notificationCenterDelegate: UNUserNotificationCenterDelegate) -> UNUserNotificationCenter {
        let center = UNUserNotificationCenter.current()
        center.setNotificationCategories(Braze.Notifications.categories)
        center.delegate = notificationCenterDelegate
        return center
    }
}

extension ClientEngagementService: BrazeInAppMessageUIDelegate {
    public func inAppMessage(_ ui: BrazeInAppMessageUI, displayChoiceForMessage message: Braze.InAppMessage) -> BrazeInAppMessageUI.DisplayChoice {
        guard message.extras["display_restriction"] as? String == "ntp_only" else {
            return .now
        }
        
        var choice: BrazeInAppMessageUI.DisplayChoice = .discard
        
        if #available(iOS 15.0, *) {
            let firstKeyWindow = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .filter { $0.activationState == .foregroundActive }
                .first?.keyWindow
            
            let browserViewController = firstKeyWindow?.rootViewController?.children
                .first(where: { String(describing: type(of: $0)) == "BrowserViewController" })
            
            let homepageViewController = browserViewController?.children
                .first(where: { String(describing: type(of: $0)) == "HomepageViewController" })
            
            if let _ = homepageViewController {
                choice = .now
            } else {
                choice = .reenqueue
            }
        } else {
            // Fallback on earlier versions
        }
        
        return choice
    }
}

struct EnvironmentFetcher {
    
    private init() {}
    
    /// Fetches a string value associated with the specified key either from the Main Bundle Info Dictionary or the Process Info environment.
    ///
    /// - Parameters:
    ///   - key: The key for which to retrieve the associated string value.
    /// - Returns: The string value associated with the key, or nil if not found.
    static func valueFromMainBundleOrProcessInfo(forKey key: String) -> String? {
        // Attempt to retrieve the value from the Main Bundle Info Dictionary
        // If not found, try to retrieve it from the Process Info environment
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String
                ?? ProcessInfo.processInfo.environment[key] else {
            // Return nil if the value is not found in either location
            return nil
        }
        
        // Return the retrieved value
        return value
    }
}
