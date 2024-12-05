/// Utilized mainly for the Unleash refresh logic and accommodate testability
/// see: `DeviceRegionChangeProvider.swift`
public protocol RegionLocatable {
    var regionIdentifierLowercasedWithFallbackValue: String { get }
}
