import Foundation

extension Locale {

    var identifierWithDashedLanguageAndRegion: String {
        identifier.replacingOccurrences(of: "_", with: "-").lowercased()
    }

    var regionIdentifier: String? {
        if #available(iOS 16, macOS 13, *) {
            return region?.identifier
        } else {
            return regionCode
        }
    }

    public var regionIdentifierLowercasedWithFallbackValue: String {
        regionIdentifier?.lowercased() ?? "us"
    }
}

extension Locale: RegionLocatable {}
