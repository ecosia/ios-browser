import Foundation

public enum Scheme: String {
    case
    http,
    https,
    gmsg,
    other

    public enum Policy {
        case
        allow,
        cancel
    }

    var policy: Policy {
        switch self {
        case .gmsg:
            return .cancel
        default:
            return .allow
        }
    }

    var isBrowser: Bool {
        switch self {
        case .http, .https:
            return true
        default:
            return false
        }
    }
}
