// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension FileUploadService {

    /// A response that the upload step couldn't use, such as a 403 or a redirect URLSession didn't follow.
    public struct UnexpectedResponse: Equatable, Sendable, CustomStringConvertible {
        public enum Step: String, Sendable {
            case refresh
            case presign
            case put
        }

        public let step: Step
        public let statusCode: Int
        /// Cloudflare's request ID, which looks the request up in Security Events.
        public let rayID: String?
        /// Set by Cloudflare when it challenged the request instead of forwarding it, e.g. `challenge`.
        public let cloudflareMitigation: String?
        /// Recorded instead of the body, which can echo signed upload URLs or internal error text.
        public let contentType: String?

        init(step: Step, response: HTTPURLResponse?) {
            self.step = step
            statusCode = response?.statusCode ?? -1
            rayID = response?.value(forHTTPHeaderField: "cf-ray")
            cloudflareMitigation = response?.value(forHTTPHeaderField: "cf-mitigated")
            contentType = response?.value(forHTTPHeaderField: "Content-Type")
        }

        public var description: String {
            "\(step.rawValue) unexpected response status=\(statusCode) cf-ray=\(rayID ?? "none") " +
                "cf-mitigated=\(cloudflareMitigation ?? "none") content-type=\(contentType ?? "none")"
        }
    }
}
