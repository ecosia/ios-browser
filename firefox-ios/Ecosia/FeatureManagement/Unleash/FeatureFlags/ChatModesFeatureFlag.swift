// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Gates the Chat Modes feature: the omnibox plus-button replacement and the
/// chat modes section of the "AI tools" drawer. The File Upload drawer header
/// (Camera/Photos/Files) stays under `FileUploadFeatureFlag`.
public struct ChatModesFeatureFlag {

    private init() {}

    public static var isEnabled: Bool {
        Unleash.isEnabled(.chatModes)
    }
}
