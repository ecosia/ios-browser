// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

extension URL {

    public var isHTTPS: Bool {
        scheme == "https"
    }
    
    /// This computed var is utilized to determine whether a Website is considered secure from the Ecosia's perspective
    /// We use it mainly to define the UI that tells the user that the currently visited website is secure
    /// When the URL page isn't loaded properly for some reason, we still lookup the website that is being loaded, and determine its security
    /// so the end user alway have an idea of the website being loaded shown in the URL bar and avoid any UI misalignment showing the `warning` icon for a secure website
    /// having issues to load
    /// In case at least one of the flags evaluates to `true`, we consider the URL secure.
    public var isSecure: Bool {
        let isOriginalUrlFromErrorPageSecure = InternalURL(self)?.originalURLFromErrorPage?.isHTTPS == true
        let internalUrlIsNotErrorPage = InternalURL(self)?.isErrorPage == false
        let securityFlags = [isOriginalUrlFromErrorPageSecure, internalUrlIsNotErrorPage, isHTTPS, isReaderModeURL]
        return securityFlags.first(where: { $0 == true }) ?? false
    }
}

extension URL {
    
    /// Retrieves or creates a local URL for a given image set.
    ///
    /// This function looks in the app's cache directory to see if an image with the given name and file extension
    /// already exists. If it does, it returns the URL pointing to this cached image.
    /// If the image does not exist, it attempts to create it from the app's assets and save it in the cache directory.
    ///
    /// - Parameters:
    ///   - name: The name of the image set.
    ///   - extension: The file extension of the image (e.g., "png", "jpg", "pdf").
    ///
    /// - Returns: The local URL of the image in the cache directory. Returns `nil` if the operation fails.
    static func localURLForImageset(name: String, withExtension extension: String) -> URL? {
        // Get default FileManager
        let fileManager = FileManager.default

        // Get the cache directory for the app
        guard let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }

        // Append image name and extension to form the complete URL
        let url = cacheDirectory.appendingPathComponent("\(name).\(`extension`)")

        // Check if the file already exists at the given path
        let path = url.path
        if !fileManager.fileExists(atPath: path) {
            // Create image data from assets and save it to the given path if it doesn't exist
            guard let image = UIImage(named: name), let data = image.pngData() else { return nil }
            fileManager.createFile(atPath: path, contents: data, attributes: nil)
        }

        // Return the local URL
        return url
    }
}
