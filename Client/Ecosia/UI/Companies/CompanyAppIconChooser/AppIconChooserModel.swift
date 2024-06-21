import Foundation
import UIKit

/// The alternate app icons available for this app to use.
///
/// These raw values match the names in the app's project settings under
/// `ASSETCATALOG_COMPILER_APPICON_NAME` and `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES`.
enum AppIcon: String, CaseIterable, Identifiable {
    case primary            = "AppIcon"
    case companiesTrees     = "AppIcon_Companies_Trees"
    case companiesSmileTree = "AppIcon_Companies_Smile_Tree"
    case companiesLogo1     = "AppIcon_Companies_Logo_1"
    case companiesLogo2     = "AppIcon_Companies_Logo_2"

    var id: String { self.rawValue }
}

class AppIconChooserModel: ObservableObject, Equatable {
    @Published var appIcon: AppIcon = .primary

    static func == (lhs: AppIconChooserModel, rhs: AppIconChooserModel) -> Bool {
        return lhs.appIcon == rhs.appIcon
    }

    /// Change the app icon.
    /// - Tag: setAlternateAppIcon
    func setAlternateAppIcon(icon: AppIcon) {
            // Set the icon name to nil to use the primary icon.
            let iconName: String? = (icon != .primary) ? icon.rawValue : nil

            // Avoid setting the name if the app already uses that icon.
            guard UIApplication.shared.alternateIconName != iconName else { return }

            UIApplication.shared.setAlternateIconName(iconName) { (error) in
                if let error = error {
                    print("Failed request to update the app’s icon: \(error)")
                }
            }

            appIcon = icon
    }

    /// Initializes the model with the current state of the app's icon.
    init() {
        let iconName = UIApplication.shared.alternateIconName

        if iconName == nil {
            appIcon = .primary
        } else {
            appIcon = AppIcon(rawValue: iconName!)!
        }
    }
}
