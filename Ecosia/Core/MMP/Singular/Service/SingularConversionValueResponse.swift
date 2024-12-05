import Foundation

struct SingularConversionValueResponse: Codable, Equatable {
    let conversionValue: Int
    let coarseValue: Int?
    let lockWindow: Bool?

    enum CodingKeys: String, CodingKey {
        case conversionValue = "conversion_value"
        case coarseValue = "skan_updated_coarse_value"
        case lockWindow = "skan_updated_lock_window_value"
    }

    var isValid: Bool {
        (0...63 ~= conversionValue) && (0...2 ~= coarseValue ?? 1)
    }
}
