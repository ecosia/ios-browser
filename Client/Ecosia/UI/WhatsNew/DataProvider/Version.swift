// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Represents a semantic version of an app.
///
/// A semantic version is typically represented as a series of numbers separated by dots, e.g., "1.0.0".
struct Version: CustomStringConvertible {
    
    static let appVersionUpdateKey = "appVersionUpdateKey"
    var major: Int
    var minor: Int
    var patch: Int
    
    /// Initializes a new `Version` from a string representation.
    ///
    /// - Parameter versionString: A string containing the semantic version, e.g., "1.0.0".
    init?(_ versionString: String) {
        let components = versionString.split(separator: ".")
        guard components.count == 3,
              let major = Int(components[0]),
              let minor = Int(components[1]),
              let patch = Int(components[2]) else {
            return nil
        }
        
        self.major = major
        self.minor = minor
        self.patch = patch
    }
        
    /// A string representation of the `Version`.
    var description: String {
        return "\(major).\(minor).\(patch)"
    }
}

extension Version: Comparable {
    
    /// Compares two `Version` instances for equality.
    ///
    /// - Parameters:
    ///   - lhs: A `Version`.
    ///   - rhs: Another `Version`.
    ///
    /// - Returns: `true` if both instances represent the same version, `false` otherwise.
    static func ==(lhs: Version, rhs: Version) -> Bool {
        return lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch
    }
    
    /// Compares two `Version` instances to determine their ordering.
    ///
    /// - Parameters:
    ///   - lhs: A `Version`.
    ///   - rhs: Another `Version`.
    ///
    /// - Returns: `true` if the instance on the left should come before the one on the right, `false` otherwise.
    static func <(lhs: Version, rhs: Version) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        }
        if lhs.minor != rhs.minor {
            return lhs.minor < rhs.minor
        }
        return lhs.patch < rhs.patch
    }
}

extension Version: Hashable {
    
    /// Adds this value to the given hasher.
    ///
    /// - Parameter hasher: The hasher to use when combining the components of this instance.
    func hash(into hasher: inout Hasher) {
        hasher.combine(major)
        hasher.combine(minor)
        hasher.combine(patch)
    }
}

/// Extension handling previous version retrieval and saving current version.
extension Version {
    
    /// Retrieve the previously saved version or save the current version if none exists.
    ///
    /// This method tries to retrieve a previously saved version from `UserDefaults`.
    /// If no version has been saved before, it saves the `current` version passed into the function.
    ///
    /// - Parameters:
    ///   - current: The current `Version` to save if no version exists. Optional.
    ///   - prefs: The `UserDefaults` instance to use for saving and retrieving the version.
    ///            Defaults to `UserDefaults.standard`.
    ///
    /// - Returns: The previously saved `Version` if it exists, otherwise returns the current version.
    ///            Returns `nil` if both the saved version and the current version are `nil`.
    static func retrievePreviousVersionElseSaveCurrent(_ current: Version?, using prefs: UserDefaults = UserDefaults.standard) -> Version? {
        guard let savedVersionString = prefs.string(forKey: Version.appVersionUpdateKey),
              let savedVersion = Version(savedVersionString),
              let current else {
                save(current, using: prefs)
                return current
        }
        if savedVersion != current {
            save(current, using: prefs)
        }
        return current
    }

    /// Save the specified app version to `UserDefaults`.
    ///
    /// This method takes a `Version` object and saves its description to `UserDefaults`
    /// using a predefined key.
    ///
    /// - Parameters:
    ///   - version: The `Version` instance representing the app version to be saved.
    ///   - prefs: The `UserDefaults` instance to use for saving the version.
    ///            Defaults to `UserDefaults.standard`.
    private static func save(_ version: Version?, using prefs: UserDefaults = UserDefaults.standard) {
        guard let version else { return }
        prefs.set(version.description, forKey: Version.appVersionUpdateKey)
    }
}
