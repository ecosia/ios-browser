import Foundation

public enum Environment: Equatable {
    case production
    case staging
}

extension Environment {

    public static var current: Environment {
        #if PRODUCTION
        return .production
        #else
        return .staging
        #endif
    }
}

extension Environment {

    public var urlProvider: URLProvider {
        switch self {
        case .production:
            return .production
        case .staging:
            return .staging
        }
    }
}
