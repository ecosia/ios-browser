// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

public struct EcosiaAISearchButtonTheme: EcosiaThemeable {
    public var iconColor = Color.primary

    public init() {}

    public mutating func applyTheme(theme: Theme) {
        iconColor = Color(theme.colors.ecosia.textPrimary)
    }
}
