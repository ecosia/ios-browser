import Foundation

struct ReferralRefreshCodeRequest: BaseRequest {
    var method: HTTPMethod { .get }

    var path: String { "/v1/referrals/referral/\(code)" }

    var queryParameters: [String: String]?

    var additionalHeaders: [String: String]?

    var body: Data?

    let code: String
    init(code: String) {
        self.code = code
    }
}
