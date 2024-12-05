import Foundation

struct ReferralCreateCodeRequest: BaseRequest {
    var method: HTTPMethod { .post }

    var path: String { "/v1/referrals/referral/" }

    var queryParameters: [String: String]?

    var additionalHeaders: [String: String]?

    var body: Data?
}
