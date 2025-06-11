// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

extension URLSessionConfiguration {
    
    public func withCloudFlareAuthParameters(environment: Environment = Environment.current) -> URLSessionConfiguration {
        if let auth = environment.cloudFlareAuth {
            httpAdditionalHeaders = [
                CloudflareKeyProvider.clientId: auth.id,
                CloudflareKeyProvider.clientSecret: auth.secret
            ]
        }
        return self
    }
}
