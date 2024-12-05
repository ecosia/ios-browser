import Foundation

struct DeviceRegionChangeRule: RefreshingRule {

    private var currentRegion: String

    init(localeProvider: RegionLocatable = Locale.current) {
        currentRegion = localeProvider.regionIdentifierLowercasedWithFallbackValue
    }

    var shouldRefresh: Bool {
        currentRegion != Unleash.model.deviceRegion
    }
}
