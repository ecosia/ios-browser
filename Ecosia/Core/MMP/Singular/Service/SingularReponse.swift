import Foundation

struct SingularResponse: Codable {
    let status: String
    let errorReason: String?

    enum CodingKeys: String, CodingKey {
        case status
        case errorReason = "reason"
    }

    var isOK: Bool {
        status == "ok"
    }
}
