// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SnapshotTesting
import UIKit

/// An enum representing different device types and their corresponding `ViewImageConfig` configurations.
enum DeviceType: String, CaseIterable {
    case iPhone8_Portrait
    case iPhone8_Landscape
    case iPhone12Pro_Portrait
    case iPhone12Pro_Landscape
    case iPhone13ProMax_Portrait
    case iPhone13ProMax_Landscape
    case iPadPro_Portrait
    case iPadPro_Landscape
    
    var config: ViewImageConfig {
        switch self {
        case .iPhone8_Portrait:
            return ViewImageConfig.iPhone8(.portrait)
        case .iPhone8_Landscape:
            return ViewImageConfig.iPhone8(.landscape)
        case .iPhone12Pro_Portrait:
            return ViewImageConfig.iPhone12Pro(.portrait)
        case .iPhone12Pro_Landscape:
            return ViewImageConfig.iPhone12Pro(.landscape)
        case .iPhone13ProMax_Portrait:
            return ViewImageConfig.iPhone13ProMax(.portrait)
        case .iPhone13ProMax_Landscape:
            return ViewImageConfig.iPhone13ProMax(.landscape)
        case .iPadPro_Portrait:
            return ViewImageConfig.iPadPro12_9(.portrait)
        case .iPadPro_Landscape:
            return ViewImageConfig.iPadPro12_9(.landscape)
        }
    }
    
    /// Returns a `DeviceType` based on the provided device name and orientation.
    ///
    /// - Parameters:
    ///   - deviceName: The name of the device (e.g., "iPhone 8").
    ///   - orientation: The orientation of the device (e.g., "portrait").
    /// - Returns: The corresponding `DeviceType` or crashes 💥 if the combination is not supported.
    static func from(deviceName: String, orientation: String) -> DeviceType {
        switch (deviceName, orientation) {
        case ("iPhone 8", "portrait"):
            return .iPhone8_Portrait
        case ("iPhone 8", "landscape"):
            return .iPhone8_Landscape
        case ("iPhone 12 Pro", "portrait"):
            return .iPhone12Pro_Portrait
        case ("iPhone 12 Pro", "landscape"):
            return .iPhone12Pro_Landscape
        case ("iPhone 13 Pro Max", "portrait"):
            return .iPhone13ProMax_Portrait
        case ("iPhone 13 Pro Max", "landscape"):
            return .iPhone13ProMax_Landscape
        case ("iPad Pro (12.9-inch)", "portrait"):
            return .iPadPro_Portrait
        case ("iPad Pro (12.9-inch)", "landscape"):
            return .iPadPro_Landscape
        default:
            fatalError("Device Name \(deviceName) and Orientation \(orientation) not found. Please add them correctly.")
        }
    }
}
