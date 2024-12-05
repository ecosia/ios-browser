import Foundation

extension Environment {
    struct Auth: Equatable {
        let id: String
        let secret: String
    }

    var auth: Auth? {
        switch self {
        case .staging:
            let keyId = "CF_ACCESS_CLIENT_ID"
            let keySecret = "CF_ACCESS_CLIENT_SECRET"

            guard let id = EnvironmentFetcher.valueFromMainBundleOrProcessInfo(forKey: keyId),
                  let secret = EnvironmentFetcher.valueFromMainBundleOrProcessInfo(forKey: keySecret) else { return nil }
            return Auth(id: id, secret: secret)

        default:
            return nil
        }
    }
}
