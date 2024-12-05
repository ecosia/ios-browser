import Foundation

public protocol MMPProvider {

    func sendSessionInfo(appDeviceInfo: AppDeviceInfo) async throws

    func sendEvent(_ event: MMPEvent, appDeviceInfo: AppDeviceInfo) async throws
}
