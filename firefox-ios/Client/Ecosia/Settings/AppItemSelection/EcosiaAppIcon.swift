import Foundation

class EcosiaAppIcon {

    static func displayName(icon: AppIcon) -> String {
        switch icon {
        case .ecosiaLight:
            return .localized(.appIconEcosiaLight)
        case .ecosiaDark:
            return .localized(.appIconEcosiaDark)
        case .ecosiaForest:
            return .localized(.appIconEcosiaForest)
        case .ecosiaMushroom:
            return .localized(.appIconEcosiaMushroom)
        case .ecosiaLeaf:
            return .localized(.appIconEcosiaLeaf)
        case .ecosiaWood:
            return .localized(.appIconEcosiaWood)
        case .ecosiaSea:
            return .localized(.appIconEcosiaSea)
        case .ecosiaMountain:
            return .localized(.appIconEcosiaMountain)
        }
    }

    static func imageSetAssetName(icon: AppIcon) -> String {
        switch icon {
        case .ecosiaLight:
            return "EcosiaLight"
        case .ecosiaDark:
            return "EcosiaDark"
        case .ecosiaForest:
            return "EcosiaForest"
        case .ecosiaMushroom:
            return "EcosiaMushroom"
        case .ecosiaLeaf:
            return "EcosiaLeaf"
        case .ecosiaWood:
            return "EcosiaWood"
        case .ecosiaSea:
            return "EcosiaSea"
        case .ecosiaMountain:
            return "EcosiaMountain"
        }
    }

    static func appIconAssetName(icon: AppIcon) -> String? {
        switch icon {
        case .ecosiaLight:
            return nil
        case .ecosiaDark:
            return "EcosiaDarkAppIcon"
        case .ecosiaForest:
            return "EcosiaForestAppIcon"
        case .ecosiaMushroom:
            return "EcosiaMushroomAppIcon"
        case .ecosiaLeaf:
            return "EcosiaLeafAppIcon"
        case .ecosiaWood:
            return "EcosiaWoodAppIcon"
        case .ecosiaSea:
            return "EcosiaSeaAppIcon"
        case .ecosiaMountain:
            return "EcosiaMountainAppIcon"
        }
    }
    
    static func defaultAppIcon() -> AppIcon {
        .ecosiaLight
    }
}
