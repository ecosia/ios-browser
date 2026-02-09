// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// Represents the available app icons that users can select.
///
/// Each case maps to an `.appiconset` in the asset catalog.
/// The `default` case uses the primary icon (`AppIcon`), while
/// alternate cases use `UIApplication.setAlternateIconName(_:)`.
public enum AppIcon: String, CaseIterable, Codable, Equatable {
    case `default` = "AppIcon"
    case green = "AppIconGreen"
    case black = "AppIconBlack"

    /// The icon name to pass to `UIApplication.setAlternateIconName(_:)`.
    /// Returns `nil` for the default/primary icon.
    public var alternateIconName: String? {
        switch self {
        case .default: return nil
        default: return rawValue
        }
    }

    /// A localized display name for use in the settings UI.
    public var localizedTitleKey: String.Key {
        switch self {
        case .default: return .appIconDefault
        case .green: return .appIconGreen
        case .black: return .appIconBlack
        }
    }

    /// The name of the preview image in the asset catalog used in settings.
    public var previewImageName: String {
        rawValue + "Preview"
    }

    /// Resolves an `AppIcon` from the current `UIApplication.alternateIconName`.
    public static func current(alternateIconName: String?) -> AppIcon {
        guard let name = alternateIconName else { return .default }
        return AppIcon(rawValue: name) ?? .default
    }
}

/// Manages alternate app icon selection at runtime.
///
/// Uses `UIApplication.shared.setAlternateIconName(_:)` to switch icons
/// and persists the user's choice in `User.shared`.
public final class AppIconManager {

    public static let shared = AppIconManager()

    private let application: UIApplication?

    /// Initializes the manager.
    ///
    /// - Parameter application: The `UIApplication` instance to use.
    ///   Pass `nil` during testing; in production the shared instance
    ///   resolves `UIApplication.shared` on the main thread automatically.
    public init(application: UIApplication? = nil) {
        self.application = application
    }

    /// Whether the device supports alternate app icons.
    public var supportsAlternateIcons: Bool {
        resolvedApplication?.supportsAlternateIcons ?? false
    }

    /// The currently active app icon, derived from the system state.
    public var currentIcon: AppIcon {
        AppIcon.current(alternateIconName: resolvedApplication?.alternateIconName)
    }

    /// Sets the app icon to the given value.
    ///
    /// The call is dispatched asynchronously to avoid
    /// `LSIconAlertManager` errors that occur when the system
    /// alert token is requested during an in-flight UI interaction.
    ///
    /// - Parameters:
    ///   - icon: The desired `AppIcon`.
    ///   - completion: Called on the main queue with an optional error.
    public func setIcon(_ icon: AppIcon, completion: ((Error?) -> Void)? = nil) {
        let app = resolvedApplication
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            app?.setAlternateIconName(icon.alternateIconName) { error in
                if error == nil {
                    User.shared.appIcon = icon
                }
                completion?(error)
            }
        }
    }

    // MARK: - Private

    private var resolvedApplication: UIApplication? {
        if let application { return application }
        guard Thread.isMainThread else {
            assertionFailure("AppIconManager: UIApplication.shared must be accessed from the main thread.")
            return nil
        }
        return UIApplication.shared
    }
}
