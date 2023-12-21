import Foundation
import Core

final class ClientEngagementService {
    
    private init() {}
    
    static let shared = ClientEngagementService()
    private let service  = EngagementService(provider: Braze())
    
    func initialize(parameters: [String: Any]) {
        do {
            try service.initialize(parameters: parameters)
        } catch {
            debugPrint(error)
        }
    }
    
    func registerDeviceToken(_ deviceToken: Data) {
        service.registerDeviceToken(deviceToken)
    }
    
    func requestAPNConsent(notificationCenterDelegate: UNUserNotificationCenterDelegate,
                           completionHandler: @escaping (Bool, Swift.Error?) -> Void) {
        service.provider.requestAPNConsent(notificationCenterDelegate: notificationCenterDelegate, 
                                           completionHandler: completionHandler)
    }
    
    func requestAPNConsent(notificationCenterDelegate: UNUserNotificationCenterDelegate) async throws -> Bool {
        try await service.requestAPNConsent(notificationCenterDelegate: notificationCenterDelegate)
    }
}
