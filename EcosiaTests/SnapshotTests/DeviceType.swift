// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SnapshotTesting
import UIKit

/// An enum representing different device types and their corresponding `ViewImageConfig` configurations.
enum DeviceType: String, CaseIterable {
    case iPhoneSE_Portrait
    case iPhoneSE_Landscape
    case iPhone14Pro_Portrait
    case iPhone14Pro_Landscape
    case iPhone14ProMax_Portrait
    case iPhone14ProMax_Landscape
    case iPadPro_Portrait
    case iPadPro_Landscape
    
    var config: ViewImageConfig {
        switch self {
        case .iPhoneSE_Portrait:
            return ViewImageConfig.iPhone8(.portrait)
        case .iPhoneSE_Landscape:
            return ViewImageConfig.iPhone8(.landscape)
        case .iPhone14Pro_Portrait:
            return ViewImageConfig.iPhone13Pro(.portrait)
        case .iPhone14Pro_Landscape:
            return ViewImageConfig.iPhone13Pro(.landscape)
        case .iPhone14ProMax_Portrait:
            return ViewImageConfig.iPhone13ProMax(.portrait)
        case .iPhone14ProMax_Landscape:
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
        case ("iPhone SE (3rd generation)", "portrait"):
            return .iPhoneSE_Portrait
        case ("iPhone SE (3rd generation)", "landscape"):
            return .iPhoneSE_Landscape
        case ("iPhone 14 Pro", "portrait"):
            return .iPhone14Pro_Portrait
        case ("iPhone 14 Pro", "landscape"):
            return .iPhone14Pro_Landscape
        case ("iPhone 14 Pro Max", "portrait"):
            return .iPhone14ProMax_Portrait
        case ("iPhone 14 Pro Max", "landscape"):
            return .iPhone14ProMax_Landscape
        case ("iPad Pro (12.9-inch) (6th generation)", "portrait"):
            return .iPadPro_Portrait
        case ("iPad Pro (12.9-inch) (6th generation)", "landscape"):
            return .iPadPro_Landscape
        default:
            fatalError("Device Name \(deviceName) and Orientation \(orientation) not found. Please add them correctly.")
        }
    }
}
