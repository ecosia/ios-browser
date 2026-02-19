// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

enum WallpaperURLType {
    case metadata
    case image(named: String, withFolderName: String)
}

struct WallpaperURLProvider {
    // MARK: - Properties
    enum URLProviderError: Error {
        case noBundledURL
        case invalidURL
    }

    enum WallpaperMetadataEndpoint: String {
        case v1
    }

    private let wallpaperURLScheme = "MozWallpaperURLScheme"
    static let testURL = "https://my.test.url"
    let currentMetadataEndpoint: WallpaperMetadataEndpoint = .v1

    func url(for urlType: WallpaperURLType) throws -> URL {
        print("🐛 WALLPAPER: WallpaperURLProvider.url(for:) called with type: \(urlType)")
        switch urlType {
        case .metadata:
            let metadataURL = try metadataURL()
            print("🐛 WALLPAPER: metadataURL = \(metadataURL)")
            return metadataURL
        case .image(let fileName, let folderName):
            return try imageURLWith(folderName, and: fileName)
        }
    }

    private func metadataURL() throws -> URL {
        // TEMPORARY HARDCODE: Bypass Info.plist for debugging
        // TODO: fetch from buildconfig
        print("🐛 WALLPAPER: Using hardcoded metadata URL (cdn2)")
        return URL(string: "https://raw.githubusercontent.com/ecosia/ios-browser/refs/heads/copilot/add-background-to-ecosian-ntp/docs/cdn2/metadata/v1/wallpapers.json")!
    }

    private func imageURLWith(_ key: String, and fileName: String) throws -> URL {
        // TEMPORARY HARDCODE: Use same base URL as metadata
        // TODO: fetch from buildconfig
        let baseURL = "https://raw.githubusercontent.com/ecosia/ios-browser/refs/heads/copilot/add-background-to-ecosian-ntp/docs/cdn2"
        print("🐛 WALLPAPER: imageURLWith baseURL=\(baseURL), key=\(key), fileName=\(fileName)")
        guard let url = URL(string: "\(baseURL)/\(key)/\(fileName).jpg") else {
            print("🐛 WALLPAPER: Failed to create URL from \(baseURL)/\(key)/\(fileName).jpg")
            throw URLProviderError.invalidURL
        }
        print("🐛 WALLPAPER: Created image URL: \(url)")
        return url
    }

    /// Builds a URL for the server based on the specified environment.
    private func urlScheme() throws -> String {
        if AppConstants.isRunningTest { return WallpaperURLProvider.testURL }

        let bundle = AppInfo.applicationBundle
        guard let appToken = bundle.object(forInfoDictionaryKey: wallpaperURLScheme) as? String,
              !appToken.isEmpty
        else { throw URLProviderError.noBundledURL }

        return appToken
    }
}
