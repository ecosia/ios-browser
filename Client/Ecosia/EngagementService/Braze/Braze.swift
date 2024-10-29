import BrazeKit
import BrazeUI
import UIKit
import UserNotifications
import Core

public class Braze: EngagementServiceProvider {
    
    // MARK: - Initialization
    
    public init() {}
    
    private var braze: BrazeKit.Braze? = nil
    private var parameters: [String: Any] = [:]
    private static var apiKey = EnvironmentFetcher.valueFromMainBundleOrProcessInfo(forKey: "BRAZE_API_KEY") ?? ""
    
    enum Error: Swift.Error {
        case invalidConfiguration
        case generic(description: String)
    }

    @MainActor
    public func initialize(parameters: [String: Any]) throws {
        self.braze = BrazeKit.Braze(configuration: try getBrazeConfiguration())
        let inAppMessageUI = BrazeInAppMessageUI()
        inAppMessageUI.delegate = self
        self.braze?.inAppMessagePresenter = inAppMessageUI
        self.parameters = parameters
        Task.detached(priority: .medium) { [weak self] in
            await self?.updateID(self?.parameters["id"] as? String)
        }
    }
    
    @MainActor 
    public func presentNextQueuedMessage() {
        (self.braze?.inAppMessagePresenter as? BrazeInAppMessageUI)?.presentNext()
    }
    
    public func logCustomEvent(name: String) {
        self.braze?.logCustomEvent(name: name)
    }
    
    // MARK: - Device Token Registration
    
    public func registerDeviceToken(_ deviceToken: Data) {
        braze?.notifications.register(deviceToken: deviceToken)
        Task.detached(priority: .medium) { [weak self] in
            await self?.updateID(self?.parameters["id"] as? String)
        }
    }
    
    // MARK: - APN Consent
    
    public func requestAPNConsent(notificationCenterDelegate: UNUserNotificationCenterDelegate,
                                  completionHandler: @escaping (Bool, Swift.Error?) -> Void) {
        UIApplication.shared.registerForRemoteNotifications()
        let notificationCenter = makeNotificationCenter(notificationCenterDelegate: notificationCenterDelegate)
        notificationCenter.requestAuthorization(options: [.badge, .sound, .alert]) { granted, error in
            //#if DEBUG
            print("Notification authorization, granted: \(granted), error: \(String(describing: error))")
            //#endif
            completionHandler(granted, error)
        }
    }
    
    public func requestAPNConsent(notificationCenterDelegate: UNUserNotificationCenterDelegate) async throws -> Bool {
        await UIApplication.shared.registerForRemoteNotifications()
        let notificationCenter = makeNotificationCenter(notificationCenterDelegate: notificationCenterDelegate)
        return try await notificationCenter.requestAuthorization()
    }
    
    // MARK: - APN Registration Refresh
    
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

extension Braze {
    
    // MARK: - Notification Center Factory
    
    private func makeNotificationCenter(notificationCenterDelegate: UNUserNotificationCenterDelegate) -> UNUserNotificationCenter {
        let center = UNUserNotificationCenter.current()
        center.setNotificationCategories(BrazeKit.Braze.Notifications.categories)
        center.delegate = notificationCenterDelegate
        return center
    }
}

extension Braze {
    
    // MARK: - ID Update

    private func updateID(_ id: String?) async {
        guard let id else { return }
        //#if DEBUG
        print("📣🆔 Braze Identifier Updating To: \(id)")
        //#endif
        let brazeID = await braze?.user.id()
        guard id != brazeID else { return }
        braze?.changeUser(userId: id)
    }
}

extension Braze {
    
    // MARK: - Environment Configuration

    /// Retrieves the Braze configuration based on the provided parameters.
    ///
    /// - Parameters:
    ///   - apiKey: The Braze API key to be used for configuration.
    ///   - environment: The target environment for which the Braze configuration is requested.
    ///                  Defaults to the current environment.
    /// - Returns: A Braze configuration if the required parameters are present.
    /// - Throws: An `Error.invalidConfiguration` if the API key is empty.
    ///
    /// - Note: The `environment` parameter allows customization of the target environment.
    ///   If not provided, it defaults to the current environment.
    ///
    /// - Warning: Ensure that the provided API key is not empty to avoid invalid configurations.
    func getBrazeConfiguration(apiKey: String = Braze.apiKey,
                               environment: Environment = Environment.current) throws -> BrazeKit.Braze.Configuration {

        guard !apiKey.isEmpty else { throw Error.invalidConfiguration }
        
        let brazeConfiguration = BrazeKit.Braze.Configuration(apiKey: apiKey, endpoint: environment.urlProvider.brazeEndpoint)
        //#if DEBUG
        brazeConfiguration.logger.level = .debug
        //#endif
        brazeConfiguration.triggerMinimumTimeInterval = 5
        return brazeConfiguration
    }
}

extension Braze: BrazeInAppMessageUIDelegate {
    public func inAppMessage(_ ui: BrazeInAppMessageUI, displayChoiceForMessage message: BrazeKit.Braze.InAppMessage) -> BrazeInAppMessageUI.DisplayChoice {
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
