import Foundation

struct SingularConversionValueRequest: BaseRequest {

    struct Parameters: Encodable {
        let identifier: String
        let platform: String
        let bundleId: String
        let eventName: String
        let osVersion: String
        let appVersion: String

        enum CodingKeys: String, CodingKey {
            case identifier = "sing"
            case platform = "p"
            case bundleId = "i"
            case eventName = "n"
            case osVersion = "ve"
            case appVersion = "app_v"
        }

        init(identifier: String, eventName: String, appDeviceInfo: AppDeviceInfo) {
            self.identifier = identifier
            self.platform = appDeviceInfo.platform
            self.bundleId = appDeviceInfo.bundleId
            self.eventName = eventName
            self.osVersion = appDeviceInfo.osVersion
            self.appVersion = appDeviceInfo.appVersion
        }
    }

    var method: HTTPMethod {
        .get
    }

    var path: String {
        "/v2/attribution/conversion-value"
    }

    var queryParameters: [String: String]?

    var additionalHeaders: [String: String]?

    var body: Data?

    init(_ parameters: Parameters, skanParameters: [String: String]) {
        self.queryParameters = parameters.dictionary.merging(skanParameters) { current, _ in current }
    }
}
