// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

extension URLRequest {

    /// Name of the header identifying the Ecosia app to Ecosia backends.
    public static let ecosiaAppHeaderField = "X-Ecosia-App"

    /// Value of ``ecosiaAppHeaderField``: `<platform>[/<version>]`, e.g. `ios/12.5.0`.
    public static var ecosiaAppHeaderValue: String {
        "ios/\(AppInfo.ecosiaAppVersion)"
    }

    @discardableResult
    public mutating func withCloudFlareAuthParameters(environment: Environment = EcosiaEnvironment.current) -> URLRequest {
        withCloudFlareAuthParameters(auth: environment.cloudFlareAuth)
    }

    /// Internal overload that accepts auth directly, enabling unit tests to inject credentials
    /// without relying on process-info environment variables.
    @discardableResult
    mutating func withCloudFlareAuthParameters(auth: Environment.CloudFlareAuth?) -> URLRequest {
        if let auth {
            setValue(auth.id, forHTTPHeaderField: CloudflareKeyProvider.clientId)
            setValue(auth.secret, forHTTPHeaderField: CloudflareKeyProvider.clientSecret)
        }
        return self
    }

    /// This function provides an additional HTTP request header when loading SERP through native UI (i.e. submitting a search)
    /// to help SERP decide which market to serve.
    public mutating func addLanguageRegionHeader() {
        setValue(Locale.current.identifierWithDashedLanguageAndRegion, forHTTPHeaderField: "x-ecosia-app-language-region")
    }

    /// Identifies the app and its version to Ecosia backends.
    /// Callers must scope this to Ecosia-owned hosts; it must never reach a third party.
    public mutating func addEcosiaAppHeader() {
        setValue(Self.ecosiaAppHeaderValue, forHTTPHeaderField: Self.ecosiaAppHeaderField)
    }
}
